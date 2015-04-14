--
-- Author: Your Name
-- Date: 2015-01-22 19:55:54
--
local MultiBattleResultCell = import(".ui.MultiBattleResultCell")
local MultiBattleResultProcessor = class("MultiBattleResultProcessor", BaseProcessor)
function MultiBattleResultProcessor:ctor()
end
function MultiBattleResultProcessor:ListNotification()
	return {
			MultiBattleModule.SHOW_MULTI_BATTLE_RESULT
    }
end
function MultiBattleResultProcessor:handleNotification(notify, data)
	if notify == MultiBattleModule.SHOW_MULTI_BATTLE_RESULT then
		self:initUI()
		self:setData(data.data)
	end
end
function MultiBattleResultProcessor:initUI()
	if(not self.view) then
		self.panel = ResourceManager:widgetFromJsonFile("ui/MultiBattleResult.json")
		self.closebtn = self.panel:getChildByName("closebtn")
		self.scrollview = self.panel:getChildByName("scrollview")
		self:setView(self.panel)
		self:addPopView(self.view)
		self.closebtn:addTouchEventListener(handler(self,self.onClick))
	end
end
function MultiBattleResultProcessor:setData(data)
	self.data = data
	local h = 125
	local w = 594
	local rowPadding = 10
	local leftPadding = (self.scrollview:getContentSize().width - w)/2
	local tlen = #self.data
	local innerWidth = self.scrollview:getInnerContainerSize().width
	self.minHeight = self.scrollview:getContentSize().height
	local itemsHeight = tlen * (h + rowPadding) + rowPadding
	self.innerHeight = math.max(itemsHeight,self.minHeight)
	self.scrollview:setInnerContainerSize(cc.size(innerWidth,self.innerHeight))

	--y起始坐标
	local ystart = self.innerHeight 

	local i = 1
	for k,v in ipairs(self.data) do
		render = MultiBattleResultCell.new()
		render:setData(k,v)
		render:setPosition(leftPadding ,ystart - i*(h + rowPadding))
		self.scrollview:addChild(render)
		i = i + 1
	end
	self.scrollview:setInnerContainerSize(cc.size(innerWidth,self.innerHeight))
end
function MultiBattleResultProcessor:onClick(sender,eventType)
	if  eventType ~= TouchEventType.ended then 
		return
	end
	self:removePopView(self.view)
end
return MultiBattleResultProcessor