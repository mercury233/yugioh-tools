FileEncoding, UTF-8

gui, add, Button, w50 h30 x10 y10 gStartCheck, 开始
gui, add, Text, w400 h30 x70 y10 vStatusTxt, 
gui, add, edit, w500 h500 x10 y50 vLogTxt, 
gui, show,, 脚本查错工具

return

GuiClose:
ExitApp
return

StartCheck:
;msgbox % RegExMatch("function s.cfilter(c,tp)", "^function s\..*\(((?!tp).)*\)$", Match)
;loop, Files, F:\Works\ignis-scripts\*.lua, R
;loop, Files, F:\Works\ygopro-pre-script\scripts\*.lua, R
loop, Files, F:\Works\ygopro-scripts\*.lua
{
	;msgbox % A_LoopFileFullPath
	FileRead, MyFileContents, % A_LoopFileFullPath
	SplitPath, % A_LoopFileFullPath,,,, filename
	status("当前卡片：" filename)
	StringTrimLeft , filename, filename, 1
	in_no_tp_func:=false
	Loop, parse, MyFileContents, `n, `r
	{
		If (RegExMatch(A_LoopField, "^function s\..*\(((?!tp).)*\)$", Match))
			in_no_tp_func := true
		If (RegExMatch(A_LoopField, "^function c\d+\..*\(((?!tp).)*\)$", Match))
			in_no_tp_func := true
		If (RegExMatch(A_LoopField, "^end\s*$", Match))
			in_no_tp_func := false
		If (RegExMatch(A_LoopField, "local tp", Match))
			in_no_tp_func := false
		If (RegExMatch(A_LoopField, "local .*tp.*=Duel.GetChainInfo", Match))
			in_no_tp_func := false
		If (RegExMatch(A_LoopField, "return.+function.*tp", Match))
			in_no_tp_func := false
		If (RegExMatch(A_LoopField, "^.*( |\t|\(|,|=)+function.*tp", Match))
			in_no_tp_func := false
		If (in_no_tp_func && RegExMatch(A_LoopField, "(\(|,|=|\-| )tp(,|\)| |$)", Match))
			log(filename " " A_Index " " A_LoopField)
		;log(A_LoopField " " in_no_tp_func)
	}
	;break
}
status("完成！")
return

log(text)
{
	GuiControlGet,t,,LogTxt
    GuiControl,,LogTxt,%t%%text%`n
}

status(text)
{
    GuiControl,,StatusTxt,%text%
}

