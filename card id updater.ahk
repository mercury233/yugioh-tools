;#NoTrayIcon
#Include <DBA>
SetBatchLines, -1
SetControlDelay, -1
FileEncoding, UTF-8-RAW

If A_IsCompiled
Menu, Tray, Icon, %A_ScriptFullPath%
Else
Menu, Tray, Icon, %A_ScriptDir%\NBX卡组转core卡组.ahk_1.ico

IfNotExist, sqlite3.dll
{
	MsgBox, 16, ID转换工具, 未找到sqlite3.dll。
	ExitApp
}

OldIds :=
NewIds :=

gui, add, combobox, x10 y15 w460 h20 vScriptsDir r5 Choose1, F:\Works\ygopro-pre-script\scripts|F:\Works\ignis-scripts
gui, add, Button, w40 h30 x480 y10 gUpdateScripts, 开始
gui, add, combobox, x10 y50 w460 h20 vDataBaseFile r5 Choose2, F:\Works\ygopro-pre-data\expansions\pre-release.cdb|F:\Works\db-yugioh-card-com\output\OmegaDB.cdb
gui, add, Button, w40 h30 x480 y45 gUpdateDataBase, 开始
gui, add, edit, w250 h500 x10 y90 vOldIdsEdit,
gui, add, edit, w250 h500 x270 y90 vNewIdsEdit,
gui, add, text, w500 h20 x10 y600 vStatusTxt, 咕
gui, add, button, w40 h20 x240 y70 gSwapIds, 交换
gui, show,, ID转换工具

return

GuiClose:
ExitApp
return

UpdateVars:
gui, submit, nohide
OldIds := StrSplit(OldIdsEdit, "`n", " `t`r")
NewIds := StrSplit(NewIdsEdit, "`n", " `t`r")
return

SwapIds:
gui, submit, nohide
GuiControl,,OldIdsEdit, % NewIdsEdit
GuiControl,,NewIdsEdit, % OldIdsEdit
return

ReplaceIDs(content)
{
	global
	loop, % OldIds.Length()
	{
		content := RegExReplace(content, OldIds[A_Index], NewIds[A_Index])
	}
	return content
}


UpdateScripts:
gosub, UpdateVars
if (OldIds.Length() != NewIds.Length())
{
	MsgBox 长度不一致！
	return
}
SetWorkingDir, % ScriptsDir

loop, Files, *.lua, R
{
	FileRead, FileContent, % A_LoopFileFullPath
	SplitPath, % A_LoopFileFullPath,,,, filename
	StringTrimLeft, cardid, filename, 1
	status(cardid)
	if ( not cardid*1>0 )
		continue
	NewContent := ReplaceIDs(FileContent)
	FileDelete, % A_LoopFileFullPath
	FileAppend,% NewContent, *%A_LoopFileFullPath%
}

loop, Files, *, DR
{
	status(A_LoopFileFullPath)
	loop, % OldIds.Length()
	{
		oldcode:=OldIds[A_Index]
		newcode:=NewIds[A_Index]
		FileMove, %A_LoopFileFullPath%\c%oldcode%.lua, %A_LoopFileFullPath%\c%newcode%.lua
	}
}
status("完成！")
return

UpdateDataBase:
gosub, UpdateVars
if (OldIds.Length() != NewIds.Length())
{
	MsgBox 长度不一致！
	return
}

DB := DBA.DataBaseFactory.OpenDataBase("SQLite", DataBaseFile)
DB.Query("PRAGMA foreign_keys = OFF;")
DB.BeginTransaction()
loop, % OldIds.Length()
{
	oldcode:=OldIds[A_Index]
	newcode:=NewIds[A_Index]
	status(oldcode)
	sql = update datas set id = %newcode% where id = %oldcode%`; update texts set id = %newcode% where id = %oldcode%`;
	DB.Query(sql)
}
DB.EndTransaction()

DB := ""
status("完成！")
return

status(text)
{
    GuiControl,,StatusTxt,%text%
}
