--字符串库
COMMON_FONT_SIZE = 18
BATTLE_FONT_SIZE = 20
CHAT_FONT_SIZE = 20
local StrLib ={
	--战斗使用
	["s1"] = {{"%s释放了%s技能,",{255,255,255},BATTLE_FONT_SIZE,DEFAULT_FONT},{"对%s造成%s点伤害",{255,255,255},BATTLE_FONT_SIZE,DEFAULT_FONT }},
	["s2"] = {{"%s释放了%s技能,",{255,255,255},BATTLE_FONT_SIZE,DEFAULT_FONT},{"%s属性增强%s点",{255,0,0},BATTLE_FONT_SIZE,DEFAULT_FONT }},

	["s4"] = {{"战斗胜利！%s",{68,220,33},BATTLE_FONT_SIZE,DEFAULT_FONT}},
	["s5"] = {{"获得经验%s",{209,47,255},BATTLE_FONT_SIZE,DEFAULT_FONT}},
	["s6"] = {{"获得银两%s",{209,47,255},BATTLE_FONT_SIZE,DEFAULT_FONT}},
	["s7"] = {{"                   %s",{0,0,0},BATTLE_FONT_SIZE,DEFAULT_FONT}},
	["s8"] = {{"正在恢复休息中,并搜索敌人与计算奖励...%s",{0,0,0},BATTLE_FONT_SIZE,DEFAULT_FONT}},
	["s9"] = {{"您遇到了LV.%s%s(HP:%s)",{0,0,0},BATTLE_FONT_SIZE,DEFAULT_FONT}},
	["s10"] = {{"获得%s",{0,0,0},BATTLE_FONT_SIZE,DEFAULT_FONT}},
	["s11"] = {{"战斗失败！%s",{220,0,0},BATTLE_FONT_SIZE,DEFAULT_FONT}},
	["s12"] = {{"BOSS战即将开始！%s",{255,0,0},BATTLE_FONT_SIZE,DEFAULT_FONT}},
	["s13"] = {{"BOSS战结束！即将转入下一场战斗%s",{255,0,0},BATTLE_FONT_SIZE,DEFAULT_FONT}},
	["s14"] = {{"自动卖出装备%s，获得银两%s",{0,0,0},BATTLE_FONT_SIZE,DEFAULT_FONT}},
	--聊天使用
	["s19"] = {{"%s",{255,255,255},CHAT_FONT_SIZE,DEFAULT_FONT}},
	["s20"] = {{"%s%s：%s%s",{255,255,255},CHAT_FONT_SIZE,DEFAULT_FONT}},
	--战斗使用
	["s21"] = {{"竞技战即将开始！%s",{255,0,0},BATTLE_FONT_SIZE,DEFAULT_FONT}},
	["s22"] = {{"竞技战结束！即将转入下一场战斗%s",{255,0,0},BATTLE_FONT_SIZE,DEFAULT_FONT}},
	--邮件使用
	["s23"] = {{"%s",{255,255,255},COMMON_FONT_SIZE,DEFAULT_FONT}},
	--战斗使用
	["s24"] = {{"获得%s",{0,0,0},BATTLE_FONT_SIZE,DEFAULT_FONT}},
	--有伤害，玩家一伙打对方，xx使用xx对xx造成xx点伤害(会心)
	--战斗日志
	--[[
	玩家一伙名字颜色:
	回合颜色：255,100,0
	]]
	["s25"] = {
		{"[%s]",{255,100,0},BATTLE_FONT_SIZE,DEFAULT_FONT},
		{"%s",{0,0,0},BATTLE_FONT_SIZE,DEFAULT_FONT},
		{"使用%s对",{0,0,0},BATTLE_FONT_SIZE,DEFAULT_FONT},
		{"%s",{0,0,0},BATTLE_FONT_SIZE,DEFAULT_FONT},
		{"造成%s点伤害",{0,0,0},BATTLE_FONT_SIZE,DEFAULT_FONT},
		{"%s",{0,0,0},BATTLE_FONT_SIZE,DEFAULT_FONT},
	},
	--玩家一伙被人打，
	["s26"] = {
		{"[%s]",{255,100,0},BATTLE_FONT_SIZE,DEFAULT_FONT},
		{"%s",{0,0,0},BATTLE_FONT_SIZE,DEFAULT_FONT},
		{"使用%s对",{0,0,0},BATTLE_FONT_SIZE,DEFAULT_FONT},
		{"%s",{0,0,0},BATTLE_FONT_SIZE,DEFAULT_FONT},
		{"造成%s点伤害",{0,0,0},BATTLE_FONT_SIZE,DEFAULT_FONT},
		{"%s",{0,0,0},BATTLE_FONT_SIZE,DEFAULT_FONT},
	},
	--xx释放技能xx
	["s27"] = {
		{"[%s]",{255,100,0},BATTLE_FONT_SIZE,DEFAULT_FONT},
		{"%s",{0,0,0},BATTLE_FONT_SIZE,DEFAULT_FONT},
		{"释放技能%s",{0,0,0},BATTLE_FONT_SIZE,DEFAULT_FONT},
	},
	--xx处于xx
	["s28"] = {
		{"[%s]",{255,100,0},BATTLE_FONT_SIZE,DEFAULT_FONT},
		{"%s",{0,0,0},BATTLE_FONT_SIZE,DEFAULT_FONT},
		{"处于%s",{0,0,0},BATTLE_FONT_SIZE,DEFAULT_FONT},
	},
	--xx使用xx移除(回复)xx xx点xx值
	["s29"] = {
		{"[%s]",{255,100,0},BATTLE_FONT_SIZE,DEFAULT_FONT},
		{"%s",{0,0,0},BATTLE_FONT_SIZE,DEFAULT_FONT},
		{"使用%s",{0,0,0},BATTLE_FONT_SIZE,DEFAULT_FONT},
		{"%s",{0,0,0},BATTLE_FONT_SIZE,DEFAULT_FONT},
		{"%s",{0,0,0},BATTLE_FONT_SIZE,DEFAULT_FONT},
		{"%s",{0,0,0},BATTLE_FONT_SIZE,DEFAULT_FONT},
		{"%s",{0,0,0},BATTLE_FONT_SIZE,DEFAULT_FONT},
	},
	["s30"] = {{"获得威望%s",{209,47,255},BATTLE_FONT_SIZE,DEFAULT_FONT}},
}

return StrLib