-- 佣兵技能处理器
-- Author: wanghe
-- Date: 2014-11-14 10:42:36
--
local ChatPlayerItem = import(".ui.ChatPlayerItem")

local ChatPlayerProcessor = class("ChatPlayerProcessor",BaseProcessor)

function ChatPlayerProcessor:ListNotification()
	return {
		ChatModule.USER_CHAT_USER_INFO
	}
end

function ChatPlayerProcessor:handleNotification(notify, data)
	if notify == ChatModule.USER_CHAT_USER_INFO then
		self:initUI()
		self:setData(data)
	end
end

--初始化UI显示
function ChatPlayerProcessor:ctor()
end
function ChatPlayerProcessor:initUI()
	if self.view ~= nil then
		return
	end

	local view = ResourceManager:widgetFromJsonFile("ui/chatplayer.json")

	self.btnClose = view:getChildByName("btnClose")
	self.txtChat = view:getChildByName("txtChat")
	self.txtPrompt = view:getChildByName("txtPrompt")
	self.list = view:getChildByName("playerscrollview")

	self.list:setBounceEnabled(false)

	self.txtChat:enableOutline(cc.c4b(0,0,0,255), 2)
	self.txtPrompt:enableOutline(cc.c4b(0,0,0,255), 2)

	local cfg = DataConfig:getAllConfigMsg()
	self.txtChat:setString(cfg["20038"])
	self.txtPrompt:setString(cfg["20039"])

	self.btnClose:addTouchEventListener(handler(self,self.onBtnClick))

	self:setView(view)
	self:addPopView(view)
end

--设置数据
function ChatPlayerProcessor:setData(node)
	self.data = node.data

	self.list:removeAllChildren()

	-- for i = 1,31 do
	-- 	self.data.data[''..i] = {uid=i, name="玩家昵称", hero_type=i%3+1, lv=i}
	-- end

	local width = 140
	local height = 145

	local xstart = 18.75
	local ystart = 110

	local size = self.list:getInnerContainerSize()
	local newHeight = math.ceil(table.nums(self.data.data) / 4) * height
	if newHeight > size.height then
		size.height = newHeight
	end
	self.list:setInnerContainerSize(size)

	local i = 0
	for k,v in pairs(self.data.data) do
		local item = ChatPlayerItem.new()

		v.uid = k
		item:setData(v)
		item:setPosition(xstart + i % 4 * width, size.height - ystart - math.floor(i / 4) * height)
		-- print(xstart + i % 4 * width, size.height - ystart - math.floor(i / 4) * height)
		self.list:addChild(item)

		i = i + 1
	end

	self.list:jumpToTop()
end

function ChatPlayerProcessor:onBtnClick(sender,eventType)
	if eventType ~= TouchEventType.ended then
		return
	end

	local btnName = sender:getName()
	if btnName == "btnClose" then
		self:removePopView(self.view)
	end
end

return ChatPlayerProcessor