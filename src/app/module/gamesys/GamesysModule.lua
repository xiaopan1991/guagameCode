--游戏系统模块
--
local GamesysModule = class("GamesysModule",BaseModule)
--处理器
local GamesetProcessor = import(".GamesetProcessor")
local GameAwardProcessor = import(".GameAwardProcessor")
local PersonInfoProcessor = import(".PersonInfoProcessor")
local VipProcessor = import(".VipProcessor")
local GongGaoProcessor = import(".GongGaoProcessor")
local GameMailProcessor = import(".GameMailProcessor")
local ChangeTitleNameProcessor = import(".ChangeTitleNameProcessor")
local ChangePwdProcessor = import(".ChangePwdProcessor")
local CdkProcessor = import(".CdkProcessor")
local RankProcessor = import(".RankProcessor")
local RankListProcessor = import(".RankListProcessor")


--消息
GamesysModule.SHOW_GAME_SET   = "SHOW_GAME_SET"  	 			--显示游戏设置界面
GamesysModule.UPDATE_GAME_SET = "UPDATE_GAME_SET"				--更新游戏设置界面
GamesysModule.SHOW_GAME_TASK = "SHOW_GAME_TASK"    				--显示任务奖励界面
GamesysModule.SHOW_PERSON_INFO = "SHOW_PERSON_INFO"     		--显示个人信息
GamesysModule.HIDE_PERSON_INFO = "HIDE_PERSON_INFO"     		--显示个人信息
GamesysModule.SHOW_VIP_VIEW = "SHOW_VIP_VIEW"       	        --显示 VIP界面
GamesysModule.SHOW_GONGGAO = "SHOW_GONGGAO"       		        --显示公告界面
GamesysModule.SHOW_GAME_MAIL = "SHOW_GAME_MAIL"    		        --显示邮件界面
GamesysModule.SHOW_CHANGE_TITLE_NAME = "SHOW_CHANGE_TITLE_NAME" --显示更改称号
GamesysModule.UPDATE_GAME_TASK = "UPDATE_GAME_TASK"     --更新任务奖励界面
GamesysModule.UPDATE_GAME_MAIL = "UPDATE_GAME_MAIL"    	--更新邮件界面
GamesysModule.UPDATE_USER_TITLE = "UPDATE_USER_TITLE"	-- 更新用户称号
GamesysModule.UPDATE_USER_TITLES = "UPDATE_USER_TITLES" -- 更新用户所有称号
GamesysModule.SHOW_CHANGE_PWD = "SHOW_CHANGE_PWD"       --更改密码界面
GamesysModule.SHOW_CDK_VIEW = "SHOW_CDK_VIEW"           --显示CDK提示
GamesysModule.USER_GET_REWARD_BY_CODE = "user.get_reward_by_code" --请求CDK兑换


GamesysModule.USER_GET_MSG = "user.get_msg"    			--请求邮件列表
GamesysModule.USER_GET_GIFT_MSG = "user.get_gift_msg"   --请求领取邮件
GamesysModule.USER_GAME_SETTING = "user.game_setting"   --更改游戏设置
GamesysModule.USER_TASK_DONE = "user.task_done"   --请求领取任务奖励
GamesysModule.USER_CHANGE_SIGNATURE = "user.change_signature"  -- 修改用户签名
GamesysModule.USER_CHANGE_TITLE = "user.change_title" -- 用户修改称号
GamesysModule.USER_CHANGE_NAME = "user.change_name" --用户更改昵称
GamesysModule.USER_CHANGE_PASSWORD = "user.change_password" --用户更改密码
GamesysModule.USER_FIRST_RANK = "user.first_rank" -- 排行榜
GamesysModule.USER_GET_RANK_ALL_LIST = "user.get_rank_all_list" -- 排行榜详细列表



function GamesysModule:ProcessorList()
	return {
		GamesetProcessor,
		GameAwardProcessor,
		PersonInfoProcessor,
		VipProcessor,
		GongGaoProcessor,
		GameMailProcessor,
		ChangeTitleNameProcessor,
		CdkProcessor,
		ChangePwdProcessor,
		RankProcessor,
		RankListProcessor,
	}
end

return GamesysModule