--批量卖出处理器
local LotSellProcessor = class("LotSellProcessor", BaseProcessor)

function LotSellProcessor:ListNotification()
	return {
		BagModule.SHOW_LOT_SELL,
		BagModule.USER_EQUIP_SELL
	}
end

function LotSellProcessor:handleNotification(notify, data)
	if notify == BagModule.SHOW_LOT_SELL then
		self:onSetView()
		self:onSetData()
	end 
end
--显示卖出界面
function LotSellProcessor:onSetView()
	if self.view ~= nil then
     	return
    end
    local lotSellPanel = ResourceManager:widgetFromJsonFile("ui/lotsellpanel.json")
	--出售按钮
	self.btnSell1 = lotSellPanel:getChildByName("btnSell1")
	self.btnSell2 = lotSellPanel:getChildByName("btnSell2")
	self.btnSell3 = lotSellPanel:getChildByName("btnSell3")
	self.btnSell4 = lotSellPanel:getChildByName("btnSell4")
	--装备数量文本
	self.txt1 = lotSellPanel:getChildByName("txt1")
	self.txt2 = lotSellPanel:getChildByName("txt2")
	self.txt3 = lotSellPanel:getChildByName("txt3")
	self.txt4 = lotSellPanel:getChildByName("txt4")
	
	self.btnSell1:addTouchEventListener(handler(self,self.onBtnClick))
	self.btnSell2:addTouchEventListener(handler(self,self.onBtnClick))
	self.btnSell3:addTouchEventListener(handler(self,self.onBtnClick))
	self.btnSell4:addTouchEventListener(handler(self,self.onBtnClick))

	local btnClose = lotSellPanel:getChildByName("btnClose")
	
	btnClose:addTouchEventListener(handler(self,self.onBtnClick))

	self:setView(lotSellPanel)
	self:addPopView(lotSellPanel)
end
--数据
function LotSellProcessor:onSetData(data)
	local equips = Bag:getAllEquip(nil,"bag")
	local data = {}
	data.eq1 = {}   --白
	data.eq2 = {}   --绿
	data.eq3 = {}   --蓝
	data.eq4 = {}   --紫
	for k,v in pairs(equips) do
		if v.color[1] == 0 then
			data.eq1[#data.eq1 + 1] = v
		elseif v.color[1] == 1 then
			data.eq2[#data.eq2 + 1] = v
		elseif v.color[1] == 2 then
			data.eq3[#data.eq3 + 1] = v
		elseif v.color[1] == 3 then
			data.eq4[#data.eq4 + 1] = v
		end
	end
	self.txt1:setString("白色装备*"..#data.eq1)
	self.txt2:setString("绿色装备*"..#data.eq2)
	self.txt3:setString("蓝色装备*"..#data.eq3)
	self.txt4:setString("紫色装备*"..#data.eq4)
	self.data1 = data
end
--按钮的点击事件
function LotSellProcessor:onBtnClick(sender,eventType)
	-- 触摸完毕再触发事件
	if  eventType ~= TouchEventType.ended then 
		return
	end
	local btn = tolua.cast(sender,"ccui.Button")
	local btnName = btn:getName()

	if btnName == "btnClose" then
		self:removePopView(self.view)
	elseif btnName == "btnSell1" then
		print(#self.data1.eq1)
		if #self.data1.eq1 == 0 then
			toastNotice("白色装备已经售完")
			return
		end
		self:sendLotSellData(self.data1.eq1)
	elseif btnName == "btnSell2" then
		if #self.data1.eq2 == 0 then
			toastNotice("绿色装备已经售完")
			return
		end
		self:sendLotSellData(self.data1.eq2)

	elseif btnName == "btnSell3" then
		if #self.data1.eq3 == 0 then
			toastNotice("蓝色装备已经售完")
			return
		end
		self:sendLotSellData(self.data1.eq3)

	elseif btnName == "btnSell4" then
		if #self.data1.eq4 == 0 then
			toastNotice("紫色装备已经售完")
			return
		end
	    self:sendLotSellData(self.data1.eq4)
	end
end
--发送批量卖出的消息
function LotSellProcessor:sendLotSellData(tables)
	local talSids = tables
	-- dump(talSids)
	local data = {}
	data.method = BagModule.USER_EQUIP_SELL
	data.params = {}
	data.params.eqids = {}
	for k,v in pairs(talSids) do
		--神器不能卖
		if #v.god == 0 then
			data.params.eqids[#data.params.eqids+1] = v.sid
		end
	end
	if #data.params.eqids ~= 0 then
		Net.sendhttp(data)
	end	
	self:removePopView(self.view)
end

return LotSellProcessor