local MapModule = class("MapModule", BaseModule)
local MapProcessor = import(".MapProcessor")
--消息
MapModule.SHOW_MAP = "SHOP_MAP"
MapModule.BOSS_TIME_CHANGE = "BOSS_TIME_CHANGE"
MapModule.UPDATE_MAP = "UPDATE_MAP"
MapModule.USER_CHANGE_MAP = "user.change_map" 		 --更换地图
MapModule.USER_BUY_BOSS_COUNT = "user.buy_BOSS_count" 		 --购买BOSS挑战次数
MapModule.USER_BOSS_SWEEEP = "user.boss_sweep" --扫荡

function MapModule:ctor()
	-- body
	MapModule.super.ctor(self)
end


function MapModule:ProcessorList()
	return {
		MapProcessor
    }
end

return MapModule