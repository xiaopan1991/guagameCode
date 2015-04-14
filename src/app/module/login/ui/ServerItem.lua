-- 服务器条子
-- Author: whe
-- Date: 2014-10-31 10:45:50

local ServerItem = class("ServerItem",function()
	local node = ccui.Layout:create()
	node:setContentSize(cc.size(332,37))
	cc(node):addComponent("components.behavior.EventProtocol"):exportMethods()
	-- node:setTouchEnabled(true)
	return node
	end)

--选择分区点击
ServerItem.ZONE_CLICK = "ZONE_CLICK"

function ServerItem:ctor()
	self.data = nil
end

function ServerItem:setData(data)
	self.data = data
	local view = nil
	if ServerItem.view == nil then
		ServerItem.view = ResourceManager:widgetFromJsonFile("ui/serveritem.json")
		ServerItem.view:retain()
	end



	view = ServerItem.view:clone()
	local lbZone = view:getChildByName("lbZone")
	self:addChild(view)
	lbZone:setString(data[1].cn)
	view:addTouchEventListener(handler(self,self.handleItemClick))
end

function ServerItem:handleItemClick(sender,eventType)
	if eventType ~= TouchEventType.ended then
		return
	end
	self:dispatchEvent({name = ServerItem.ZONE_CLICK, data = self.data})
end


return ServerItem