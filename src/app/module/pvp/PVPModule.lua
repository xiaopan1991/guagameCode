--PVP模块
local PVPModule = class("PVPModule", BaseModule)
local PVPProcessor = import(".PVPProcessor")
local RankProcessor = import(".RankProcessor")
local JJCProcessor = import(".JJCProcessor")
local WeiwangProcessor = import(".WeiwangProcessor")


--显示PVP界面
PVPModule.SHOW_PVP_PANEL = "SHOW_PVP_PANEL"
PVPModule.UPDATE_PVP_ROLE = "UPDATE_PVP_ROLE"
PVPModule.PVP_TIMES_CHANGE = "PVP_TIMES_CHANGE"
PVPModule.UPDATE_PVP_PANEL = "UPDATE_PVP_PANEL"



--通信协议
PVPModule.USER_GET_MY_RANK = "user.get_my_rank"
PVPModule.USER_PK_COMBAT_PVP = "user.pk_combat_pvp"
PVPModule.USER_BUY_PVP_COUNT = "user.buy_PVP_count"

--请求威望商店数据
PVPModule.USER_MANA_SHOP_INFO = "user.mana_shop_info"
--威望商店购买接口
PVPModule.USER_BUY_MANA_SHOP  = "user.buy_mana_shop"
--威望商店刷新接口
PVPModule.USER_MANA_SHOP_REFRESH  = "user.mana_shop_refresh"
--获取PVP排行
PVPModule.USER_GET_PVP_RANK  = "user.get_pvp_rank"



--请求PVP列表  请求排行榜
function PVPModule:ProcessorList()
	return {
		PVPProcessor, 
		RankProcessor, 
		JJCProcessor,
		WeiwangProcessor,
	} 
	end
return PVPModule