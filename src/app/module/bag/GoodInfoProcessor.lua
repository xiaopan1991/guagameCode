--道具信息处理器
local GoodInfoProcessor = class("GoodInfoProcessor", BaseProcessor)
local ItemFace = require("app.components.ItemFace")

function GoodInfoProcessor:ctor()
	-- body
end

function GoodInfoProcessor:ListNotification()
	return {
		BagModule.SHOW_GOODS_INFO,
		BagModule.UPDATE_GOODS_INFO,
		BagModule.USER_GEM_BAG_OPEN,
		BagModule.HIDE_GOODS_INFO,
		BagModule.USER_SY_GODEQUIP,
		BagModule.USE_CHALLENGE_COUPON
	}
end

--消息处理
function GoodInfoProcessor:handleNotification(notify, node)
	if notify == BagModule.SHOW_GOODS_INFO then
		-- TODO 重新做界面 需求还没出来
		self.data = node.data
		self:initUI()
		self:setData()
		self:onSetView()
	elseif notify == BagModule.UPDATE_GOODS_INFO then
		self:onUpdateGoodsInfo()
	elseif notify == BagModule.USER_GEM_BAG_OPEN then
		self:onGemBagOpen(node.data)
	elseif notify == BagModule.HIDE_GOODS_INFO then
		self:onHideGoodsInfo()
	elseif notify == BagModule.USER_SY_GODEQUIP then
		self:onGodHeCheng(node.data)
	elseif notify == BagModule.USE_CHALLENGE_COUPON then
		self:onBossChallengeUse(node.data)
	end
end
function GoodInfoProcessor:initUI()
	local goodsInfo = ResourceManager:widgetFromJsonFile("ui/goodsinfo.json")

	self.goodsInfo = goodsInfo
	self.txtInfo = goodsInfo:getChildByName("txtInfo")
	self.panel = goodsInfo:getChildByName("panel")
	self.bg = goodsInfo:getChildByName("btnClose")
	self.Image_3 = goodsInfo:getChildByName("Image_3")
	self.txtTitle = goodsInfo:getChildByName("txtTitle")
	self.btnClose = goodsInfo:getChildByName("btnClose")
	self.btnOK = goodsInfo:getChildByName("btnOK")
	self.btnGemUp = goodsInfo:getChildByName("btnGemUp")
	self.btnOpen = goodsInfo:getChildByName("btnOpen")
	self.btnOpenTen = goodsInfo:getChildByName("btnOpenTen")
	self.txtName = goodsInfo:getChildByName("txtName")
	self.txtPrompt = goodsInfo:getChildByName("txtPrompt")
	self.btnGodhecheng = goodsInfo:getChildByName("btnGodhecheng")
	self.btnUse = goodsInfo:getChildByName("btnUse")
	

	--装备格子
	self.itemface = ItemFace.new()
	self.itemface.showInfo = false --禁用鼠标事件
	self.itemface:setPosition(70,168)
	self.goodsInfo:addChild(self.itemface)

	-- 按钮事件
	self.btnClose:addTouchEventListener(handler(self,self.onBtnCloseClick))
	self.btnOK:addTouchEventListener(handler(self,self.onBtnCloseClick))
	self.btnGemUp:addTouchEventListener(handler(self,self.onBtnGemUpClick))
	self.btnOpen:addTouchEventListener(handler(self,self.onBtnOpenClick))
	self.btnOpenTen:addTouchEventListener(handler(self,self.onBtnOpenClick))
	self.btnGodhecheng:addTouchEventListener(handler(self,self.onBtnGodhechengClick))
	self.btnUse:addTouchEventListener(handler(self,self.onBtnUse))

	self:setView(self.goodsInfo)
end
function GoodInfoProcessor:setData()
	-- dump(self.data)
	if(not self.view) then
		return
	end
	--装备说明
	if(self.data.edata.info) then
		self.txtInfo:setString(self.data.edata.info)
	end
	-- 装备名称
	self.txtName:setString(self.data.edata.name)

	--装备格子
	self.itemface:setData(self.data)

	-- 按钮隐藏
	self.btnOK:setVisible(false)
	self.btnGemUp:setVisible(false)
	self.btnOpen:setVisible(false)
	self.btnOpenTen:setVisible(false)
	self.btnGodhecheng:setVisible(false)
	self.btnUse:setVisible(false)

	self.btnOK:setTouchEnabled(false)
	self.btnGemUp:setTouchEnabled(false)
	self.btnOpen:setTouchEnabled(false)
	self.btnOpenTen:setTouchEnabled(false)
	self.btnGodhecheng:setTouchEnabled(false)
	self.btnUse:setTouchEnabled(false)

	-- 按钮
	-- box 宝箱 gem 宝石 gem_bag 宝石袋 hammer 锤子 key 钥匙 pith 强化精华
	local type = self.data.edata.type
	if type == "box" or type == "hammer" or type == "key" or type == "pitch" then
		self.btnOK:setVisible(true)
		self.btnOK:setTouchEnabled(true)
	elseif type == "gem" then
		self.btnGemUp:setVisible(true)
		self.btnGemUp:setTouchEnabled(true)
	elseif type == "gem_bag" then
		self.btnOpen:setVisible(true)
		self.btnOpenTen:setVisible(true)
		self.btnOpen:setTouchEnabled(true)
		self.btnOpenTen:setTouchEnabled(true)
	elseif type == "god_debris" then
		self.btnGodhecheng:setVisible(true)
		self.btnGodhecheng:setTouchEnabled(true)
	elseif type == "BOSS" then
		self.btnUse:setVisible(true)
		self.btnUse:setTouchEnabled(true)
	end
end
function GoodInfoProcessor:onSetView()
	self:addPopView(self.goodsInfo)
end
function GoodInfoProcessor:onUpdateGoodsInfo()
	if self.data == nil then
		return
	end
	
	local goods = Bag:getGoodsById(self.data.eid)
	if goods == nil or goods.num <= 0 then
		self:removePopView(self.view)
		return
	end

	self.data = goods
	self:setData()
end
--boss挑战卷使用
function GoodInfoProcessor:onBtnUse(sender, eventType)
	if eventType ~= TouchEventType.ended then
		return true
	end
	local net = {}
	net.method = BagModule.USE_CHALLENGE_COUPON
	net.params = {}
	Net.sendhttp(net)
end
--神器碎片合成
function GoodInfoProcessor:onBtnGodhechengClick(sender, eventType)
	if eventType ~= TouchEventType.ended then
		return true
	end
	if(DataConfig:getGodsHeChengNeedNum() <= Bag:getGoodsById("I6001").num) then--碎片数量够
		local net = {}
		net.method = BagModule.USER_SY_GODEQUIP
		net.params = {}
		Net.sendhttp(net)
	else--不够
		local cfg = DataConfig:getAllConfigMsg()
		toastNotice(cfg["10179"])
	end
end
function GoodInfoProcessor:onBtnCloseClick(sender, eventType)
	if eventType ~= TouchEventType.ended then
		return true
	end

	self:removePopView(self.view)
	self.view = nil
end
function GoodInfoProcessor:onBtnGemUpClick(sender, eventType)
	if eventType ~= TouchEventType.ended then
		return true
	end

	-- 检查宝石是否满级
	local gem_up_lv = DataConfig:getGemUpLv()
	if self.data.edata.lv > #gem_up_lv.consume_gold then
		toastNotice("宝石已满级")
		return
	end

	-- self:removePopView(self.view)
	Observer.sendNotification(BagModule.SHOW_GEM_UP, self)
end
function GoodInfoProcessor:onBtnOpenClick(sender, eventType)
	if eventType ~= TouchEventType.ended then
		return true
	end

	local btn = tolua.cast(sender,"ccui.Button")
	local btnName = btn:getName()

	local openNum = 1

	if btnName == "btnOpen" then

	elseif btnName == "btnOpenTen" then
		if self.data.num < 10 then
			toastNotice("数量不足")
			return
		end

		openNum = 10
	end

	local net = {}
	net.method = BagModule.USER_GEM_BAG_OPEN
	net.params = {}
	net.params.gem_bag_id = self.data.eid
	net.params.count = openNum
	Net.sendhttp(net)
end
function GoodInfoProcessor:onGemBagOpen(result)
	-- dump(result)
	local data = result.data

	-- 提示信息 并将获得的道具 添加到背包
	local notices = {}
	for eid, num in pairs(data.bag) do
		local goods_info = DataConfig:getGoodByID(eid)
		table.insert(notices, {string.format("获得了%d个%s", num, goods_info.name), COLOR_GREEN})
		Bag:plusGoods(eid, num)
	end
	popNotices(notices)
	-- 减少宝石袋
	Bag:plusGoods(self.data.eid, -result.params.count)

	-- 通知背包道具更新
	Observer.sendNotification(BagModule.UPDATE_BAG_GOODS)

	-- 检查宝石袋是否用光了
	self.data = Bag:getGoodsById(self.data.eid)
	if self.data == nil or self.data.num <= 0 then
		self:removePopView(self.view)
		return
	end

	self:setData()
end
function GoodInfoProcessor:onHideGoodsInfo()
	self:removePopView(self.view)
end
function GoodInfoProcessor:onGodHeCheng(data)
	local notices = {}
	local lastNum
	local name
	local eqid = data.data.eqid
	local info = data.data.info
	for k,v in pairs(data.data.bag) do
		lastNum = Bag:getGoodsById("I6001").num
		Bag:addGoods(k,v)
		name = DataConfig:getGoodByID(k).name
		table.insert(notices,{name..": -"..(lastNum - v),COLOR_RED})
		if(v == 0) then
			self:removePopView(self.view)
		else
			Observer.sendNotification(BagModule.UPDATE_GOODS_INFO)
		end
	end	
	if(eqid) then
		Bag:addEquip(eqid,info)
		local msg = DataConfig:getConfigMsgByID("30051")
		local lv = tonumber(string.sub(info.eid,4,6))
		name = DataConfig:getEquipById(info.eid).name
		table.insert(notices,{addArgsToMsg(msg,lv,name),COLOR_GREEN})
	end
	Observer.sendNotification(BagModule.UPDATE_BAG_GOODS) --数量更新
	Observer.sendNotification(BagModule.EQUIP_NUM_UPDATE) --数量更新
	popNotices(notices)
	local node = display.newNode()
	node.data = Bag:getEquipById(eqid)
	Observer.sendNotification(BagModule.SHOW_EQUIP_INFO, node)
end
function GoodInfoProcessor:onBossChallengeUse(data)
	--dump(data)
	BossPvpBattleManager:setBossChargeTimes(data.data.BOSS_count)
	--Bag:addGoods("I6002",data.data.bag["I6002"])
	local lastNum
	local name
	local notices = {}
	for k,v in pairs(data.data.bag) do
		lastNum = Bag:getGoodsById(k).num
		Bag:addGoods(k,v)
		name = DataConfig:getGoodByID(k).name
		if(self.view) then
			if(v == 0) then
				self:removePopView(self.view)
			else
				Observer.sendNotification(BagModule.UPDATE_GOODS_INFO)
			end
		end		
	end
	Observer.sendNotification(BagModule.UPDATE_BAG_GOODS) --数量更新
	table.insert(notices,{DataConfig:getConfigMsgByID("20023"),COLOR_GREEN})
	popNotices(notices)
end
return GoodInfoProcessor