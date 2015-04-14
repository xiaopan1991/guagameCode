--背包模块
local BattleModule = class("BattleModule", BaseModule)
local BattleProcessor = import(".BattleProcessor") 	--BossPvp挂机战斗


BattleModule.GUAJI_WAIT_FOR_FIGHT = "GUAJI_WAIT_FOR_FIGHT" --等待战斗，处理倒计时信息
BattleModule.GUAJI_BEGIN_FIGHT = "GUAJI_BEGIN_FIGHT" --开始战斗，处理战斗ui的初始化和找到怪物
BattleModule.GUAJI_ATTACK_ONE = "GUAJI_ATTACK_ONE" --一次的攻击结果，更新头像血条和界面表现
BattleModule.GUAJI_FIGHT_END = "GUAJI_FIGHT_END" --战斗结束
BattleModule.GUAJI_ADD_BATTLE_LOG = "GUAJI_ADD_BATTLE_LOG" --ADD战斗日志
BattleModule.GUAJI_SKILL_COST_MP = "GUAJI_SKILL_COST_MP" --更新头像蓝信息
BattleModule.GUAJI_BUFFER_HP_MP = "GUAJI_BUFFER_HP_MP" --buffer影响的+—血蓝，反伤-蓝
--BattleModule.GUAJI_BUFFER_EFFECT = "GUAJI_BUFFER_EFFECT" --技能释放buffer信息显示
BattleModule.GUAJI_BUFFER_UPDATE = "GUAJI_BUFFER_UPDATE" --buffer更新




BattleModule.BOSS_PVP_WAIT_FOR_FIGHT = "BOSS_PVP_WAIT_FOR_FIGHT" --等待战斗，处理倒计时信息
BattleModule.BOSS_PVP_BEGIN_FIGHT = "BOSS_PVP_BEGIN_FIGHT" --开始战斗，处理战斗ui的初始化和找到怪物
BattleModule.BOSS_PVP_ATTACK_ONE = "BOSS_PVP_ATTACK_ONE" --一次的攻击结果，更新头像血条和界面表现
BattleModule.BOSS_PVP_FIGHT_END = "BOSS_PVP_FIGHT_END" --战斗结束
BattleModule.BOSS_PVP_ADD_BATTLE_LOG = "BOSS_PVP_ADD_BATTLE_LOG" --ADD战斗日志
BattleModule.BOSS_PVP_SKILL_COST_MP = "BOSS_PVP_SKILL_COST_MP" --更新头像蓝信息
BattleModule.BOSS_PVP_BUFFER_HP_MP = "BOSS_PVP_BUFFER_HP_MP" --buffer影响的+—血蓝，反伤-蓝
--BattleModule.BOSS_PVP_BUFFER_EFFECT = "BOSS_PVP_BUFFER_EFFECT" --技能释放buffer信息显示
BattleModule.BOSS_PVP_BUFFER_UPDATE = "BOSS_PVP_BUFFER_UPDATE" --buffer更新
BattleModule.BOSS_PVP_SHOW_NEXT = "BOSS_PVP_SHOW_NEXT" --显示下一场战斗对象（竞技 or BOSS）




BattleModule.SHOW_BATTLE_UI = "SHOW_BATTLE_UI" --显示界面
BattleModule.UPDATE_SWITCH = "UPDATE_SWITCH" --更新类型后刷新界面

BattleModule.USER_HANG_CLEAR= "user.hang_clear" --挂机奖励
BattleModule.USER_PK_COMBAT_MAIN= "user.pk_combat_main" --BOSS挑战
BattleModule.USER_GET_PK_BOSS_REWARD= "user.get_pk_boss_reward" --更新BOSS挑战奖励
BattleModule.USER_UPGRADE= "user.upgrade"


BattleModule.GUAJI = 1 --1，普通挂机更新显示；2，boss+pvp战斗更新显示
BattleModule.BOSS_PVP = 2
BattleModule.CUR_SHOW_TYPE = BattleModule.GUAJI

function BattleModule:ProcessorList()
	return {
		BattleProcessor,
	}
end
function BattleModule:sendHangclear(fighting)--fighting,是否是快速戰斗；
	local net = {}
	net.method = BattleModule.USER_HANG_CLEAR
	net.params = {}
	net.params.fighting = fighting
	Net.sendhttp(net)
end

return BattleModule