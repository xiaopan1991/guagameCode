--
-- Author: Your Name
-- Date: 2015-01-23 10:55:21
--
--
-- Author: Your Name
-- Date: 2015-01-22 19:55:54
--
local MultiBattleOneResultCell = import(".ui.MultiBattleOneResultCell")
local MultiBattleOneResultProcessor = class("MultiBattleOneResultProcessor", BaseProcessor)
function MultiBattleOneResultProcessor:ctor()
end
function MultiBattleOneResultProcessor:ListNotification()
	return {
			MultiBattleModule.SHOW_MULTI_BATTLE_ONE_RESULT
    }
end
function MultiBattleOneResultProcessor:handleNotification(notify, data)
	if notify == MultiBattleModule.SHOW_MULTI_BATTLE_ONE_RESULT then
		self:initUI()
		self:setData(data.data,data.index)
	end
end
function MultiBattleOneResultProcessor:initUI()
	if(not self.view) then
		self.panel = ResourceManager:widgetFromJsonFile("ui/MultiBattleOneResult.json")
		self.closebtn = self.panel:getChildByName("closebtn")
		self.okbtn = self.panel:getChildByName("okbtn")
		self.scrollview = self.panel:getChildByName("scrollview")		
		self.resultsign = self.panel:getChildByName("resultsign")
		self:setView(self.panel)
		self:addPopView(self.view)
		self.closebtn:addTouchEventListener(handler(self,self.onClick))
		self.okbtn:addTouchEventListener(handler(self,self.onClick))
	end
end
function MultiBattleOneResultProcessor:initTitle(num)
	local bai = math.floor(num/100)
	local shi = math.floor((num - bai*100)/10)
	local ge = num - bai*100 - shi*10
	local node = display.newNode()
	local nums = {}
	table.insert(nums,display.newSprite("ui/titleword1.png"))
	if(bai > 0) then
		table.insert(nums, display.newSprite("ui/titlenum"..bai..".png"))
		table.insert(nums, display.newSprite("ui/titlenum100.png"))
	end
	if(shi > 0) then
		table.insert(nums, display.newSprite("ui/titlenum"..shi..".png"))
		table.insert(nums, display.newSprite("ui/titlenum10.png"))
	end
	if(ge > 0) then
		table.insert(nums, display.newSprite("ui/titlenum"..ge..".png"))
	end
	table.insert(nums,display.newSprite("ui/titleword2.png"))
	local allWidth = 0
	for i,v in ipairs(nums) do
		v:setAnchorPoint(cc.p(0,0.5))
		v:setPosition(allWidth,0)
		allWidth = allWidth + v:getContentSize().width
		node:addChild(v)
	end
	node:setPosition(320-allWidth/2,744)
	self.panel:addChild(node)
end
function MultiBattleOneResultProcessor:onClick(sender,eventType)
	if  eventType ~= TouchEventType.ended then 
		return
	end
	self:removePopView(self.view)
end
function MultiBattleOneResultProcessor:setData(data,index)
	self.data = data
	self.index = index	
	self.data1 = self.data.my_team
	self.data2 = self.data.rival_team
	local h = 103
	local w = 299
	local rowPadding = 10
	local leftPadding = 7
	local tlen = math.max(#self.data1,#self.data2)
	local innerWidth = self.scrollview:getInnerContainerSize().width
	self.minHeight = self.scrollview:getContentSize().height
	local itemsHeight = tlen * (h + rowPadding) + rowPadding
	self.innerHeight = math.max(itemsHeight,self.minHeight)
	self.scrollview:setInnerContainerSize(cc.size(innerWidth,self.innerHeight))

	--y起始坐标
	local ystart = self.innerHeight 

	local i = 1
	for k,v in ipairs(self.data1) do
		render = MultiBattleOneResultCell.new()
		render:setData(v,true,(v[1] == PlayerData:getUid()))
		render:setPosition(leftPadding ,ystart - i*(h + rowPadding))
		self.scrollview:addChild(render)
		i = i + 1
	end
	i = 1
	for k,v in ipairs(self.data2) do
		render = MultiBattleOneResultCell.new()
		render:setData(v,false)
		render:setPosition(leftPadding+w+3 ,ystart - i*(h + rowPadding))
		self.scrollview:addChild(render)
		i = i + 1
	end
	self.scrollview:setInnerContainerSize(cc.size(innerWidth,self.innerHeight))

	if(self.data.case == "lose_team") then
		self.resultsign:loadTexture("ui/multibattlefailure.png")
	else
		self.resultsign:loadTexture("ui/multibattlevictory.png")
	end
	self:initTitle(self.index)
end
return MultiBattleOneResultProcessor