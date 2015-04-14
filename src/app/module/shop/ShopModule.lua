--商店模块
local ShopModule = class("ShopModule", BaseModule)
local ShopProcessor = import(".ShopProcessor")
local PayInfoProcessor = import(".PayInfoProcessor")

ShopModule.SHOW_SHOP            = "SHOW_SHOP" 		--显示商店  参数0 地精商店 参数1银两商店
ShopModule.SHOW_PAY_INFO        = "SHOW_PAY_INFO" 	--显示购买的信息
ShopModule.SHOW_BUY_GOODS		= "SHOW_BUY_GOODS"	--购买道具

ShopModule.SHOP_INFO            = "user.shop_info" 			--获取商城数据
ShopModule.USER_SHOP_BUY_EQUIPS = "user.shop_buy_equips" 	--购买商城道具
ShopModule.USER_SHOP_REFRESH    = "user.shop_refresh" 		--刷新商城道具
ShopModule.USER_SHOP_BUY_GOLD   = "user.shop_buy_gold" 	 	--购买银两


function ShopModule:ctor()
	-- body
	ShopModule.super.ctor(self)
end

--Processor列表
function ShopModule:ProcessorList()
	-- body
	return {
		ShopProcessor,
		PayInfoProcessor
	}
end

return ShopModule