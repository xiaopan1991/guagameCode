-- 商店商品Render
-- Author: whe
-- Date: 2014-07-26 11:39:21
local ItemFace = require("app.components.ItemFace")

local GoodsItem = class(GoodsItem, function()
	local node = ccui.Layout:create()
	cc(node):addComponent("components.behavior.EventProtocol"):exportMethods()
    return node
end)

GoodsItem.BUY_CLICK = "BUY_CLICK"

function GoodsItem:ctor()
	-- 背景
	local bg = nil
	if GoodsItem.bgcls ~= nil then
		bg = GoodsItem.bgcls:clone()
	else 
		bg = ResourceManager:widgetFromJsonFile("ui/goodsitem.json")
		GoodsItem.bgcls = bg:clone()
		GoodsItem.bgcls:retain()
	end

	self:setContentSize(bg:getContentSize())
	self.txtName = bg:getChildByName("txtName")
	self.lbPrice = bg:getChildByName("lbPrice")
	self.btnBuy = bg:getChildByName("btnBuy")
	self.imgMoneyType = bg:getChildByName("imgMoneyType")
	self.btnBuy:addTouchEventListener(handler(self,self.buyClick))
	enableBtnOutLine(self.btnBuy,COMMON_BUTTONS.BLUE_BUTTON)
	

	local item = ItemFace.new()
	item.showInfo = false
	item.showlv = true
	item:setData(nil)
	item:setScale(0.7)
	item:setTouchEnabled(true)
	item:addTouchEventListener(handler(self,self.itemClick))
	item:setPosition(50,116)
	self.item = item
	self:addChild(bg)
	self:addChild(item)
end

--商品数据
--data  根据不同的数据 设置 不同的显示
function GoodsItem:setData(data)
	self.data = data
	--dump(data)
	self.txtName:setString(data.edata.name.."*"..data.item_num)
	local c3 = Bag:getEquipColor(data.color[1])
	if c3 ~= nil then
		self.txtName:setColor(c3)
	end
	self.item:setData(data)
	self.item:setTouchEnabled(true)
	if data.is_sell == true then
		self.item:setTouchEnabled(false)
		self.btnBuy:setTouchEnabled(false)
		self:setTouchEnabled(false)
		--售罄图标
		local sellimage = ccui.ImageView:create("ui/sellout.png")
		self:addChild(sellimage)
		sellimage:setPosition(90,100)
	end
	--价格
	self.lbPrice:setString(tostring(data.price))

	if data.sell_type == "coin" then
		self.imgMoneyType:loadTexture("ui/gold.png")
	elseif data.sell_type == "gold" then
		self.imgMoneyType:loadTexture("ui/yinliang.png")
	end
	--折扣
	local discount = data.discount
	local imagepath = ""
	if discount ~= nil then
		if discount == 0.1 then
			imagepath = "ui/discount1.png"
		elseif discount == 0.2 then
			imagepath = "ui/discount2.png"
		elseif discount == 0.5 then
			imagepath = "ui/discount5.png"
		elseif discount == 0.8 then
			imagepath = "ui/discount8.png"
		end

		if imagepath~= "" then
			local disimage = ccui.ImageView:create(imagepath)
			self:addChild(disimage)
			disimage:setPosition(42,167)
		end
	end
end

--购买按钮点击
function GoodsItem:buyClick(sender,eventType)
	if  eventType ~= TouchEventType.ended then 
		return
	end
	--派发事件
	print("购买商品按钮点击")
	self:dispatchEvent({name =  GoodsItem.BUY_CLICK, data = self.data})
end
--item点击
function GoodsItem:itemClick(sender,eventType)
	if eventType ~= TouchEventType.ended then
		return true
	end
	local node = display.newNode()
	node.data = self.data
	Observer.sendNotification(ShopModule.SHOW_PAY_INFO,node)
end

return GoodsItem