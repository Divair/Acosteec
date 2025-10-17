#INCLUDE "protheus.ch"

#DEFINE SIMPLES Char( 39 )
#DEFINE DUPLAS  Char( 34 )

#DEFINE CSSBOTAO	"QPushButton { color: #024670; "+;
"    border-image: url(rpo:fwstd_btn_nml.png) 3 3 3 3 stretch; "+;
"    border-top-width: 3px; "+;
"    border-left-width: 3px; "+;
"    border-right-width: 3px; "+;
"    border-bottom-width: 3px }"+;
"QPushButton:pressed {	color: #FFFFFF; "+;
"    border-image: url(rpo:fwstd_btn_prd.png) 3 3 3 3 stretch; "+;
"    border-top-width: 3px; "+;
"    border-left-width: 3px; "+;
"    border-right-width: 3px; "+;
"    border-bottom-width: 3px }"

//--------------------------------------------------------------------
/*/{Protheus.doc} UPDCRM

Fun��o de update de dicion�rios para compatibiliza��o

@author UPDATE gerado automaticamente
@since  01/10/2025
@obs    Gerado por EXPORDIC - V.8.0.1.0 EFS / Upd. V.6.4.1 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
User Function UPDPROG( cEmpAmb, cFilAmb )
Local   aSay      := {}
Local   aButton   := {}
Local   aMarcadas := {}
Local   cTitulo   := "ATUALIZA��O DE DICION�RIOS E TABELAS"
Local   cDesc1    := "Esta rotina tem como fun��o fazer  a atualiza��o  dos dicion�rios do Sistema ( SX?/SIX )"
Local   cDesc2    := "Este processo deve ser executado em modo EXCLUSIVO, ou seja n�o podem haver outros"
Local   cDesc3    := "usu�rios  ou  jobs utilizando  o sistema.  � EXTREMAMENTE recomendav�l  que  se  fa�a"
Local   cDesc4    := "um BACKUP  dos DICION�RIOS  e da  BASE DE DADOS antes desta atualiza��o, para"
Local   cDesc5    := "que caso ocorram eventuais falhas, esse backup possa ser restaurado."
Local   cDesc6    := ""
Local   cDesc7    := ""
Local   cMsg      := ""
Local   lOk       := .F.
Local   lAuto     := ( cEmpAmb <> NIL .or. cFilAmb <> NIL )

Private oMainWnd  := NIL
Private oProcess  := NIL

#IFDEF TOP
    TCInternal( 5, "*OFF" ) // Desliga Refresh no Lock do Top
#ENDIF

__cInterNet := NIL
__lPYME     := .F.



Set Dele On

// Mensagens de Tela Inicial
aAdd( aSay, cDesc1 )
aAdd( aSay, cDesc2 )
aAdd( aSay, cDesc3 )
aAdd( aSay, cDesc4 )
aAdd( aSay, cDesc5 )
//aAdd( aSay, cDesc6 )
//aAdd( aSay, cDesc7 )

// Botoes Tela Inicial
aAdd(  aButton, {  1, .T., { || lOk := .T., FechaBatch() } } )
aAdd(  aButton, {  2, .T., { || lOk := .F., FechaBatch() } } )

MSGALERT('OI d')

If lAuto
	lOk := .T.
Else
	FormBatch(  cTitulo,  aSay,  aButton )
EndIf



If lOk

	If GetVersao(.F.) < "12" .OR. ( FindFunction( "MPDicInDB" ) .AND. !MPDicInDB() )
		cMsg := "Este update N�O PODE ser executado neste Ambiente." + CRLF + CRLF + ;
				"Os arquivos de dicion�rios se encontram em formato ISAM" + " (" + GetDbExtension() + ") " + "Os arquivos de dicion�rios se encontram em formato ISAM" + " " + ;
				"para atualizar apenas ambientes com dicion�rios no Banco de Dados."

		If lAuto
			AutoGrLog( Replicate( "-", 128 ) )
			AutoGrLog( Replicate( " ", 128 ) )
			AutoGrLog( "LOG DA ATUALIZA��O DOS DICION�RIOS" )
			AutoGrLog( Replicate( " ", 128 ) )
			AutoGrLog( Replicate( "-", 128 ) )
			AutoGrLog( Replicate( " ", 128 ) )
			AutoGrLog( cMsg )
			ConOut( DToC(Date()) + "|" + Time() + cMsg )
		Else
			MsgInfo( cMsg )
		EndIf

		Return NIL
	EndIf

	If lAuto
		aMarcadas :={{ cEmpAmb, cFilAmb, "" }}
	Else
		aMarcadas := EscEmpresa()
	EndIf

	If !Empty( aMarcadas )
		If lAuto .OR. MsgNoYes( "Confirma a atualiza��o dos dicion�rios ?", cTitulo )
			oProcess := MsNewProcess():New( { | lEnd | lOk := FSTProc( @lEnd, aMarcadas, lAuto ) }, "Atualizando", "Aguarde, atualizando ...", .F. )
			oProcess:Activate()

			If lAuto
				If lOk
					MsgInfo( "Atualiza��o realizada.", "UPDCRM" )
				Else
					MsgStop( "Atualiza��o n�o realizada.", "UPDCRM" )
				EndIf
				dbCloseAll()
			Else
				If lOk
					Final( "Atualiza��o realizada." )
				Else
					Final( "Atualiza��o n�o realizada." )
				EndIf
			EndIf

		Else
			Final( "Atualiza��o n�o realizada." )

		EndIf

	Else
		Final( "Atualiza��o n�o realizada." )

	EndIf

EndIf

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} FSTProc

Fun��o de processamento da grava��o dos arquivos

@author UPDATE gerado automaticamente
@since  01/10/2025
@obs    Gerado por EXPORDIC - V.8.0.1.0 EFS / Upd. V.6.4.1 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function FSTProc( lEnd, aMarcadas, lAuto )
Local   aInfo     := {}
Local   aRecnoSM0 := {}
Local   cAux      := ""
Local   cFile     := ""
Local   cFileLog  := ""
Local   cMask     := "Arquivos Texto" + "(*.TXT)|*.txt|"
Local   cTCBuild  := "TCGetBuild"
Local   cTexto    := ""
Local   cTopBuild := ""
Local   lOpen     := .F.
Local   lRet      := .T.
Local   nI        := 0
Local   nPos      := 0
Local   nRecno    := 0
Local   nX        := 0
Local   oDlg      := NIL
Local   oFont     := NIL
Local   oMemo     := NIL

Private aArqUpd   := {}

If ( lOpen := MyOpenSm0(.T.) )

	dbSelectArea( "SM0" )
	dbGoTop()

	While !SM0->( EOF() )
		// S� adiciona no aRecnoSM0 se a empresa for diferente
		If aScan( aRecnoSM0, { |x| x[2] == SM0->M0_CODIGO } ) == 0 ;
		   .AND. aScan( aMarcadas, { |x| x[1] == SM0->M0_CODIGO } ) > 0
			aAdd( aRecnoSM0, { Recno(), SM0->M0_CODIGO } )
		EndIf
		SM0->( dbSkip() )
	End

	SM0->( dbCloseArea() )

	If lOpen

		For nI := 1 To Len( aRecnoSM0 )

			If !( lOpen := MyOpenSm0(.F.) )
				MsgStop( "Atualiza��o da empresa " + aRecnoSM0[nI][2] + " n�o efetuada." )
				Exit
			EndIf

			SM0->( dbGoTo( aRecnoSM0[nI][1] ) )

			RpcSetEnv( SM0->M0_CODIGO, SM0->M0_CODFIL )

			lMsFinalAuto := .F.
			lMsHelpAuto  := .F.

			AutoGrLog( Replicate( "-", 128 ) )
			AutoGrLog( Replicate( " ", 128 ) )
			AutoGrLog( "LOG DA ATUALIZA��O DOS DICION�RIOS" )
			AutoGrLog( Replicate( " ", 128 ) )
			AutoGrLog( Replicate( "-", 128 ) )
			AutoGrLog( " " )
			AutoGrLog( " Dados Ambiente" )
			AutoGrLog( " --------------------" )
			AutoGrLog( " Empresa / Filial...: " + cEmpAnt + "/" + cFilAnt )
			AutoGrLog( " Nome Empresa.......: " + Capital( AllTrim( GetAdvFVal( "SM0", "M0_NOMECOM", cEmpAnt + cFilAnt, 1, "" ) ) ) )
			AutoGrLog( " Nome Filial........: " + Capital( AllTrim( GetAdvFVal( "SM0", "M0_FILIAL" , cEmpAnt + cFilAnt, 1, "" ) ) ) )
			AutoGrLog( " DataBase...........: " + DtoC( dDataBase ) )
			AutoGrLog( " Data / Hora �nicio.: " + DtoC( Date() )  + " / " + Time() )
			AutoGrLog( " Environment........: " + GetEnvServer()  )
			AutoGrLog( " StartPath..........: " + GetSrvProfString( "StartPath", "" ) )
			AutoGrLog( " RootPath...........: " + GetSrvProfString( "RootPath" , "" ) )
			AutoGrLog( " Vers�o.............: " + GetVersao(.T.) )
			AutoGrLog( " Usu�rio TOTVS .....: " + __cUserId + " " +  cUserName )
			AutoGrLog( " Computer Name......: " + GetComputerName() )

			aInfo   := GetUserInfo()
			If ( nPos    := aScan( aInfo,{ |x,y| x[3] == ThreadId() } ) ) > 0
				AutoGrLog( " " )
				AutoGrLog( " Dados Thread" )
				AutoGrLog( " --------------------" )
				AutoGrLog( " Usu�rio da Rede....: " + aInfo[nPos][1] )
				AutoGrLog( " Esta��o............: " + aInfo[nPos][2] )
				AutoGrLog( " Programa Inicial...: " + aInfo[nPos][5] )
				AutoGrLog( " Environment........: " + aInfo[nPos][6] )
				AutoGrLog( " Conex�o............: " + AllTrim( StrTran( StrTran( aInfo[nPos][7], Chr( 13 ), "" ), Chr( 10 ), "" ) ) )
			EndIf
			AutoGrLog( Replicate( "-", 128 ) )
			AutoGrLog( " " )

			If !lAuto
				AutoGrLog( Replicate( "-", 128 ) )
				AutoGrLog( "Empresa : " + SM0->M0_CODIGO + "/" + SM0->M0_NOME + CRLF )
			EndIf

			oProcess:SetRegua1( 8 )

			//------------------------------------
			// Atualiza o dicion�rio SX2
			//------------------------------------
			oProcess:IncRegua1( "Dicion�rio de arquivos" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
			FSAtuSX2()

			//------------------------------------
			// Atualiza o dicion�rio SX3
			//------------------------------------
			FSAtuSX3()

			//------------------------------------
			// Atualiza o dicion�rio SIX
			//------------------------------------
			oProcess:IncRegua1( "Dicion�rio de �ndices" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
			FSAtuSIX()

			oProcess:IncRegua1( "Dicion�rio de dados" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
			oProcess:IncRegua2( "Atualizando campos/�ndices" )

			// Altera��o f�sica dos arquivos
			__SetX31Mode( .F. )

			If FindFunction(cTCBuild)
				cTopBuild := &cTCBuild.()
			EndIf

			For nX := 1 To Len( aArqUpd )

				If cTopBuild >= "20090811" .AND. TcInternal( 89 ) == "CLOB_SUPPORTED"
					If ( ( aArqUpd[nX] >= "NQ " .AND. aArqUpd[nX] <= "NZZ" ) .OR. ( aArqUpd[nX] >= "O0 " .AND. aArqUpd[nX] <= "NZZ" ) ) .AND.;
						!aArqUpd[nX] $ "NQD,NQF,NQP,NQT"
						TcInternal( 25, "CLOB" )
					EndIf
				EndIf

				If Select( aArqUpd[nX] ) > 0
					dbSelectArea( aArqUpd[nX] )
					dbCloseArea()
				EndIf

				X31UpdTable( aArqUpd[nX] )

				If __GetX31Error()
					Alert( __GetX31Trace() )
					MsgStop( "Ocorreu um erro desconhecido durante a atualiza��o da tabela : " + aArqUpd[nX] + ". Verifique a integridade do dicion�rio e da tabela.", "ATEN��O" )
					AutoGrLog( "Ocorreu um erro desconhecido durante a atualiza��o da estrutura da tabela : " + aArqUpd[nX] )
				EndIf

				If cTopBuild >= "20090811" .AND. TcInternal( 89 ) == "CLOB_SUPPORTED"
					TcInternal( 25, "OFF" )
				EndIf

			Next nX

			//------------------------------------
			// Atualiza o dicion�rio SX7
			//------------------------------------
			oProcess:IncRegua1( "Dicion�rio de gatilhos" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
			FSAtuSX7()

			//------------------------------------
			// Atualiza o dicion�rio SX5
			//------------------------------------
			oProcess:IncRegua1( "Dicion�rio de tabelas sistema" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
			FSAtuSX5()

			//------------------------------------
			// Atualiza o dicion�rio SX9
			//------------------------------------
			oProcess:IncRegua1( "Dicion�rio de relacionamentos" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
			FSAtuSX9()

			//------------------------------------
			// Atualiza os helps
			//------------------------------------
			oProcess:IncRegua1( "Helps de Campo" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
			FSAtuHlp()

			AutoGrLog( Replicate( "-", 128 ) )
			AutoGrLog( " Data / Hora Final.: " + DtoC( Date() ) + " / " + Time() )
			AutoGrLog( Replicate( "-", 128 ) )

			RpcClearEnv()

		Next nI

		If !lAuto

			cTexto := LeLog()

			Define Font oFont Name "Mono AS" Size 5, 12

			Define MsDialog oDlg Title "Atualiza��o concluida." From 3, 0 to 340, 417 Pixel

			@ 5, 5 Get oMemo Var cTexto Memo Size 200, 145 Of oDlg Pixel
			oMemo:bRClicked := { || AllwaysTrue() }
			oMemo:oFont     := oFont

			Define SButton From 153, 175 Type  1 Action oDlg:End() Enable Of oDlg Pixel // Apaga
			Define SButton From 153, 145 Type 13 Action ( cFile := cGetFile( cMask, "" ), If( cFile == "", .T., ;
			MemoWrite( cFile, cTexto ) ) ) Enable Of oDlg Pixel

			Activate MsDialog oDlg Center

		EndIf

	EndIf

Else

	lRet := .F.

EndIf

Return lRet


//--------------------------------------------------------------------
/*/{Protheus.doc} FSAtuSX2

Fun��o de processamento da grava��o do SX2 - Arquivos

@author UPDATE gerado automaticamente
@since  01/10/2025
@obs    Gerado por EXPORDIC - V.8.0.1.0 EFS / Upd. V.6.4.1 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function FSAtuSX2()
Local aEstrut   := {}
Local aSX2      := {}
Local cAlias    := ""
Local cCpoUpd   := "X2_ROTINA /X2_UNICO  /X2_DISPLAY/X2_SYSOBJ /X2_USROBJ /X2_POSLGT /"
Local cEmpr     := ""
Local cPath     := ""
Local nI        := 0
Local nJ        := 0

AutoGrLog( "�nicio da Atualiza��o" + " SX2" + CRLF )

aEstrut := { "X2_CHAVE"  , "X2_PATH"   , "X2_ARQUIVO", "X2_NOME"   , "X2_NOMESPA", "X2_NOMEENG", "X2_MODO"   , ;
             "X2_TTS"    , "X2_ROTINA" , "X2_PYME"   , "X2_UNICO"  , "X2_DISPLAY", "X2_SYSOBJ" , "X2_USROBJ" , ;
             "X2_POSLGT" , "X2_CLOB"   , "X2_AUTREC" , "X2_MODOEMP", "X2_MODOUN" , "X2_STAMP"  , "X2_INSDT"  , ;
             "X2_MODULO" }


dbSelectArea( "SX2" )
SX2->( dbSetOrder( 1 ) )
SX2->( dbGoTop() )
cPath := SX2->X2_PATH
cPath := IIf( Right( AllTrim( cPath ), 1 ) <> "\", PadR( AllTrim( cPath ) + "\", Len( cPath ) ), cPath )
cEmpr := Substr( SX2->X2_ARQUIVO, 4 )

//
// Tabela ZD4
//
aAdd( aSX2, { ;
	'ZD4'																	, ; //X2_CHAVE
	cPath																	, ; //X2_PATH
	'ZD4'+cEmpr																, ; //X2_ARQUIVO
	'CRM'																	, ; //X2_NOME
	'CRM'																	, ; //X2_NOMESPA
	'CRM'																	, ; //X2_NOMEENG
	'C'																		, ; //X2_MODO
	''																		, ; //X2_TTS
	''																		, ; //X2_ROTINA
	''																		, ; //X2_PYME
	'ZD4_FILIAL+ ZD4_CODCRM'												, ; //X2_UNICO
	''																		, ; //X2_DISPLAY
	''																		, ; //X2_SYSOBJ
	''																		, ; //X2_USROBJ
	''																		, ; //X2_POSLGT
	''																		, ; //X2_CLOB
	''																		, ; //X2_AUTREC
	'C'																		, ; //X2_MODOEMP
	'C'																		, ; //X2_MODOUN
	''																		, ; //X2_STAMP
	''																		, ; //X2_INSDT
	0																		} ) //X2_MODULO

//
// Tabela ZD5
//
aAdd( aSX2, { ;
	'ZD5'																	, ; //X2_CHAVE
	cPath																	, ; //X2_PATH
	'ZD5'+cEmpr																, ; //X2_ARQUIVO
	'ATIVIDADES CRM'														, ; //X2_NOME
	'ATIVIDADES CRM'														, ; //X2_NOMESPA
	'ATIVIDADES CRM'														, ; //X2_NOMEENG
	'C'																		, ; //X2_MODO
	''																		, ; //X2_TTS
	''																		, ; //X2_ROTINA
	''																		, ; //X2_PYME
	''																		, ; //X2_UNICO
	''																		, ; //X2_DISPLAY
	''																		, ; //X2_SYSOBJ
	''																		, ; //X2_USROBJ
	''																		, ; //X2_POSLGT
	''																		, ; //X2_CLOB
	''																		, ; //X2_AUTREC
	'C'																		, ; //X2_MODOEMP
	'C'																		, ; //X2_MODOUN
	''																		, ; //X2_STAMP
	''																		, ; //X2_INSDT
	0																		} ) //X2_MODULO

//
// Atualizando dicion�rio
//
oProcess:SetRegua2( Len( aSX2 ) )

dbSelectArea( "SX2" )
dbSetOrder( 1 )

For nI := 1 To Len( aSX2 )

	oProcess:IncRegua2( "Atualizando Arquivos (SX2) ..." )

	If !SX2->( dbSeek( aSX2[nI][1] ) )

		If !( aSX2[nI][1] $ cAlias )
			cAlias += aSX2[nI][1] + "/"
			AutoGrLog( "Foi inclu�da a tabela " + aSX2[nI][1] )
		EndIf

		RecLock( "SX2", .T. )
		For nJ := 1 To Len( aSX2[nI] )
			If FieldPos( aEstrut[nJ] ) > 0
				If AllTrim( aEstrut[nJ] ) == "X2_ARQUIVO"
					FieldPut( FieldPos( aEstrut[nJ] ), SubStr( aSX2[nI][nJ], 1, 3 ) + cEmpAnt +  "0" )
				Else
					FieldPut( FieldPos( aEstrut[nJ] ), aSX2[nI][nJ] )
				EndIf
			EndIf
		Next nJ
		MsUnLock()

	Else

		If  !( StrTran( Upper( AllTrim( SX2->X2_UNICO ) ), " ", "" ) == StrTran( Upper( AllTrim( aSX2[nI][12]  ) ), " ", "" ) )
			RecLock( "SX2", .F. )
			SX2->X2_UNICO := aSX2[nI][12]
			MsUnlock()

			If MSFILE( RetSqlName( aSX2[nI][1] ),RetSqlName( aSX2[nI][1] ) + "_UNQ"  )
				TcInternal( 60, RetSqlName( aSX2[nI][1] ) + "|" + RetSqlName( aSX2[nI][1] ) + "_UNQ" )
			EndIf

			AutoGrLog( "Foi alterada a chave �nica da tabela " + aSX2[nI][1] )
		EndIf

		RecLock( "SX2", .F. )
		For nJ := 1 To Len( aSX2[nI] )
			If FieldPos( aEstrut[nJ] ) > 0
				If PadR( aEstrut[nJ], 10 ) $ cCpoUpd
					FieldPut( FieldPos( aEstrut[nJ] ), aSX2[nI][nJ] )
				EndIf

			EndIf
		Next nJ
		MsUnLock()

	EndIf

Next nI

AutoGrLog( CRLF + "Final da Atualiza��o" + " SX2" + CRLF + Replicate( "-", 128 ) + CRLF )

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} FSAtuSX3

Fun��o de processamento da grava��o do SX3 - Campos

@author UPDATE gerado automaticamente
@since  01/10/2025
@obs    Gerado por EXPORDIC - V.8.0.1.0 EFS / Upd. V.6.4.1 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function FSAtuSX3()
Local aEstrut   := {}
Local aSX3      := {}
Local cAlias    := ""
Local cAliasAtu := ""
Local cMsg      := ""
Local cSeqAtu   := ""
Local cX3Campo  := ""
Local cX3Dado   := ""
Local lTodosNao := .F.
Local lTodosSim := .F.
Local nI        := 0
Local nJ        := 0
Local nOpcA     := 0
Local nPosArq   := 0
Local nPosCpo   := 0
Local nPosOrd   := 0
Local nPosSXG   := 0
Local nPosTam   := 0
Local nPosVld   := 0
Local nSeqAtu   := 0
Local nTamSeek  := Len( SX3->X3_CAMPO )

AutoGrLog( "�nicio da Atualiza��o" + " SX3" + CRLF )

aEstrut := { { "X3_ARQUIVO", 0 }, { "X3_ORDEM"  , 0 }, { "X3_CAMPO"  , 0 }, { "X3_TIPO"   , 0 }, { "X3_TAMANHO", 0 }, { "X3_DECIMAL", 0 }, { "X3_TITULO" , 0 }, ;
             { "X3_TITSPA" , 0 }, { "X3_TITENG" , 0 }, { "X3_DESCRIC", 0 }, { "X3_DESCSPA", 0 }, { "X3_DESCENG", 0 }, { "X3_PICTURE", 0 }, { "X3_VALID"  , 0 }, ;
             { "X3_USADO"  , 0 }, { "X3_RELACAO", 0 }, { "X3_F3"     , 0 }, { "X3_NIVEL"  , 0 }, { "X3_RESERV" , 0 }, { "X3_CHECK"  , 0 }, { "X3_TRIGGER", 0 }, ;
             { "X3_PROPRI" , 0 }, { "X3_BROWSE" , 0 }, { "X3_VISUAL" , 0 }, { "X3_CONTEXT", 0 }, { "X3_OBRIGAT", 0 }, { "X3_VLDUSER", 0 }, { "X3_CBOX"   , 0 }, ;
             { "X3_CBOXSPA", 0 }, { "X3_CBOXENG", 0 }, { "X3_PICTVAR", 0 }, { "X3_WHEN"   , 0 }, { "X3_INIBRW" , 0 }, { "X3_GRPSXG" , 0 }, { "X3_FOLDER" , 0 }, ;
             { "X3_CONDSQL", 0 }, { "X3_CHKSQL" , 0 }, { "X3_IDXSRV" , 0 }, { "X3_ORTOGRA", 0 }, { "X3_TELA"   , 0 }, { "X3_POSLGT" , 0 }, { "X3_IDXFLD" , 0 }, ;
             { "X3_AGRUP"  , 0 }, { "X3_MODAL"  , 0 }, { "X3_PYME"   , 0 } }

aEval( aEstrut, { |x| x[2] := SX3->( FieldPos( x[1] ) ) } )

//
// --- ATEN��O ---
// Coloque .F. na 2a. posi��o de cada elemento do array, para os dados do SX3
// que n�o ser�o atualizados quando o campo j� existir.
//

//
// Campos Tabela ZD4
//
aAdd( aSX3, { ;
	{ 'ZD4'																	, .T. }, ; //X3_ARQUIVO
	{ '01'																	, .T. }, ; //X3_ORDEM
	{ 'ZD4_FILIAL'															, .T. }, ; //X3_CAMPO
	{ 'C'																	, .T. }, ; //X3_TIPO
	{ 2																		, .T. }, ; //X3_TAMANHO
	{ 0																		, .T. }, ; //X3_DECIMAL
	{ 'Filial'																, .T. }, ; //X3_TITULO
	{ 'Sucursal'															, .T. }, ; //X3_TITSPA
	{ 'Branch'																, .T. }, ; //X3_TITENG
	{ 'Filial do Sistema'													, .T. }, ; //X3_DESCRIC
	{ 'Sucursal'															, .T. }, ; //X3_DESCSPA
	{ 'Branch of the System'												, .T. }, ; //X3_DESCENG
	{ '@!'																	, .T. }, ; //X3_PICTURE
	{ ''																	, .T. }, ; //X3_VALID
	{ 'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x', .T. }, ; //X3_USADO
	{ ''																	, .T. }, ; //X3_RELACAO
	{ ''																	, .T. }, ; //X3_F3
	{ 1																		, .T. }, ; //X3_NIVEL
	{ 'XXXXXX X'															, .T. }, ; //X3_RESERV
	{ ''																	, .T. }, ; //X3_CHECK
	{ ''																	, .T. }, ; //X3_TRIGGER
	{ 'U'																	, .T. }, ; //X3_PROPRI
	{ 'N'																	, .T. }, ; //X3_BROWSE
	{ ''																	, .T. }, ; //X3_VISUAL
	{ ''																	, .T. }, ; //X3_CONTEXT
	{ ''																	, .T. }, ; //X3_OBRIGAT
	{ ''																	, .T. }, ; //X3_VLDUSER
	{ ''																	, .T. }, ; //X3_CBOX
	{ ''																	, .T. }, ; //X3_CBOXSPA
	{ ''																	, .T. }, ; //X3_CBOXENG
	{ ''																	, .T. }, ; //X3_PICTVAR
	{ ''																	, .T. }, ; //X3_WHEN
	{ ''																	, .T. }, ; //X3_INIBRW
	{ '033'																	, .T. }, ; //X3_GRPSXG
	{ ''																	, .T. }, ; //X3_FOLDER
	{ ''																	, .T. }, ; //X3_CONDSQL
	{ ''																	, .T. }, ; //X3_CHKSQL
	{ ''																	, .T. }, ; //X3_IDXSRV
	{ ''																	, .T. }, ; //X3_ORTOGRA
	{ ''																	, .T. }, ; //X3_TELA
	{ ''																	, .T. }, ; //X3_POSLGT
	{ ''																	, .T. }, ; //X3_IDXFLD
	{ ''																	, .T. }, ; //X3_AGRUP
	{ ''																	, .T. }, ; //X3_MODAL
	{ ''																	, .T. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'ZD4'																	, .T. }, ; //X3_ARQUIVO
	{ '02'																	, .T. }, ; //X3_ORDEM
	{ 'ZD4_STATUS'															, .T. }, ; //X3_CAMPO
	{ 'C'																	, .T. }, ; //X3_TIPO
	{ 1																		, .T. }, ; //X3_TAMANHO
	{ 0																		, .T. }, ; //X3_DECIMAL
	{ 'Status'																, .T. }, ; //X3_TITULO
	{ 'Status'																, .T. }, ; //X3_TITSPA
	{ 'Status'																, .T. }, ; //X3_TITENG
	{ 'Status'																, .T. }, ; //X3_DESCRIC
	{ 'Status'																, .T. }, ; //X3_DESCSPA
	{ 'Status'																, .T. }, ; //X3_DESCENG
	{ ''																	, .T. }, ; //X3_PICTURE
	{ ''																	, .T. }, ; //X3_VALID
	{ 'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x', .T. }, ; //X3_USADO
	{ '1'																	, .T. }, ; //X3_RELACAO
	{ ''																	, .T. }, ; //X3_F3
	{ 0																		, .T. }, ; //X3_NIVEL
	{ 'xxxxxx x'															, .T. }, ; //X3_RESERV
	{ ''																	, .T. }, ; //X3_CHECK
	{ ''																	, .T. }, ; //X3_TRIGGER
	{ 'U'																	, .T. }, ; //X3_PROPRI
	{ 'S'																	, .T. }, ; //X3_BROWSE
	{ 'V'																	, .T. }, ; //X3_VISUAL
	{ 'R'																	, .T. }, ; //X3_CONTEXT
	{ 'x'																	, .T. }, ; //X3_OBRIGAT
	{ ''																	, .T. }, ; //X3_VLDUSER
	{ '1=Aberto;2=Efetuado;3=Perdido;4=Com Atividades;5=Com Atividades Vencidas;6=Cancelada', .T. }, ; //X3_CBOX
	{ '1=Aberto;2=Efetuado;3=Perdido;4=Com Atividades;5=Com Atividades Vencidas;6=Cancelada', .T. }, ; //X3_CBOXSPA
	{ '1=Aberto;2=Efetuado;3=Perdido;4=Com Atividades;5=Com Atividades Vencidas;6=Cancelada', .T. }, ; //X3_CBOXENG
	{ ''																	, .T. }, ; //X3_PICTVAR
	{ ''																	, .T. }, ; //X3_WHEN
	{ ''																	, .T. }, ; //X3_INIBRW
	{ ''																	, .T. }, ; //X3_GRPSXG
	{ ''																	, .T. }, ; //X3_FOLDER
	{ ''																	, .T. }, ; //X3_CONDSQL
	{ ''																	, .T. }, ; //X3_CHKSQL
	{ ''																	, .T. }, ; //X3_IDXSRV
	{ 'N'																	, .T. }, ; //X3_ORTOGRA
	{ ''																	, .T. }, ; //X3_TELA
	{ ''																	, .T. }, ; //X3_POSLGT
	{ 'N'																	, .T. }, ; //X3_IDXFLD
	{ ''																	, .T. }, ; //X3_AGRUP
	{ ''																	, .T. }, ; //X3_MODAL
	{ ''																	, .T. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'ZD4'																	, .T. }, ; //X3_ARQUIVO
	{ '03'																	, .T. }, ; //X3_ORDEM
	{ 'ZD4_CODCRM'															, .T. }, ; //X3_CAMPO
	{ 'C'																	, .T. }, ; //X3_TIPO
	{ 6																		, .T. }, ; //X3_TAMANHO
	{ 0																		, .T. }, ; //X3_DECIMAL
	{ 'C�digo CRM'															, .T. }, ; //X3_TITULO
	{ 'C�digo CRM'															, .T. }, ; //X3_TITSPA
	{ 'C�digo CRM'															, .T. }, ; //X3_TITENG
	{ 'C�digo CRM'															, .T. }, ; //X3_DESCRIC
	{ 'C�digo CRM'															, .T. }, ; //X3_DESCSPA
	{ 'C�digo CRM'															, .T. }, ; //X3_DESCENG
	{ ''																	, .T. }, ; //X3_PICTURE
	{ ''																	, .T. }, ; //X3_VALID
	{ 'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x', .T. }, ; //X3_USADO
	{ "GetSxeNum('ZD4','ZD4_CODCRM')"										, .T. }, ; //X3_RELACAO
	{ ''																	, .T. }, ; //X3_F3
	{ 0																		, .T. }, ; //X3_NIVEL
	{ 'xxxxxx x'															, .T. }, ; //X3_RESERV
	{ ''																	, .T. }, ; //X3_CHECK
	{ ''																	, .T. }, ; //X3_TRIGGER
	{ 'U'																	, .T. }, ; //X3_PROPRI
	{ 'S'																	, .T. }, ; //X3_BROWSE
	{ 'V'																	, .T. }, ; //X3_VISUAL
	{ 'R'																	, .T. }, ; //X3_CONTEXT
	{ 'x'																	, .T. }, ; //X3_OBRIGAT
	{ ''																	, .T. }, ; //X3_VLDUSER
	{ ''																	, .T. }, ; //X3_CBOX
	{ ''																	, .T. }, ; //X3_CBOXSPA
	{ ''																	, .T. }, ; //X3_CBOXENG
	{ ''																	, .T. }, ; //X3_PICTVAR
	{ ''																	, .T. }, ; //X3_WHEN
	{ ''																	, .T. }, ; //X3_INIBRW
	{ ''																	, .T. }, ; //X3_GRPSXG
	{ ''																	, .T. }, ; //X3_FOLDER
	{ ''																	, .T. }, ; //X3_CONDSQL
	{ ''																	, .T. }, ; //X3_CHKSQL
	{ ''																	, .T. }, ; //X3_IDXSRV
	{ 'N'																	, .T. }, ; //X3_ORTOGRA
	{ ''																	, .T. }, ; //X3_TELA
	{ ''																	, .T. }, ; //X3_POSLGT
	{ 'N'																	, .T. }, ; //X3_IDXFLD
	{ ''																	, .T. }, ; //X3_AGRUP
	{ ''																	, .T. }, ; //X3_MODAL
	{ ''																	, .T. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'ZD4'																	, .T. }, ; //X3_ARQUIVO
	{ '04'																	, .T. }, ; //X3_ORDEM
	{ 'ZD4_CODCLI'															, .T. }, ; //X3_CAMPO
	{ 'C'																	, .T. }, ; //X3_TIPO
	{ 6																		, .T. }, ; //X3_TAMANHO
	{ 0																		, .T. }, ; //X3_DECIMAL
	{ 'C�d Cliente'															, .T. }, ; //X3_TITULO
	{ 'C�d Cliente'															, .T. }, ; //X3_TITSPA
	{ 'C�d Cliente'															, .T. }, ; //X3_TITENG
	{ 'C�digo do Cliente'													, .T. }, ; //X3_DESCRIC
	{ 'C�digo do Cliente'													, .T. }, ; //X3_DESCSPA
	{ 'C�digo do Cliente'													, .T. }, ; //X3_DESCENG
	{ ''																	, .T. }, ; //X3_PICTURE
	{ ''																	, .T. }, ; //X3_VALID
	{ 'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x', .T. }, ; //X3_USADO
	{ ''																	, .T. }, ; //X3_RELACAO
	{ 'SA1'																	, .T. }, ; //X3_F3
	{ 0																		, .T. }, ; //X3_NIVEL
	{ 'xxxxxx x'															, .T. }, ; //X3_RESERV
	{ ''																	, .T. }, ; //X3_CHECK
	{ 'S'																	, .T. }, ; //X3_TRIGGER
	{ 'U'																	, .T. }, ; //X3_PROPRI
	{ 'S'																	, .T. }, ; //X3_BROWSE
	{ 'A'																	, .T. }, ; //X3_VISUAL
	{ 'R'																	, .T. }, ; //X3_CONTEXT
	{ 'x'																	, .T. }, ; //X3_OBRIGAT
	{ "ExistCpo('SA1',FwFldGet('ZD4_CODCLI') + alltrim(FwFldGet('ZD4_LOJCLI')))", .T. }, ; //X3_VLDUSER
	{ ''																	, .T. }, ; //X3_CBOX
	{ ''																	, .T. }, ; //X3_CBOXSPA
	{ ''																	, .T. }, ; //X3_CBOXENG
	{ ''																	, .T. }, ; //X3_PICTVAR
	{ 'Inclui'																, .T. }, ; //X3_WHEN
	{ ''																	, .T. }, ; //X3_INIBRW
	{ ''																	, .T. }, ; //X3_GRPSXG
	{ ''																	, .T. }, ; //X3_FOLDER
	{ ''																	, .T. }, ; //X3_CONDSQL
	{ ''																	, .T. }, ; //X3_CHKSQL
	{ ''																	, .T. }, ; //X3_IDXSRV
	{ 'N'																	, .T. }, ; //X3_ORTOGRA
	{ ''																	, .T. }, ; //X3_TELA
	{ ''																	, .T. }, ; //X3_POSLGT
	{ 'N'																	, .T. }, ; //X3_IDXFLD
	{ ''																	, .T. }, ; //X3_AGRUP
	{ ''																	, .T. }, ; //X3_MODAL
	{ ''																	, .T. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'ZD4'																	, .T. }, ; //X3_ARQUIVO
	{ '05'																	, .T. }, ; //X3_ORDEM
	{ 'ZD4_LOJCLI'															, .T. }, ; //X3_CAMPO
	{ 'C'																	, .T. }, ; //X3_TIPO
	{ 2																		, .T. }, ; //X3_TAMANHO
	{ 0																		, .T. }, ; //X3_DECIMAL
	{ 'Loja'																, .T. }, ; //X3_TITULO
	{ 'Loja'																, .T. }, ; //X3_TITSPA
	{ 'Loja'																, .T. }, ; //X3_TITENG
	{ 'Loja do Cliente'														, .T. }, ; //X3_DESCRIC
	{ 'Loja do Cliente'														, .T. }, ; //X3_DESCSPA
	{ 'Loja do Cliente'														, .T. }, ; //X3_DESCENG
	{ ''																	, .T. }, ; //X3_PICTURE
	{ ''																	, .T. }, ; //X3_VALID
	{ 'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x', .T. }, ; //X3_USADO
	{ ''																	, .T. }, ; //X3_RELACAO
	{ ''																	, .T. }, ; //X3_F3
	{ 0																		, .T. }, ; //X3_NIVEL
	{ 'xxxxxx x'															, .T. }, ; //X3_RESERV
	{ ''																	, .T. }, ; //X3_CHECK
	{ 'S'																	, .T. }, ; //X3_TRIGGER
	{ 'U'																	, .T. }, ; //X3_PROPRI
	{ 'S'																	, .T. }, ; //X3_BROWSE
	{ 'A'																	, .T. }, ; //X3_VISUAL
	{ 'R'																	, .T. }, ; //X3_CONTEXT
	{ 'x'																	, .T. }, ; //X3_OBRIGAT
	{ "ExistCpo('SA1',FwFldGet('ZD4_CODCLI') + alltrim(FwFldGet('ZD4_LOJCLI')))", .T. }, ; //X3_VLDUSER
	{ ''																	, .T. }, ; //X3_CBOX
	{ ''																	, .T. }, ; //X3_CBOXSPA
	{ ''																	, .T. }, ; //X3_CBOXENG
	{ ''																	, .T. }, ; //X3_PICTVAR
	{ 'Inclui'																, .T. }, ; //X3_WHEN
	{ ''																	, .T. }, ; //X3_INIBRW
	{ ''																	, .T. }, ; //X3_GRPSXG
	{ ''																	, .T. }, ; //X3_FOLDER
	{ ''																	, .T. }, ; //X3_CONDSQL
	{ ''																	, .T. }, ; //X3_CHKSQL
	{ ''																	, .T. }, ; //X3_IDXSRV
	{ 'N'																	, .T. }, ; //X3_ORTOGRA
	{ ''																	, .T. }, ; //X3_TELA
	{ ''																	, .T. }, ; //X3_POSLGT
	{ 'N'																	, .T. }, ; //X3_IDXFLD
	{ ''																	, .T. }, ; //X3_AGRUP
	{ ''																	, .T. }, ; //X3_MODAL
	{ ''																	, .T. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'ZD4'																	, .T. }, ; //X3_ARQUIVO
	{ '06'																	, .T. }, ; //X3_ORDEM
	{ 'ZD4_NOMCLI'															, .T. }, ; //X3_CAMPO
	{ 'C'																	, .T. }, ; //X3_TIPO
	{ 50																	, .T. }, ; //X3_TAMANHO
	{ 0																		, .T. }, ; //X3_DECIMAL
	{ 'Nome Cliente'														, .T. }, ; //X3_TITULO
	{ 'Nome Cliente'														, .T. }, ; //X3_TITSPA
	{ 'Nome Cliente'														, .T. }, ; //X3_TITENG
	{ 'Nome do Cliente'														, .T. }, ; //X3_DESCRIC
	{ 'Nome do Cliente'														, .T. }, ; //X3_DESCSPA
	{ 'Nome do Cliente'														, .T. }, ; //X3_DESCENG
	{ '@!'																	, .T. }, ; //X3_PICTURE
	{ ''																	, .T. }, ; //X3_VALID
	{ 'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x', .T. }, ; //X3_USADO
	{ ''																	, .T. }, ; //X3_RELACAO
	{ ''																	, .T. }, ; //X3_F3
	{ 0																		, .T. }, ; //X3_NIVEL
	{ 'xxxxxx x'															, .T. }, ; //X3_RESERV
	{ ''																	, .T. }, ; //X3_CHECK
	{ ''																	, .T. }, ; //X3_TRIGGER
	{ 'U'																	, .T. }, ; //X3_PROPRI
	{ 'S'																	, .T. }, ; //X3_BROWSE
	{ 'V'																	, .T. }, ; //X3_VISUAL
	{ 'R'																	, .T. }, ; //X3_CONTEXT
	{ 'x'																	, .T. }, ; //X3_OBRIGAT
	{ ''																	, .T. }, ; //X3_VLDUSER
	{ ''																	, .T. }, ; //X3_CBOX
	{ ''																	, .T. }, ; //X3_CBOXSPA
	{ ''																	, .T. }, ; //X3_CBOXENG
	{ ''																	, .T. }, ; //X3_PICTVAR
	{ ''																	, .T. }, ; //X3_WHEN
	{ ''																	, .T. }, ; //X3_INIBRW
	{ ''																	, .T. }, ; //X3_GRPSXG
	{ ''																	, .T. }, ; //X3_FOLDER
	{ ''																	, .T. }, ; //X3_CONDSQL
	{ ''																	, .T. }, ; //X3_CHKSQL
	{ ''																	, .T. }, ; //X3_IDXSRV
	{ 'N'																	, .T. }, ; //X3_ORTOGRA
	{ ''																	, .T. }, ; //X3_TELA
	{ ''																	, .T. }, ; //X3_POSLGT
	{ 'N'																	, .T. }, ; //X3_IDXFLD
	{ ''																	, .T. }, ; //X3_AGRUP
	{ ''																	, .T. }, ; //X3_MODAL
	{ ''																	, .T. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'ZD4'																	, .T. }, ; //X3_ARQUIVO
	{ '07'																	, .T. }, ; //X3_ORDEM
	{ 'ZD4_ESPEC'															, .T. }, ; //X3_CAMPO
	{ 'M'																	, .T. }, ; //X3_TIPO
	{ 10																	, .T. }, ; //X3_TAMANHO
	{ 0																		, .T. }, ; //X3_DECIMAL
	{ 'Especific.'															, .T. }, ; //X3_TITULO
	{ 'Especific.'															, .T. }, ; //X3_TITSPA
	{ 'Especific.'															, .T. }, ; //X3_TITENG
	{ 'Especifica��es'														, .T. }, ; //X3_DESCRIC
	{ 'Especifica��es'														, .T. }, ; //X3_DESCSPA
	{ 'Especifica��es'														, .T. }, ; //X3_DESCENG
	{ ''																	, .T. }, ; //X3_PICTURE
	{ ''																	, .T. }, ; //X3_VALID
	{ 'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x', .T. }, ; //X3_USADO
	{ ''																	, .T. }, ; //X3_RELACAO
	{ ''																	, .T. }, ; //X3_F3
	{ 0																		, .T. }, ; //X3_NIVEL
	{ 'xxxxxx x'															, .T. }, ; //X3_RESERV
	{ ''																	, .T. }, ; //X3_CHECK
	{ ''																	, .T. }, ; //X3_TRIGGER
	{ 'U'																	, .T. }, ; //X3_PROPRI
	{ 'N'																	, .T. }, ; //X3_BROWSE
	{ 'A'																	, .T. }, ; //X3_VISUAL
	{ 'R'																	, .T. }, ; //X3_CONTEXT
	{ ''																	, .T. }, ; //X3_OBRIGAT
	{ ''																	, .T. }, ; //X3_VLDUSER
	{ ''																	, .T. }, ; //X3_CBOX
	{ ''																	, .T. }, ; //X3_CBOXSPA
	{ ''																	, .T. }, ; //X3_CBOXENG
	{ ''																	, .T. }, ; //X3_PICTVAR
	{ "U_fCRMWhen('',.f.,'')"												, .T. }, ; //X3_WHEN
	{ ''																	, .T. }, ; //X3_INIBRW
	{ ''																	, .T. }, ; //X3_GRPSXG
	{ ''																	, .T. }, ; //X3_FOLDER
	{ ''																	, .T. }, ; //X3_CONDSQL
	{ ''																	, .T. }, ; //X3_CHKSQL
	{ ''																	, .T. }, ; //X3_IDXSRV
	{ 'N'																	, .T. }, ; //X3_ORTOGRA
	{ ''																	, .T. }, ; //X3_TELA
	{ ''																	, .T. }, ; //X3_POSLGT
	{ 'N'																	, .T. }, ; //X3_IDXFLD
	{ ''																	, .T. }, ; //X3_AGRUP
	{ ''																	, .T. }, ; //X3_MODAL
	{ ''																	, .T. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'ZD4'																	, .T. }, ; //X3_ARQUIVO
	{ '08'																	, .T. }, ; //X3_ORDEM
	{ 'ZD4_DTINCL'															, .T. }, ; //X3_CAMPO
	{ 'D'																	, .T. }, ; //X3_TIPO
	{ 8																		, .T. }, ; //X3_TAMANHO
	{ 0																		, .T. }, ; //X3_DECIMAL
	{ 'Dt Inclus�o'															, .T. }, ; //X3_TITULO
	{ 'Dt Inclus�o'															, .T. }, ; //X3_TITSPA
	{ 'Dt Inclus�o'															, .T. }, ; //X3_TITENG
	{ 'Data da Inclus�o'													, .T. }, ; //X3_DESCRIC
	{ 'Data da Inclus�o'													, .T. }, ; //X3_DESCSPA
	{ 'Data da Inclus�o'													, .T. }, ; //X3_DESCENG
	{ ''																	, .T. }, ; //X3_PICTURE
	{ ''																	, .T. }, ; //X3_VALID
	{ 'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x', .T. }, ; //X3_USADO
	{ 'Date()'																, .T. }, ; //X3_RELACAO
	{ ''																	, .T. }, ; //X3_F3
	{ 0																		, .T. }, ; //X3_NIVEL
	{ 'xxxxxx x'															, .T. }, ; //X3_RESERV
	{ ''																	, .T. }, ; //X3_CHECK
	{ ''																	, .T. }, ; //X3_TRIGGER
	{ 'U'																	, .T. }, ; //X3_PROPRI
	{ 'S'																	, .T. }, ; //X3_BROWSE
	{ 'V'																	, .T. }, ; //X3_VISUAL
	{ 'R'																	, .T. }, ; //X3_CONTEXT
	{ ''																	, .T. }, ; //X3_OBRIGAT
	{ ''																	, .T. }, ; //X3_VLDUSER
	{ ''																	, .T. }, ; //X3_CBOX
	{ ''																	, .T. }, ; //X3_CBOXSPA
	{ ''																	, .T. }, ; //X3_CBOXENG
	{ ''																	, .T. }, ; //X3_PICTVAR
	{ ''																	, .T. }, ; //X3_WHEN
	{ ''																	, .T. }, ; //X3_INIBRW
	{ ''																	, .T. }, ; //X3_GRPSXG
	{ ''																	, .T. }, ; //X3_FOLDER
	{ ''																	, .T. }, ; //X3_CONDSQL
	{ ''																	, .T. }, ; //X3_CHKSQL
	{ ''																	, .T. }, ; //X3_IDXSRV
	{ 'N'																	, .T. }, ; //X3_ORTOGRA
	{ ''																	, .T. }, ; //X3_TELA
	{ ''																	, .T. }, ; //X3_POSLGT
	{ 'N'																	, .T. }, ; //X3_IDXFLD
	{ ''																	, .T. }, ; //X3_AGRUP
	{ ''																	, .T. }, ; //X3_MODAL
	{ ''																	, .T. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'ZD4'																	, .T. }, ; //X3_ARQUIVO
	{ '09'																	, .T. }, ; //X3_ORDEM
	{ 'ZD4_USINCL'															, .T. }, ; //X3_CAMPO
	{ 'C'																	, .T. }, ; //X3_TIPO
	{ 25																	, .T. }, ; //X3_TAMANHO
	{ 0																		, .T. }, ; //X3_DECIMAL
	{ 'Usr Inclus�o'														, .T. }, ; //X3_TITULO
	{ 'Usr Inclus�o'														, .T. }, ; //X3_TITSPA
	{ 'Usr Inclus�o'														, .T. }, ; //X3_TITENG
	{ 'Usu�rio Inclus�o'													, .T. }, ; //X3_DESCRIC
	{ 'Usu�rio Inclus�o'													, .T. }, ; //X3_DESCSPA
	{ 'Usu�rio Inclus�o'													, .T. }, ; //X3_DESCENG
	{ ''																	, .T. }, ; //X3_PICTURE
	{ ''																	, .T. }, ; //X3_VALID
	{ 'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x', .T. }, ; //X3_USADO
	{ 'upper(UsrFullName())'												, .T. }, ; //X3_RELACAO
	{ ''																	, .T. }, ; //X3_F3
	{ 0																		, .T. }, ; //X3_NIVEL
	{ 'xxxxxx x'															, .T. }, ; //X3_RESERV
	{ ''																	, .T. }, ; //X3_CHECK
	{ ''																	, .T. }, ; //X3_TRIGGER
	{ 'U'																	, .T. }, ; //X3_PROPRI
	{ 'S'																	, .T. }, ; //X3_BROWSE
	{ 'V'																	, .T. }, ; //X3_VISUAL
	{ 'R'																	, .T. }, ; //X3_CONTEXT
	{ ''																	, .T. }, ; //X3_OBRIGAT
	{ ''																	, .T. }, ; //X3_VLDUSER
	{ ''																	, .T. }, ; //X3_CBOX
	{ ''																	, .T. }, ; //X3_CBOXSPA
	{ ''																	, .T. }, ; //X3_CBOXENG
	{ ''																	, .T. }, ; //X3_PICTVAR
	{ ''																	, .T. }, ; //X3_WHEN
	{ ''																	, .T. }, ; //X3_INIBRW
	{ ''																	, .T. }, ; //X3_GRPSXG
	{ ''																	, .T. }, ; //X3_FOLDER
	{ ''																	, .T. }, ; //X3_CONDSQL
	{ ''																	, .T. }, ; //X3_CHKSQL
	{ ''																	, .T. }, ; //X3_IDXSRV
	{ 'N'																	, .T. }, ; //X3_ORTOGRA
	{ ''																	, .T. }, ; //X3_TELA
	{ ''																	, .T. }, ; //X3_POSLGT
	{ 'N'																	, .T. }, ; //X3_IDXFLD
	{ ''																	, .T. }, ; //X3_AGRUP
	{ ''																	, .T. }, ; //X3_MODAL
	{ ''																	, .T. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'ZD4'																	, .T. }, ; //X3_ARQUIVO
	{ '10'																	, .T. }, ; //X3_ORDEM
	{ 'ZD4_DTALT'															, .T. }, ; //X3_CAMPO
	{ 'D'																	, .T. }, ; //X3_TIPO
	{ 8																		, .T. }, ; //X3_TAMANHO
	{ 0																		, .T. }, ; //X3_DECIMAL
	{ 'Dt Altera��o'														, .T. }, ; //X3_TITULO
	{ 'Dt Altera��o'														, .T. }, ; //X3_TITSPA
	{ 'Dt Altera��o'														, .T. }, ; //X3_TITENG
	{ 'Data da Altera��o'													, .T. }, ; //X3_DESCRIC
	{ 'Data da Altera��o'													, .T. }, ; //X3_DESCSPA
	{ 'Data da Altera��o'													, .T. }, ; //X3_DESCENG
	{ ''																	, .T. }, ; //X3_PICTURE
	{ ''																	, .T. }, ; //X3_VALID
	{ 'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x', .T. }, ; //X3_USADO
	{ ''																	, .T. }, ; //X3_RELACAO
	{ ''																	, .T. }, ; //X3_F3
	{ 0																		, .T. }, ; //X3_NIVEL
	{ 'xxxxxx x'															, .T. }, ; //X3_RESERV
	{ ''																	, .T. }, ; //X3_CHECK
	{ ''																	, .T. }, ; //X3_TRIGGER
	{ 'U'																	, .T. }, ; //X3_PROPRI
	{ 'S'																	, .T. }, ; //X3_BROWSE
	{ 'V'																	, .T. }, ; //X3_VISUAL
	{ 'R'																	, .T. }, ; //X3_CONTEXT
	{ ''																	, .T. }, ; //X3_OBRIGAT
	{ ''																	, .T. }, ; //X3_VLDUSER
	{ ''																	, .T. }, ; //X3_CBOX
	{ ''																	, .T. }, ; //X3_CBOXSPA
	{ ''																	, .T. }, ; //X3_CBOXENG
	{ ''																	, .T. }, ; //X3_PICTVAR
	{ ''																	, .T. }, ; //X3_WHEN
	{ ''																	, .T. }, ; //X3_INIBRW
	{ ''																	, .T. }, ; //X3_GRPSXG
	{ ''																	, .T. }, ; //X3_FOLDER
	{ ''																	, .T. }, ; //X3_CONDSQL
	{ ''																	, .T. }, ; //X3_CHKSQL
	{ ''																	, .T. }, ; //X3_IDXSRV
	{ 'N'																	, .T. }, ; //X3_ORTOGRA
	{ ''																	, .T. }, ; //X3_TELA
	{ ''																	, .T. }, ; //X3_POSLGT
	{ 'N'																	, .T. }, ; //X3_IDXFLD
	{ ''																	, .T. }, ; //X3_AGRUP
	{ ''																	, .T. }, ; //X3_MODAL
	{ ''																	, .T. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'ZD4'																	, .T. }, ; //X3_ARQUIVO
	{ '11'																	, .T. }, ; //X3_ORDEM
	{ 'ZD4_USALT'															, .T. }, ; //X3_CAMPO
	{ 'C'																	, .T. }, ; //X3_TIPO
	{ 25																	, .T. }, ; //X3_TAMANHO
	{ 0																		, .T. }, ; //X3_DECIMAL
	{ 'Us Altera��o'														, .T. }, ; //X3_TITULO
	{ 'Us Altera��o'														, .T. }, ; //X3_TITSPA
	{ 'Us Altera��o'														, .T. }, ; //X3_TITENG
	{ 'Usu�rio Altera��o'													, .T. }, ; //X3_DESCRIC
	{ 'Usu�rio Altera��o'													, .T. }, ; //X3_DESCSPA
	{ 'Usu�rio Altera��o'													, .T. }, ; //X3_DESCENG
	{ '@!'																	, .T. }, ; //X3_PICTURE
	{ ''																	, .T. }, ; //X3_VALID
	{ 'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x', .T. }, ; //X3_USADO
	{ ''																	, .T. }, ; //X3_RELACAO
	{ ''																	, .T. }, ; //X3_F3
	{ 0																		, .T. }, ; //X3_NIVEL
	{ 'xxxxxx x'															, .T. }, ; //X3_RESERV
	{ ''																	, .T. }, ; //X3_CHECK
	{ ''																	, .T. }, ; //X3_TRIGGER
	{ 'U'																	, .T. }, ; //X3_PROPRI
	{ 'S'																	, .T. }, ; //X3_BROWSE
	{ 'V'																	, .T. }, ; //X3_VISUAL
	{ 'R'																	, .T. }, ; //X3_CONTEXT
	{ ''																	, .T. }, ; //X3_OBRIGAT
	{ ''																	, .T. }, ; //X3_VLDUSER
	{ ''																	, .T. }, ; //X3_CBOX
	{ ''																	, .T. }, ; //X3_CBOXSPA
	{ ''																	, .T. }, ; //X3_CBOXENG
	{ ''																	, .T. }, ; //X3_PICTVAR
	{ ''																	, .T. }, ; //X3_WHEN
	{ ''																	, .T. }, ; //X3_INIBRW
	{ ''																	, .T. }, ; //X3_GRPSXG
	{ ''																	, .T. }, ; //X3_FOLDER
	{ ''																	, .T. }, ; //X3_CONDSQL
	{ ''																	, .T. }, ; //X3_CHKSQL
	{ ''																	, .T. }, ; //X3_IDXSRV
	{ 'N'																	, .T. }, ; //X3_ORTOGRA
	{ ''																	, .T. }, ; //X3_TELA
	{ ''																	, .T. }, ; //X3_POSLGT
	{ 'N'																	, .T. }, ; //X3_IDXFLD
	{ ''																	, .T. }, ; //X3_AGRUP
	{ ''																	, .T. }, ; //X3_MODAL
	{ ''																	, .T. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'ZD4'																	, .T. }, ; //X3_ARQUIVO
	{ '12'																	, .T. }, ; //X3_ORDEM
	{ 'ZD4_MOTPRD'															, .T. }, ; //X3_CAMPO
	{ 'C'																	, .T. }, ; //X3_TIPO
	{ 2																		, .T. }, ; //X3_TAMANHO
	{ 0																		, .T. }, ; //X3_DECIMAL
	{ 'Motivo Perda'														, .T. }, ; //X3_TITULO
	{ 'Motivo Perda'														, .T. }, ; //X3_TITSPA
	{ 'Motivo Perda'														, .T. }, ; //X3_TITENG
	{ 'Motivo Perda'														, .T. }, ; //X3_DESCRIC
	{ 'Motivo Perda'														, .T. }, ; //X3_DESCSPA
	{ 'Motivo Perda'														, .T. }, ; //X3_DESCENG
	{ ''																	, .T. }, ; //X3_PICTURE
	{ ''																	, .T. }, ; //X3_VALID
	{ 'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x', .T. }, ; //X3_USADO
	{ ''																	, .T. }, ; //X3_RELACAO
	{ 'ZA'																	, .T. }, ; //X3_F3
	{ 0																		, .T. }, ; //X3_NIVEL
	{ 'xxxxxx x'															, .T. }, ; //X3_RESERV
	{ ''																	, .T. }, ; //X3_CHECK
	{ 'S'																	, .T. }, ; //X3_TRIGGER
	{ 'U'																	, .T. }, ; //X3_PROPRI
	{ 'S'																	, .T. }, ; //X3_BROWSE
	{ 'A'																	, .T. }, ; //X3_VISUAL
	{ 'R'																	, .T. }, ; //X3_CONTEXT
	{ ''																	, .T. }, ; //X3_OBRIGAT
	{ "ExistCpo('SX5','ZA' + FwFldGet('ZD4_MOTPRD'))"						, .T. }, ; //X3_VLDUSER
	{ ''																	, .T. }, ; //X3_CBOX
	{ ''																	, .T. }, ; //X3_CBOXSPA
	{ ''																	, .T. }, ; //X3_CBOXENG
	{ ''																	, .T. }, ; //X3_PICTVAR
	{ "U_fCRMWhen('',.f.,'CANC/PERD')"										, .T. }, ; //X3_WHEN
	{ ''																	, .T. }, ; //X3_INIBRW
	{ ''																	, .T. }, ; //X3_GRPSXG
	{ ''																	, .T. }, ; //X3_FOLDER
	{ ''																	, .T. }, ; //X3_CONDSQL
	{ ''																	, .T. }, ; //X3_CHKSQL
	{ ''																	, .T. }, ; //X3_IDXSRV
	{ 'N'																	, .T. }, ; //X3_ORTOGRA
	{ ''																	, .T. }, ; //X3_TELA
	{ ''																	, .T. }, ; //X3_POSLGT
	{ 'N'																	, .T. }, ; //X3_IDXFLD
	{ ''																	, .T. }, ; //X3_AGRUP
	{ ''																	, .T. }, ; //X3_MODAL
	{ ''																	, .T. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'ZD4'																	, .T. }, ; //X3_ARQUIVO
	{ '13'																	, .T. }, ; //X3_ORDEM
	{ 'ZD4_DSCPRD'															, .T. }, ; //X3_CAMPO
	{ 'C'																	, .T. }, ; //X3_TIPO
	{ 50																	, .T. }, ; //X3_TAMANHO
	{ 0																		, .T. }, ; //X3_DECIMAL
	{ 'Descr Motivo'														, .T. }, ; //X3_TITULO
	{ 'Descr Motivo'														, .T. }, ; //X3_TITSPA
	{ 'Descr Motivo'														, .T. }, ; //X3_TITENG
	{ 'Descri��o do Motivo Perda'											, .T. }, ; //X3_DESCRIC
	{ 'Descri��o do Motivo Perda'											, .T. }, ; //X3_DESCSPA
	{ 'Descri��o do Motivo Perda'											, .T. }, ; //X3_DESCENG
	{ ''																	, .T. }, ; //X3_PICTURE
	{ ''																	, .T. }, ; //X3_VALID
	{ 'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x', .T. }, ; //X3_USADO
	{ ''																	, .T. }, ; //X3_RELACAO
	{ ''																	, .T. }, ; //X3_F3
	{ 0																		, .T. }, ; //X3_NIVEL
	{ 'xxxxxx x'															, .T. }, ; //X3_RESERV
	{ ''																	, .T. }, ; //X3_CHECK
	{ ''																	, .T. }, ; //X3_TRIGGER
	{ 'U'																	, .T. }, ; //X3_PROPRI
	{ 'N'																	, .T. }, ; //X3_BROWSE
	{ 'V'																	, .T. }, ; //X3_VISUAL
	{ 'R'																	, .T. }, ; //X3_CONTEXT
	{ ''																	, .T. }, ; //X3_OBRIGAT
	{ ''																	, .T. }, ; //X3_VLDUSER
	{ ''																	, .T. }, ; //X3_CBOX
	{ ''																	, .T. }, ; //X3_CBOXSPA
	{ ''																	, .T. }, ; //X3_CBOXENG
	{ ''																	, .T. }, ; //X3_PICTVAR
	{ ''																	, .T. }, ; //X3_WHEN
	{ ''																	, .T. }, ; //X3_INIBRW
	{ ''																	, .T. }, ; //X3_GRPSXG
	{ ''																	, .T. }, ; //X3_FOLDER
	{ ''																	, .T. }, ; //X3_CONDSQL
	{ ''																	, .T. }, ; //X3_CHKSQL
	{ ''																	, .T. }, ; //X3_IDXSRV
	{ 'N'																	, .T. }, ; //X3_ORTOGRA
	{ ''																	, .T. }, ; //X3_TELA
	{ ''																	, .T. }, ; //X3_POSLGT
	{ 'N'																	, .T. }, ; //X3_IDXFLD
	{ ''																	, .T. }, ; //X3_AGRUP
	{ ''																	, .T. }, ; //X3_MODAL
	{ ''																	, .T. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'ZD4'																	, .T. }, ; //X3_ARQUIVO
	{ '14'																	, .T. }, ; //X3_ORDEM
	{ 'ZD4_OBS'																, .T. }, ; //X3_CAMPO
	{ 'M'																	, .T. }, ; //X3_TIPO
	{ 10																	, .T. }, ; //X3_TAMANHO
	{ 0																		, .T. }, ; //X3_DECIMAL
	{ 'Observa��es'															, .T. }, ; //X3_TITULO
	{ 'Observa��es'															, .T. }, ; //X3_TITSPA
	{ 'Observa��es'															, .T. }, ; //X3_TITENG
	{ 'Observa��es'															, .T. }, ; //X3_DESCRIC
	{ 'Observa��es'															, .T. }, ; //X3_DESCSPA
	{ 'Observa��es'															, .T. }, ; //X3_DESCENG
	{ ''																	, .T. }, ; //X3_PICTURE
	{ ''																	, .T. }, ; //X3_VALID
	{ 'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x', .T. }, ; //X3_USADO
	{ ''																	, .T. }, ; //X3_RELACAO
	{ ''																	, .T. }, ; //X3_F3
	{ 0																		, .T. }, ; //X3_NIVEL
	{ 'xxxxxx x'															, .T. }, ; //X3_RESERV
	{ ''																	, .T. }, ; //X3_CHECK
	{ ''																	, .T. }, ; //X3_TRIGGER
	{ 'U'																	, .T. }, ; //X3_PROPRI
	{ 'N'																	, .T. }, ; //X3_BROWSE
	{ 'A'																	, .T. }, ; //X3_VISUAL
	{ 'R'																	, .T. }, ; //X3_CONTEXT
	{ ''																	, .T. }, ; //X3_OBRIGAT
	{ ''																	, .T. }, ; //X3_VLDUSER
	{ ''																	, .T. }, ; //X3_CBOX
	{ ''																	, .T. }, ; //X3_CBOXSPA
	{ ''																	, .T. }, ; //X3_CBOXENG
	{ ''																	, .T. }, ; //X3_PICTVAR
	{ ''																	, .T. }, ; //X3_WHEN
	{ ''																	, .T. }, ; //X3_INIBRW
	{ ''																	, .T. }, ; //X3_GRPSXG
	{ ''																	, .T. }, ; //X3_FOLDER
	{ ''																	, .T. }, ; //X3_CONDSQL
	{ ''																	, .T. }, ; //X3_CHKSQL
	{ ''																	, .T. }, ; //X3_IDXSRV
	{ 'N'																	, .T. }, ; //X3_ORTOGRA
	{ ''																	, .T. }, ; //X3_TELA
	{ ''																	, .T. }, ; //X3_POSLGT
	{ 'N'																	, .T. }, ; //X3_IDXFLD
	{ ''																	, .T. }, ; //X3_AGRUP
	{ ''																	, .T. }, ; //X3_MODAL
	{ ''																	, .T. }} ) //X3_PYME

//
// Campos Tabela ZD5
//
aAdd( aSX3, { ;
	{ 'ZD5'																	, .T. }, ; //X3_ARQUIVO
	{ '01'																	, .T. }, ; //X3_ORDEM
	{ 'ZD5_FILIAL'															, .T. }, ; //X3_CAMPO
	{ 'C'																	, .T. }, ; //X3_TIPO
	{ 2																		, .T. }, ; //X3_TAMANHO
	{ 0																		, .T. }, ; //X3_DECIMAL
	{ 'Filial'																, .T. }, ; //X3_TITULO
	{ 'Sucursal'															, .T. }, ; //X3_TITSPA
	{ 'Branch'																, .T. }, ; //X3_TITENG
	{ 'Filial do Sistema'													, .T. }, ; //X3_DESCRIC
	{ 'Sucursal'															, .T. }, ; //X3_DESCSPA
	{ 'Branch of the System'												, .T. }, ; //X3_DESCENG
	{ '@!'																	, .T. }, ; //X3_PICTURE
	{ ''																	, .T. }, ; //X3_VALID
	{ 'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x', .T. }, ; //X3_USADO
	{ ''																	, .T. }, ; //X3_RELACAO
	{ ''																	, .T. }, ; //X3_F3
	{ 1																		, .T. }, ; //X3_NIVEL
	{ 'XXXXXX X'															, .T. }, ; //X3_RESERV
	{ ''																	, .T. }, ; //X3_CHECK
	{ ''																	, .T. }, ; //X3_TRIGGER
	{ 'U'																	, .T. }, ; //X3_PROPRI
	{ 'N'																	, .T. }, ; //X3_BROWSE
	{ ''																	, .T. }, ; //X3_VISUAL
	{ ''																	, .T. }, ; //X3_CONTEXT
	{ ''																	, .T. }, ; //X3_OBRIGAT
	{ ''																	, .T. }, ; //X3_VLDUSER
	{ ''																	, .T. }, ; //X3_CBOX
	{ ''																	, .T. }, ; //X3_CBOXSPA
	{ ''																	, .T. }, ; //X3_CBOXENG
	{ ''																	, .T. }, ; //X3_PICTVAR
	{ ''																	, .T. }, ; //X3_WHEN
	{ ''																	, .T. }, ; //X3_INIBRW
	{ '033'																	, .T. }, ; //X3_GRPSXG
	{ ''																	, .T. }, ; //X3_FOLDER
	{ ''																	, .T. }, ; //X3_CONDSQL
	{ ''																	, .T. }, ; //X3_CHKSQL
	{ ''																	, .T. }, ; //X3_IDXSRV
	{ ''																	, .T. }, ; //X3_ORTOGRA
	{ ''																	, .T. }, ; //X3_TELA
	{ ''																	, .T. }, ; //X3_POSLGT
	{ ''																	, .T. }, ; //X3_IDXFLD
	{ ''																	, .T. }, ; //X3_AGRUP
	{ ''																	, .T. }, ; //X3_MODAL
	{ ''																	, .T. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'ZD5'																	, .T. }, ; //X3_ARQUIVO
	{ '02'																	, .T. }, ; //X3_ORDEM
	{ 'ZD5_STATUS'															, .T. }, ; //X3_CAMPO
	{ 'C'																	, .T. }, ; //X3_TIPO
	{ 1																		, .T. }, ; //X3_TAMANHO
	{ 0																		, .T. }, ; //X3_DECIMAL
	{ 'Status'																, .T. }, ; //X3_TITULO
	{ 'Status'																, .T. }, ; //X3_TITSPA
	{ 'Status'																, .T. }, ; //X3_TITENG
	{ 'Status'																, .T. }, ; //X3_DESCRIC
	{ 'Status'																, .T. }, ; //X3_DESCSPA
	{ 'Status'																, .T. }, ; //X3_DESCENG
	{ ''																	, .T. }, ; //X3_PICTURE
	{ ''																	, .T. }, ; //X3_VALID
	{ 'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x', .T. }, ; //X3_USADO
	{ "'1'"																	, .T. }, ; //X3_RELACAO
	{ ''																	, .T. }, ; //X3_F3
	{ 0																		, .T. }, ; //X3_NIVEL
	{ 'xxxxxx x'															, .T. }, ; //X3_RESERV
	{ ''																	, .T. }, ; //X3_CHECK
	{ ''																	, .T. }, ; //X3_TRIGGER
	{ 'U'																	, .T. }, ; //X3_PROPRI
	{ 'N'																	, .T. }, ; //X3_BROWSE
	{ 'V'																	, .T. }, ; //X3_VISUAL
	{ 'R'																	, .T. }, ; //X3_CONTEXT
	{ ''																	, .T. }, ; //X3_OBRIGAT
	{ ''																	, .T. }, ; //X3_VLDUSER
	{ '1=Aguardando In�cio;2=In�cio Atrasado;3=Em Andamento;4=Atrasada;5=Conclu�da;6=Conclu�da com Atraso;7=Cancelada', .T. }, ; //X3_CBOX
	{ '1=Aguardando In�cio;2=In�cio Atrasado;3=Em Andamento;4=Atrasada;5=Conclu�da;6=Conclu�da com Atraso;7=Cancelada', .T. }, ; //X3_CBOXSPA
	{ '1=Aguardando In�cio;2=In�cio Atrasado;3=Em Andamento;4=Atrasada;5=Conclu�da;6=Conclu�da com Atraso;7=Cancelada', .T. }, ; //X3_CBOXENG
	{ ''																	, .T. }, ; //X3_PICTVAR
	{ ''																	, .T. }, ; //X3_WHEN
	{ ''																	, .T. }, ; //X3_INIBRW
	{ ''																	, .T. }, ; //X3_GRPSXG
	{ ''																	, .T. }, ; //X3_FOLDER
	{ ''																	, .T. }, ; //X3_CONDSQL
	{ ''																	, .T. }, ; //X3_CHKSQL
	{ ''																	, .T. }, ; //X3_IDXSRV
	{ 'N'																	, .T. }, ; //X3_ORTOGRA
	{ ''																	, .T. }, ; //X3_TELA
	{ ''																	, .T. }, ; //X3_POSLGT
	{ 'N'																	, .T. }, ; //X3_IDXFLD
	{ ''																	, .T. }, ; //X3_AGRUP
	{ ''																	, .T. }, ; //X3_MODAL
	{ ''																	, .T. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'ZD5'																	, .T. }, ; //X3_ARQUIVO
	{ '03'																	, .T. }, ; //X3_ORDEM
	{ 'ZD5_CODCRM'															, .T. }, ; //X3_CAMPO
	{ 'C'																	, .T. }, ; //X3_TIPO
	{ 6																		, .T. }, ; //X3_TAMANHO
	{ 0																		, .T. }, ; //X3_DECIMAL
	{ 'C�digo CRM'															, .T. }, ; //X3_TITULO
	{ 'C�digo CRM'															, .T. }, ; //X3_TITSPA
	{ 'C�digo CRM'															, .T. }, ; //X3_TITENG
	{ 'C�digo CRM'															, .T. }, ; //X3_DESCRIC
	{ 'C�digo CRM'															, .T. }, ; //X3_DESCSPA
	{ 'C�digo CRM'															, .T. }, ; //X3_DESCENG
	{ ''																	, .T. }, ; //X3_PICTURE
	{ ''																	, .T. }, ; //X3_VALID
	{ 'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x', .T. }, ; //X3_USADO
	{ ''																	, .T. }, ; //X3_RELACAO
	{ ''																	, .T. }, ; //X3_F3
	{ 0																		, .T. }, ; //X3_NIVEL
	{ 'xxxxxx x'															, .T. }, ; //X3_RESERV
	{ ''																	, .T. }, ; //X3_CHECK
	{ ''																	, .T. }, ; //X3_TRIGGER
	{ 'U'																	, .T. }, ; //X3_PROPRI
	{ 'S'																	, .T. }, ; //X3_BROWSE
	{ 'V'																	, .T. }, ; //X3_VISUAL
	{ 'R'																	, .T. }, ; //X3_CONTEXT
	{ ''																	, .T. }, ; //X3_OBRIGAT
	{ ''																	, .T. }, ; //X3_VLDUSER
	{ ''																	, .T. }, ; //X3_CBOX
	{ ''																	, .T. }, ; //X3_CBOXSPA
	{ ''																	, .T. }, ; //X3_CBOXENG
	{ ''																	, .T. }, ; //X3_PICTVAR
	{ ''																	, .T. }, ; //X3_WHEN
	{ ''																	, .T. }, ; //X3_INIBRW
	{ ''																	, .T. }, ; //X3_GRPSXG
	{ ''																	, .T. }, ; //X3_FOLDER
	{ ''																	, .T. }, ; //X3_CONDSQL
	{ ''																	, .T. }, ; //X3_CHKSQL
	{ ''																	, .T. }, ; //X3_IDXSRV
	{ 'N'																	, .T. }, ; //X3_ORTOGRA
	{ ''																	, .T. }, ; //X3_TELA
	{ ''																	, .T. }, ; //X3_POSLGT
	{ 'N'																	, .T. }, ; //X3_IDXFLD
	{ ''																	, .T. }, ; //X3_AGRUP
	{ ''																	, .T. }, ; //X3_MODAL
	{ ''																	, .T. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'ZD5'																	, .T. }, ; //X3_ARQUIVO
	{ '04'																	, .T. }, ; //X3_ORDEM
	{ 'ZD5_DESCRI'															, .T. }, ; //X3_CAMPO
	{ 'C'																	, .T. }, ; //X3_TIPO
	{ 254																	, .T. }, ; //X3_TAMANHO
	{ 0																		, .T. }, ; //X3_DECIMAL
	{ 'Descri��o'															, .T. }, ; //X3_TITULO
	{ 'Descri��o'															, .T. }, ; //X3_TITSPA
	{ 'Descri��o'															, .T. }, ; //X3_TITENG
	{ 'Descri��o da Atividade'												, .T. }, ; //X3_DESCRIC
	{ 'Descri��o da Atividade'												, .T. }, ; //X3_DESCSPA
	{ 'Descri��o da Atividade'												, .T. }, ; //X3_DESCENG
	{ '@!'																	, .T. }, ; //X3_PICTURE
	{ ''																	, .T. }, ; //X3_VALID
	{ 'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x', .T. }, ; //X3_USADO
	{ ''																	, .T. }, ; //X3_RELACAO
	{ ''																	, .T. }, ; //X3_F3
	{ 0																		, .T. }, ; //X3_NIVEL
	{ 'xxxxxx x'															, .T. }, ; //X3_RESERV
	{ ''																	, .T. }, ; //X3_CHECK
	{ ''																	, .T. }, ; //X3_TRIGGER
	{ 'U'																	, .T. }, ; //X3_PROPRI
	{ 'S'																	, .T. }, ; //X3_BROWSE
	{ 'A'																	, .T. }, ; //X3_VISUAL
	{ 'R'																	, .T. }, ; //X3_CONTEXT
	{ 'x'																	, .T. }, ; //X3_OBRIGAT
	{ ''																	, .T. }, ; //X3_VLDUSER
	{ ''																	, .T. }, ; //X3_CBOX
	{ ''																	, .T. }, ; //X3_CBOXSPA
	{ ''																	, .T. }, ; //X3_CBOXENG
	{ ''																	, .T. }, ; //X3_PICTVAR
	{ ''																	, .T. }, ; //X3_WHEN
	{ ''																	, .T. }, ; //X3_INIBRW
	{ ''																	, .T. }, ; //X3_GRPSXG
	{ ''																	, .T. }, ; //X3_FOLDER
	{ ''																	, .T. }, ; //X3_CONDSQL
	{ ''																	, .T. }, ; //X3_CHKSQL
	{ ''																	, .T. }, ; //X3_IDXSRV
	{ 'N'																	, .T. }, ; //X3_ORTOGRA
	{ ''																	, .T. }, ; //X3_TELA
	{ ''																	, .T. }, ; //X3_POSLGT
	{ 'N'																	, .T. }, ; //X3_IDXFLD
	{ ''																	, .T. }, ; //X3_AGRUP
	{ ''																	, .T. }, ; //X3_MODAL
	{ ''																	, .T. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'ZD5'																	, .T. }, ; //X3_ARQUIVO
	{ '05'																	, .T. }, ; //X3_ORDEM
	{ 'ZD5_PRVINI'															, .T. }, ; //X3_CAMPO
	{ 'D'																	, .T. }, ; //X3_TIPO
	{ 8																		, .T. }, ; //X3_TAMANHO
	{ 0																		, .T. }, ; //X3_DECIMAL
	{ 'Prev In�cio,'														, .T. }, ; //X3_TITULO
	{ 'Prev In�cio,'														, .T. }, ; //X3_TITSPA
	{ 'Prev In�cio,'														, .T. }, ; //X3_TITENG
	{ 'Previs�o de In�cio'													, .T. }, ; //X3_DESCRIC
	{ 'Previs�o de In�cio'													, .T. }, ; //X3_DESCSPA
	{ 'Previs�o de In�cio'													, .T. }, ; //X3_DESCENG
	{ ''																	, .T. }, ; //X3_PICTURE
	{ ''																	, .T. }, ; //X3_VALID
	{ 'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x', .T. }, ; //X3_USADO
	{ ''																	, .T. }, ; //X3_RELACAO
	{ ''																	, .T. }, ; //X3_F3
	{ 0																		, .T. }, ; //X3_NIVEL
	{ 'xxxxxx x'															, .T. }, ; //X3_RESERV
	{ ''																	, .T. }, ; //X3_CHECK
	{ 'S'																	, .T. }, ; //X3_TRIGGER
	{ 'U'																	, .T. }, ; //X3_PROPRI
	{ 'S'																	, .T. }, ; //X3_BROWSE
	{ 'A'																	, .T. }, ; //X3_VISUAL
	{ 'R'																	, .T. }, ; //X3_CONTEXT
	{ 'x'																	, .T. }, ; //X3_OBRIGAT
	{ 'U_CRMValCp()'														, .T. }, ; //X3_VLDUSER
	{ ''																	, .T. }, ; //X3_CBOX
	{ ''																	, .T. }, ; //X3_CBOXSPA
	{ ''																	, .T. }, ; //X3_CBOXENG
	{ ''																	, .T. }, ; //X3_PICTVAR
	{ "U_fCRMWhen('ZD5_DTINI',.T.,'ALT')"									, .T. }, ; //X3_WHEN
	{ ''																	, .T. }, ; //X3_INIBRW
	{ ''																	, .T. }, ; //X3_GRPSXG
	{ ''																	, .T. }, ; //X3_FOLDER
	{ ''																	, .T. }, ; //X3_CONDSQL
	{ ''																	, .T. }, ; //X3_CHKSQL
	{ ''																	, .T. }, ; //X3_IDXSRV
	{ 'N'																	, .T. }, ; //X3_ORTOGRA
	{ ''																	, .T. }, ; //X3_TELA
	{ ''																	, .T. }, ; //X3_POSLGT
	{ 'N'																	, .T. }, ; //X3_IDXFLD
	{ ''																	, .T. }, ; //X3_AGRUP
	{ ''																	, .T. }, ; //X3_MODAL
	{ ''																	, .T. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'ZD5'																	, .T. }, ; //X3_ARQUIVO
	{ '06'																	, .T. }, ; //X3_ORDEM
	{ 'ZD5_DTINI'															, .T. }, ; //X3_CAMPO
	{ 'D'																	, .T. }, ; //X3_TIPO
	{ 8																		, .T. }, ; //X3_TAMANHO
	{ 0																		, .T. }, ; //X3_DECIMAL
	{ 'Data In�cio'															, .T. }, ; //X3_TITULO
	{ 'Data In�cio'															, .T. }, ; //X3_TITSPA
	{ 'Data In�cio'															, .T. }, ; //X3_TITENG
	{ 'Data do In�cio'														, .T. }, ; //X3_DESCRIC
	{ 'Data do In�cio'														, .T. }, ; //X3_DESCSPA
	{ 'Data do In�cio'														, .T. }, ; //X3_DESCENG
	{ ''																	, .T. }, ; //X3_PICTURE
	{ ''																	, .T. }, ; //X3_VALID
	{ 'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x', .T. }, ; //X3_USADO
	{ ''																	, .T. }, ; //X3_RELACAO
	{ ''																	, .T. }, ; //X3_F3
	{ 0																		, .T. }, ; //X3_NIVEL
	{ 'xxxxxx x'															, .T. }, ; //X3_RESERV
	{ ''																	, .T. }, ; //X3_CHECK
	{ 'S'																	, .T. }, ; //X3_TRIGGER
	{ 'U'																	, .T. }, ; //X3_PROPRI
	{ 'S'																	, .T. }, ; //X3_BROWSE
	{ 'A'																	, .T. }, ; //X3_VISUAL
	{ 'R'																	, .T. }, ; //X3_CONTEXT
	{ ''																	, .T. }, ; //X3_OBRIGAT
	{ 'U_CRMValCp()'														, .T. }, ; //X3_VLDUSER
	{ ''																	, .T. }, ; //X3_CBOX
	{ ''																	, .T. }, ; //X3_CBOXSPA
	{ ''																	, .T. }, ; //X3_CBOXENG
	{ ''																	, .T. }, ; //X3_PICTVAR
	{ "U_fCRMWhen('ZD5_PRVINI',.F.,'ALT')"									, .T. }, ; //X3_WHEN
	{ ''																	, .T. }, ; //X3_INIBRW
	{ ''																	, .T. }, ; //X3_GRPSXG
	{ ''																	, .T. }, ; //X3_FOLDER
	{ ''																	, .T. }, ; //X3_CONDSQL
	{ ''																	, .T. }, ; //X3_CHKSQL
	{ ''																	, .T. }, ; //X3_IDXSRV
	{ 'N'																	, .T. }, ; //X3_ORTOGRA
	{ ''																	, .T. }, ; //X3_TELA
	{ ''																	, .T. }, ; //X3_POSLGT
	{ 'N'																	, .T. }, ; //X3_IDXFLD
	{ ''																	, .T. }, ; //X3_AGRUP
	{ ''																	, .T. }, ; //X3_MODAL
	{ ''																	, .T. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'ZD5'																	, .T. }, ; //X3_ARQUIVO
	{ '07'																	, .T. }, ; //X3_ORDEM
	{ 'ZD5_PRVFIM'															, .T. }, ; //X3_CAMPO
	{ 'D'																	, .T. }, ; //X3_TIPO
	{ 8																		, .T. }, ; //X3_TAMANHO
	{ 0																		, .T. }, ; //X3_DECIMAL
	{ 'Prv Conclus.'														, .T. }, ; //X3_TITULO
	{ 'Prv Conclus.'														, .T. }, ; //X3_TITSPA
	{ 'Prv Conclus.'														, .T. }, ; //X3_TITENG
	{ 'Data Prevista Conclus�o'												, .T. }, ; //X3_DESCRIC
	{ 'Data Prevista Conclus�o'												, .T. }, ; //X3_DESCSPA
	{ 'Data Prevista Conclus�o'												, .T. }, ; //X3_DESCENG
	{ ''																	, .T. }, ; //X3_PICTURE
	{ ''																	, .T. }, ; //X3_VALID
	{ 'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x', .T. }, ; //X3_USADO
	{ ''																	, .T. }, ; //X3_RELACAO
	{ ''																	, .T. }, ; //X3_F3
	{ 0																		, .T. }, ; //X3_NIVEL
	{ 'xxxxxx x'															, .T. }, ; //X3_RESERV
	{ ''																	, .T. }, ; //X3_CHECK
	{ 'S'																	, .T. }, ; //X3_TRIGGER
	{ 'U'																	, .T. }, ; //X3_PROPRI
	{ 'S'																	, .T. }, ; //X3_BROWSE
	{ 'A'																	, .T. }, ; //X3_VISUAL
	{ 'R'																	, .T. }, ; //X3_CONTEXT
	{ ''																	, .T. }, ; //X3_OBRIGAT
	{ 'U_CRMValCp()'														, .T. }, ; //X3_VLDUSER
	{ ''																	, .T. }, ; //X3_CBOX
	{ ''																	, .T. }, ; //X3_CBOXSPA
	{ ''																	, .T. }, ; //X3_CBOXENG
	{ ''																	, .T. }, ; //X3_PICTVAR
	{ "U_fCRMWhen('ZD5_DTFIM',.T.,'ALT')	"									, .T. }, ; //X3_WHEN
	{ ''																	, .T. }, ; //X3_INIBRW
	{ ''																	, .T. }, ; //X3_GRPSXG
	{ ''																	, .T. }, ; //X3_FOLDER
	{ ''																	, .T. }, ; //X3_CONDSQL
	{ ''																	, .T. }, ; //X3_CHKSQL
	{ ''																	, .T. }, ; //X3_IDXSRV
	{ 'N'																	, .T. }, ; //X3_ORTOGRA
	{ ''																	, .T. }, ; //X3_TELA
	{ ''																	, .T. }, ; //X3_POSLGT
	{ 'N'																	, .T. }, ; //X3_IDXFLD
	{ ''																	, .T. }, ; //X3_AGRUP
	{ ''																	, .T. }, ; //X3_MODAL
	{ ''																	, .T. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'ZD5'																	, .T. }, ; //X3_ARQUIVO
	{ '08'																	, .T. }, ; //X3_ORDEM
	{ 'ZD5_DTFIM'															, .T. }, ; //X3_CAMPO
	{ 'D'																	, .T. }, ; //X3_TIPO
	{ 8																		, .T. }, ; //X3_TAMANHO
	{ 0																		, .T. }, ; //X3_DECIMAL
	{ 'Dt T�rmino'															, .T. }, ; //X3_TITULO
	{ 'Dt T�rmino'															, .T. }, ; //X3_TITSPA
	{ 'Dt T�rmino'															, .T. }, ; //X3_TITENG
	{ 'Data T�rmino'														, .T. }, ; //X3_DESCRIC
	{ 'Data T�rmino'														, .T. }, ; //X3_DESCSPA
	{ 'Data T�rmino'														, .T. }, ; //X3_DESCENG
	{ ''																	, .T. }, ; //X3_PICTURE
	{ ''																	, .T. }, ; //X3_VALID
	{ 'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x', .T. }, ; //X3_USADO
	{ ''																	, .T. }, ; //X3_RELACAO
	{ ''																	, .T. }, ; //X3_F3
	{ 0																		, .T. }, ; //X3_NIVEL
	{ 'xxxxxx x'															, .T. }, ; //X3_RESERV
	{ ''																	, .T. }, ; //X3_CHECK
	{ 'S'																	, .T. }, ; //X3_TRIGGER
	{ 'U'																	, .T. }, ; //X3_PROPRI
	{ 'S'																	, .T. }, ; //X3_BROWSE
	{ 'A'																	, .T. }, ; //X3_VISUAL
	{ 'R'																	, .T. }, ; //X3_CONTEXT
	{ ''																	, .T. }, ; //X3_OBRIGAT
	{ 'U_CRMValCp()'														, .T. }, ; //X3_VLDUSER
	{ ''																	, .T. }, ; //X3_CBOX
	{ ''																	, .T. }, ; //X3_CBOXSPA
	{ ''																	, .T. }, ; //X3_CBOXENG
	{ ''																	, .T. }, ; //X3_PICTVAR
	{ "U_fCRMWhen('ZD5_PRVFIM',.F.,'ALT')	"									, .T. }, ; //X3_WHEN
	{ ''																	, .T. }, ; //X3_INIBRW
	{ ''																	, .T. }, ; //X3_GRPSXG
	{ ''																	, .T. }, ; //X3_FOLDER
	{ ''																	, .T. }, ; //X3_CONDSQL
	{ ''																	, .T. }, ; //X3_CHKSQL
	{ ''																	, .T. }, ; //X3_IDXSRV
	{ 'N'																	, .T. }, ; //X3_ORTOGRA
	{ ''																	, .T. }, ; //X3_TELA
	{ ''																	, .T. }, ; //X3_POSLGT
	{ 'N'																	, .T. }, ; //X3_IDXFLD
	{ ''																	, .T. }, ; //X3_AGRUP
	{ ''																	, .T. }, ; //X3_MODAL
	{ ''																	, .T. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'ZD5'																	, .T. }, ; //X3_ARQUIVO
	{ '09'																	, .T. }, ; //X3_ORDEM
	{ 'ZD5_DTCANC'															, .T. }, ; //X3_CAMPO
	{ 'D'																	, .T. }, ; //X3_TIPO
	{ 8																		, .T. }, ; //X3_TAMANHO
	{ 0																		, .T. }, ; //X3_DECIMAL
	{ 'Data Cancel.'														, .T. }, ; //X3_TITULO
	{ 'Data Cancel.'														, .T. }, ; //X3_TITSPA
	{ 'Data Cancel.'														, .T. }, ; //X3_TITENG
	{ 'Data do Cancelamento'												, .T. }, ; //X3_DESCRIC
	{ 'Data do Cancelamento'												, .T. }, ; //X3_DESCSPA
	{ 'Data do Cancelamento'												, .T. }, ; //X3_DESCENG
	{ ''																	, .T. }, ; //X3_PICTURE
	{ ''																	, .T. }, ; //X3_VALID
	{ 'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x', .T. }, ; //X3_USADO
	{ ''																	, .T. }, ; //X3_RELACAO
	{ ''																	, .T. }, ; //X3_F3
	{ 0																		, .T. }, ; //X3_NIVEL
	{ 'xxxxxx x'															, .T. }, ; //X3_RESERV
	{ ''																	, .T. }, ; //X3_CHECK
	{ 'S'																	, .T. }, ; //X3_TRIGGER
	{ 'U'																	, .T. }, ; //X3_PROPRI
	{ 'S'																	, .T. }, ; //X3_BROWSE
	{ 'A'																	, .T. }, ; //X3_VISUAL
	{ 'R'																	, .T. }, ; //X3_CONTEXT
	{ ''																	, .T. }, ; //X3_OBRIGAT
	{ 'U_CRMValCp()'														, .T. }, ; //X3_VLDUSER
	{ ''																	, .T. }, ; //X3_CBOX
	{ ''																	, .T. }, ; //X3_CBOXSPA
	{ ''																	, .T. }, ; //X3_CBOXENG
	{ ''																	, .T. }, ; //X3_PICTVAR
	{ "U_fCRMWhen('ZD5_DTFIM',.T.,'ALT')	"									, .T. }, ; //X3_WHEN
	{ ''																	, .T. }, ; //X3_INIBRW
	{ ''																	, .T. }, ; //X3_GRPSXG
	{ ''																	, .T. }, ; //X3_FOLDER
	{ ''																	, .T. }, ; //X3_CONDSQL
	{ ''																	, .T. }, ; //X3_CHKSQL
	{ ''																	, .T. }, ; //X3_IDXSRV
	{ 'N'																	, .T. }, ; //X3_ORTOGRA
	{ ''																	, .T. }, ; //X3_TELA
	{ ''																	, .T. }, ; //X3_POSLGT
	{ 'N'																	, .T. }, ; //X3_IDXFLD
	{ ''																	, .T. }, ; //X3_AGRUP
	{ ''																	, .T. }, ; //X3_MODAL
	{ ''																	, .T. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'ZD5'																	, .T. }, ; //X3_ARQUIVO
	{ '10'																	, .T. }, ; //X3_ORDEM
	{ 'ZD5_OBSFIM'															, .T. }, ; //X3_CAMPO
	{ 'M'																	, .T. }, ; //X3_TIPO
	{ 10																	, .T. }, ; //X3_TAMANHO
	{ 0																		, .T. }, ; //X3_DECIMAL
	{ 'Observa��es'															, .T. }, ; //X3_TITULO
	{ 'Observa��es'															, .T. }, ; //X3_TITSPA
	{ 'Observa��es'															, .T. }, ; //X3_TITENG
	{ 'Observa��es  da Atividade'											, .T. }, ; //X3_DESCRIC
	{ 'Observa��es  da Atividade'											, .T. }, ; //X3_DESCSPA
	{ 'Observa��es  da Atividade'											, .T. }, ; //X3_DESCENG
	{ ''																	, .T. }, ; //X3_PICTURE
	{ ''																	, .T. }, ; //X3_VALID
	{ 'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x', .T. }, ; //X3_USADO
	{ ''																	, .T. }, ; //X3_RELACAO
	{ ''																	, .T. }, ; //X3_F3
	{ 0																		, .T. }, ; //X3_NIVEL
	{ 'xxxxxx x'															, .T. }, ; //X3_RESERV
	{ ''																	, .T. }, ; //X3_CHECK
	{ ''																	, .T. }, ; //X3_TRIGGER
	{ 'U'																	, .T. }, ; //X3_PROPRI
	{ 'N'																	, .T. }, ; //X3_BROWSE
	{ 'A'																	, .T. }, ; //X3_VISUAL
	{ 'R'																	, .T. }, ; //X3_CONTEXT
	{ ''																	, .T. }, ; //X3_OBRIGAT
	{ ''																	, .T. }, ; //X3_VLDUSER
	{ ''																	, .T. }, ; //X3_CBOX
	{ ''																	, .T. }, ; //X3_CBOXSPA
	{ ''																	, .T. }, ; //X3_CBOXENG
	{ ''																	, .T. }, ; //X3_PICTVAR
	{ "U_fCRMWhen('',.F.,'ALT')"											, .T. }, ; //X3_WHEN
	{ ''																	, .T. }, ; //X3_INIBRW
	{ ''																	, .T. }, ; //X3_GRPSXG
	{ ''																	, .T. }, ; //X3_FOLDER
	{ ''																	, .T. }, ; //X3_CONDSQL
	{ ''																	, .T. }, ; //X3_CHKSQL
	{ ''																	, .T. }, ; //X3_IDXSRV
	{ 'N'																	, .T. }, ; //X3_ORTOGRA
	{ ''																	, .T. }, ; //X3_TELA
	{ ''																	, .T. }, ; //X3_POSLGT
	{ 'N'																	, .T. }, ; //X3_IDXFLD
	{ ''																	, .T. }, ; //X3_AGRUP
	{ ''																	, .T. }, ; //X3_MODAL
	{ ''																	, .T. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'ZD5'																	, .T. }, ; //X3_ARQUIVO
	{ '11'																	, .T. }, ; //X3_ORDEM
	{ 'ZD5_DTINCL'															, .T. }, ; //X3_CAMPO
	{ 'D'																	, .T. }, ; //X3_TIPO
	{ 8																		, .T. }, ; //X3_TAMANHO
	{ 0																		, .T. }, ; //X3_DECIMAL
	{ 'Dt Inclus�o'															, .T. }, ; //X3_TITULO
	{ 'Dt Inclus�o'															, .T. }, ; //X3_TITSPA
	{ 'Dt Inclus�o'															, .T. }, ; //X3_TITENG
	{ 'Data da Inclus�o'													, .T. }, ; //X3_DESCRIC
	{ 'Data da Inclus�o'													, .T. }, ; //X3_DESCSPA
	{ 'Data da Inclus�o'													, .T. }, ; //X3_DESCENG
	{ ''																	, .T. }, ; //X3_PICTURE
	{ ''																	, .T. }, ; //X3_VALID
	{ 'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x', .T. }, ; //X3_USADO
	{ 'Date()'																, .T. }, ; //X3_RELACAO
	{ ''																	, .T. }, ; //X3_F3
	{ 0																		, .T. }, ; //X3_NIVEL
	{ 'xxxxxx x'															, .T. }, ; //X3_RESERV
	{ ''																	, .T. }, ; //X3_CHECK
	{ ''																	, .T. }, ; //X3_TRIGGER
	{ 'U'																	, .T. }, ; //X3_PROPRI
	{ 'N'																	, .T. }, ; //X3_BROWSE
	{ 'V'																	, .T. }, ; //X3_VISUAL
	{ 'R'																	, .T. }, ; //X3_CONTEXT
	{ ''																	, .T. }, ; //X3_OBRIGAT
	{ ''																	, .T. }, ; //X3_VLDUSER
	{ ''																	, .T. }, ; //X3_CBOX
	{ ''																	, .T. }, ; //X3_CBOXSPA
	{ ''																	, .T. }, ; //X3_CBOXENG
	{ ''																	, .T. }, ; //X3_PICTVAR
	{ ''																	, .T. }, ; //X3_WHEN
	{ ''																	, .T. }, ; //X3_INIBRW
	{ ''																	, .T. }, ; //X3_GRPSXG
	{ ''																	, .T. }, ; //X3_FOLDER
	{ ''																	, .T. }, ; //X3_CONDSQL
	{ ''																	, .T. }, ; //X3_CHKSQL
	{ ''																	, .T. }, ; //X3_IDXSRV
	{ 'N'																	, .T. }, ; //X3_ORTOGRA
	{ ''																	, .T. }, ; //X3_TELA
	{ ''																	, .T. }, ; //X3_POSLGT
	{ 'N'																	, .T. }, ; //X3_IDXFLD
	{ ''																	, .T. }, ; //X3_AGRUP
	{ ''																	, .T. }, ; //X3_MODAL
	{ ''																	, .T. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'ZD5'																	, .T. }, ; //X3_ARQUIVO
	{ '12'																	, .T. }, ; //X3_ORDEM
	{ 'ZD5_USRINC'															, .T. }, ; //X3_CAMPO
	{ 'C'																	, .T. }, ; //X3_TIPO
	{ 25																	, .T. }, ; //X3_TAMANHO
	{ 0																		, .T. }, ; //X3_DECIMAL
	{ 'Usr Inclus�o'														, .T. }, ; //X3_TITULO
	{ 'Usr Inclus�o'														, .T. }, ; //X3_TITSPA
	{ 'Usr Inclus�o'														, .T. }, ; //X3_TITENG
	{ 'Usu�rio Inclus�o'													, .T. }, ; //X3_DESCRIC
	{ 'Usu�rio Inclus�o'													, .T. }, ; //X3_DESCSPA
	{ 'Usu�rio Inclus�o'													, .T. }, ; //X3_DESCENG
	{ '@!'																	, .T. }, ; //X3_PICTURE
	{ ''																	, .T. }, ; //X3_VALID
	{ 'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x', .T. }, ; //X3_USADO
	{ 'upper(UsrFullName())'												, .T. }, ; //X3_RELACAO
	{ ''																	, .T. }, ; //X3_F3
	{ 0																		, .T. }, ; //X3_NIVEL
	{ 'xxxxxx x'															, .T. }, ; //X3_RESERV
	{ ''																	, .T. }, ; //X3_CHECK
	{ ''																	, .T. }, ; //X3_TRIGGER
	{ 'U'																	, .T. }, ; //X3_PROPRI
	{ 'N'																	, .T. }, ; //X3_BROWSE
	{ 'V'																	, .T. }, ; //X3_VISUAL
	{ 'R'																	, .T. }, ; //X3_CONTEXT
	{ ''																	, .T. }, ; //X3_OBRIGAT
	{ ''																	, .T. }, ; //X3_VLDUSER
	{ ''																	, .T. }, ; //X3_CBOX
	{ ''																	, .T. }, ; //X3_CBOXSPA
	{ ''																	, .T. }, ; //X3_CBOXENG
	{ ''																	, .T. }, ; //X3_PICTVAR
	{ ''																	, .T. }, ; //X3_WHEN
	{ ''																	, .T. }, ; //X3_INIBRW
	{ ''																	, .T. }, ; //X3_GRPSXG
	{ ''																	, .T. }, ; //X3_FOLDER
	{ ''																	, .T. }, ; //X3_CONDSQL
	{ ''																	, .T. }, ; //X3_CHKSQL
	{ ''																	, .T. }, ; //X3_IDXSRV
	{ 'N'																	, .T. }, ; //X3_ORTOGRA
	{ ''																	, .T. }, ; //X3_TELA
	{ ''																	, .T. }, ; //X3_POSLGT
	{ 'N'																	, .T. }, ; //X3_IDXFLD
	{ ''																	, .T. }, ; //X3_AGRUP
	{ ''																	, .T. }, ; //X3_MODAL
	{ ''																	, .T. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'ZD5'																	, .T. }, ; //X3_ARQUIVO
	{ '13'																	, .T. }, ; //X3_ORDEM
	{ 'ZD5_DTALT'															, .T. }, ; //X3_CAMPO
	{ 'D'																	, .T. }, ; //X3_TIPO
	{ 8																		, .T. }, ; //X3_TAMANHO
	{ 0																		, .T. }, ; //X3_DECIMAL
	{ 'Dt Altera��o'														, .T. }, ; //X3_TITULO
	{ 'Dt Altera��o'														, .T. }, ; //X3_TITSPA
	{ 'Dt Altera��o'														, .T. }, ; //X3_TITENG
	{ 'Data de Altera��o'													, .T. }, ; //X3_DESCRIC
	{ 'Data de Altera��o'													, .T. }, ; //X3_DESCSPA
	{ 'Data de Altera��o'													, .T. }, ; //X3_DESCENG
	{ ''																	, .T. }, ; //X3_PICTURE
	{ ''																	, .T. }, ; //X3_VALID
	{ 'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x', .T. }, ; //X3_USADO
	{ ''																	, .T. }, ; //X3_RELACAO
	{ ''																	, .T. }, ; //X3_F3
	{ 0																		, .T. }, ; //X3_NIVEL
	{ 'xxxxxx x'															, .T. }, ; //X3_RESERV
	{ ''																	, .T. }, ; //X3_CHECK
	{ ''																	, .T. }, ; //X3_TRIGGER
	{ 'U'																	, .T. }, ; //X3_PROPRI
	{ 'S'																	, .T. }, ; //X3_BROWSE
	{ 'V'																	, .T. }, ; //X3_VISUAL
	{ 'R'																	, .T. }, ; //X3_CONTEXT
	{ ''																	, .T. }, ; //X3_OBRIGAT
	{ ''																	, .T. }, ; //X3_VLDUSER
	{ ''																	, .T. }, ; //X3_CBOX
	{ ''																	, .T. }, ; //X3_CBOXSPA
	{ ''																	, .T. }, ; //X3_CBOXENG
	{ ''																	, .T. }, ; //X3_PICTVAR
	{ ''																	, .T. }, ; //X3_WHEN
	{ ''																	, .T. }, ; //X3_INIBRW
	{ ''																	, .T. }, ; //X3_GRPSXG
	{ ''																	, .T. }, ; //X3_FOLDER
	{ ''																	, .T. }, ; //X3_CONDSQL
	{ ''																	, .T. }, ; //X3_CHKSQL
	{ ''																	, .T. }, ; //X3_IDXSRV
	{ 'N'																	, .T. }, ; //X3_ORTOGRA
	{ ''																	, .T. }, ; //X3_TELA
	{ ''																	, .T. }, ; //X3_POSLGT
	{ 'N'																	, .T. }, ; //X3_IDXFLD
	{ ''																	, .T. }, ; //X3_AGRUP
	{ ''																	, .T. }, ; //X3_MODAL
	{ ''																	, .T. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'ZD5'																	, .T. }, ; //X3_ARQUIVO
	{ '14'																	, .T. }, ; //X3_ORDEM
	{ 'ZD5_USRALT'															, .T. }, ; //X3_CAMPO
	{ 'C'																	, .T. }, ; //X3_TIPO
	{ 25																	, .T. }, ; //X3_TAMANHO
	{ 0																		, .T. }, ; //X3_DECIMAL
	{ 'Us Altera��o'														, .T. }, ; //X3_TITULO
	{ 'Us Altera��o'														, .T. }, ; //X3_TITSPA
	{ 'Us Altera��o'														, .T. }, ; //X3_TITENG
	{ 'Usu�rio Altera��o'													, .T. }, ; //X3_DESCRIC
	{ 'Usu�rio Altera��o'													, .T. }, ; //X3_DESCSPA
	{ 'Usu�rio Altera��o'													, .T. }, ; //X3_DESCENG
	{ '@!'																	, .T. }, ; //X3_PICTURE
	{ ''																	, .T. }, ; //X3_VALID
	{ 'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x', .T. }, ; //X3_USADO
	{ ''																	, .T. }, ; //X3_RELACAO
	{ ''																	, .T. }, ; //X3_F3
	{ 0																		, .T. }, ; //X3_NIVEL
	{ 'xxxxxx x'															, .T. }, ; //X3_RESERV
	{ ''																	, .T. }, ; //X3_CHECK
	{ ''																	, .T. }, ; //X3_TRIGGER
	{ 'U'																	, .T. }, ; //X3_PROPRI
	{ 'S'																	, .T. }, ; //X3_BROWSE
	{ 'V'																	, .T. }, ; //X3_VISUAL
	{ 'R'																	, .T. }, ; //X3_CONTEXT
	{ ''																	, .T. }, ; //X3_OBRIGAT
	{ ''																	, .T. }, ; //X3_VLDUSER
	{ ''																	, .T. }, ; //X3_CBOX
	{ ''																	, .T. }, ; //X3_CBOXSPA
	{ ''																	, .T. }, ; //X3_CBOXENG
	{ ''																	, .T. }, ; //X3_PICTVAR
	{ ''																	, .T. }, ; //X3_WHEN
	{ ''																	, .T. }, ; //X3_INIBRW
	{ ''																	, .T. }, ; //X3_GRPSXG
	{ ''																	, .T. }, ; //X3_FOLDER
	{ ''																	, .T. }, ; //X3_CONDSQL
	{ ''																	, .T. }, ; //X3_CHKSQL
	{ ''																	, .T. }, ; //X3_IDXSRV
	{ 'N'																	, .T. }, ; //X3_ORTOGRA
	{ ''																	, .T. }, ; //X3_TELA
	{ ''																	, .T. }, ; //X3_POSLGT
	{ 'N'																	, .T. }, ; //X3_IDXFLD
	{ ''																	, .T. }, ; //X3_AGRUP
	{ ''																	, .T. }, ; //X3_MODAL
	{ ''																	, .T. }} ) //X3_PYME


//
// Atualizando dicion�rio
//
nPosArq := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_ARQUIVO" } )
nPosOrd := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_ORDEM"   } )
nPosCpo := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_CAMPO"   } )
nPosTam := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_TAMANHO" } )
nPosSXG := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_GRPSXG"  } )
nPosVld := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_VALID"   } )

aSort( aSX3,,, { |x,y| x[nPosArq][1]+x[nPosOrd][1]+x[nPosCpo][1] < y[nPosArq][1]+y[nPosOrd][1]+y[nPosCpo][1] } )

oProcess:SetRegua2( Len( aSX3 ) )

dbSelectArea( "SX3" )
dbSetOrder( 2 )
cAliasAtu := ""

For nI := 1 To Len( aSX3 )

	//
	// Verifica se o campo faz parte de um grupo e ajusta tamanho
	//
	If !Empty( aSX3[nI][nPosSXG][1] )
		SXG->( dbSetOrder( 1 ) )
		If SXG->( MSSeek( aSX3[nI][nPosSXG][1] ) )
			If aSX3[nI][nPosTam][1] <> SXG->XG_SIZE
				aSX3[nI][nPosTam][1] := SXG->XG_SIZE
				AutoGrLog( "O tamanho do campo " + aSX3[nI][nPosCpo][1] + " N�O atualizado e foi mantido em [" + ;
				AllTrim( Str( SXG->XG_SIZE ) ) + "]" + CRLF + ;
				" por pertencer ao grupo de campos [" + SXG->XG_GRUPO + "]" + CRLF )
			EndIf
		EndIf
	EndIf

	SX3->( dbSetOrder( 2 ) )

	If !( aSX3[nI][nPosArq][1] $ cAlias )
		cAlias += aSX3[nI][nPosArq][1] + "/"
		aAdd( aArqUpd, aSX3[nI][nPosArq][1] )
	EndIf

	If !SX3->( dbSeek( PadR( aSX3[nI][nPosCpo][1], nTamSeek ) ) )

		//
		// Busca ultima ocorrencia do alias
		//
		If ( aSX3[nI][nPosArq][1] <> cAliasAtu )
			cSeqAtu   := "00"
			cAliasAtu := aSX3[nI][nPosArq][1]

			dbSetOrder( 1 )
			SX3->( dbSeek( cAliasAtu + "ZZ", .T. ) )
			dbSkip( -1 )

			If ( SX3->X3_ARQUIVO == cAliasAtu )
				cSeqAtu := SX3->X3_ORDEM
			EndIf

			nSeqAtu := Val( RetAsc( cSeqAtu, 3, .F. ) )
		EndIf

		nSeqAtu++
		cSeqAtu := RetAsc( Str( nSeqAtu ), 2, .T. )

		RecLock( "SX3", .T. )
		For nJ := 1 To Len( aSX3[nI] )
			If     nJ == nPosOrd  // Ordem
				SX3->( FieldPut( FieldPos( aEstrut[nJ][1] ), cSeqAtu ) )

			ElseIf aEstrut[nJ][2] > 0
				SX3->( FieldPut( FieldPos( aEstrut[nJ][1] ), aSX3[nI][nJ][1] ) )

			EndIf
		Next nJ

		dbCommit()
		MsUnLock()

		AutoGrLog( "Criado campo " + aSX3[nI][nPosCpo][1] )

	Else

		//
		// Verifica se o campo faz parte de um grupo e ajsuta tamanho
		//
		If !Empty( SX3->X3_GRPSXG ) .AND. SX3->X3_GRPSXG <> aSX3[nI][nPosSXG][1]
			SXG->( dbSetOrder( 1 ) )
			If SXG->( MSSeek( SX3->X3_GRPSXG ) )
				If aSX3[nI][nPosTam][1] <> SXG->XG_SIZE
					aSX3[nI][nPosTam][1] := SXG->XG_SIZE
					AutoGrLog( "O tamanho do campo " + aSX3[nI][nPosCpo][1] + " N�O atualizado e foi mantido em [" + ;
					AllTrim( Str( SXG->XG_SIZE ) ) + "]"+ CRLF + ;
					"   por pertencer ao grupo de campos [" + SX3->X3_GRPSXG + "]" + CRLF )
				EndIf
			EndIf
		EndIf

		//
		// Verifica todos os campos
		//
		For nJ := 1 To Len( aSX3[nI] )

			//
			// Se o campo estiver diferente da estrutura
			//
			If aSX3[nI][nJ][2]
				cX3Campo := AllTrim( aEstrut[nJ][1] )
				cX3Dado  := SX3->( FieldGet( aEstrut[nJ][2] ) )

				If  aEstrut[nJ][2] > 0 .AND. ;
					PadR( StrTran( AllToChar( cX3Dado ), " ", "" ), 250 ) <> ;
					PadR( StrTran( AllToChar( aSX3[nI][nJ][1] ), " ", "" ), 250 ) .AND. ;
					!cX3Campo == "X3_ORDEM"

					cMsg := "O campo " + aSX3[nI][nPosCpo][1] + " est� com o " + cX3Campo + ;
					" com o conte�do" + CRLF + ;
					"[" + RTrim( AllToChar( cX3Dado ) ) + "]" + CRLF + ;
					"que ser� substitu�do pelo NOVO conte�do" + CRLF + ;
					"[" + RTrim( AllToChar( aSX3[nI][nJ][1] ) ) + "]" + CRLF + ;
					"Deseja substituir ? "

					If      lTodosSim
						nOpcA := 1
					ElseIf  lTodosNao
						nOpcA := 2
					Else
						nOpcA := Aviso( "ATUALIZA��O DE DICION�RIOS E TABELAS", cMsg, { "Sim", "N�o", "Sim p/Todos", "N�o p/Todos" }, 3, "Diferen�a de conte�do - SX3" )
						lTodosSim := ( nOpcA == 3 )
						lTodosNao := ( nOpcA == 4 )

						If lTodosSim
							nOpcA := 1
							lTodosSim := MsgNoYes( "Foi selecionada a op��o de REALIZAR TODAS altera��es no SX3 e N�O MOSTRAR mais a tela de aviso." + CRLF + "Confirma a a��o [Sim p/Todos] ?" )
						EndIf

						If lTodosNao
							nOpcA := 2
							lTodosNao := MsgNoYes( "Foi selecionada a op��o de N�O REALIZAR nenhuma altera��o no SX3 que esteja diferente da base e N�O MOSTRAR mais a tela de aviso." + CRLF + "Confirma esta a��o [N�o p/Todos]?" )
						EndIf

					EndIf

					If nOpcA == 1
						AutoGrLog( "Alterado campo " + aSX3[nI][nPosCpo][1] + CRLF + ;
						"   " + PadR( cX3Campo, 10 ) + " de [" + AllToChar( cX3Dado ) + "]" + CRLF + ;
						"            para [" + AllToChar( aSX3[nI][nJ][1] )           + "]" + CRLF )

						RecLock( "SX3", .F. )
						FieldPut( FieldPos( aEstrut[nJ][1] ), aSX3[nI][nJ][1] )
						MsUnLock()
					EndIf

				EndIf

			EndIf

		Next

	EndIf

	oProcess:IncRegua2( "Atualizando Campos de Tabelas (SX3) ..." )

Next nI

AutoGrLog( CRLF + "Final da Atualiza��o" + " SX3" + CRLF + Replicate( "-", 128 ) + CRLF )

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} FSAtuSIX

Fun��o de processamento da grava��o do SIX - Indices

@author UPDATE gerado automaticamente
@since  01/10/2025
@obs    Gerado por EXPORDIC - V.8.0.1.0 EFS / Upd. V.6.4.1 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function FSAtuSIX()
Local aEstrut   := {}
Local aSIX      := {}
Local lAlt      := .F.
Local lDelInd   := .F.
Local nI        := 0
Local nJ        := 0

AutoGrLog( "�nicio da Atualiza��o" + " SIX" + CRLF )

aEstrut := { "INDICE" , "ORDEM" , "CHAVE", "DESCRICAO", "DESCSPA"  , ;
             "DESCENG", "PROPRI", "F3"   , "NICKNAME" , "SHOWPESQ" }

//
// Tabela ZD4
//
aAdd( aSIX, { ;
	'ZD4'																	, ; //INDICE
	'1'																		, ; //ORDEM
	'ZD4_FILIAL+ZD4_CODCRM'													, ; //CHAVE
	'C�digo CRM'															, ; //DESCRICAO
	'C�digo CRM'															, ; //DESCSPA
	'C�digo CRM'															, ; //DESCENG
	'U'																		, ; //PROPRI
	''																		, ; //F3
	''																		, ; //NICKNAME
	'S'																		} ) //SHOWPESQ

aAdd( aSIX, { ;
	'ZD4'																	, ; //INDICE
	'2'																		, ; //ORDEM
	'ZD4_FILIAL+ZD4_CODCLI+ZD4_LOJCLI'										, ; //CHAVE
	'C�d Cliente+Loja'														, ; //DESCRICAO
	'C�d Cliente+Loja'														, ; //DESCSPA
	'C�d Cliente+Loja'														, ; //DESCENG
	'U'																		, ; //PROPRI
	''																		, ; //F3
	''																		, ; //NICKNAME
	'S'																		} ) //SHOWPESQ

aAdd( aSIX, { ;
	'ZD4'																	, ; //INDICE
	'3'																		, ; //ORDEM
	'ZD4_FILIAL+ZD4_NOMCLI'													, ; //CHAVE
	'Nome Cliente'															, ; //DESCRICAO
	'Nome Cliente'															, ; //DESCSPA
	'Nome Cliente'															, ; //DESCENG
	'U'																		, ; //PROPRI
	''																		, ; //F3
	''																		, ; //NICKNAME
	'S'																		} ) //SHOWPESQ

aAdd( aSIX, { ;
	'ZD4'																	, ; //INDICE
	'4'																		, ; //ORDEM
	'ZD4_FILIAL+ZD4_STATUS+ZD4_CODCLI+ZD4_LOJCLI'							, ; //CHAVE
	'Status+C�d Cliente+Loja'												, ; //DESCRICAO
	'Status+C�d Cliente+Loja'												, ; //DESCSPA
	'Status+C�d Cliente+Loja'												, ; //DESCENG
	'U'																		, ; //PROPRI
	''																		, ; //F3
	''																		, ; //NICKNAME
	'S'																		} ) //SHOWPESQ

aAdd( aSIX, { ;
	'ZD4'																	, ; //INDICE
	'5'																		, ; //ORDEM
	'ZD4_FILIAL+ZD4_STATUS+ZD4_NOMCLI'										, ; //CHAVE
	'Status+Nome Cliente'													, ; //DESCRICAO
	'Status+Nome Cliente'													, ; //DESCSPA
	'Status+Nome Cliente'													, ; //DESCENG
	'U'																		, ; //PROPRI
	''																		, ; //F3
	''																		, ; //NICKNAME
	'S'																		} ) //SHOWPESQ

//
// Tabela ZD5
//
aAdd( aSIX, { ;
	'ZD5'																	, ; //INDICE
	'1'																		, ; //ORDEM
	'ZD5_FILIAL+ZD5_CODCRM+ZD5_PRVINI'										, ; //CHAVE
	'C�digo CRM+Prev In�cio,'												, ; //DESCRICAO
	'C�digo CRM+Prev In�cio,'												, ; //DESCSPA
	'C�digo CRM+Prev In�cio,'												, ; //DESCENG
	'U'																		, ; //PROPRI
	''																		, ; //F3
	''																		, ; //NICKNAME
	'S'																		} ) //SHOWPESQ

//
// Atualizando dicion�rio
//
oProcess:SetRegua2( Len( aSIX ) )

dbSelectArea( "SIX" )
SIX->( dbSetOrder( 1 ) )

For nI := 1 To Len( aSIX )

	lAlt    := .F.
	lDelInd := .F.

	If !SIX->( dbSeek( aSIX[nI][1] + aSIX[nI][2] ) )
		AutoGrLog( "�ndice criado " + aSIX[nI][1] + "/" + aSIX[nI][2] + " - " + aSIX[nI][3] )
	Else
		lAlt := .T.
		aAdd( aArqUpd, aSIX[nI][1] )
		If !StrTran( Upper( AllTrim( CHAVE )       ), " ", "" ) == ;
		    StrTran( Upper( AllTrim( aSIX[nI][3] ) ), " ", "" )
			AutoGrLog( "Chave do �ndice alterado " + aSIX[nI][1] + "/" + aSIX[nI][2] + " - " + aSIX[nI][3] )
			lDelInd := .T. // Se for altera��o precisa apagar o indice do banco
		EndIf
	EndIf

	RecLock( "SIX", !lAlt )
	For nJ := 1 To Len( aSIX[nI] )
		If FieldPos( aEstrut[nJ] ) > 0
			FieldPut( FieldPos( aEstrut[nJ] ), aSIX[nI][nJ] )
		EndIf
	Next nJ
	MsUnLock()

	dbCommit()

	If lDelInd
		TcInternal( 60, RetSqlName( aSIX[nI][1] ) + "|" + RetSqlName( aSIX[nI][1] ) + aSIX[nI][2] )
	EndIf

	oProcess:IncRegua2( "Atualizando �ndices ..." )

Next nI

AutoGrLog( CRLF + "Final da Atualiza��o" + " SIX" + CRLF + Replicate( "-", 128 ) + CRLF )

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} FSAtuSX7

Fun��o de processamento da grava��o do SX7 - Gatilhos

@author UPDATE gerado automaticamente
@since  01/10/2025
@obs    Gerado por EXPORDIC - V.8.0.1.0 EFS / Upd. V.6.4.1 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function FSAtuSX7()
Local aEstrut   := {}
Local aAreaSX3  := SX3->( GetArea() )
Local aSX7      := {}
Local cAlias    := ""
Local nI        := 0
Local nJ        := 0
Local nTamSeek  := Len( SX7->X7_CAMPO )

AutoGrLog( "�nicio da Atualiza��o" + " SX7" + CRLF )

aEstrut := { "X7_CAMPO", "X7_SEQUENC", "X7_REGRA", "X7_CDOMIN", "X7_TIPO", "X7_SEEK", ;
             "X7_ALIAS", "X7_ORDEM"  , "X7_CHAVE", "X7_PROPRI", "X7_CONDIC" }

//
// Campo ZD4_CODCLI
//
aAdd( aSX7, { ;
	'ZD4_CODCLI'															, ; //X7_CAMPO
	'001'																	, ; //X7_SEQUENC
	'SA1->A1_NOME'															, ; //X7_REGRA
	'ZD4_NOMCLI'															, ; //X7_CDOMIN
	'P'																		, ; //X7_TIPO
	'S'																		, ; //X7_SEEK
	'SA1'																	, ; //X7_ALIAS
	1																		, ; //X7_ORDEM
	"xFilial('SA1') + FwFldGet('ZD4_CODCLI') + alltrim(FwFldGet('ZD4_LOJCLI'))"	, ; //X7_CHAVE
	'U'																		, ; //X7_PROPRI
	''																		} ) //X7_CONDIC

//
// Campo ZD4_LOJCLI
//
aAdd( aSX7, { ;
	'ZD4_LOJCLI'															, ; //X7_CAMPO
	'001'																	, ; //X7_SEQUENC
	'SA1->A1_NOME'															, ; //X7_REGRA
	'ZD4_NOMCLI'															, ; //X7_CDOMIN
	'P'																		, ; //X7_TIPO
	'S'																		, ; //X7_SEEK
	'SA1'																	, ; //X7_ALIAS
	1																		, ; //X7_ORDEM
	"xFilial('SA1') + FwFldGet('ZD4_CODCLI') + alltrim(FwFldGet('ZD4_LOJCLI'))"	, ; //X7_CHAVE
	'U'																		, ; //X7_PROPRI
	''																		} ) //X7_CONDIC

//
// Campo ZD4_MOTPER
//
aAdd( aSX7, { ;
	'ZD4_MOTPER'															, ; //X7_CAMPO
	'001'																	, ; //X7_SEQUENC
	'SX5->X5_DESCRI'														, ; //X7_REGRA
	'ZD4_DSCPER'															, ; //X7_CDOMIN
	'P'																		, ; //X7_TIPO
	'S'																		, ; //X7_SEEK
	'SX5'																	, ; //X7_ALIAS
	1																		, ; //X7_ORDEM
	"xFilial('SX5') + '12' + FwFldGet('ZD4_MOTPER')"						, ; //X7_CHAVE
	''																		, ; //X7_PROPRI
	''																		} ) //X7_CONDIC

//
// Campo ZD5_DTCANC
//
aAdd( aSX7, { ;
	'ZD5_DTCANC'															, ; //X7_CAMPO
	'001'																	, ; //X7_SEQUENC
	'date()'																, ; //X7_REGRA
	'ZD5_DTCANC'															, ; //X7_CDOMIN
	'P'																		, ; //X7_TIPO
	'N'																		, ; //X7_SEEK
	''																		, ; //X7_ALIAS
	0																		, ; //X7_ORDEM
	''																		, ; //X7_CHAVE
	'U'																		, ; //X7_PROPRI
	"empty(FwFldGet('ZD5_DTCANC'))"											} ) //X7_CONDIC

aAdd( aSX7, { ;
	'ZD5_DTCANC'															, ; //X7_CAMPO
	'002'																	, ; //X7_SEQUENC
	"U_CRMSTATUS(FwFldGet('ZD5_DTCANC'),FwFldGet('ZD5_PRVINI'),FwFldGet('ZD5_DTINI'),FwFldGet('ZD5_PRVFIM'),FwFldGet('ZD5_DTFIM'))", ; //X7_REGRA
	'ZD5_STATUS'															, ; //X7_CDOMIN
	'P'																		, ; //X7_TIPO
	'N'																		, ; //X7_SEEK
	''																		, ; //X7_ALIAS
	0																		, ; //X7_ORDEM
	''																		, ; //X7_CHAVE
	'U'																		, ; //X7_PROPRI
	''																		} ) //X7_CONDIC

//
// Campo ZD5_DTFIM
//
aAdd( aSX7, { ;
	'ZD5_DTFIM'																, ; //X7_CAMPO
	'001'																	, ; //X7_SEQUENC
	'date()'																, ; //X7_REGRA
	'ZD5_DTFIM'																, ; //X7_CDOMIN
	'P'																		, ; //X7_TIPO
	'N'																		, ; //X7_SEEK
	''																		, ; //X7_ALIAS
	0																		, ; //X7_ORDEM
	''																		, ; //X7_CHAVE
	'U'																		, ; //X7_PROPRI
	"empty(FwFldGet('ZD5_DTFIM'))"											} ) //X7_CONDIC

aAdd( aSX7, { ;
	'ZD5_DTFIM'																, ; //X7_CAMPO
	'002'																	, ; //X7_SEQUENC
	"U_CRMSTATUS(FwFldGet('ZD5_DTCANC'),FwFldGet('ZD5_PRVINI'),FwFldGet('ZD5_DTINI'),FwFldGet('ZD5_PRVFIM'),FwFldGet('ZD5_DTFIM'))", ; //X7_REGRA
	'ZD5_STATUS'															, ; //X7_CDOMIN
	'P'																		, ; //X7_TIPO
	'N'																		, ; //X7_SEEK
	''																		, ; //X7_ALIAS
	0																		, ; //X7_ORDEM
	''																		, ; //X7_CHAVE
	'U'																		, ; //X7_PROPRI
	''																		} ) //X7_CONDIC

//
// Campo ZD5_DTINI
//
aAdd( aSX7, { ;
	'ZD5_DTINI'																, ; //X7_CAMPO
	'001'																	, ; //X7_SEQUENC
	'date()'																, ; //X7_REGRA
	'ZD5_DTINI'																, ; //X7_CDOMIN
	'P'																		, ; //X7_TIPO
	'N'																		, ; //X7_SEEK
	''																		, ; //X7_ALIAS
	0																		, ; //X7_ORDEM
	''																		, ; //X7_CHAVE
	'U'																		, ; //X7_PROPRI
	"empty(FwFldGet('ZD5_DTINI'))"											} ) //X7_CONDIC

aAdd( aSX7, { ;
	'ZD5_DTINI'																, ; //X7_CAMPO
	'002'																	, ; //X7_SEQUENC
	"U_CRMSTATUS(FwFldGet('ZD5_DTCANC'),FwFldGet('ZD5_PRVINI'),FwFldGet('ZD5_DTINI'),FwFldGet('ZD5_PRVFIM'),FwFldGet('ZD5_DTFIM'))", ; //X7_REGRA
	'ZD5_STATUS'															, ; //X7_CDOMIN
	'P'																		, ; //X7_TIPO
	'N'																		, ; //X7_SEEK
	''																		, ; //X7_ALIAS
	0																		, ; //X7_ORDEM
	''																		, ; //X7_CHAVE
	'U'																		, ; //X7_PROPRI
	''																		} ) //X7_CONDIC

//
// Campo ZD5_PRVFIM
//
aAdd( aSX7, { ;
	'ZD5_PRVFIM'															, ; //X7_CAMPO
	'001'																	, ; //X7_SEQUENC
	"U_CRMSTATUS(FwFldGet('ZD5_DTCANC'),FwFldGet('ZD5_PRVINI'),FwFldGet('ZD5_DTINI'),FwFldGet('ZD5_PRVFIM'),FwFldGet('ZD5_DTFIM'))", ; //X7_REGRA
	'ZD5_STATUS'															, ; //X7_CDOMIN
	'P'																		, ; //X7_TIPO
	'N'																		, ; //X7_SEEK
	''																		, ; //X7_ALIAS
	0																		, ; //X7_ORDEM
	''																		, ; //X7_CHAVE
	'U'																		, ; //X7_PROPRI
	''																		} ) //X7_CONDIC

//
// Campo ZD5_PRVINI
//
aAdd( aSX7, { ;
	'ZD5_PRVINI'															, ; //X7_CAMPO
	'001'																	, ; //X7_SEQUENC
	"U_CRMSTATUS(FwFldGet('ZD5_DTCANC'),FwFldGet('ZD5_PRVINI'),FwFldGet('ZD5_DTINI'),FwFldGet('ZD5_PRVFIM'),FwFldGet('ZD5_DTFIM'))", ; //X7_REGRA
	'ZD5_STATUS'															, ; //X7_CDOMIN
	'P'																		, ; //X7_TIPO
	'N'																		, ; //X7_SEEK
	''																		, ; //X7_ALIAS
	0																		, ; //X7_ORDEM
	''																		, ; //X7_CHAVE
	'U'																		, ; //X7_PROPRI
	''																		} ) //X7_CONDIC

//
// Atualizando dicion�rio
//
oProcess:SetRegua2( Len( aSX7 ) )

dbSelectArea( "SX3" )
dbSetOrder( 2 )

dbSelectArea( "SX7" )
dbSetOrder( 1 )

For nI := 1 To Len( aSX7 )

	If !SX7->( dbSeek( PadR( aSX7[nI][1], nTamSeek ) + aSX7[nI][2] ) )

		AutoGrLog( "Foi inclu�do o gatilho " + aSX7[nI][1] + "/" + aSX7[nI][2] )

		RecLock( "SX7", .T. )
		For nJ := 1 To Len( aSX7[nI] )
			If FieldPos( aEstrut[nJ] ) > 0
				FieldPut( FieldPos( aEstrut[nJ] ), aSX7[nI][nJ] )
			EndIf
		Next nJ

		dbCommit()
		MsUnLock()

		If SX3->( dbSeek( SX7->X7_CAMPO ) )
			RecLock( "SX3", .F. )
			SX3->X3_TRIGGER := "S"
			MsUnLock()
		EndIf

	EndIf
	oProcess:IncRegua2( "Atualizando Arquivos (SX7) ..." )

Next nI

RestArea( aAreaSX3 )

AutoGrLog( CRLF + "Final da Atualiza��o" + " SX7" + CRLF + Replicate( "-", 128 ) + CRLF )

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} FSAtuSX5

Fun��o de processamento da grava��o do SX5 - Indices

@author UPDATE gerado automaticamente
@since  01/10/2025
@obs    Gerado por EXPORDIC - V.8.0.1.0 EFS / Upd. V.6.4.1 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function FSAtuSX5()
Local aEstrut   := {}
Local aSX5      := {}
Local cAlias    := ""
Local cFilSX5   := xFilial( "SX5" )
Local nI        := 0
Local nJ        := 0
Local nTamFil   := Len( SX5->X5_FILIAL )

AutoGrLog( "�nicio da Atualiza��o SX5" + CRLF )

aEstrut := { "X5_FILIAL", "X5_TABELA", "X5_CHAVE", "X5_DESCRI", "X5_DESCSPA", "X5_DESCENG" }

//
// Tabela 00
//
aAdd( aSX5, { ;
	cFilSX5																	, ; //X5_FILIAL
	'00'																	, ; //X5_TABELA
	'ZB'																	, ; //X5_CHAVE
	'MOTIVOS INDIPONIBILIDADE'												, ; //X5_DESCRI
	'MOTIVOS INDIPONIBILIDADE'												, ; //X5_DESCSPA
	'MOTIVOS INDIPONIBILIDADE'												} ) //X5_DESCENG

//
// Tabela ZB
//
aAdd( aSX5, { ;
	cFilSX5																	, ; //X5_FILIAL
	'ZB'																	, ; //X5_TABELA
	'01'																	, ; //X5_CHAVE
	'MOTIVOS INDIPONIBILIDADE 01'											, ; //X5_DESCRI
	'MOTIVOS INDIPONIBILIDADE 01'											, ; //X5_DESCSPA
	'MOTIVOS INDIPONIBILIDADE 01'											} ) //X5_DESCENG

aAdd( aSX5, { ;
	cFilSX5																	, ; //X5_FILIAL
	'ZB'																	, ; //X5_TABELA
	'02'																	, ; //X5_CHAVE
	'MOTIVOS INDIPONIBILIDADE 02'											, ; //X5_DESCRI
	'MOTIVOS INDIPONIBILIDADE 02'											, ; //X5_DESCSPA
	'MOTIVOS INDIPONIBILIDADE 02'											} ) //X5_DESCENG

//
// Atualizando dicion�rio
//
oProcess:SetRegua2( Len( aSX5 ) )

dbSelectArea( "SX5" )
SX5->( dbSetOrder( 1 ) )

For nI := 1 To Len( aSX5 )

	oProcess:IncRegua2( "Atualizando tabelas ..." )

	If !SX5->( dbSeek( PadR( aSX5[nI][1], nTamFil ) + aSX5[nI][2] + aSX5[nI][3] ) )
		AutoGrLog( "Item da tabela criado. Tabela " + AllTrim( aSX5[nI][1] ) + aSX5[nI][2] + "/" + aSX5[nI][3] )
		RecLock( "SX5", .T. )
	Else
		AutoGrLog( "Item da tabela alterado. Tabela " + AllTrim( aSX5[nI][1] ) + aSX5[nI][2] + "/" + aSX5[nI][3] )
		RecLock( "SX5", .F. )
	EndIf

	For nJ := 1 To Len( aSX5[nI] )
		If FieldPos( aEstrut[nJ] ) > 0
			FieldPut( FieldPos( aEstrut[nJ] ), aSX5[nI][nJ] )
		EndIf
	Next nJ

	MsUnLock()

	aAdd( aArqUpd, aSX5[nI][1] )

	If !( aSX5[nI][1] $ cAlias )
		cAlias += aSX5[nI][1] + "/"
	EndIf

Next nI

AutoGrLog( CRLF + "Final da Atualiza��o" + " SX5" + CRLF + Replicate( "-", 128 ) + CRLF )

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} FSAtuSX9

Fun��o de processamento da grava��o do SX9 - Relacionamento

@author UPDATE gerado automaticamente
@since  01/10/2025
@obs    Gerado por EXPORDIC - V.8.0.1.0 EFS / Upd. V.6.4.1 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function FSAtuSX9()
Local aEstrut   := {}
Local aSX9      := {}
Local cAlias    := ""
Local nI        := 0
Local nJ        := 0
Local nTamSeek  := Len( SX9->X9_DOM )

AutoGrLog( "�nicio da Atualiza��o" + " SX9" + CRLF )

aEstrut := { "X9_DOM"    , "X9_IDENT"  , "X9_CDOM"   , "X9_EXPDOM" , "X9_EXPCDOM", "X9_PROPRI" , "X9_LIGDOM" , ;
             "X9_LIGCDOM", "X9_CONDSQL", "X9_USEFIL" , "X9_VINFIL" , "X9_CHVFOR" , "X9_ENABLE" }


//
// Dom�nio ZD4
//
aAdd( aSX9, { ;
	'ZD4'																	, ; //X9_DOM
	'001'																	, ; //X9_IDENT
	'ZD4'																	, ; //X9_CDOM
	'ZD4_CODCRM'															, ; //X9_EXPDOM
	'ZD4_CODCRM'															, ; //X9_EXPCDOM
	'U'																		, ; //X9_PROPRI
	'1'																		, ; //X9_LIGDOM
	'N'																		, ; //X9_LIGCDOM
	''																		, ; //X9_CONDSQL
	'S'																		, ; //X9_USEFIL
	'S'																		, ; //X9_VINFIL
	'S'																		, ; //X9_CHVFOR
	'S'																		} ) //X9_ENABLE

//
// Atualizando dicion�rio
//
oProcess:SetRegua2( Len( aSX9 ) )

dbSelectArea( "SX9" )
dbSetOrder( 2 )

For nI := 1 To Len( aSX9 )

	If !SX9->( dbSeek( PadR( aSX9[nI][3], nTamSeek ) + PadR( aSX9[nI][1], nTamSeek ) ) )

		If !( aSX9[nI][1]+aSX9[nI][3] $ cAlias )
			cAlias += aSX9[nI][1]+aSX9[nI][3] + "/"
		EndIf

		RecLock( "SX9", .T. )
		For nJ := 1 To Len( aSX9[nI] )
			If FieldPos( aEstrut[nJ] ) > 0
				FieldPut( FieldPos( aEstrut[nJ] ), aSX9[nI][nJ] )
			EndIf
		Next nJ
		dbCommit()
		MsUnLock()

		AutoGrLog( "Foi inclu�do o relacionamento " + aSX9[nI][1] + "/" + aSX9[nI][3] )

		oProcess:IncRegua2( "Atualizando Arquivos (SX9) ..." )

	EndIf

Next nI

AutoGrLog( CRLF + "Final da Atualiza��o" + " SX9" + CRLF + Replicate( "-", 128 ) + CRLF )

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} FSAtuHlp

Fun��o de processamento da grava��o dos Helps de Campos

@author UPDATE gerado automaticamente
@since  01/10/2025
@obs    Gerado por EXPORDIC - V.8.0.1.0 EFS / Upd. V.6.4.1 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function FSAtuHlp()
Local aHlpPor   := {}
Local aHlpEng   := {}
Local aHlpSpa   := {}

AutoGrLog( "�nicio da Atualiza��o" + " " + "Helps de Campos" + CRLF )


oProcess:IncRegua2( "Atualizando Helps de Campos ..." )

//
// Helps Tabela ZD4
//
aHlpPor := {}
aAdd( aHlpPor, 'Status' )

aHlpEng := {}
aAdd( aHlpEng, 'Status' )

aHlpSpa := {}
aAdd( aHlpSpa, 'Status' )

PutSX1Help( "PZD4_STATUS", aHlpPor, aHlpEng, aHlpSpa, .T.,,.T. )
AutoGrLog( "Atualizado o Help do campo " + "ZD4_STATUS" )

aHlpPor := {}
aAdd( aHlpPor, 'C�digo CRM' )

aHlpEng := {}
aAdd( aHlpEng, 'C�digo CRM' )

aHlpSpa := {}
aAdd( aHlpSpa, 'C�digo CRM' )

PutSX1Help( "PZD4_CODCRM", aHlpPor, aHlpEng, aHlpSpa, .T.,,.T. )
AutoGrLog( "Atualizado o Help do campo " + "ZD4_CODCRM" )

aHlpPor := {}
aAdd( aHlpPor, 'C�digo do Cliente' )

aHlpEng := {}
aAdd( aHlpEng, 'C�digo do Cliente' )

aHlpSpa := {}
aAdd( aHlpSpa, 'C�digo do Cliente' )

PutSX1Help( "PZD4_CODCLI", aHlpPor, aHlpEng, aHlpSpa, .T.,,.T. )
AutoGrLog( "Atualizado o Help do campo " + "ZD4_CODCLI" )

aHlpPor := {}
aAdd( aHlpPor, 'Loja do Cliente' )

aHlpEng := {}
aAdd( aHlpEng, 'Loja do Cliente' )

aHlpSpa := {}
aAdd( aHlpSpa, 'Loja do Cliente' )

PutSX1Help( "PZD4_LOJCLI", aHlpPor, aHlpEng, aHlpSpa, .T.,,.T. )
AutoGrLog( "Atualizado o Help do campo " + "ZD4_LOJCLI" )

aHlpPor := {}
aAdd( aHlpPor, 'Nome do Cliente' )

aHlpEng := {}
aAdd( aHlpEng, 'Nome do Cliente' )

aHlpSpa := {}
aAdd( aHlpSpa, 'Nome do Cliente' )

PutSX1Help( "PZD4_NOMCLI", aHlpPor, aHlpEng, aHlpSpa, .T.,,.T. )
AutoGrLog( "Atualizado o Help do campo " + "ZD4_NOMCLI" )

aHlpPor := {}
aAdd( aHlpPor, 'Especifica��es' )

aHlpEng := {}
aAdd( aHlpEng, 'Especifica��es' )

aHlpSpa := {}
aAdd( aHlpSpa, 'Especifica��es' )

PutSX1Help( "PZD4_ESPEC ", aHlpPor, aHlpEng, aHlpSpa, .T.,,.T. )
AutoGrLog( "Atualizado o Help do campo " + "ZD4_ESPEC" )

aHlpPor := {}
aAdd( aHlpPor, 'Data da Inclus�o' )

aHlpEng := {}
aAdd( aHlpEng, 'Data da Inclus�o' )

aHlpSpa := {}
aAdd( aHlpSpa, 'Data da Inclus�o' )

PutSX1Help( "PZD4_DTINCL", aHlpPor, aHlpEng, aHlpSpa, .T.,,.T. )
AutoGrLog( "Atualizado o Help do campo " + "ZD4_DTINCL" )

aHlpPor := {}
aAdd( aHlpPor, 'Usu�rio Inclus�o' )

aHlpEng := {}
aAdd( aHlpEng, 'Usu�rio Inclus�o' )

aHlpSpa := {}
aAdd( aHlpSpa, 'Usu�rio Inclus�o' )

PutSX1Help( "PZD4_USINCL", aHlpPor, aHlpEng, aHlpSpa, .T.,,.T. )
AutoGrLog( "Atualizado o Help do campo " + "ZD4_USINCL" )

aHlpPor := {}
aAdd( aHlpPor, 'Data da Altera��o' )

aHlpEng := {}
aAdd( aHlpEng, 'Data da Altera��o' )

aHlpSpa := {}
aAdd( aHlpSpa, 'Data da Altera��o' )

PutSX1Help( "PZD4_DTALT ", aHlpPor, aHlpEng, aHlpSpa, .T.,,.T. )
AutoGrLog( "Atualizado o Help do campo " + "ZD4_DTALT" )

aHlpPor := {}
aAdd( aHlpPor, 'Usu�rio Altera��o' )

aHlpEng := {}
aAdd( aHlpEng, 'Usu�rio Altera��o' )

aHlpSpa := {}
aAdd( aHlpSpa, 'Usu�rio Altera��o' )

PutSX1Help( "PZD4_USALT ", aHlpPor, aHlpEng, aHlpSpa, .T.,,.T. )
AutoGrLog( "Atualizado o Help do campo " + "ZD4_USALT" )

aHlpPor := {}
aAdd( aHlpPor, 'Motivo Perda' )

aHlpEng := {}
aAdd( aHlpEng, 'Motivo Perda' )

aHlpSpa := {}
aAdd( aHlpSpa, 'Motivo Perda' )

PutSX1Help( "PZD4_MOTPRD", aHlpPor, aHlpEng, aHlpSpa, .T.,,.T. )
AutoGrLog( "Atualizado o Help do campo " + "ZD4_MOTPRD" )

aHlpPor := {}
aAdd( aHlpPor, 'Descri��o do Motivo Perda' )

aHlpEng := {}
aAdd( aHlpEng, 'Descri��o do Motivo Perda' )

aHlpSpa := {}
aAdd( aHlpSpa, 'Descri��o do Motivo Perda' )

PutSX1Help( "PZD4_DSCPRD", aHlpPor, aHlpEng, aHlpSpa, .T.,,.T. )
AutoGrLog( "Atualizado o Help do campo " + "ZD4_DSCPRD" )

//
// Helps Tabela ZD5
//
aHlpPor := {}
aAdd( aHlpPor, 'Status' )

aHlpEng := {}
aAdd( aHlpEng, 'Status' )

aHlpSpa := {}
aAdd( aHlpSpa, 'Status' )

PutSX1Help( "PZD5_STATUS", aHlpPor, aHlpEng, aHlpSpa, .T.,,.T. )
AutoGrLog( "Atualizado o Help do campo " + "ZD5_STATUS" )

aHlpPor := {}
aAdd( aHlpPor, 'C�digo CRM' )

aHlpEng := {}
aAdd( aHlpEng, 'C�digo CRM' )

aHlpSpa := {}
aAdd( aHlpSpa, 'C�digo CRM' )

PutSX1Help( "PZD5_CODCRM", aHlpPor, aHlpEng, aHlpSpa, .T.,,.T. )
AutoGrLog( "Atualizado o Help do campo " + "ZD5_CODCRM" )

aHlpPor := {}
aAdd( aHlpPor, 'Descri��o da Atividade' )

aHlpEng := {}
aAdd( aHlpEng, 'Descri��o da Atividade' )

aHlpSpa := {}
aAdd( aHlpSpa, 'Descri��o da Atividade' )

PutSX1Help( "PZD5_DESCRI", aHlpPor, aHlpEng, aHlpSpa, .T.,,.T. )
AutoGrLog( "Atualizado o Help do campo " + "ZD5_DESCRI" )

aHlpPor := {}
aAdd( aHlpPor, 'Previs�o de In�cio' )

aHlpEng := {}
aAdd( aHlpEng, 'Previs�o de In�cio' )

aHlpSpa := {}
aAdd( aHlpSpa, 'Previs�o de In�cio' )

PutSX1Help( "PZD5_PRVINI", aHlpPor, aHlpEng, aHlpSpa, .T.,,.T. )
AutoGrLog( "Atualizado o Help do campo " + "ZD5_PRVINI" )

aHlpPor := {}
aAdd( aHlpPor, 'Data do In�cio' )

aHlpEng := {}
aAdd( aHlpEng, 'Data do In�cio' )

aHlpSpa := {}
aAdd( aHlpSpa, 'Data do In�cio' )

PutSX1Help( "PZD5_DTINI ", aHlpPor, aHlpEng, aHlpSpa, .T.,,.T. )
AutoGrLog( "Atualizado o Help do campo " + "ZD5_DTINI" )

aHlpPor := {}
aAdd( aHlpPor, 'Data Prevista Conclus�o' )

aHlpEng := {}
aAdd( aHlpEng, 'Data Prevista Conclus�o' )

aHlpSpa := {}
aAdd( aHlpSpa, 'Data Prevista Conclus�o' )

PutSX1Help( "PZD5_PRVFIM", aHlpPor, aHlpEng, aHlpSpa, .T.,,.T. )
AutoGrLog( "Atualizado o Help do campo " + "ZD5_PRVFIM" )

aHlpPor := {}
aAdd( aHlpPor, 'Data T�rmino' )

aHlpEng := {}
aAdd( aHlpEng, 'Data T�rmino' )

aHlpSpa := {}
aAdd( aHlpSpa, 'Data T�rmino' )

PutSX1Help( "PZD5_DTFIM ", aHlpPor, aHlpEng, aHlpSpa, .T.,,.T. )
AutoGrLog( "Atualizado o Help do campo " + "ZD5_DTFIM" )

aHlpPor := {}
aAdd( aHlpPor, 'Data do Cancelamento' )

aHlpEng := {}
aAdd( aHlpEng, 'Data do Cancelamento' )

aHlpSpa := {}
aAdd( aHlpSpa, 'Data do Cancelamento' )

PutSX1Help( "PZD5_DTCANC", aHlpPor, aHlpEng, aHlpSpa, .T.,,.T. )
AutoGrLog( "Atualizado o Help do campo " + "ZD5_DTCANC" )

aHlpPor := {}
aAdd( aHlpPor, 'Observa��es  da Atividade' )

aHlpEng := {}
aAdd( aHlpEng, 'Observa��es  da Atividade' )

aHlpSpa := {}
aAdd( aHlpSpa, 'Observa��es  da Atividade' )

PutSX1Help( "PZD5_OBSFIM", aHlpPor, aHlpEng, aHlpSpa, .T.,,.T. )
AutoGrLog( "Atualizado o Help do campo " + "ZD5_OBSFIM" )

aHlpPor := {}
aAdd( aHlpPor, 'Data da Inclus�o' )

aHlpEng := {}
aAdd( aHlpEng, 'Data da Inclus�o' )

aHlpSpa := {}
aAdd( aHlpSpa, 'Data da Inclus�o' )

PutSX1Help( "PZD5_DTINCL", aHlpPor, aHlpEng, aHlpSpa, .T.,,.T. )
AutoGrLog( "Atualizado o Help do campo " + "ZD5_DTINCL" )

aHlpPor := {}
aAdd( aHlpPor, 'Usu�rio Inclus�o' )

aHlpEng := {}
aAdd( aHlpEng, 'Usu�rio Inclus�o' )

aHlpSpa := {}
aAdd( aHlpSpa, 'Usu�rio Inclus�o' )

PutSX1Help( "PZD5_USRINC", aHlpPor, aHlpEng, aHlpSpa, .T.,,.T. )
AutoGrLog( "Atualizado o Help do campo " + "ZD5_USRINC" )

aHlpPor := {}
aAdd( aHlpPor, 'Data de Altera��o' )

aHlpEng := {}
aAdd( aHlpEng, 'Data de Altera��o' )

aHlpSpa := {}
aAdd( aHlpSpa, 'Data de Altera��o' )

PutSX1Help( "PZD5_DTALT ", aHlpPor, aHlpEng, aHlpSpa, .T.,,.T. )
AutoGrLog( "Atualizado o Help do campo " + "ZD5_DTALT" )

aHlpPor := {}
aAdd( aHlpPor, 'Usu�rio Altera��o' )

aHlpEng := {}
aAdd( aHlpEng, 'Usu�rio Altera��o' )

aHlpSpa := {}
aAdd( aHlpSpa, 'Usu�rio Altera��o' )

PutSX1Help( "PZD5_USRALT", aHlpPor, aHlpEng, aHlpSpa, .T.,,.T. )
AutoGrLog( "Atualizado o Help do campo " + "ZD5_USRALT" )

AutoGrLog( CRLF + "Final da Atualiza��o" + " " + "Helps de Campos" + CRLF + Replicate( "-", 128 ) + CRLF )

Return {}


//--------------------------------------------------------------------
/*/{Protheus.doc} EscEmpresa
Fun��o gen�rica para escolha de Empresa, montada pelo SM0

@return aRet Vetor contendo as sele��es feitas.
             Se n�o for marcada nenhuma o vetor volta vazio

@author Ernani Forastieri
@since  27/09/2004
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function EscEmpresa()

//---------------------------------------------
// Par�metro  nTipo
// 1 - Monta com Todas Empresas/Filiais
// 2 - Monta s� com Empresas
// 3 - Monta s� com Filiais de uma Empresa
//
// Par�metro  aMarcadas
// Vetor com Empresas/Filiais pr� marcadas
//
// Par�metro  cEmpSel
// Empresa que ser� usada para montar sele��o
//---------------------------------------------
Local   aRet      := {}
Local   aSalvAmb  := GetArea()
Local   aSalvSM0  := {}
Local   aVetor    := {}
Local   cMascEmp  := "??"
Local   cVar      := ""
Local   lChk      := .F.
Local   lOk       := .F.
Local   lTeveMarc := .F.
Local   oNo       := LoadBitmap( GetResources(), "LBNO" )
Local   oOk       := LoadBitmap( GetResources(), "LBOK" )
Local   oDlg, oChkMar, oLbx, oMascEmp, oSay
Local   oButDMar, oButInv, oButMarc, oButOk, oButCanc

Local   aMarcadas := {}


If !MyOpenSm0(.F.)
	Return aRet
EndIf


dbSelectArea( "SM0" )
aSalvSM0 := SM0->( GetArea() )
dbSetOrder( 1 )
dbGoTop()

While !SM0->( EOF() )

	If aScan( aVetor, {|x| x[2] == SM0->M0_CODIGO} ) == 0
		aAdd(  aVetor, { aScan( aMarcadas, {|x| x[1] == SM0->M0_CODIGO .and. x[2] == SM0->M0_CODFIL} ) > 0, SM0->M0_CODIGO, SM0->M0_CODFIL, SM0->M0_NOME, SM0->M0_FILIAL } )
	EndIf

	dbSkip()
End

RestArea( aSalvSM0 )

Define MSDialog  oDlg Title "" From 0, 0 To 280, 395 Pixel

oDlg:cToolTip := "Tela para M�ltiplas Sele��es de Empresas/Filiais"

oDlg:cTitle   := "Selecione a(s) Empresa(s) para Atualiza��o"

@ 10, 10 Listbox  oLbx Var  cVar Fields Header " ", " ", "Empresa" Size 178, 095 Of oDlg Pixel
oLbx:SetArray(  aVetor )
oLbx:bLine := {|| {IIf( aVetor[oLbx:nAt, 1], oOk, oNo ), ;
aVetor[oLbx:nAt, 2], ;
aVetor[oLbx:nAt, 4]}}
oLbx:BlDblClick := { || aVetor[oLbx:nAt, 1] := !aVetor[oLbx:nAt, 1], VerTodos( aVetor, @lChk, oChkMar ), oChkMar:Refresh(), oLbx:Refresh()}
oLbx:cToolTip   :=  oDlg:cTitle
oLbx:lHScroll   := .F. // NoScroll

@ 112, 10 CheckBox oChkMar Var  lChk Prompt "Todos" Message "Marca / Desmarca"+ CRLF + "Todos" Size 40, 007 Pixel Of oDlg;
on Click MarcaTodos( lChk, @aVetor, oLbx )

// Marca/Desmarca por mascara
@ 113, 51 Say   oSay Prompt "Empresa" Size  40, 08 Of oDlg Pixel
@ 112, 80 MSGet oMascEmp Var  cMascEmp Size  05, 05 Pixel Picture "@!"  Valid (  cMascEmp := StrTran( cMascEmp, " ", "?" ), oMascEmp:Refresh(), .T. ) ;
Message "M�scara Empresa ( ?? )"  Of oDlg
oSay:cToolTip := oMascEmp:cToolTip

@ 128, 10 Button oButInv    Prompt "&Inverter"  Size 32, 12 Pixel Action ( InvSelecao( @aVetor, oLbx ), VerTodos( aVetor, @lChk, oChkMar ) ) ;
Message "Inverter Sele��o" Of oDlg
oButInv:SetCss( CSSBOTAO )
@ 128, 50 Button oButMarc   Prompt "&Marcar"    Size 32, 12 Pixel Action ( MarcaMas( oLbx, aVetor, cMascEmp, .T. ), VerTodos( aVetor, @lChk, oChkMar ) ) ;
Message "Marcar usando" + CRLF + "m�scara ( ?? )"    Of oDlg
oButMarc:SetCss( CSSBOTAO )
@ 128, 80 Button oButDMar   Prompt "&Desmarcar" Size 32, 12 Pixel Action ( MarcaMas( oLbx, aVetor, cMascEmp, .F. ), VerTodos( aVetor, @lChk, oChkMar ) ) ;
Message "Desmarcar usando" + CRLF + "m�scara ( ?? )" Of oDlg
oButDMar:SetCss( CSSBOTAO )
@ 112, 157  Button oButOk   Prompt "Processar"  Size 32, 12 Pixel Action (  RetSelecao( @aRet, aVetor ), IIf( Len( aRet ) > 0, oDlg:End(), MsgStop( "Ao menos um grupo deve ser selecionado", "UPDCRM" ) ) ) ;
Message "Confirma a sele��o e efetua" + CRLF + "o processamento" Of oDlg
oButOk:SetCss( CSSBOTAO )
@ 128, 157  Button oButCanc Prompt "Cancelar"   Size 32, 12 Pixel Action ( IIf( lTeveMarc, aRet :=  aMarcadas, .T. ), oDlg:End() ) ;
Message "Cancela o processamento" + CRLF + "e abandona a aplica��o" Of oDlg
oButCanc:SetCss( CSSBOTAO )

Activate MSDialog  oDlg Center

RestArea( aSalvAmb )
dbSelectArea( "SM0" )
dbCloseArea()

Return  aRet


//--------------------------------------------------------------------
/*/{Protheus.doc} MarcaTodos
Fun��o auxiliar para marcar/desmarcar todos os �tens do ListBox ativo

@param lMarca  Cont�udo para marca .T./.F.
@param aVetor  Vetor do ListBox
@param oLbx    Objeto do ListBox

@author Ernani Forastieri
@since  27/09/2004
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function MarcaTodos( lMarca, aVetor, oLbx )
Local  nI := 0

For nI := 1 To Len( aVetor )
	aVetor[nI][1] := lMarca
Next nI

oLbx:Refresh()

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} InvSelecao
Fun��o auxiliar para inverter a sele��o do ListBox ativo

@param aVetor  Vetor do ListBox
@param oLbx    Objeto do ListBox

@author Ernani Forastieri
@since  27/09/2004
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function InvSelecao( aVetor, oLbx )
Local  nI := 0

For nI := 1 To Len( aVetor )
	aVetor[nI][1] := !aVetor[nI][1]
Next nI

oLbx:Refresh()

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} RetSelecao
Fun��o auxiliar que monta o retorno com as sele��es

@param aRet    Array que ter� o retorno das sele��es (� alterado internamente)
@param aVetor  Vetor do ListBox

@author Ernani Forastieri
@since  27/09/2004
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function RetSelecao( aRet, aVetor )
Local  nI    := 0

aRet := {}
For nI := 1 To Len( aVetor )
	If aVetor[nI][1]
		aAdd( aRet, { aVetor[nI][2] , aVetor[nI][3], aVetor[nI][2] +  aVetor[nI][3] } )
	EndIf
Next nI

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} MarcaMas
Fun��o para marcar/desmarcar usando m�scaras

@param oLbx     Objeto do ListBox
@param aVetor   Vetor do ListBox
@param cMascEmp Campo com a m�scara (???)
@param lMarDes  Marca a ser atribu�da .T./.F.

@author Ernani Forastieri
@since  27/09/2004
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function MarcaMas( oLbx, aVetor, cMascEmp, lMarDes )
Local cPos1 := SubStr( cMascEmp, 1, 1 )
Local cPos2 := SubStr( cMascEmp, 2, 1 )
Local nPos  := oLbx:nAt
Local nZ    := 0

For nZ := 1 To Len( aVetor )
	If cPos1 == "?" .or. SubStr( aVetor[nZ][2], 1, 1 ) == cPos1
		If cPos2 == "?" .or. SubStr( aVetor[nZ][2], 2, 1 ) == cPos2
			aVetor[nZ][1] := lMarDes
		EndIf
	EndIf
Next

oLbx:nAt := nPos
oLbx:Refresh()

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} VerTodos
Fun��o auxiliar para verificar se est�o todos marcados ou n�o

@param aVetor   Vetor do ListBox
@param lChk     Marca do CheckBox do marca todos (referncia)
@param oChkMar  Objeto de CheckBox do marca todos

@author Ernani Forastieri
@since  27/09/2004
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function VerTodos( aVetor, lChk, oChkMar )
Local lTTrue := .T.
Local nI     := 0

For nI := 1 To Len( aVetor )
	lTTrue := IIf( !aVetor[nI][1], .F., lTTrue )
Next nI

lChk := IIf( lTTrue, .T., .F. )
oChkMar:Refresh()

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} MyOpenSM0

Fun��o de processamento abertura do SM0 modo exclusivo

@author UPDATE gerado automaticamente
@since  01/10/2025
@obs    Gerado por EXPORDIC - V.8.0.1.0 EFS / Upd. V.6.4.1 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function MyOpenSM0( lShared )
Local lOpen := .F.
Local nLoop := 0

If FindFunction( "OpenSM0Excl" )
	For nLoop := 1 To 20
		If OpenSM0Excl(,.F.)
			lOpen := .T.
			Exit
		EndIf
		Sleep( 500 )
	Next nLoop
Else
	For nLoop := 1 To 20
		dbUseArea( .T., , "SIGAMAT.EMP", "SM0", lShared, .F. )

		If !Empty( Select( "SM0" ) )
			lOpen := .T.
			dbSetIndex( "SIGAMAT.IND" )
			Exit
		EndIf
		Sleep( 500 )
	Next nLoop
EndIf

If !lOpen
	MsgStop( "N�o foi poss�vel a abertura da tabela " + ;
	IIf( lShared, "de empresas (SM0).", "de empresas (SM0) de forma exclusiva." ), "ATEN��O" )
EndIf

Return lOpen


//--------------------------------------------------------------------
/*/{Protheus.doc} LeLog

Fun��o de leitura do LOG gerado com limitacao de string

@author UPDATE gerado automaticamente
@since  01/10/2025
@obs    Gerado por EXPORDIC - V.8.0.1.0 EFS / Upd. V.6.4.1 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function LeLog()
Local cRet  := ""
Local cFile := NomeAutoLog()
Local cAux  := ""

FT_FUSE( cFile )
FT_FGOTOP()

While !FT_FEOF()

	cAux := FT_FREADLN()

	If Len( cRet ) + Len( cAux ) < 1048000
		cRet += cAux + CRLF
	Else
		cRet += CRLF
		cRet += Replicate( "=" , 128 ) + CRLF
		cRet += "Tamanho de exibi��o maxima do LOG alcan�ado." + CRLF
		cRet += "LOG Completo no arquivo " + cFile + CRLF
		cRet += Replicate( "=" , 128 ) + CRLF
		Exit
	EndIf

	FT_FSKIP()
End

FT_FUSE()

Return cRet


/////////////////////////////////////////////////////////////////////////////
