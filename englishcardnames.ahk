MsgBox Use this script after editing pathes...
return

#Include <DBA> ;http://www.autohotkey.com/board/topic/71179-ahk-l-dba-16-oop-sql-database-sqlite-mysql-ado/
SetWorkingDir, %A_ScriptDir%
SetBatchLines, -1
SetControlDelay, -1
FileEncoding, UTF-8-RAW

DB := DBA.DataBaseFactory.OpenDataBase("SQLite", "0-en-OCGTCG.cdb")



loop, Files, F:\Works\ygopro-scripts\*.lua
{
	FileRead, FileContent, % A_LoopFileFullPath
	SplitPath, % A_LoopFileFullPath,,,, filename
	StringTrimLeft , cardid, filename, 1
	cardname:=0
	if ( not cardid*1>0 )
		continue
	SQL := "select id,name from texts where id=" . cardid
	TABLE := DB.Query(SQL)
	for each, RS in TABLE.Rows
	{   
		cardname := RS["name"]
	}
	if (cardname)
	{
		;ToolTip % cardname
		NewContent := RegExReplace(FileContent, "`n)(\-\-.*)", "$1`n--" . cardname,,1)
		FileDelete, % A_LoopFileFullPath
		FileAppend,% NewContent, *%A_LoopFileFullPath%
	}
	else
	{
		MsgBox Name not found for %cardid%
	}
}
