--
-- Author: Your Name
-- Date: 2015-01-22 18:45:25
--
local MultiBattlePlayerCell = import(".ui.MultiBattlePlayerCell")
local MultiBattlePlayerListProcessor = class("MultiBattlePlayerListProcessor", BaseProcessor)
function MultiBattlePlayerListProcessor:ctor()
end
function MultiBattlePlayerListProcessor:ListNotification()
	return {
			MultiBattleModule.USER_LOOK_TEAM_INFO,
			MultiBattleModule.USER_LEADER_REFRESH_TEAM,
			MultiBattleModule.USER_KICK_OUT,
    }
end
function MultiBattlePlayerListProcessor:handleNotification(notify, data)
	if notify == MultiBattleModule.USER_LOOK_TEAM_INFO then
		self:initUI()
		self:setData(data.data.data)
	elseif notify == MultiBattleModule.USER_LEADER_REFRESH_TEAM then
		-- dump(data.data)
		if data.data.data ~= nil and data.data.data.team_info ~= nil then
			self:setData(data.data.data.team_info)
		end
	elseif notify == MultiBattleModule.USER_KICK_OUT then
		data = data.data.data

		local payCoin = PlayerData:getCoin() - data.coin

		PlayerData:setCoin(math.floor(data.coin))
		PlayerData.data.records.kick_out_count = data.kick_out_count

		local uid = data.uid
		local new_data = {}
		for k,v in pairs(self.data) do
			if v.uid ~= uid then
				new_data[#new_data+1] = v
			end
		end

		self:setData(new_data)
		
		popNotices({{"创建队伍成功",COLOR_GREEN},{"元宝: -"..payCoin,COLOR_RED},})
	end
end
function MultiBattlePlayerListProcessor:initUI()
	if(not self.view) then
		self.panel = ResourceManager:widgetFromJsonFile("ui/MultiBattlePlayerList.json")
		self.closebtn = self.panel:getChildByName("closebtn")  
		self.bg = self.panel:getChildByName("bg")
		self.top = self.panel:getChildByName("top")
		self.scrollview = self.panel:getChildByName("scrollview")
		self.bottom = self.panel:getChildByName("bottom")
		self.refreshbtn = self.bottom:getChildByName("refreshbtn")
		self.bottomtiptxt = self.bottom:getChildByName("bottomtiptxt")
		self.bottomtiptxt2 = self.bottom:getChildByName("bottomtiptxt2")
		self.leadertxt = self.top:getChildByName("leadertxt")
		self.tiptxt1 = self.top:getChildByName("tiptxt1")
		self.tiptxt2 = self.top:getChildByName("tiptxt2")
		local theight = 766
		self.det = display.height - 960
		if display.height > 960 then
			theight = theight + self.det
		end
		local size = self.panel:getLayoutSize()
		self.panel:setContentSize(cc.size(size.width,theight))
		size = self.bg:getContentSize()
		self.bg:setContentSize(cc.size(size.width,size.height + self.det))
		size = self.scrollview:getContentSize()
		self.scrollview:setContentSize(cc.size(size.width,size.height + self.det))
		self:setView(self.panel)
		self:addPopView(self.panel,true)
		enableBtnOutLine(self.refreshbtn,COMMON_BUTTONS.BLUE_BUTTON)
		self.refreshbtn:addTouchEventListener(handler(self,self.onClick))

		self.closebtn:addTouchEventListener(handler(self,self.onClick))
	end
end
function MultiBattlePlayerListProcessor:onClick(sender,eventType)
	if  eventType ~= TouchEventType.ended then 
		return
	end
	local btn = tolua.cast(sender,"ccui.Button")
	local btnName = btn:getName()
	if btnName == "refreshbtn" then
		local net = {}
		net.method = MultiBattleModule.USER_LEADER_REFRESH_TEAM
		net.params = {}
		Net.sendhttp(net)
	elseif btnName == 'closebtn' then
		self:removePopView(self.view)
	end
end
function MultiBattlePlayerListProcessor:setData(data)
	self.scrollview:removeAllChildren()

	-- self.data = {0,0,0,0,0,0,0,0}
	self.data = data

	-- 排序
	table.sort(self.data, function(a, b)
		local a_num = a.power
		local b_num = b.power
		if a.is_leader == 1 then
			a_num = a_num + 9999999
		end
		if b.is_leader == 1 then
			b_num = b_num + 9999999
		end
		return a_num > b_num
	end)

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

	self.power_sum = 0
	local i = 1
	for k,v in ipairs(self.data) do
		self.power_sum = self.power_sum + v.power
		render = MultiBattlePlayerCell.new()
		render:setData(v)
		render:setPosition(leftPadding ,ystart - i*(h + rowPadding))
		self.scrollview:addChild(render)
		i = i + 1
	end
	self.scrollview:setInnerContainerSize(cc.size(innerWidth,self.innerHeight))

	-- 设置标题 设置文字介绍
	local cfg = DataConfig:getAllConfigMsg()
	local pvp = DataConfig.data.cfg.system_simple.multiplayer_pvp
	self.leadertxt:setString(addArgsToMsg(cfg["30072"],PlayerData:getPlayerName()))
	self.tiptxt1:setString(addArgsToMsg(cfg["30073"],self.power_sum,#self.data,pvp.num_limit))
	self.tiptxt2:setString(cfg['20034'])
	self.bottomtiptxt2:setString(cfg['20032'])
end
return MultiBattlePlayerListProcessor