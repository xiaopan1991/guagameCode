-- 宝石升级处理器
local GemUpProcessor = class("GemUpProcessor", BaseProcessor)
local ItemFace = require("app.components.ItemFace")

function GemUpProcessor:ctor()
end

function GemUpProcessor:ListNotification()
	return {
		BagModule.SHOW_GEM_UP,
		BagModule.USER_GEM_UP,
	}
end

--消息处理
function GemUpProcessor:handleNotification(notify, node)
	if notify == BagModule.SHOW_GEM_UP then
		self.data = node.data
		self:initUI()
		self:setData()
		self:onSetView()
	elseif notify == BagModule.USER_GEM_UP then
		self:onUserGemUp(node)
	end
end

function GemUpProcessor:initUI()
	-- 界面
	local view = ResourceManager:widgetFromJsonFile("ui/GemUp.json")
	self.btnClose = view:getChildByName("btnClose")
	local helpBtn = view:getChildByName("helpBtn")
	local content = view:getChildByName("panelContent")
	local prompt = content:getChildByName("panelPrompt")
	self.txtPrompt = prompt:getChildByName("txtPrompt")
	local main = content:getChildByName("panelMain")
	self.txtName = main:getChildByName("txtName")
	self.imgIcon = main:getChildByName("imgIcon")
	self.txtHead = main:getChildByName("txtHead")
	self.txtInfoGold = main:getChildByName("txtInfoGold")
	self.txtInfoGem = main:getChildByName("txtInfoGem")
	self.txtLucky = main:getChildByName("txtLucky")
	self.txtNumber = main:getChildByName("txtNumber")
	self.sliderGemUp = main:getChildByName("sliderGemUp")
	self.btnGemUp = content:getChildByName("btnGemUp")

	self.content = content
	self.prompt = prompt
	self.main = main

	-- 事件
	self.btnClose:addTouchEventListener(handler(self, self.onBtnCloseClick))
	self.btnGemUp:addTouchEventListener(handler(self, self.onBtnGemUpClick))
	helpBtn:addTouchEventListener(handler(self,self.onBtnClick))

	-- 隐藏占位图
	self.imgIcon:setVisible(false)

	-- 物品
	self.itemface = ItemFace.new()
	self.itemface.showInfo = false --禁用鼠标事件
	self.itemface:setPosition(self.imgIcon:getPositionX(), self.imgIcon:getPositionY())
	self.main:addChild(self.itemface)
	
	self:setView(view)
end

function GemUpProcessor:setData()
	-- dump(self.data)

	-- 升级消耗
	local gem_up_lv = DataConfig:getGemUpLv()

	-- 判断是否顶级
	if self.data.edata.lv > #gem_up_lv.consume_gold then
		local node = display.newNode()
		node.data = self.data
		Observer.sendNotification(BagModule.HIDE_GOODS_INFO)
		Observer.sendNotification(BagModule.SHOW_GOODS_INFO, node)
		self:removePopView(self.view)
		-- self:reset()
		-- self.txtName:setString(self.data.edata.name)
		-- self.itemface:setData(self.data)
		return
	end

	-- 装备名称
	self.txtName:setString(self.data.edata.name)

	-- 装备格子
	self.itemface:setData(self.data)

	-- 属性信息
	local gem_up_gold = gem_up_lv.consume_gold[self.data.edata.lv]
	local gem_up_gem = gem_up_lv.consume_gem[self.data.edata.lv]
	local gem_up_luck = gem_up_lv.luck[self.data.edata.lv]
	local gem_up_luck_value = gem_up_lv.luck_value[self.data.edata.lv]
	local player_gold = PlayerData:getGold()
	local player_gem = 0
	local player_gem_luck = PlayerData:getGemUpLuck()

	-- 银两消耗提示
	local gold_info = string.format("银两%s（当前拥有：%s）", gem_up_gold, player_gold)
	self.txtInfoGold:setString(gold_info)
	if player_gold < gem_up_gold then
		self.txtInfoGold:setColor(COLOR_RED)
	else
		self.txtInfoGold:setColor(display.COLOR_WHITE)
	end

	-- 宝石消耗提示
	if gem_up_gem == nil or gem_up_gem == 0 then
		self.txtInfoGem:setString("")
		self.txtInfoGem:setColor(display.COLOR_WHITE)
	else
		local bag_up_eid = string.sub(self.data.eid, 1, 3) .. "01"

		local goods = Bag:getGoodsById(bag_up_eid)
		if goods ~= nil then
			player_gem = goods.num
		end
		local edata = DataConfig:getGoodByID(bag_up_eid)
		local gem_info = string.format("%s*%s（当前拥有：%s）", edata.name, gem_up_gem, player_gem)
		self.txtInfoGem:setString(gem_info)
		if player_gem < gem_up_gem then
			self.txtInfoGem:setColor(COLOR_RED)
		else
			self.txtInfoGem:setColor(display.COLOR_WHITE)
		end
	end

	-- 幸运值
	if player_gem_luck > gem_up_luck_value then
		player_gem_luck = gem_up_luck_value
	end
	self.txtNumber:setString(string.format("%d/%d", player_gem_luck, gem_up_luck_value))

	-- 进度条
	-- print(tolua.type(self.sliderGemUp))
	self.sliderGemUp:setPercent((player_gem_luck / gem_up_luck_value) * 100)
end

function GemUpProcessor:onSetView()
	self:addPopView(self.view)
end
function GemUpProcessor:onBtnClick(sender, eventType)
	if eventType ~= TouchEventType.ended then
		return true
	end
	local alert = GameAlert.new()
	alert:popHelp("gem_upgrade")
end
function GemUpProcessor:onBtnCloseClick(sender, eventType)
	if eventType ~= TouchEventType.ended then
		return true
	end
	self:removePopView(self.view)
end

function GemUpProcessor:onBtnGemUpClick(sender, eventType)
	if eventType ~= TouchEventType.ended then
		return true
	end

	local gem_up_lv = DataConfig:getGemUpLv()
	if self.data.edata.lv > #gem_up_lv.consume_gold then
		toastNotice("宝石已满级")
		return
	end

	local gem_up_gold = gem_up_lv.consume_gold[self.data.edata.lv]
	local gem_up_gem = gem_up_lv.consume_gem[self.data.edata.lv]
	local player_gold = PlayerData:getGold()
	local player_gem = 0

	if player_gold < gem_up_gold then
		toastNotice("银两不足")
		return
	end

	if gem_up_gem ~= nil and gem_up_gem > 0 then
		local bag_up_eid = string.sub(self.data.eid, 1, 3) .. "01"
		local goods = Bag:getGoodsById(bag_up_eid)
		if goods ~= nil then
			player_gem = goods.num
		end
		if player_gem < gem_up_gem then
			toastNotice("宝石不足")
			return
		end
	end

	local net = {}
	net.method = BagModule.USER_GEM_UP
	net.params = {}
	net.params.gem_id = self.data.eid
	Net.sendhttp(net)
end

function GemUpProcessor:onUserGemUp(node)
	--dump(node.data)
	local result = node.data.data

	-- -- 删除所有宝石
	-- local goods = Bag:getAllGoods()
	-- local preifx = string.sub(self.data.eid, 1,3)
	-- for i,v in pairs(goods) do
	-- 	if v.edata.type == 'gem' and string.sub(i, 1,3) == preifx then
	-- 		Bag:removeGoodsById(i)
	-- 	end
	-- end

	-- 保存数据
	for eid, num in pairs(result.bag) do
		Bag:updateGoodsNum(eid, num)
	end
	PlayerData:setGemUpLuck(result.gem_luck)
	PlayerData:setGold(result.gold)

	local show_eid = ''
	if result.gem_luck > 0 then
		toastNotice("宝石升级失败", COLOR_RED)
		show_eid = self.data.eid
	else
		toastNotice("宝石升级成功", COLOR_GREEN)
		show_eid = string.format("%s%02d", string.sub(self.data.eid, 1, 3), tonumber(string.sub(self.data.eid, 4, 5)) + 1)
	end
	-- print(show_eid)

	Observer.sendNotification(BagModule.UPDATE_GOODS_INFO)
	Observer.sendNotification(BagModule.UPDATE_BAG_GOODS)

	local data = Bag:getGoodsById(show_eid)
	if data == nil or data.num <= 0 then
		self:removePopView(self.view)
		return
	end

	self.data = data
	self:setData()
end

function GemUpProcessor:reset()
	self.itemface:reset()
	self.txtName:setString("")
	-- self.btnGemUp:setEnabled(false)
	self.txtHead:setString("升级消耗：")
	self.txtInfoGold:setString("")
	self.txtInfoGem:setString("")
	self.txtNumber:setString("0/0")
	self.sliderGemUp:setPercent(0)
end

return GemUpProcessor