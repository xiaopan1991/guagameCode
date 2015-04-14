--
-- Author: Your Name
-- Date: 2015-01-22 17:52:53
--
local MultiBattleModule = class("MultiBattleModule", BaseModule)
local MultiBattleProcessor = import(".MultiBattleProcessor")
local MultiBattleResultProcessor = import(".MultiBattleResultProcessor")
local MultiBattlePlayerListProcessor = import(".MultiBattlePlayerListProcessor")
local MultiBattleOneResultProcessor = import(".MultiBattleOneResultProcessor")

--消息
MultiBattleModule.SHOW_MULTI_BATTLE = "SHOW_MULTI_BATTLE"
MultiBattleModule.SHOW_MULTI_BATTLE_PLAYER_LIST = "SHOW_MULTI_BATTLE_PLAYER_LIST"
MultiBattleModule.SHOW_MULTI_BATTLE_RESULT = "SHOW_MULTI_BATTLE_RESULT"
MultiBattleModule.SHOW_MULTI_BATTLE_ONE_RESULT = "SHOW_MULTI_BATTLE_ONE_RESULT"

--获取当前状态
MultiBattleModule.USER_GET_MULTIPLAYER_PVP_INFO = "user.get_multiplayer_pvp_info"--参数 : 无
--报名接口
MultiBattleModule.USER_SIGN_UP_MULTIPLAYER_PVP = "user.sign_up_multiplayer_pvp"--参数 : is_leader = True or False
--取消报名接口
MultiBattleModule.USER_CANCEL_SIGN_UP = "user.cancel_sign_up"--参数 : 无
--队长查看该队伍信息
MultiBattleModule.USER_LOOK_TEAM_INFO = "user.look_team_info"--参数 : 无
--队长刷新队伍成员
MultiBattleModule.USER_LEADER_REFRESH_TEAM = "user.leader_refresh_team"--参数 : 无
--队长踢人
MultiBattleModule.USER_KICK_OUT = "user.kick_out"--参数 : uid


function MultiBattleModule:ctor()
	-- body
	MultiBattleModule.super.ctor(self)
end      


function MultiBattleModule:ProcessorList()
	return {
		MultiBattleProcessor,
		MultiBattlePlayerListProcessor,
		MultiBattleResultProcessor,
		MultiBattleOneResultProcessor,
    }
end

return MultiBattleModule