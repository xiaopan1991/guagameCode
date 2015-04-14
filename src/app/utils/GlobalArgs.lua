--公共的类型定义
TouchEventType = 
{
	began    = 0,
	moved    = 1,
	ended    = 2,
	canceled = 3,
}

--复选框类型
CheckBoxEventType = 
{
    selected = 0,
    unselected = 1,
}


--门派类型
PlayerType = 
{
	"武当",
	"丐帮",
	"峨眉",
}

--道具类型
GoodsType = {
	hammer = "hammer",	--锤子
	gem = "gem",		--宝石
	pith = "pith", 		--强化精华
}

--武器，衣服，马，护腿，腰带，鞋，戒指，护手，头，饰品
--道具部位
EquipPosType = {
	WEAPON		= 0,		--武器
	CLOTHES 	= 1,		--衣服
	HORSE 		= 2,		--马
	LEG       	= 3,		--护腿
	BELT       	= 4,		--腰带
	SHOES      	= 5,  		--鞋
	RING      	= 6,		--戒指
	HADN       	= 7,		--护手
	HEAD       	= 8,		--头
	NECK       	= 9,		--饰品
}

EquipPosName = {
	["0"] = "武器",	--武器
	["1"] = "衣服",	--衣服
	["2"] = "马",		--马
	["3"] = "护腿",	--护腿
	["4"] = "腰带",	--腰带
	["5"] = "鞋子",  	--鞋
	["6"] = "戒指",	--戒指
	["7"] = "护手",	--护手
	["8"] = "头部",	--头
	["9"] = "饰品",	--饰品
}

--装备品质
EquipQuality = {
	WHITE  = 0,		--白色
	GREEN  = 1,		--绿色
	BLUE   = 2,		--蓝色
	PURPLE = 3,		--紫色
	ORANGE = 4,		--橙色
	RED    = 5 		--红色
}
--装备颜色
--白色
EQUIP_WHITE 	= cc.c3b(171,171,171)
--绿色
EQUIP_GREEN 	= cc.c3b(28,126,5)
--蓝色
EQUIP_BLUE  	= cc.c3b(1,144,254)
--紫色
EQUIP_PURPLE 	= cc.c3b(209,47,255)
--橙色
EQUIP_ORANGE 	= cc.c3b(161,99,9)
--灰色
EQUIP_GRAY 		= cc.c3b(171,171,171)

--游戏所用字体颜色
COLOR_YELLOW = cc.c3b(161,99,9)
COLOR_WHITE = cc.c3b(255,255,255)
COLOR_BLUE = cc.c3b(1,144,254)
COLOR_RED = cc.c3b(255,53,53)
COLOR_GREEN = cc.c3b(28,126,5)




function getEquipCCC3Color(color)
	local tempColors = {EQUIP_WHITE,EQUIP_GREEN,EQUIP_BLUE,EQUIP_PURPLE,EQUIP_ORANGE}
	if(color >= 0 and color < #tempColors) then
		return tempColors[color+1]
	end
end
function getEquipColor(color)
	local tempColors = {{171,171,171},{68,220,33},{1,144,254},{209,47,255},{255,205,30}}
	if(color >= 0 and color < #tempColors) then
		return tempColors[color+1]
	end
end

--根据属性英文 获取中文
function getAttrName(attr)
	if attr == "strr" then
		return "strr","力道"
	elseif attr == "agi" then
		return "agi","身法"
	elseif attr == "intt" then
		return "intt","内劲"
	elseif attr == "sta" then
		return "sta","体质"
	elseif attr == "hp" then
		return "hp","气血"
	elseif attr == "mp" then
		return "mp","内力"
	elseif attr == "dam" then
		return "dam","伤害"
	elseif attr == "arm" then
		return "arm","筋骨"
	elseif attr == "deff" then
		return "deff","外防"
	elseif attr == "adf" then
		return "adf","内防"
	elseif attr == "cri" then
		return "cri","会心"
	elseif attr == "crd" then
		return "crd","会心一击伤害"
	elseif attr == "hit" then
		return "hit","命中"
	elseif attr == "dod" then
		return "dod","闪避"
	elseif attr == "res" then
		return "res","招架"
	elseif attr == "mps" then
		return "mps","回复内力"
	elseif attr == "cri_rate" then
		return "cri_rate","会心率"
	elseif attr == "minDmg" then
		return "minDmg","最小伤害"
	elseif attr == "maxDmg" then
		return "maxDmg","最大伤害"
	end
end

-- ID 规则
-- E代表装备
-- 第一位为所属职业[0~4]
-- 第二位为该装备的位置[0~9]
-- 第3,4,5位为等级 例如：030 为30级装备
-- 最后一位为品阶，同一个等级有多阶
-- 所属职业[0~4] [0~9位置][001~995等级] [0~5品级]
