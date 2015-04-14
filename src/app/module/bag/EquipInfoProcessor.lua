--装备信息面板处理器
--
local ItemFace = require("app.components.ItemFace")
local EquipAttrInfo = require("app.components.EquipAttrInfo")
local EquipInfoProcessor = class("EquipInfoProcessor", BaseProcessor)

function EquipInfoProcessor:ctor()
	-- body
end

function EquipInfoProcessor:ListNotification()
	return {
		BagModule.SHOW_EQUIP_INFO,
		BagModule.USER_EQUIP_SELL,
		BagModule.UPDATE_EQUIP_ATTR,
		-- BagModule.UPDATE_USER_TITLE,
	}
end

--消息处理
function EquipInfoProcessor:handleNotification(notify, data)
	if notify == BagModule.SHOW_EQUIP_INFO then
		self.data = data.data  --保存数据
		self.callback = data.callback
		self.params = data.params
		self.user = data.user

		self:initUI()
		self:setData()
	elseif notify == BagModule.USER_EQUIP_SELL then
		--卖出装备
		local bag = data.data.data.bag  --道具
		local eqids = data.data.data.eqids
		local gold = data.data.data.gold

		local notices = {}
		local sellNum = table.nums(eqids)
		table.insert(notices,{"卖出"..sellNum.."件装备",COLOR_RED})
		if bag ~= nil then
			for k,v in pairs(bag) do
				if(v > 0) then
					local last = 0
					if(Bag:getGoodsById(k)) then
						last = Bag:getGoodsById(k).num
					end
					Bag:addGoods(k,v+last)				
					table.insert(notices,{"获得"..DataConfig:getGoodByID(k).name.." "..v,COLOR_GREEN})
				end				
			end
		end

		if eqids ~= nil then
			Bag:removeEquips(eqids)
		end
		Observer.sendNotification(BagModule.UPDATE_EQUIP_ATTR) --数量更新
		local nowgold = PlayerData:getGold()
		table.insert(notices,{"获得银两:"..(gold-nowgold),COLOR_GREEN})
		popNotices(notices)
		PlayerData:setGold(gold)
	elseif notify == BagModule.UPDATE_EQUIP_ATTR then
		if self.view ~= nil and not tolua.isnull(self.view) then
			self.data = Bag:getEquipById(self.data.sid)
			self:setData()
		end
	end
end

--初始化UI
function EquipInfoProcessor:initUI()
	local view = ResourceManager:widgetFromJsonFile("ui/equipinfo.json") 
	local btnClose = view:getChildByName("btnClose")
	btnClose:addTouchEventListener(handler(self,self.onClose))
	--属性列表
	local attr = EquipAttrInfo.new()
	self.attr = attr
	-- attr:setData(data)
	attr:setPosition(420,620)
	view:addChild(attr)
	--装备格子
	local itemface = ItemFace.new()
	self.itemface = itemface
	itemface.showInfo = false --禁用鼠标事件
	
	itemface:setPosition(130 - 52,530)
	view:addChild(itemface)

	local btnQiangHua   = view:getChildByName("btnQiangHua")	--强化
	local btnXiLian     = view:getChildByName("btnXiLian")		--洗练
	local btnXieXia     = view:getChildByName("btnXieXia")		--卸下 or 卖出  在身上就是卸下 在背包里就是卖出
	local btnGengHuan   = view:getChildByName("btnGengHuan")	--更换
	local btnXiangQian  = view:getChildByName("btnXiangQian")  --镶嵌
	local btnTunShi     = view:getChildByName("btnTunShi")     --吞噬
	local btnChuanCheng = view:getChildByName("btnChuanCheng") --传承
	local btnSell 		= view:getChildByName("btnSell") 		--卖出
	
	local imgpos 		= view:getChildByName("imgpos")			--部位图片
	self.imgpos 		= imgpos

	btnQiangHua:addTouchEventListener(handler(self,self.onBtnClick))
	btnXiLian:addTouchEventListener(handler(self,self.onBtnClick))    
	btnXieXia:addTouchEventListener(handler(self,self.onBtnClick))    
	btnGengHuan:addTouchEventListener(handler(self,self.onBtnClick))  
	btnXiangQian:addTouchEventListener(handler(self,self.onBtnClick)) 
	btnTunShi:addTouchEventListener(handler(self,self.onBtnClick))    
	btnChuanCheng:addTouchEventListener(handler(self,self.onBtnClick))
	btnSell:addTouchEventListener(handler(self,self.onBtnClick))

	self.btnQiangHua = btnQiangHua
	self.btnXiangQian = btnXiangQian
	self.btnXieXia = btnXieXia
	self.btnXiLian = btnXiLian
	self.btnTunShi = btnTunShi
	self.btnChuanCheng = btnChuanCheng
	self.btnGengHuan = btnGengHuan
	self.btnSell = btnSell
	self:setView(view)
	self:addPopView(view)

end

--设置数据
function EquipInfoProcessor:setData(data)
	--处理卸下卖出按钮
	if self.data.pos == "body" or self.data.pos == "follower" then
		-- self.btnXieXia:setTitleText("卸下")
		self.btnSell:setEnabled(false)
		self.btnSell:setVisible(false)
	elseif self.data.pos == "bag" then
		self.btnXieXia:setEnabled(false)
		self.btnGengHuan:setEnabled(false)
		self.btnSell:setEnabled(true)
		self.btnXieXia:setVisible(false)
		self.btnGengHuan:setVisible(false)
		self.btnSell:setVisible(true)
	else
		self.btnXieXia:setEnabled(false)
		self.btnXieXia:setVisible(false)
	end

	if self.data.color[1] < 2 then
		self.btnXiLian:setEnabled(false)
		self.btnXiLian:setVisible(false)
	end

	if #self.data.god == 0 then
		self.btnTunShi:setEnabled(false)
		self.btnChuanCheng:setEnabled(false)
		self.btnTunShi:setVisible(false)
		self.btnChuanCheng:setVisible(false)
	end
	if(self.user == "OtherPlayerProcessor") then
		self.btnSell:setEnabled(false)
		self.btnXieXia:setEnabled(false)
		self.btnGengHuan:setEnabled(false)
		self.btnXiLian:setEnabled(false)
		self.btnTunShi:setEnabled(false)
		self.btnChuanCheng:setEnabled(false)
		self.btnQiangHua:setEnabled(false)
		self.btnXiangQian:setEnabled(false)

		self.btnSell:setVisible(false)
		self.btnXieXia:setVisible(false)
		self.btnGengHuan:setVisible(false)
		self.btnXiLian:setVisible(false)
		self.btnTunShi:setVisible(false)
		self.btnChuanCheng:setVisible(false)
		self.btnQiangHua:setVisible(false)
		self.btnXiangQian:setVisible(false)
	end

	local pos = string.sub(self.data.eid,3,3)
	self.imgpos:loadTexture("ui/e"..pos..".png")

	-- 检查玩家等级和装备等级 低于指定等级不显示镶嵌按钮
	local player_lv = PlayerData:getLv()
	local equip_lv = tonumber(string.sub(self.data.eid, 4, 6))
	local equip_hole = GameInstance.config.cfg.system_simple.equip_hole
	if player_lv < equip_hole.user_lv_limit or equip_lv < equip_hole.equip_lv_limit then
		self.btnXiangQian:setVisible(false)
		self.btnXiangQian:setEnabled(false)
	end

	-- 检查装备品质等级 蓝色及以上的装备才显示洗练按钮
	equip_quality = self.data.color[1]
	if equip_quality < EquipQuality.BLUE then
		self.btnXiLian:setVisible(false)
		self.btnXiLian:setEnabled(false)
	end
	local lv
	if(self.user == "OtherPlayerProcessor") then
		lv = self.module:getProcessorByName("OtherPlayerProcessor"):getImproveLv()
	end
	
	self.attr:setData(self.data,true,lv)
	self.itemface:setData(self.data)
	self.itemface:setPosition(130 - 52,530)
end

--关闭按钮点击
function EquipInfoProcessor:onClose(sender,eventType)
	if  eventType ~= TouchEventType.ended then 
		return
	end
	self:removePopView(self.view)
	self.view = nil
end

--按钮点击
function EquipInfoProcessor:onBtnClick(sender,eventType)
	if  eventType ~= TouchEventType.ended then 
		return
	end
	local btn = tolua.cast(sender,"ccui.Button")
	local btnName = btn:getName()

	print("touch equipinfo btn:"..btnName)

	if btnName == "btnQiangHua" then
		-- 强化
		local node = display.newNode()
		node.data = self.data
		Observer.sendNotification(BagModule.SHOW_EQUIP_QIANGHUA, node)
	elseif btnName == "btnXiLian" then
		-- 洗练
		local node = display.newNode()
		node.data = self.data
		Observer.sendNotification(BagModule.SHOW_EQUIP_XILIAN, node)
	elseif btnName == "btnXieXia" then
		if self.data.pos == "body" or self.data.pos == "follower" then	
			self.callback(self.data)
		elseif self.data.pos == "bag" then			
			
		end
		--卸下 
	elseif btnName == "btnSell" then
		-- 卖出
		if #self.data.god >= 3 then
			toastNotice("神器不能出售！")
			return
		end
		if self.data.dimnum > 0 then
			toastNotice("镶嵌宝石的装备不能出售！")
			return
		end
		self:sellEquip()
	elseif btnName == "btnGengHuan" then
		--更换
		local node = display.newNode()
		node.data = self.data
		node.callback = self.callback
		node.type = "button" --单选类型 条子上显示按钮
		node.params = self.params
		node.user = self.user
		
		Observer.sendNotification(BagModule.SHOW_COMMON_EQUIP_SELECT, node)
	elseif btnName == "btnXiangQian" then
		--镶嵌
		local node = display.newNode()
		node.data = self.data
		Observer.sendNotification(BagModule.SHOW_EQUIP_XIANGQIAN,node)
	elseif btnName == "btnTunShi" then
		--吞噬
		local node = display.newNode()
		self.data = Bag:getEquipById(self.data.sid)
		node.data = self.data
		Observer.sendNotification(BagModule.SHOW_TUN_SHI,node)
	elseif btnName == "btnChuanCheng" then
		--传承
		local node = display.newNode()
		node.data = self.data
		Observer.sendNotification(BagModule.SHOW_CHUAN_CHENG, node)
	end
end

--卖出道具
function EquipInfoProcessor:sellEquip()
	local net = {}
	net.method = BagModule.USER_EQUIP_SELL
	net.params = {}
	net.params.eqids = {self.data.sid}
	print("卖出道具"..self.data.sid)
	Net.sendhttp(net)

	self:removePopView(self.view)
end




return EquipInfoProcessor