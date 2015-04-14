--
-- Author: wanghe
-- Date: 2014-11-14 14:19:05
-- followerskillitem
local ChatPlayerItem = class("ChatPlayerItem", function ()
	local node = ccui.Layout:create()
	node:setContentSize(cc.size(100,100))
	cc(node):addComponent("components.behavior.EventProtocol"):exportMethods()
	return node
end)

ChatPlayerItem.skin = nil

function ChatPlayerItem:ctor()
	if ChatPlayerItem.skin == nil then
		ChatPlayerItem.skin = ResourceManager:widgetFromJsonFile("ui/chatplayeritem.json")
		ChatPlayerItem.skin:retain()
	end

	local view = ChatPlayerItem.skin:clone()
	self:addChild(view)
	self.view = view

	self.imgBg 	= view:getChildByName("imgBg")
	self.imgHead 	= view:getChildByName("imgHead")
	self.imgBorder 	= view:getChildByName("imgBorder")
	self.txtLv 		= view:getChildByName("txtLv")
	self.txtName 		= view:getChildByName("txtName")
	self.txtLv:enableOutline(cc.c4b(0,0,0,254), 2)
	self.txtName:enableOutline(cc.c4b(0,0,0,255), 2)

	self.view:setTouchEnabled(true)
	self.view:addTouchEventListener(handler(self,self.onTouch))
end


function ChatPlayerItem:onTouch(sender,eventType)
	if eventType ~= TouchEventType.ended then
		return
	end

	local net = {}
	net.method = BagModule.USER_GET_USER_INFO
	net.params = {}
	net.params.uid = self.data.uid
	Net.sendhttp(net)
end

function ChatPlayerItem:setData(data)
	self.data = data

	if self.data == nil then
		return
	end

	self.imgHead:loadTexture("ui/head/"..self.data.hero_type..".png")
	self.txtLv:setString("Lv "..self.data.lv)
	self.txtName:setString(self.data.name)
end

return ChatPlayerItem