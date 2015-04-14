local PayInfoProcessor = class("PayInfoProcessor", BaseProcessor)
local ItemFace = require("app.components.ItemFace")
local EquipAttrInfo = require("app.components.EquipAttrInfo")
local XRichText = require("app.components.XRichText")

function PayInfoProcessor:ctor()
	-- body
end

function PayInfoProcessor:ListNotification()
	return {
		ShopModule.SHOW_PAY_INFO
	}
end

--消息处理
function PayInfoProcessor:handleNotification(notify, node)
	if notify == ShopModule.SHOW_PAY_INFO then
		self.data = node.data
		self:initUI()
		self:setData()
	end
end
function PayInfoProcessor:initUI()
	local payInfo = ResourceManager:widgetFromJsonFile("ui/payInfo.json")

	self.payInfo = payInfo
	self.txtTitle = payInfo:getChildByName("txtTitle")
	self.txtName = payInfo:getChildByName("txtName")
	self.bg = payInfo:getChildByName("bg")
	
	local btnClose = payInfo:getChildByName("btnClose")
	local btnBuy = payInfo:getChildByName("btnBuy")
	
	--装备格子
	self.itemface = ItemFace.new()
	self.itemface.showInfo = false --禁用鼠标事件
	self.itemface:setPosition(70,168)
	self.payInfo:addChild(self.itemface)
	-- 按钮事件
	btnClose:addTouchEventListener(handler(self,self.onBtnClick))
	btnBuy:addTouchEventListener(handler(self,self.onBtnClick))
	self:setView(payInfo)
	self:addPopView(payInfo)
end
function PayInfoProcessor:setData()
	--dump(self.data)
    
	local richtext = XRichText.new()
	self.richtext = richtext
	self.richtext:setContentSize(cc.size(300,180))
	self.richtext:setPosition(380,185)
	self.payInfo:addChild(self.richtext)
	--区分类型 是装备还是道具 
	if string.sub(self.data.eid,1,1) == "E" then
		--self.txtTitle:setString("装备简介")
		self.txtTitle:loadTexture("ui/titleequipintro.png")

		
		local name = self.data.edata.name
		local lv = tonumber(string.sub(self.data.eid,4,6))
		local numcolor = self.data.color[1]
		local c3 = Bag:getEquipColor(numcolor)
		local namestr = "Lv"..lv.." "..name
		self:appendStr(namestr,22,c3)

		--职业限制
		local player_type = string.sub(self.data.eid,2,2)
		if player_type == "0" then
			self:appendStr("只有武当可以装备",18,cc.c3b(255,245,135))
		elseif player_type == "1" then
			self:appendStr("只有丐帮可以装备",18,cc.c3b(255,245,135))
		elseif player_type == "2" then
			self:appendStr("只有峨眉可以装备",18,cc.c3b(255,245,135))
		end

		local equipData = DataConfig:getEquipById(self.data.id_type)
		local info,msg = Bag:getEquipAttrName(self.data.edata)
		local str = ""
		if info == "dam" then
			str = msg..":"..equipData.dam[1].."~"..equipData.dam[2]
		elseif info ~= nil then
			str = msg..":"..equipData[info]
		end
        if str ~= "" then
		    self:appendStr(str,18,cc.c3b(255,255,255))
        end

		local num = 0
		if numcolor == 4 then
		 	num = 4
		elseif numcolor == 3 then
		 	num = 3
		elseif numcolor == 2 then
		 	num = 2	
		end 
		local mstr = "随机"..num.."个副属性"
		self:appendStr(mstr,18,cc.c3b(209,47,255))
	else
		--self.txtTitle:setString("道具简介")
		self.txtTitle:loadTexture("ui/titlegoodintro.png")
		--说明
		self:appendStr(self.data.edata.info,22,cc.c3b(255,255,255))
	end
	--名称
	self.txtName:setString(self.data.edata.name)
	--数据
	self.itemface:setData(self.data)
end
--追加文本
function PayInfoProcessor:appendStr(txt,fontsize,color)
	self.richtext:appendStr(txt.."\n",color,fontsize)
end

function PayInfoProcessor:onBtnClick(sender, eventType)
	if eventType ~= TouchEventType.ended then
		return true
	end
	local btnName = sender:getName()
	if btnName == "btnBuy" then
		local node = display.newNode()
		node.data = self.data
		Observer.sendNotification(ShopModule.SHOW_BUY_GOODS, node)
		--啰嗦了
		self:removePopView(self.view)
	elseif btnName == "btnClose" then
		self:removePopView(self.view)
	end
end
return PayInfoProcessor