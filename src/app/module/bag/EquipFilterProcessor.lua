--背包界面的装备筛选
local  EquipFilterProcessor = class("EquipFilterProcessor",BaseProcessor)

function EquipFilterProcessor:ctor()
	-- body
	self.isshow = false
end

function EquipFilterProcessor:ListNotification()
	return {
		BagModule.SHOW_EQUIP_FILTER
	}
end

function EquipFilterProcessor:handleNotification(notify, data)
	if notify == BagModule.SHOW_EQUIP_FILTER then
		self.data = data.data
		self:initUI()
		self:setData()
	end
end

--初始化UI显示
-- arg  预留 没用
function EquipFilterProcessor:initUI(arg)
	print("self.isshow"..tostring(self.isshow))
	if self.view ~= nil and self.isshow == true then
		return
	end

	local view = ResourceManager:widgetFromJsonFile("ui/equipshai.json")
	-- 武器，衣服，马，护腿，腰带，鞋，戒指，护手，头，饰品
	self.btn0 = view:getChildByName("btn0")	--武器
	self.btn1 = view:getChildByName("btn1")	--衣服
	self.btn2 = view:getChildByName("btn2")	--马
	self.btn3 = view:getChildByName("btn3")	--护腿
	self.btn4 = view:getChildByName("btn4")	--腰带
	self.btn5 = view:getChildByName("btn5")	--鞋
	self.btn6 = view:getChildByName("btn6")	--戒指
	self.btn7 = view:getChildByName("btn7")	--护手
	self.btn8 = view:getChildByName("btn8")	--头
	self.btn9 = view:getChildByName("btn9")	--饰品
	for i=0,9 do
		enableBtnOutLine(self["btn"..i],COMMON_BUTTONS.BLUE_BUTTON)
	end



	self.btnc0 = view:getChildByName("btnc0")	--白
	self.btnc0:getTitleRenderer():enableOutline(cc.c4b(60,92,156,255),2)
	self.btnc1 = view:getChildByName("btnc1")	--绿
	self.btnc1:getTitleRenderer():enableOutline(cc.c4b(43,87,43,255),2)
	self.btnc2 = view:getChildByName("btnc2")	--蓝
	self.btnc2:getTitleRenderer():enableOutline(cc.c4b(60,92,156,255),2)
	self.btnc3 = view:getChildByName("btnc3")	--紫
	self.btnc3:getTitleRenderer():enableOutline(cc.c4b(75,40,72,255),2)
	self.btnc4 = view:getChildByName("btnc4")	--橙
	self.btnc4:getTitleRenderer():enableOutline(cc.c4b(73,56,40,255),2)
	self.btnc5 = view:getChildByName("btnc5")	--神器
	self.btnc5:getTitleRenderer():enableOutline(cc.c4b(73,56,40,255),2)

	self.btnAll = view:getChildByName("btnAll")	--所有
	self.btnAll:getTitleRenderer():enableOutline(cc.c4b(60,92,156,255),2)
	local btnClose = view:getChildByName("btnClose")--关闭

	self.btn0:addTouchEventListener(handler(self,self.onBtnClick))
	self.btn1:addTouchEventListener(handler(self,self.onBtnClick))
	self.btn2:addTouchEventListener(handler(self,self.onBtnClick))
	self.btn3:addTouchEventListener(handler(self,self.onBtnClick))
	self.btn4:addTouchEventListener(handler(self,self.onBtnClick))
	self.btn5:addTouchEventListener(handler(self,self.onBtnClick))
	self.btn6:addTouchEventListener(handler(self,self.onBtnClick))
	self.btn7:addTouchEventListener(handler(self,self.onBtnClick))
	self.btn8:addTouchEventListener(handler(self,self.onBtnClick))
	self.btn9:addTouchEventListener(handler(self,self.onBtnClick))

	self.btnc0:addTouchEventListener(handler(self,self.onBtnClick))
	self.btnc1:addTouchEventListener(handler(self,self.onBtnClick))
	self.btnc2:addTouchEventListener(handler(self,self.onBtnClick))
	self.btnc3:addTouchEventListener(handler(self,self.onBtnClick))
	self.btnc4:addTouchEventListener(handler(self,self.onBtnClick))
	self.btnc5:addTouchEventListener(handler(self,self.onBtnClick))


	self.btnAll:addTouchEventListener(handler(self,self.onBtnClick))
	btnClose:addTouchEventListener(handler(self,self.onBtnClick))

	self:setView(view)
	self:addPopView(view)
end



--按钮点击
function EquipFilterProcessor:onBtnClick(sender, eventType)
	if eventType ~= TouchEventType.ended then
		return
	end
	local text = "装备筛选"
	local btnName = sender:getName()
	local etype = ""  -- pos or color or all
	local evalue = ""
	if #btnName == 4 then
		etype = "pos"
		evalue = string.sub(btnName,4,4)
		text = sender:getTitleText()
	elseif #btnName == 5 then
		etype = "color"
		evalue = string.sub(btnName,5,5)
		text = sender:getTitleText()
	elseif btnName == "btnAll" then
		etype = "all"
	elseif btnName == "btnClose" then
		self:removePopView(self.view)
		return
	end

	self:removePopView(self.view)

	if self.data ~= nil and self.data.callback ~=nil then
		self.data.callback(etype,evalue,text)
	end
end

--设置数据
function EquipFilterProcessor:setData(data)
	local data = {}
	data.pos0 = 0
	data.pos1 = 0
	data.pos2 = 0
	data.pos3 = 0
	data.pos4 = 0
	data.pos5 = 0
	data.pos6 = 0
	data.pos7 = 0
	data.pos8 = 0
	data.pos9 = 0

	data.color0	= 0 
	data.color1	= 0 
	data.color2	= 0 
	data.color3	= 0 
	data.color4	= 0 
	data.color5	= 0
	
	local equips = Bag:getAllEquip(nil,"bag")
	local pos = 0
	local color = 0
	local count = 0
	for k,v in pairs(equips) do
		pos = string.sub(v.eid,3,3)
		color = v.color[1]
		data["pos"..pos] = data["pos"..pos] + 1
		data["color"..color] = data["color"..color] + 1
		if(#v.god > 0) then
			data.color5 = data.color5 + 1
		end
		count = count+1
	end

	self.btn0:setTitleText("武器*"..data.pos0)	--武器
	self.btn1:setTitleText("衣服*"..data.pos1)	--衣服
	self.btn2:setTitleText("马*"..data.pos2)		--马
	self.btn3:setTitleText("护腿*"..data.pos3)	--护腿
	self.btn4:setTitleText("腰带*"..data.pos4)	--腰带
	self.btn5:setTitleText("鞋*"..data.pos5)		--鞋
	self.btn6:setTitleText("戒指*"..data.pos6)	--戒指
	self.btn7:setTitleText("护手*"..data.pos7)	--护手
	self.btn8:setTitleText("头*"..data.pos8)		--头
	self.btn9:setTitleText("饰品*"..data.pos9)	--饰品

	self.btnc0:setTitleText("白色装备*"..data.color0)	--白
	self.btnc1:setTitleText("绿色装备*"..data.color1)	--绿
	self.btnc2:setTitleText("蓝色装备*"..data.color2)	--蓝
	self.btnc3:setTitleText("紫色装备*"..data.color3)	--紫
	self.btnc4:setTitleText("橙色装备*"..data.color4)	--橙
	self.btnc5:setTitleText("神器*"..data.color5)		--神器

	self.btnAll:setTitleText("全部*"..count)		--神器
end

function EquipFilterProcessor:onHideView(view)
	if self.view ~= nil then
		self.view:retain()
		self.view:removeFromParent(false)
	end
end

return EquipFilterProcessor
