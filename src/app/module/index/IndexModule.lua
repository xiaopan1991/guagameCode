--主页模块
local IndexModule = class("IndexModule", BaseModule)
--processor
local IndexProcessor = import(".IndexProcessor")
local MainTopProcessor = import(".MainTopProcessor")
--消息
IndexModule.SHOW_INDEX    = "SHOW_INDEX"	--显示主页
IndexModule.SHOW_MAIN_TOP = "SHOW_MAIN_TOP" --显示主界面顶部
IndexModule.MONEY_UPDATE  = "MONEY_UPDATE" 	--货币更新
IndexModule.EXP_UPDATE    = "EXP_UPDATE" 	--经验更新
IndexModule.LEVEL_UPDATE  = "LEVEL_UPDATE" 	--等级更新
IndexModule.REWARD_NOTICE  = "REWARD_NOTICE" 	--未领取奖励
IndexModule.MAIL_NOTICE  = "MAIL_NOTICE" 	--未领取邮件提示
IndexModule.CHAT_NOTICE  = "CHAT_NOTICE" 	--有人聊天提示
IndexModule.NAME_UPDATE = "NAME_UPDATE"      --修改玩家昵称

function IndexModule:ctor()
	-- body
	IndexModule.super.ctor(self)
end

--Processor列表
function IndexModule:ProcessorList()
	-- body
	return {
		IndexProcessor,
		MainTopProcessor
	}
end

return IndexModule