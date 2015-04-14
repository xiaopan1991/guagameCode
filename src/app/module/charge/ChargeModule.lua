--游戏系统模块
--
local ChargeModule = class("ChargeModule",BaseModule)
--处理器
local ChargeProcessor = import(".ChargeProcessor")

--消息
ChargeModule.SHOW_CHARGE_VIEW = "SHOW_CHARGE_VIEW"  	--显示充值界面
ChargeModule.USER_LOCAL_PAY_TEST = "user.local_pay_test" --充值消息
ChargeModule.USER_GET_COIN = "user.get_coin"             




function ChargeModule:ProcessorList()
	return {
		ChargeProcessor
	}
end

return ChargeModule