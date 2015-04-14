--更改称号处理
local ChangeTitleNameProcessor = class("ChangeTitleNameProcessor",BaseProcessor)
local NameItem = import(".ui.NameItem")

function ChangeTitleNameProcessor:ctor()
		
end

function ChangeTitleNameProcessor:ListNotification()
	return {
		GamesysModule.SHOW_CHANGE_TITLE_NAME,
		GamesysModule.USER_CHANGE_TITLE,
		GamesysModule.UPDATE_USER_TITLES,
	}
end

function ChangeTitleNameProcessor:handleNotification(notify, data)
	if notify == GamesysModule.SHOW_CHANGE_TITLE_NAME then
		self:initUI()
		self:setData()
	elseif notify == GamesysModule.USER_CHANGE_TITLE then
		self:onTitleChangeDone(data)
	-- elseif notify == GamesysModule.UPDATE_USER_TITLES then
	-- 	self:initUI()
	-- 	self:updateUI(data)
	-- 	self:setData()
	end
end
--初始化UI显示
-- arg  预留 没用
function ChangeTitleNameProcessor:initUI(arg)
	if self.view ~= nil then
		return
	end

	local view = ResourceManager:widgetFromJsonFile("ui/changetitlename.json")
	self.scrollView = view:getChildByName("ScrollView")
	self.txtInfo = view:getChildByName("txtInfo")
	--self.txtInfo:setString("")

	local btnCancle = view:getChildByName("btnCancle")                --取消
	local btnKeep = view:getChildByName("btnKeep")                    --保持
	local btnClose = view:getChildByName("btnClose")                  --关闭
	
	enableBtnOutLine(btnKeep,COMMON_BUTTONS.ORANGE_BUTTON)
	
	local title = btnKeep:getTitleText()
	btnKeep:setTitleText('')
	btnKeep:setTitleText(title)

	btnCancle:addTouchEventListener(handler(self,self.onBtnClick))
	btnKeep:addTouchEventListener(handler(self,self.onBtnClick))
	btnClose:addTouchEventListener(handler(self,self.onBtnClick))
	
	self.btnKeep = btnKeep
	self.btnCancle = btnCancle


	self:addPopView(view) 
	self:setView(view)
end
--设置数据
function ChangeTitleNameProcessor:setData()
	-- 玩家现在使用的称号
	local player_title = PlayerData:getTitle()
	-- 玩家拥有的所有称号
	local player_titles =  PlayerData:getTitles()
	-- 系统内所有的称号
	-- local titles = DataConfig:getAllTitles()
	local title_map = DataConfig:getAllTitles()

	-- -- 模拟数据
	-- player_title = "equip_color_4"
	-- player_titles = {"equip_color_4", "pvp_rank_10", "pvp_rank_100", "pvp_rank_20"}
	-- -- 模拟数据 end

	-- 用于检查用户是否获得了称号
	local player_titles_map = {}
	for _, player_usable_title in ipairs(player_titles) do
		player_titles_map[player_usable_title] = true
	end

	-- 将键值对转换为数组用于排序 并检查称号是否拥有 和是否使用
	local titles = {}
	for title_no, title in pairs(title_map) do
		title.no = title_no
		title.usable = player_titles_map[title.no] or false
		title.use = player_title == title.no
		title.order = title.color
		if title.usable then
			title.order = title.order + 10
		end
		titles[#titles+1] = title
	end

	-- 排序
	table.sort(titles, function(a, b)return a.order > b.order end)
	self.txtInfo:setString(string.format("我的称号已达成：%d个（未达成：%d个）", #player_titles, table.nums(titles) - #player_titles))

	local num = table.nums(titles)
    local rowPadding = 7
	local colNum = 1

	local w = 545
	local h = 127
	local leftPadding = (self.scrollView:getContentSize().width - w)/2
	--滚动条宽度
	local innerWidth = self.scrollView:getInnerContainerSize().width
	--设置滚动条内容区域大小
	-- self.scrollView:setInnerContainerSize(cc.size(innerWidth,math.max(math.ceil(num/colNum) * (h + rowPadding) + 20,self.scrollView:getContentSize().height)))
	self.scrollView:setInnerContainerSize(cc.size(innerWidth,math.max(math.ceil(num/colNum) * (h + rowPadding) - 5,self.scrollView:getContentSize().height)))

	local render = nil
	local innerHeight = self.scrollView:getInnerContainerSize().height
	--y起始坐标
	-- local ystart = innerHeight - 3
	local ystart = innerHeight + 5

	self.items = {}
	for i, title in ipairs(titles) do
		render = NameItem.new()
		render.p = self
		render:setData(title, player_titles_map[title.no] or false, player_title == title.no)
		render:setPosition(leftPadding ,ystart - math.modf(i/colNum)*(h + rowPadding))
		self.scrollView:addChild(render)
		self.items[#self.items + 1] = render

		i = i + 1
	end
	-- local i = 1
	-- for k,v in pairs(5) do
	-- 	render = NameItem.new()
	-- 	render:setData(k)
	-- 	render:setPosition(leftPadding ,ystart - math.modf(i/colNum)*(h + rowPadding))
	-- 	self.scrollView:addChild(render)
	-- 	i = i + 1
	-- end
end

function ChangeTitleNameProcessor:onItemsCheckBox(sender)
	for i,v in ipairs(self.items) do
		if v.usable then
			if v.title.no ~= sender.title.no then
				v.boxSelect:setSelected(false)
			end
		end
	end
end

--按钮点击
function ChangeTitleNameProcessor:onBtnClick(sender,eventType)
	if  eventType ~= TouchEventType.ended then
		return
	end
	local btn = tolua.cast(sender,"ccui.Button")
	local btnName = btn:getName()
	if btnName == "btnKeep" then
		local title = nil
		for i,v in ipairs(self.items) do
			if v.usable then
				if v.boxSelect:isSelected() then
					title = v.title
				end
			end
		end

		-- if title == nil then
		-- 	self:removePopView(self.view)
		-- 	self.view = nil
		-- 	return
		-- end

		title_no = ""
		if title ~= nil then
			title_no = title.no
		end

		self.change_title_no = title_no
		print(title_no)

		local net = {}
		net.method = GamesysModule.USER_CHANGE_TITLE
		net.params = {}
		net.params.title = title_no
		Net.sendhttp(net)
	elseif btnName == "btnCancle" then
		self:removePopView(self.view)
		self.view = nil
	elseif btnName == "btnClose" then
		self:removePopView(self.view)
		self.view = nil
	end

end

-- 称号保存完成
function ChangeTitleNameProcessor:onTitleChangeDone(node)
	self:removePopView(self.view)
	self.view = nil
	toastNotice("称号保存完成",COLOR_GREEN)
	PlayerData:setTitle(node.data.data.title)
	PlayerData:setTitles(node.data.data.titles)
end

-- 更新用户所有称号
function ChangeTitleNameProcessor:updateUI(data)
	self.scrollView:removeAllChildren()
end

return ChangeTitleNameProcessor