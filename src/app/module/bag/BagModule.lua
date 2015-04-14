--背包模块
local BagModule = class("BagModule", BaseModule)

local BagProcessor = import(".BagProcessor") 					--背包
local EquipInfoProcessor = import(".EquipInfoProcessor")		--装备信息
local GoodInfoProcessor = import(".GoodInfoProcessor")			--道具信息
local QiangHuaProcessor = import(".QiangHuaProcessor")			--强化装备
local XiLianProcessor = import(".XiLianProcessor")				--洗练装备
local XiangQianProcessor = import(".XiangQianProcessor")		--宝石镶嵌
local ChuanChengProcessor = import(".ChuanChengProcessor")  	--神器传承
local TunShiProcessor = import(".TunShiProcessor")          	--神器吞噬
local GoodsSelectProcessor = import(".GoodsSelectProcessor")    --道具选择
local LotSellProcessor = import(".LotSellProcessor")			--批量卖出
local CommonEquipSelectProcessor = import(".CommonEquipSelectProcessor")    --装备选择
local EquipProcessor = import(".EquipProcessor") 				--装备界面
local EquipFilterProcessor = import(".EquipFilterProcessor") 	--装备筛选界面
local GemUpProcessor = import(".GemUpProcessor") 				-- 宝石升级界面

local OtherPlayerEquipProcessor = import(".OtherPlayerProcessor") 				--其他玩家装备界面

--[[模块消息]]
--显示背包
BagModule.SHOW_BAG = "SHOW_BAG"
--显示装备信息
BagModule.SHOW_EQUIP_INFO = "SHOW_EQUIP_INFO"
--显示道具信息
BagModule.SHOW_GOODS_INFO = "SHOW_GOODS_INFO"
--显示强化装备
BagModule.SHOW_EQUIP_QIANGHUA = "SHOW_EQUIP_QIANGHUA"
--显示装备洗练
BagModule.SHOW_EQUIP_XILIAN = "SHOW_EQUIP_XILIAN"
--显示装备镶嵌
BagModule.SHOW_EQUIP_XIANGQIAN = "SHOW_EQUIP_XIANGQIAN"
--显示神器传承
BagModule.SHOW_CHUAN_CHENG = "SHOW_CHUAN_CHENG"
--显示神器吞噬
BagModule.SHOW_TUN_SHI = "SHOW_TUN_SHI"
--显示道具选择界面 可筛选不同的道具类型
BagModule.SHOW_GOODS_SELECT = "SHOW_GOODS_SELECT"
--显示装备选择界面
-- BagModule.SHOW_COMMON_EQUIP_SELECT = "SHOW_EQUIP_SELECT"
BagModule.SHOW_COMMON_EQUIP_SELECT = "SHOW_COMMON_EQUIP_SELECT"

BagModule.OPEN_EQUIP = "OPEN_EQUIP" --打开装备界面
BagModule.UPDATE_EQUIP_ATTR = "UPDATE_EQUIP_ATTR" --更新装备属性数据
--显示装备筛选界面
BagModule.SHOW_EQUIP_FILTER = "SHOW_EQUIP_FILTER"
--显示批量卖出界面
BagModule.SHOW_LOT_SELL = "SHOW_LOT_SELL"
--属性界面显示有更好的装备可以替换
BagModule.NOTICE_BETTER_EQUIP = "NOTICE_BETTER_EQUIP"
-- 宝石升级界面
BagModule.SHOW_GEM_UP = "SHOW_GEM_UP"
-- 用户称号变更
BagModule.UPDATE_USER_TITLE = "UPDATE_USER_TITLE"
-- 更新道具详情界面
BagModule.UPDATE_GOODS_INFO = "UPDATE_GOODS_INFO"
-- 隐藏道具详情界面
BagModule.HIDE_GOODS_INFO = "HIDE_GOODS_INFO"
-- 更新背包道具列表
BagModule.UPDATE_BAG_GOODS = "UPDATE_BAG_GOODS"

--[[网络消息]]

--请求洗练
BagModule.USER_EQUIP_WASHS = "user.equip_washs"
--请求强化
BagModule.USER_EQUIP_STRENGTHEN = "user.equip_strengthen"
--请求卖出装备
BagModule.USER_EQUIP_SELL = "user.equip_sell"

--请求打孔
BagModule.USER_EQUIP_PUNCH = "user.equip_punch"
--请求镶嵌宝石
BagModule.USER_EQUIP_INSET_GEM = "user.equip_inset_gem"
--请求一键卸下
BagModule.USER_EQUIP_UNSET_GEM = "user.equip_unset_gem"
--请求吞噬
BagModule.USER_EQUIP_GOD_DEVOUR = "user.equip_god_devour"
--请求更换卸载装备
BagModule.USER_EQUIP_DRESS = "user.equip_dress"
--请求传承
BagModule.USER_EQUIP_GOD_INHERIT = "user.equip_god_inherit"

--数据更新的消息
BagModule.EQUIP_NUM_UPDATE = "EQUI_NUM_UPDATE" 	--道具数量更新

BagModule.EQUIP_INFO_UPDATE = "EQUI_INFO_UPDATE" --道具属性更新

--请求扩展背包
BagModule.EQUIP_ADD_LIMIT = "user.equip_add_limit"
--请求批量卖出
BagModule.USER_EQUIP_SELL = "user.equip_sell"

--查看其他玩家信息
BagModule.USER_GET_USER_INFO = "user.get_user_info"
BagModule.SHOW_OTHER_PLAYER = "SHOW_OTHER_PLAYER"

-- 宝石升级
BagModule.USER_GEM_UP = "user.gem_str"
-- 宝石袋打开
BagModule.USER_GEM_BAG_OPEN = "user.gem_bag"
--神器碎片合成
BagModule.USER_SY_GODEQUIP = "user.sy_godequip"
--BOSS挑战券使用
BagModule.USE_CHALLENGE_COUPON = "user.use_challenge_coupon"

function BagModule:ctor()
	BagModule.super.ctor(self)
end

function BagModule:ProcessorList()
	return {
		BagProcessor,
		EquipInfoProcessor,
		GoodInfoProcessor,
		QiangHuaProcessor,
		XiLianProcessor,
		XiangQianProcessor,
		ChuanChengProcessor,
		TunShiProcessor,
		GoodsSelectProcessor,
		CommonEquipSelectProcessor,
		EquipProcessor,
		EquipFilterProcessor,
		LotSellProcessor,
		OtherPlayerEquipProcessor,
		GemUpProcessor,
	}
end

return BagModule

