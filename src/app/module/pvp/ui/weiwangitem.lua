-- 威望商店显示Item
-- Author: wanghe
-- Date: 2014-12-16 11:28:13
--
local ItemFace = require("app.components.ItemFace")
local weiwangitem = class("weiwangitem", function()
		local node = ccui.Layout:create()
		node:setContentSize(cc.size(172,204))
		cc(node):addComponent("components.behavior.EventProtocol"):exportMethods()
		return node
	end)

weiwangitem.BUY_CLICK = "weiwangitem.BUY_CLICK"

function weiwangitem:ctor()
	self:initUI()
end

function weiwangitem:initUI()
	if weiwangitem.skin == nil then
		weiwangitem.skin = ResourceManager:widgetFromJsonFile("ui/weiwangitem.json")
		weiwangitem.skin:retain()
	end
	local view = weiwangitem.skin:clone()
	
	local txtName 	= 	view:getChildByName("txtName")
	local lbPrice 	= 	view:getChildByName("lbPrice")
	local btnBuy 	= 	view:getChildByName("btnBuy")

	btnBuy:addTouchEventListener(handler(self,self.onBtnClick))
	self:addChild(view)

	local item = ItemFace.new()
	item.showInfo = false
	item:setData(nil)
	item:setScale(0.9)
	item:setPosition(40,105)
	self:addChild(item,3)

	self.item = item
	self.lbPrice = lbPrice
	self.txtName = txtName
	self.btnBuy = btnBuy
end

function weiwangitem:setData(data)
	self.data = data

	local id 		= data.id_type
	local issell 	= data.is_sell
	local price 	= data.price

	local gdata = {}	
	gdata.eid = id
	gdata.edata = DataConfig:getGoodByID(id)

	self.item:setData(gdata)
	self.lbPrice:setString(price)
	self.txtName:setString(gdata.edata.name)
	if issell then
		self.btnBuy:setTouchEnabled(false)
		self:setTouchEnabled(false)

		local sellimage = ccui.ImageView:create("ui/sellout.png")
		self:addChild(sellimage,3)
		sellimage:setPosition(90,100)
	end
end

--
function weiwangitem:onBtnClick(sender, eventType)
	if eventType ~= TouchEventType.ended then
		return
	end
	self:dispatchEvent({name = weiwangitem.BUY_CLICK,data = self.data})
end

return weiwangitem