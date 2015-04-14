-- 充值Render
local ItemFace = require("app.components.ItemFace")

local PayItem = class(PayItem, function()
	local node = ccui.Layout:create()
	cc(node):addComponent("components.behavior.EventProtocol"):exportMethods()
    return node
end)

PayItem.BUY_CLICK = "BUY_CLICK"

function PayItem:ctor()
	-- 背景
	if PayItem.skin == nil then
		PayItem.skin = ResourceManager:widgetFromJsonFile("ui/payitem.json")
		PayItem.skin:retain()
	end
	local bg = PayItem.skin:clone()
	
	self:setContentSize(bg:getContentSize())
	self.Imafirst = bg:getChildByName("Imafirst")
	self.lbPrice = bg:getChildByName("lbPrice")
	self.lbCoin = bg:getChildByName("lbCoin")
	self.lbAdd = bg:getChildByName("lbAdd")
	self.lbPrice:setString("")
	self.lbAdd:setString("")
	self.lbCoin:setString("")
	self.btnBuy = bg:getChildByName("btnBuy")
	self.btnBuy:addTouchEventListener(handler(self,self.buyClick))
	enableBtnOutLine(self.btnBuy,COMMON_BUTTONS.BLUE_BUTTON)
	
	local item = ItemFace.new()
	item.showInfo = false
	item.showlv = true
	item:setData(nil)
	item:setScale(0.7)
	item:setPosition(50,140)
	self.item = item
	self:addChild(bg)
	self:addChild(item)
end

--购买数据
--data  根据不同的数据 设置 不同的显示
function PayItem:setData(data)
	--dump(data)
	self.data = data
	local data1 = data[1]
	--self.index = data[3]  
	local cost = data1[1]     ---花费
	local send = data1[2]     ---额外赠送
	local coin = cost * 10   ---元宝
	local color = data1[5]    ---颜色值

	self.lbPrice:setString("￥"..cost)
	self.lbAdd:setString("额外赠送"..send)
	self.lbCoin:setString(""..coin)

	self.item:setPayData(color)

	local data2 = data[2]
	if data2 == nil then
		self.Imafirst:setVisible(true)
		
	else
		self.Imafirst:setVisible(false)
	end

end

--购买按钮点击
function PayItem:buyClick(sender,eventType)
	if  eventType ~= TouchEventType.ended then 
		return
	end

	local btns = {
		{text = "取消",skin = 2,},
		{text = "确定",skin = 1, callback = handler(self,self.btnBuyOK),args = true},
	}
	local alert = GameAlert.new()
	-- dump(self.data)
	alert:pop({{text = "确定要购买?"}},"ui/titlenotice.png", btns)
end

-- 购买按钮点击确认
function PayItem:btnBuyOK()
	--派发事件
	print("购买按钮点击")
	self:dispatchEvent({name = PayItem.BUY_CLICK, data = self.data})
end

return PayItem