; 水星战士 2015/10/14

; 初始化--------------------------------------------------
;#SingleInstance Ignore
#NoTrayIcon
#Include <DBA> ;http://www.autohotkey.com/board/topic/71179-ahk-l-dba-16-oop-sql-database-sqlite-mysql-ado/
SetWorkingDir, %A_ScriptDir%
SetBatchLines, -1
SetControlDelay, -1

TYPE_MONSTER := 0x1
TYPE_SPELL := 0x2
TYPE_TRAP := 0x4
TYPE_NORMAL := 0x10
TYPE_EFFECT := 0x20
TYPE_FUSION := 0x40
TYPE_RITUAL := 0x80
TYPE_TRAPMONSTER := 0x100
TYPE_SPIRIT := 0x200
TYPE_UNION := 0x400
TYPE_DUAL := 0x800
TYPE_TUNER := 0x1000
TYPE_SYNCHRO := 0x2000
TYPE_TOKEN := 0x4000
TYPE_QUICKPLAY := 0x10000
TYPE_CONTINUOUS := 0x20000
TYPE_EQUIP := 0x40000
TYPE_FIELD := 0x80000
TYPE_COUNTER := 0x100000
TYPE_FLIP := 0x200000
TYPE_TOON := 0x400000
TYPE_XYZ := 0x800000
TYPE_PENDULUM := 0x1000000

ATTRIBUTE_EARTH := 0x01
ATTRIBUTE_WATER := 0x02
ATTRIBUTE_FIRE := 0x04
ATTRIBUTE_WIND := 0x08
ATTRIBUTE_LIGHT := 0x10
ATTRIBUTE_DARK := 0x20
ATTRIBUTE_DEVINE := 0x40

高级模式:=0
全部卡片:=Object()
符合条件的卡片:=Object()
被抽到的卡片:=Object()
禁卡列表:=Object()
限制卡列表:=Object()
准限制卡列表:=Object()

If A_IsCompiled
Menu, Tray, Icon, %A_ScriptFullPath%
Else
Menu, Tray, Icon, NBX卡组转core卡组.ahk_1.ico

IfNotExist, sqlite3.dll
{
	MsgBox, 16, 卡池生成器, 未找到sqlite3.dll。
	ExitApp
}

IfExist, %A_ScriptDir%\cards.cdb
{
	DBFILE := A_ScriptDir . "\cards.cdb"
}
else
{
	MsgBox, 16, 卡池生成器, 未找到数据库(cards.cdb)，请将本程序放到YGOPRO文件夹里！
	ExitApp
}

IfExist, %A_ScriptDir%\lflist.conf
{
	FileRead, lflist, %A_ScriptDir%\lflist.conf
	禁卡表数量:=0
	Loop, Parse, lflist, `r`n
	{
		if (RegExMatch(A_LoopField, "^!"))
		{
			禁卡表数量++
			if (禁卡表数量>=2)
			{
				break
			}
			continue
		}
		if (RegExMatch(A_LoopField, "^(\d+) 0 --.*", ID))
		{
			卡片ID := ID1 - 0
			禁卡列表.Push(卡片ID)
		}
		if (RegExMatch(A_LoopField, "^(\d+) 1 --.*", ID))
		{
			卡片ID := ID1 - 0
			限制卡列表.Push(卡片ID)
		}
		if (RegExMatch(A_LoopField, "^(\d+) 2 --.*", ID))
		{
			卡片ID := ID1 - 0
			准限制卡列表.Push(卡片ID)
		}
	}
}
else
{
	MsgBox, 48, 卡池生成器, 未找到禁卡表文件(lflist.conf)，禁卡表相关功能将无法正常使用。
}

gui, add, Text, x10 y12, 卡池量
gui, add, Edit, x50 y10 w40 h20 vListLength, 100
gui, add, button, x100 y5 w50 h30 gMakeList, 生成
gui, add, button, x160 y5 w50 h30 gSave, 保存
gui, add, edit, x10 y40 w200 h550 vList

gui, add, GroupBox, x220 y15 w160 h485, 卡片随机范围
gui, add, GroupBox, x230 y35 w140 h225, 　 　 　 ; space for 怪兽卡
gui, add, checkbox, x240 y35 w55 h16 Checked v选择怪兽卡, 怪兽卡
gui, add, checkbox, x240 y55 w40 h16 Checked v选择通常怪兽, 通常
gui, add, checkbox, x305 y55 w40 h16 Checked v选择效果怪兽, 效果
gui, add, checkbox, x240 y75 w40 h16 Checked v选择融合怪兽, 融合
gui, add, checkbox, x305 y75 w40 h16 Checked v选择仪式怪兽, 仪式
gui, add, checkbox, x240 y95 w40 h16 Checked v选择同调怪兽, 同调
gui, add, checkbox, x305 y95 w40 h16 Checked v选择超量怪兽, 超量
gui, add, checkbox, x240 y115 w16 h16 v选择等级
gui, add, edit, x260 y115 w20 h16 v输入等级最小值,1
gui, add, text, x290 y117 w10 h16 ,-
gui, add, edit, x305 y115 w20 h16 v输入等级最大值,12
gui, add, text, x335 y117 w20 h16 ,星
gui, add, checkbox, x240 y135 w16 h16 v选择刻度
gui, add, edit, x260 y135 w20 h16 v输入刻度最小值,1
gui, add, text, x290 y137 w10 h16 ,-
gui, add, edit, x305 y135 w20 h16 v输入刻度最大值,12
gui, add, text, x335 y137 w30 h16 ,刻度
gui, add, checkbox, x240 y155 w16 h16 v选择攻击
gui, add, edit, x260 y155 w30 h16 v输入攻击最小值,0
gui, add, text, x295 y157 w10 h16 ,-
gui, add, edit, x305 y155 w30 h16 v输入攻击最大值,9999
gui, add, text, x335 y157 w30 h16 ,攻击
gui, add, checkbox, x240 y175 w16 h16 v选择守备
gui, add, edit, x260 y175 w30 h16 v输入守备最小值,0
gui, add, text, x295 y177 w10 h16 ,-
gui, add, edit, x305 y175 w30 h16 v输入守备最大值,9999
gui, add, text, x335 y177 w30 h16 ,守备
gui, add, checkbox, x240 y195 w40 h16 v选择调整怪兽, 调整
选择调整怪兽_TT=限制必须拥有调整属性
gui, add, checkbox, x305 y195 w40 h16 v选择灵摆怪兽, 灵摆
选择灵摆怪兽_TT=限制必须拥有灵摆属性
gui, add, checkbox, x240 y215 w30 h16 Checked v选择地, 地
gui, add, checkbox, x272 y215 w30 h16 Checked v选择水, 水
gui, add, checkbox, x304 y215 w30 h16 Checked v选择炎, 炎
gui, add, checkbox, x240 y235 w30 h16 Checked v选择风, 风
gui, add, checkbox, x272 y235 w30 h16 Checked v选择光, 光
gui, add, checkbox, x304 y235 w30 h16 Checked v选择暗, 暗
gui, add, checkbox, x335 y235 w30 h16 Checked v选择神, 神

gui, add, GroupBox, x230 y265 w140 h85, 　 　 　 ; space for 魔法卡
gui, add, checkbox, x240 y265 w55 h16 Checked v选择魔法卡, 魔法卡
gui, add, checkbox, x240 y285 w40 h16 Checked v选择通常魔法, 通常
gui, add, checkbox, x305 y285 w40 h16 Checked v选择速攻魔法, 速攻
gui, add, checkbox, x240 y305 w40 h16 Checked v选择永续魔法, 永续
gui, add, checkbox, x305 y305 w40 h16 Checked v选择仪式魔法, 仪式
gui, add, checkbox, x240 y325 w40 h16 Checked v选择装备魔法, 装备
gui, add, checkbox, x305 y325 w40 h16 Checked v选择场地魔法, 场地

gui, add, GroupBox, x230 y355 w140 h65, 　 　 　 ; space for 陷阱卡
gui, add, checkbox, x240 y355 w55 h16 Checked v选择陷阱卡, 陷阱卡
gui, add, checkbox, x240 y375 w40 h16 Checked v选择通常陷阱, 通常
gui, add, checkbox, x305 y375 w40 h16 Checked v选择永续陷阱, 永续
gui, add, checkbox, x240 y395 w40 h16 Checked v选择反击陷阱, 反击

gui, add, GroupBox, x230 y425 w140 h65, 卡表
gui, add, checkbox, x240 y445 w60 h16 Checked v选择无限制, 无限制
gui, add, checkbox, x305 y445 w40 h16 v选择禁止, 禁止
gui, add, checkbox, x240 y465 w40 h16 Checked v选择限制, 限制
gui, add, checkbox, x305 y465 w60 h16 Checked v选择准限制, 准限制

gui, add, GroupBox, x220 y505 w160 h85, 设置
gui, add, Checkbox, x230 y525 h16 Checked vNoSameCard, 不允许重复卡片
NoSameCard_TT=同一个卡池内卡片不重复。
gui, add, Checkbox, x230 y545 h16 Checked vNoTCGCard, 排除TCG独有卡
gui, add, Checkbox, x230 y565 h16 vSaveAsYDK, 保存为ydk格式
SaveAsYDK_TT=保存为可以直接导入到YGOPRO的卡组格式。`n如不选此项，则使用便于阅读的文本格式。`n注意，若主卡组卡片超出60张或额外卡组卡片超出15张，YGOPRO不会读取超出的部分。
gui, add, button, x350 y520 w24 h63 vToggleWindow gToggleWindow, 高级
ToggleWindow_TT=点击打开/关闭隐藏功能。

gui, add, groupbox, x390 y15 w200 h110, 批量生成卡池
gui, add, text, x400 y37 w40 h16, 数量：
gui, add, edit, x440 y35 w30 h16 v输入批量生成数量, 50
gui, add, text, x400 y57 w40 h16, 存放：
gui, add, edit, x440 y55 w100 h16 v输入卡组存放目录, 
gui, add, button, x540 y53 w40 h20 gSelectDeckOutputFolder, 选择
gui, add, checkbox, x400 y80 h16 Checked vDelExistFile, 覆盖原有文件
DelExistFile_TT=如果对应文件夹里已有卡池，则删除它们。`n如不选此项，则会把新生成的卡池附加到原有卡池内，`n可以实现“给每个卡池40张怪兽卡，20张魔法卡，20张陷阱卡”的目的。
gui, add, checkbox, x400 y100 h16 vUseYDKFormat, 使用ydk格式
UseYDKFormat_TT=使用可以直接导入到YGOPRO的卡组格式。`n如不选此项，则使用便于阅读的文本格式。`n注意，若主卡组卡片超出60张或额外卡组超出15张，YGOPRO不会读取超出的部分。
gui, add, button, x530 y85 w50 h30 gBatchMakeList, 生成

gui, add, GroupBox, x390 y135 w200 h475, 抽包模式
gui, add, Edit, x400 y152 w20 h20 v包数, 5
gui, add, Text, x425 y155, 包，每包张数
gui, add, Edit, x500 y152 w20 h20 v张数, 5
gui, add, Button, x530 y145 w50 h30 gDrawPack, 抽
gui, add, edit, x400 y180 w180 h400 vPackCardList,[娱乐伙伴 副手驴]`r`n[娱乐伙伴 洒水猛犸]`r`n[娱乐伙伴 帮助公主]`r`n[超重武者 盗人-10]`r`n[超重武者 飞脚-Q]`r`n[超重武者 鼓-3]`r`n[超重武者装留 双角]`r`n[超重武者装留 光爪]`r`n[毛绒动物之翼]`r`n[DD 巴风特]`r`n[DD 螺涡史莱姆]`r`n[DD 死灵史莱姆]`r`n[急袭猛禽-荒野秃鹫]`r`n[急袭猛禽-骷髅雕]`r`n[娱乐法师 镜子指挥]`r`n[娱乐法师 火布偶]`r`n[传说的渔人三世]`r`n[强袭黑羽-雾雨之苦无鸟]`r`n[疾走的暗黑骑士 盖亚]`r`n[球形栗子球]`r`n[超战士之魂]`r`n[开辟之骑士]`r`n[宵暗之骑士]`r`n[龙魔王 魔道矢·灵摆]`r`n[威风妖怪·猫]`r`n[威风妖怪·狸]`r`n[威风妖怪·乌]`r`n[威风妖怪·狐]`r`n[威风妖怪·麒麟]`r`n[点火骑士·德林加]`r`n[点火骑士·乌兹]`r`n[灰篮史莱姆]`r`n[灰篮短吻鳄]`r`n[灰篮眼镜蛇]`r`n[灰篮鹰]`r`n[熟练的赤魔术士]`r`n[龙宫的双使者]`r`n[卡通左轮手枪龙]`r`n[文具电子人006]`r`n[禁忌之壶]`r`n[科学快人博士]`r`n[超战士 混沌战士]`r`n[魔玩具·军刀剑齿虎]`r`n[DDD 怒涛坏薙王 恺撒末日神]`r`n[异色眼风雷龙]`r`n[红莲魔龙·右红痕]`r`n[强袭黑羽-骤雨之雷切鸟]`r`n[灰篮龙]`r`n[文具电子人喷气机]`r`n[DDD 双晓王 末法神]`r`n[急袭猛禽-恶魔雕]`r`n[升龙剑士 威风星·圣骑]`r`n[洗牌苏生]`r`n[升阶魔法-急袭之力]`r`n[猛禽究极硬头锤]`r`n[超战士的仪式]`r`n[混沌场]`r`n[威风阵·飞马]`r`n[威风妖怪风暴]`r`n[威风妖怪旋风]`r`n[点火骑士上膛]`r`n[灰篮撞击]`r`n[异色眼融合]`r`n[念力宝剑]`r`n[苦涩的决断]`r`n[猪突猛进]`r`n[魔玩具行进]`r`n[DDD的契约变更]`r`n[误封的契约书]`r`n[转生的超战士]`r`n[超战士之盾]`r`n[威风妖怪龙卷]`r`n[威风妖怪大暴风]`r`n[灰篮寄生体]`r`n[灰篮分裂]`r`n[业炎防护罩 -火焰之力-]`r`n[灵摆区]`r`n[紧急仪式术]`r`n[升天之刚角笛]`r`n[救护部队]`r`n[武神-蛭子]`r`n[芙莉西亚之虫惑魔]`r`n[森罗的姬芽宫]`r`n[古遗物-金刚杵]`r`n[音响战士 麦克风]`r`n
gui, add, checkbox, x400 y585 h16 Checked vKeepPackFixed, 卡堆保持不变
KeepPackFixed_TT=即使某张卡被抽走了，卡堆仍然保留此卡。`n如不选此项，则卡片被抽走后从卡堆移除，`n可以实现“模拟真实开盒，稀有卡被别人抽走了就没了”的目的。

gui, add, Progress, x10 w370 y595 vProgressBar -Smooth
gui, show, w390 h620, 正在读取数据库...
OnMessage(0x200, "WM_MOUSEMOVE")

gui, +Disabled
gosub, LoadDataBase

gui, -Disabled
gui, show, w390 h620, 卡池生成器 1.2

return

GuiClose:
ExitApp
return

return

WM_MOUSEMOVE()
{
	gui, +OwnDialogs
    static CurrControl, PrevControl, _TT  ; _TT is kept blank for use by the ToolTip command below.
    CurrControl := A_GuiControl
    If (CurrControl <> PrevControl and not InStr(CurrControl, " "))
    {
        ToolTip  ; Turn off any previous tooltip.
        SetTimer, DisplayToolTip, 300
        PrevControl := CurrControl
    }
    return

    DisplayToolTip:
    SetTimer, DisplayToolTip, Off
    ToolTip % %CurrControl%_TT  ; The leading percent sign tell it to use an expression.
    SetTimer, RemoveToolTip, 5000
    return

    RemoveToolTip:
    SetTimer, RemoveToolTip, Off
    ToolTip
    return
}

ToggleWindow:
if (高级模式)
{
	gui, show, w390 h620
	高级模式:=0
}
else
{
	gui, show, w600 h620
	高级模式:=1
}
return

SelectDeckOutputFolder:
FileSelectFolder, DeckOutputFolder, , ,请选择要存放卡池的文件夹。
if (!ErrorLevel)
{
	GuiControl,,输入卡组存放目录, % DeckOutputFolder
}
return

LoadDataBase:
DB := DBA.DataBaseFactory.OpenDataBase("SQLite", DBFILE)

SQL := "Select count(*) from datas"
RS := DB.Query(SQL)
卡片总数 := RS.Rows[1]["count(*)"]
GuiControl, +Range1-%卡片总数% , ProgressBar
GuiControl, , ProgressBar, 1
RS.Close()

SQL := "select * from datas,texts where datas.id=texts.id"
TABLE := DB.Query(SQL)
for each, RS in TABLE.Rows
{   
	if (RS["alias"]==0 && !(RS["type"] & TYPE_TOKEN))
	{
		当前卡片 := Object()
		当前卡片["id"] := RS["id"]
		当前卡片["name"] := RS["name"]
		当前卡片["ot"] := RS["ot"]
		当前卡片["type"] := RS["type"]
		当前卡片["atk"] := RS["atk"]
		当前卡片["def"] := RS["def"]
		当前卡片["attribute"] := RS["attribute"]
		
		level := RS["level"]
		if (level<=12)
		{
			当前卡片["level"] := level
			当前卡片["scale"] := 0
		}
		else 
		{
			; 先转成16进制，截取字符串，再转回来
			SetFormat, Integer, HEX
			level+=0
			StringRight, intlevel, level, 4
			StringRight, intscale, level, 6
			StringLeft, intscale, intscale, 2
			intscale=0x%intscale%
			SetFormat, Integer, D
			intlevel+=0
			intscale+=0
			当前卡片["level"] := intlevel
			当前卡片["scale"] := intscale
		}
		全部卡片.Push(当前卡片)
	}
	GuiControl, ,ProgressBar, +1
}
TABLE := ""
RS := ""
DB := ""
return

FliterCard:
gui, submit, nohide

卡片总数:=全部卡片.Length()
GuiControl, +Range1-%卡片总数% , ProgressBar
GuiControl, , ProgressBar, 0

符合条件的卡片 := Object()

for each, 当前卡片 in 全部卡片
{
	符合条件:=0
	; 233==233 is just for line break
	if (选择怪兽卡 && (当前卡片["type"] & TYPE_MONSTER)
	&& ( 233==233
		&& ( 233==0 
			|| (选择通常怪兽 && (当前卡片["type"] & TYPE_NORMAL) && !(当前卡片["type"] & TYPE_FUSION) && !(当前卡片["type"] & TYPE_RITUAL) && !(当前卡片["type"] & TYPE_SYNCHRO) && !(当前卡片["type"] & TYPE_XYZ))
			|| (选择效果怪兽 && (当前卡片["type"] & TYPE_EFFECT) && !(当前卡片["type"] & TYPE_FUSION) && !(当前卡片["type"] & TYPE_RITUAL) && !(当前卡片["type"] & TYPE_SYNCHRO) && !(当前卡片["type"] & TYPE_XYZ))
			|| (选择融合怪兽 && (当前卡片["type"] & TYPE_FUSION))
			|| (选择仪式怪兽 && (当前卡片["type"] & TYPE_RITUAL))
			|| (选择同调怪兽 && (当前卡片["type"] & TYPE_SYNCHRO))
			|| (选择超量怪兽 && (当前卡片["type"] & TYPE_XYZ))
			&& 233==233)
		&& (!选择等级 || ((当前卡片["level"] >= 输入等级最小值) && (当前卡片["level"] <= 输入等级最大值)))
		&& (!选择刻度 || ((当前卡片["scale"] >= 输入刻度最小值) && (当前卡片["scale"] <= 输入刻度最大值)))
		&& (!选择攻击 || ((当前卡片["atk"] >= 输入攻击最小值) && (当前卡片["atk"] <= 输入攻击最大值)))
		&& (!选择守备 || ((当前卡片["def"] >= 输入守备最小值) && (当前卡片["def"] <= 输入守备最大值)))
		&& ( 233==233 
			&& (!选择调整怪兽 || (当前卡片["type"] & TYPE_TUNER))
			&& (!选择灵摆怪兽 || (当前卡片["type"] & TYPE_PENDULUM))
			&& 233==233)
		&& ( 233==0 
			|| (选择地 && (当前卡片["attribute"] & ATTRIBUTE_EARTH))
			|| (选择水 && (当前卡片["attribute"] & ATTRIBUTE_WATER))
			|| (选择炎 && (当前卡片["attribute"] & ATTRIBUTE_FIRE))
			|| (选择风 && (当前卡片["attribute"] & ATTRIBUTE_WIND))
			|| (选择光 && (当前卡片["attribute"] & ATTRIBUTE_LIGHT))
			|| (选择暗 && (当前卡片["attribute"] & ATTRIBUTE_DARK))
			|| (选择神 && (当前卡片["attribute"] & ATTRIBUTE_DEVINE))
			&& 233==233)
	&& 233==233) )
	{
		符合条件:=1
	}
	else if (选择魔法卡 && (当前卡片["type"] & TYPE_SPELL)
	&& ( 233==0
		|| (选择通常魔法 && (当前卡片["type"] == TYPE_SPELL))
		|| (选择速攻魔法 && (当前卡片["type"] & TYPE_QUICKPLAY))
		|| (选择永续魔法 && (当前卡片["type"] & TYPE_CONTINUOUS))
		|| (选择仪式魔法 && (当前卡片["type"] & TYPE_RITUAL))
		|| (选择装备魔法 && (当前卡片["type"] & TYPE_EQUIP))
		|| (选择场地魔法 && (当前卡片["type"] & TYPE_FIELD))
		&& 233==233) )
	{
		符合条件:=1
	}
	else if (选择陷阱卡 && (当前卡片["type"] & TYPE_TRAP)
	&& ( 233==0
		|| (选择通常陷阱 && (当前卡片["type"] == TYPE_TRAP))
		|| (选择永续陷阱 && (当前卡片["type"] & TYPE_CONTINUOUS))
		|| (选择反击陷阱 && (当前卡片["type"] & TYPE_COUNTER))
		&& 233==233) )
	{
		符合条件:=1
	}
	
	if (NoTCGCard && (当前卡片["ot"] == 2))
	{
		符合条件:=0
	}
	
	if (符合条件)
	{
		符合条件:=选择无限制
		
		for i, in 禁卡列表
		{
			if (当前卡片["id"]==禁卡列表[i])
			{
				符合条件:=选择禁止
			}
		}
		for i, in 限制卡列表
		{
			if (当前卡片["id"]==限制卡列表[i])
			{
				符合条件:=选择限制
			}
		}
		for i, in 准限制卡列表
		{
			if (当前卡片["id"]==准限制卡列表[i])
			{
				符合条件:=选择准限制
			}
		}
	}

	if (符合条件)
	{
		符合条件的卡片.Push(当前卡片)
	}
	
	guicontrol, , ProgressBar, % A_Index
}
return

MakeList:
Gui, +OwnDialogs
gui, submit, nohide
GuiControl, , List,
GuiControl, +Range1-%ListLength% , ProgressBar
GuiControl, , ProgressBar, 0

gosub, FliterCard

if (符合条件的卡片.Length()==0) 
{
	MsgBox, 48, 卡池生成器, 没有符合条件的卡！
	return
}
被抽到的卡片 := RandomSelect(符合条件的卡片,ListLength,NoSameCard)
卡片列表文本 := MakeText(被抽到的卡片)

GuiControl,,List, % 卡片列表文本
return

BatchMakeList:
Gui, +OwnDialogs
gui, submit, nohide

while (!InStr(FileExist(输入卡组存放目录), "D") && !ErrorLevel)
{
	gosub, SelectDeckOutputFolder
	gui, submit, nohide
}
if (ErrorLevel)
{
	return
}
if (输入批量生成数量<=0 || 输入批量生成数量>=999)
{
	MsgBox, 48, 卡池生成器, 最多支持同时生成999个卡池。
	return
}

gosub, FliterCard

GuiControl, +Range1-%输入批量生成数量% , ProgressBar
GuiControl, , ProgressBar, 0

if (符合条件的卡片.Length()==0) 
{
	MsgBox, 48, 卡池生成器, 没有符合条件的卡！
	return
}

Loop, % 输入批量生成数量
{
	被抽到的卡片 := RandomSelect(符合条件的卡片,ListLength,NoSameCard)
	卡池文本 := UseYDKFormat ? MakeYDK(被抽到的卡片) : MakeText(被抽到的卡片)
	
	卡池文件名:=A_Index
	if (输入批量生成数量>=100 && A_Index<100)
	{
		卡池文件名 := "0" . 卡池文件名
	}
	if (输入批量生成数量>=10 && A_Index<10)
	{
		卡池文件名 := "0" . 卡池文件名
	}
	卡池文件名 := UseYDKFormat ? 卡池文件名 . ".ydk" : 卡池文件名 . ".txt"
	当前卡池文件=%输入卡组存放目录%\%卡池文件名%
	

	if (DelExistFile)
	{
		FileDelete, % 当前卡池文件
	}
		
	FileAppend, % 卡池文本, % 当前卡池文件
	guicontrol, , ProgressBar, % A_Index
}
return

RandomSelect(ByRef 卡池,数量,不重复=0,还原卡池=1)
{
	临时存放 := Object()
	Loop, % 数量
	{
		Random, id, 1, 卡池.Length()
		if (不重复)
		{
			当前卡片:=卡池.RemoveAt(id)
			临时存放.Push(当前卡片)
			if (卡池.Length()<=0)
			{
				break
			}
		}
		else 
		{
			临时存放.Push(卡池[id])
		}
	}
	if (不重复 && 还原卡池)
	{
		卡池.Push(临时存放*)
	}
	return % 临时存放
}

MakeText(卡片列表)
{
	卡片列表文本=
	for each, 当前卡片 in 卡片列表
	{
		卡片列表文本 := 卡片列表文本 . "[" . 当前卡片["name"] . "]`r`n"
	}
	return 卡片列表文本
}

MakeYDK(卡片列表)
{
	卡片列表文本=#created by ...`r`n
	for each, 当前卡片 in 卡片列表
	{
		卡片列表文本 := 卡片列表文本 . "" . 当前卡片["id"] . "`r`n"
	}
	return 卡片列表文本
}

Save:
Gui, +OwnDialogs
gui, submit, nohide
if (SaveAsYDK)
{
	FileSelectFile, FileName, S16, ,保存卡池 , 卡组文件 (*.ydk) 
	if(!ErrorLevel)
	{
		IfNotInString, FileName, .ydk
		{
			FileName=%FileName%.ydk
		}
		FileDelete, %FileName%
		
		Deck:=MakeYDK(被抽到的卡片)
		
		FileAppend, % Deck, %FileName%
	}
}
else
{
	FileSelectFile, FileName, S16, ,保存卡池 , 文本文件 (*.txt) 
	if(!ErrorLevel)
	{
		IfNotInString, FileName, .txt
		{
			FileName=%FileName%.txt
		}
		FileDelete, %FileName%
		
		FileAppend, % List, %FileName%
	}
}
return

DrawPack:
gui, submit, nohide
卡堆:=Object()
Loop, Parse, PackCardList, `r`n
{
	if (A_LoopField=="")
	{
		continue
	}
	卡堆[A_Index]:=A_LoopField
}
全部卡包文本=
Loop, %包数%
{
	当前卡包文本=-------------------------`r`n第%A_Index%包：`r`n-------------------------`r`n

	当前卡包:=RandomSelect(卡堆,张数,!KeepPackFixed,KeepPackFixed)
	for each, 卡片 in 当前卡包
	{
		当前卡包文本=%当前卡包文本%%卡片%`r`n
	}

	全部卡包文本=%全部卡包文本%%当前卡包文本%
}
GuiControl,,List, % 全部卡包文本
if (!KeepPackFixed)
{
	卡堆文本=
	for each, 卡片 in 卡堆
	{
		if (卡片=="")
		{
			continue
		}
		卡堆文本=%卡堆文本%%卡片%`r`n
	}
	GuiControl,, PackCardList, % 卡堆文本
}
return
