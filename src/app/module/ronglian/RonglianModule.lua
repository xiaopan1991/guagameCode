--熔炼
local RonglianModule = class("RonglianModule",BaseModule)
local RonglianProcessor = import(".RonglianProcessor")
local DazaoProcessor = import(".DazaoProcessor")
local DazaoGodProcessor = import(".DazaoGodProcessor")
--消息

RonglianModule.SHOW_RONG_LIAN    = "SHOW_RONG_LIAN"  	 --显示熔炼界面
RonglianModule.SHOW_EQUIP_SELECT = "SHOW_EQUIP_SELECT"   --显示装备选择界面
RonglianModule.SHOW_DA_ZAO       = "SHOW_DA_ZAO"         --显示打造装备界面
RonglianModule.SHOW_HAVE_EQUIP   = "SHOW_HAVE_EQUIP"     --显示已经选择的装备，放到格子里
RonglianModule.SHOW_DA_ZAO_GAO   = "SHOW_DA_ZAO_GAO"	 --显示打造神器界面

RonglianModule.MELTE_UPDATE      = "METEL_UPDATE"		 --熔炼值更新

RonglianModule.USER_EQUIP_FORGE_INFO = "user.equip_forge_info"   		 --需要打造的装备信息
RonglianModule.USER_EQUIP_MELTE_EXCHANGE = "user.equip_melte_exchange"   --获得打造后的数据
RonglianModule.USER_EQUIP_FORGE_REFRESH = "user.equip_forge_refresh"     --刷新返回的数据
RonglianModule.USER_EQUIP_FORGE = "user.equip_forge"                     --返回熔炼后的数据
RonglianModule.USER_SP_EQUIP_MELTE = "user.sp_equip_melte"				 --打造神器
RonglianModule.USER_SP_FORGE_INFO = "user.sp_forge_info"				 --打造神器列表


function RonglianModule:ctor()
	-- body
	RonglianModule.super.ctor(self)
end

function RonglianModule:ProcessorList()
	return {
		RonglianProcessor,
		DazaoProcessor,
		DazaoGodProcessor
	}
end

return RonglianModule