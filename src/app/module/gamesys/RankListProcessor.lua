local RankItem = import(".ui.RankItem")
local RankListItem = import(".ui.RankListItem")
local RankListProcessor = class("RankListProcessor", BaseProcessor)

function RankListProcessor:ctor()
	-- body
end

function RankListProcessor:ListNotification()
	return {
		GamesysModule.USER_GET_RANK_ALL_LIST,
	}
end

function RankListProcessor:handleNotification(notify, data)
	if notify == GamesysModule.USER_GET_RANK_ALL_LIST then
		self:initView()
		self.datatype = data.data.params._type
		self:setData(data.data.data)
	end
end
function RankListProcessor:initView()
	if self.view ~= nil then
		return
	end

 	local panel = ResourceManager:widgetFromJsonFile("ui/ranklist.json")
	self.imgTitleBg = panel:getChildByName("imgTitleBg")
	self.imgTitle = panel:getChildByName("imgTitle")
	self.imgBg = panel:getChildByName("imgBg")
	self.txtPrompt = panel:getChildByName("txtPrompt")
	self.scrollView = panel:getChildByName("scrollView")
	self.btnClose = panel:getChildByName("btnClose")
	
	self.btnClose:addTouchEventListener(handler(self, self.onClick))

	self:setView(panel)
	self:addPopView(panel)
end
--数据
function RankListProcessor:setData(data)
	-- dump(data)
	self.data = data

	local cfg = DataConfig:getAllConfigMsg()
	local typedata = RankItem.typeData[self.datatype]
	self.imgTitle:loadTexture(typedata.top_img)
	self.txtPrompt:setString(cfg[typedata.info])

	self.scrollView:removeAllChildren() -- 清空内容

	local itemWidth   = 600 -- item宽度
	local itemHeight  = 125 -- item高度
	local itemPadding = 10  -- item间距
	local itemCount = table.nums(self.data)	-- item数量

	-- 设置滚动条内容区域大小
	self.scrollView:setInnerContainerSize(cc.size(self.scrollView:getContentSize().width, (itemHeight + itemPadding) * itemCount - itemPadding))

	local x = (self.scrollView:getInnerContainerSize().width - itemWidth)/2 -- item x坐标
	local ystart = self.scrollView:getInnerContainerSize().height -- item y坐标

	local item = nil
	for i, v in ipairs(data) do
		item = RankListItem.new()
		item:setDataType(self.datatype)
		item:setData(v)
		item:setPosition(x, ystart - (itemHeight + itemPadding) * i + itemPadding)
		self.scrollView:addChild(item)
	end

	self.scrollView:jumpToTop()
end
--按钮事件的处理
function RankListProcessor:onClick(sender,eventType)
	if  eventType ~= TouchEventType.ended then
		return
	end

	local btn = tolua.cast(sender,"ccui.Button")
	local btnName = btn:getName()

	if btnName == "btnClose" then
		self:removePopView(self.view)
	end
end
--移除界面
function RankListProcessor:onHideView(view)
	if self.view ~= nill then
		self.view:removeFromParent(true)
		self.view = nil
	end
end
return RankListProcessor