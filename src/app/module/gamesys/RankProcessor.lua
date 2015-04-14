local RankItem = import(".ui.RankItem")
local RankProcessor = class("RankProcessor", BaseProcessor)

function RankProcessor:ctor()
	-- body
end

function RankProcessor:ListNotification()
	return {
		GamesysModule.USER_FIRST_RANK,
	}
end

function RankProcessor:handleNotification(notify, data)
	if notify == GamesysModule.USER_FIRST_RANK then
		self:initView()
		self:setData(data.data.data)
	end
end
function RankProcessor:initView()
	if self.view ~= nil then
		return
	end

 	local panel = ResourceManager:widgetFromJsonFile("ui/rank.json")
	self.imgTitleBg = panel:getChildByName("imgTitleBg")
	self.imgTitle = panel:getChildByName("imgTitle")
	self.imgBg = panel:getChildByName("imgBg")
	self.imgPrompt = panel:getChildByName("imgPrompt")
	self.txtPrompt = panel:getChildByName("txtPrompt")
	self.scrollView = panel:getChildByName("scrollView")
	self.btnClose = panel:getChildByName("btnClose")
	
	self.btnClose:addTouchEventListener(handler(self, self.onClick))

	self:setView(panel)
	self:addMidView(panel, true)
end
--数据
function RankProcessor:setData(data)
	-- dump(data)
	self.data = data

	local cfg = DataConfig:getAllConfigMsg()
	self.txtPrompt:setString(addArgsToMsg(cfg["20075"]))

	self.scrollView:removeAllChildren() -- 清空内容

	local itemWidth   = 610 -- item宽度
	local itemHeight  = 140 -- item高度
	local itemPadding = 10  -- item间距
	local itemCount = table.nums(self.data)	-- item数量

	-- 设置滚动条内容区域大小
	self.scrollView:setInnerContainerSize(cc.size(self.scrollView:getContentSize().width, (itemHeight + itemPadding) * itemCount - itemPadding))

	local x = (self.scrollView:getInnerContainerSize().width - itemWidth)/2 -- item x坐标
	local ystart = self.scrollView:getInnerContainerSize().height -- item y坐标

	-- 排序
	local sortdata = {}
	for i, t in ipairs(RankItem.typeSort) do
		for j, v in ipairs(data) do
			if v.type == t then
				sortdata[#sortdata + 1] = v
			end
		end
	end

	local item = nil
	for i, v in ipairs(sortdata) do
		item = RankItem.new()
		item:setData(v)
		item:setPosition(x, ystart - (itemHeight + itemPadding) * i + itemPadding)
		self.scrollView:addChild(item)
	end

	self.scrollView:jumpToTop()
end
--按钮事件的处理
function RankProcessor:onClick(sender,eventType)
	if  eventType ~= TouchEventType.ended then
		return
	end

	local btn = tolua.cast(sender,"ccui.Button")
	local btnName = btn:getName()

	if btnName == "btnClose" then
		Observer.sendNotification(IndexModule.SHOW_INDEX, nil)
	end
end
--移除界面
function RankProcessor:onHideView(view)
	if self.view ~= nill then
		self.view:removeFromParent(true)
		self.view = nil
	end
end
return RankProcessor