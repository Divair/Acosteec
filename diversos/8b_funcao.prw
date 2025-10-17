//Bibliotecas
#Include "Protheus.ch"

user function ob_func()
local aFuncao 	:= {}     // Para retornar a origem da fun��o: FULL, USER, PARTNER, PATCH, TEMPLATE ou NONE
	Local aType		:= {}     // Para retornar o nome do arquivo onde foi declarada a fun��o
	Local aFile		:= {}     // Para retornar o n�mero da linha no arquivo onde foi declarada a fun��o
	Local aLine		:= {}     // Para retornar o n�mero da linha no arquivo onde foi declarada a fun��o
	Local aDate		:= {}     // Para retornar a data da �ltima modifica��o do c�digo fonte compilado
	Local aTime		:= {}     // Para retornar a hora da �ltima modifica��o do c�digo fonte compilado

	aFuncao := GetFuncArray("U_ob_func", aType, aFile, aLine, aDate, aTime)
	If Len(aDate) > 0
		_cObs := "Fun��o: "+Alltrim(aFuncao[1])+"."+chr(10)+Chr(13)+;
			"Data fonte: "+dtoc(aDate[1])+"."+chr(10)+Chr(13)+;
			"Hora fonte: "+aTime[1]+"."
		FWAlertSuccess(_cObs, "Dados da rotina")
	EndIf
return
