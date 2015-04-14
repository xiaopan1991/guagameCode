--奖励 处理器
--任务活动
local GameAwardProcessor = class("GameAwardProcessor", BaseProcessor)
local AwardItem = import(".ui.AwardItem")
local MailItem = import(".ui.MailItem")

function GameAwardProcessor:ctor()
	self.showtype = nil --0,任务1,活动
	self.taskData = nil
	self.activityData = nil
end

function GameAwardProcessor:ListNotification()
	return {
		GamesysModule.SHOW_GAME_TASK,
		GamesysModule.UPDATE_GAME_TASK,
		GamesysModule.USER_TASK_DONE,
	}
end

function GameAwardProcessor:handleNotification(notify, data)
	if notify == GamesysModule.SHOW_GAME_TASK then
		self:initUI()
		self:initData()
		self:setShowType(0)
	elseif notify == GamesysModule.UPDATE_GAME_TASK then
		--self:initUI()
		self:initData()
		if(self.view) then
			self:setShowType(self.showtype)
		end		
	elseif notify == GamesysModule.USER_TASK_DONE then
		--处理任务相关数据，领取奖励，后面只管刷新
		local key = data.data.params.task_key
		local adata = DataConfig:getAllTask()[key]
		local content
		if(adata.type == 3) then
			for i,v in ipairs(self.activityData) do
				if(v.id == key) then
					content = v.content
					break
				end
			end
		else
			for i,v in ipairs(self.taskData) do
				if(v.id == key) then
					content = v.content
					break
				end
			end
		end
		local notices = {}
		local giftsbefore = adata.content[content+1].gift
		local gifts = data.data.data.gifts
		if(gifts.coin) then	
			if(giftsbefore.coin) then
				table.insert(notices, {"获得元宝 "..(giftsbefore.coin),COLOR_GREEN})
			end
			PlayerData:setCoin(gifts.coin)
		end
		if(gifts.lv) then
			PlayerData:setLv(gifts.lv)
		end
		if(gifts.exp) then
			if(giftsbefore.exp) then
				table.insert(notices, {"获得经验 "..(giftsbefore.exp),COLOR_GREEN})
			end
			PlayerData:setExp(gifts.exp)
		end
		if(gifts.gold) then
			if(giftsbefore.gold) then
				table.insert(notices, {"获得银两 "..(giftsbefore.gold),COLOR_GREEN})
			end
			PlayerData:setGold(gifts.gold)
		end
		if(gifts.melte) then
			if(giftsbefore.melte) then
				table.insert(notices, {"获得熔炼值 "..(giftsbefore.melte),COLOR_GREEN})
			end
			PlayerData:setMelte(gifts.melte)
		end
		if(gifts.pith) then
			if(giftsbefore.pith) then
				table.insert(notices, {"获得强化精华 "..(giftsbefore.pith),COLOR_GREEN})
			end
			Bag:addGoods("I0001",gifts.pith)
		end
		if(gifts.goods) then
			for k,v in pairs(gifts.goods) do
				table.insert(notices, {"获得物品 "..(DataConfig:getGoodByID(k).name.."*"..giftsbefore.goods[k]),COLOR_GREEN})
				Bag:addGoods(k,v)
			end
		end
		if(gifts.neweids) then
			for k,v in pairs(gifts.neweids) do
				local c3 = Bag:getEquipColor(v.color[1])
				table.insert(notices, {"获得装备 "..(DataConfig:getEquipById(v.eid).name),c3})
				Bag:addEquip(k,v)
			end
		end
		popNotices(notices)
		PlayerData:setTaskData(data.data.data.task)
		Observer.sendNotification(BagModule.EQUIP_NUM_UPDATE) --数量更新	
	end
end
function GameAwardProcessor:sendRewardNotice(num)
	local tempNode = display.newNode()
	local data = {}
	tempNode.data = data
	data.rewardNum = num
	Observer.sendNotification(IndexModule.REWARD_NOTICE,tempNode)
end
--初始化UI显示
-- arg  预留 没用
function GameAwardProcessor:initUI(arg)
	if self.view ~= nil then
		return
	end
	local view = ResourceManager:widgetFromJsonFile("ui/awardpanel.json")
	view:setName("GameAwardProcessor")
	self.taskBtn = view:getChildByName("taskBtn")
	self.activityBtn = view:getChildByName("activityBtn")
	self.taskBtn:addTouchEventListener(handler(self,self.onTabClick))
	self.activityBtn:addTouchEventListener(handler(self,self.onTabClick))

	local btnCDK = view:getChildByName("btnCDK")
	btnCDK:addTouchEventListener(handler(self,self.onTabClick))
	
	enableBtnOutLine(self.taskBtn,COMMON_BUTTONS.TAB_BUTTON)
	enableBtnOutLine(self.activityBtn,COMMON_BUTTONS.TAB_BUTTON)

	local mailTip = view:getChildByName("mailTip")
	mailTip:setVisible(false)
	local mailImage = view:getChildByName("mailImage")
	mailImage:setVisible(false)
	self.det = display.height - 960
	local theight = 766
	if display.height > 960 then
		theight = 766 + self.det
	end
	local size = view:getLayoutSize()
	view:setContentSize(cc.size(size.width,theight))
	local bg = view:getChildByName("imgbg")
	local bgsize = bg:getLayoutSize()
	bg:setContentSize(cc.size(bgsize.width,bgsize.height + self.det))

	if self.awardview == nil then
		self.awardview = ResourceManager:widgetFromJsonFile("ui/awardtaskview.json")
		self.txtMsg = self.awardview:getChildByName("txtMsg")
		-- self.txtMsgBg = self.awardview:getChildByName("txtMsgBg")

		local msgs = DataConfig:getAllConfigMsg()
		self.txtMsg:setString(msgs['20013'])
		-- self.txtMsgBg:setContentSize(cc.size(self.txtMsg:getContentSize().width + 40, 32))

		local relarg = ccui.RelativeLayoutParameter:create()
		relarg:setAlign(ccui.RelativeAlign.alignParentTopLeft)
		local margin = {}
		margin.top = 125
		margin.left = 0
		relarg:setMargin(margin)
		self.awardview:setLayoutParameter(tolua.cast(relarg,"ccui.LayoutParameter"))

		local size = self.awardview:getLayoutSize()
		self.awardview:setContentSize(cc.size(size.width,size.height + self.det))

		self.scrollview = self.awardview:getChildByName("awardScroll")
		self.imabg = self.awardview:getChildByName("imabg")
		
		local listsize = self.scrollview:getContentSize()
		bgsize = self.imabg:getContentSize()
		self.imabg:setContentSize(cc.size(bgsize.width,bgsize.height+self.det))
		self.scrollview:setContentSize(cc.size(listsize.width,listsize.height+self.det))		
		view:addChild(self.awardview)
	end	
	self:tabIndex(1)
	self:setView(view)
	self:addMidView(view,true)
end

function GameAwardProcessor:onTabClick(sender, eventType)
	if eventType ~= TouchEventType.ended then
		return
	end
	local btnName = sender:getName()
	if btnName == "taskBtn" then
		self:tabIndex(1)
		self:setShowType(0)
	elseif btnName == "activityBtn" then
		self:setShowType(1)
		self:tabIndex(2)
	elseif btnName == "btnCDK" then
		Observer.sendNotification(GamesysModule.SHOW_CDK_VIEW)
	end
end
function GameAwardProcessor:processData(data)
	local cfg = DataConfig:getAllConfigMsg()
	local adata = DataConfig:getAllTask()[data.id]
	local content = adata.content[data.content + 1]
	if(data.id == "every_pvp") then--每日挑战
		local temp = PlayerData:getPVPTaskCompletedCount()
		if(content.need <= temp) then
			--可领奖
			data.txtInfo = ""
			data.canget = true
			self.cangetnum = self.cangetnum + 1
		else
			--不可领奖
			data.canget = false
			data.txtInfo = (temp.."/"..content.need)
		end
		data.conditionTxt = (addArgsToMsg(cfg[tostring(adata.info)],content.need))
	elseif (data.id== "login_catena") then--累积登陆
		local temp = PlayerData:getTotalLogin() --= PlayerData:getPVPTaskCompletedCount()
		if(content.need <= temp) then
			--可领奖
			data.txtInfo = ""
			data.canget = true
			self.cangetnum = self.cangetnum + 1
		else
			--不可领奖
			data.canget = false
			data.txtInfo = ("未完成")
		end
		data.conditionTxt = (addArgsToMsg(cfg[tostring(adata.info)],content.need))
	elseif (data.id == "level_up") then--等级提升
		local temp = PlayerData:getLv()
		if(content.need <= temp) then
			--可领奖
			data.txtInfo = ""
			data.canget = true
			self.cangetnum = self.cangetnum + 1
		else
			--不可领奖
			data.canget = false
			data.txtInfo = ("未完成")
		end
		data.conditionTxt = (addArgsToMsg(cfg[tostring(adata.info)],content.need))
	elseif (data.id == "battle_main") then--挑战BOSS
		local tempStr = Raid:getMaxRaidId()
		local temp = tonumber(string.sub(tempStr,2))
		local need = tonumber(string.sub(content.need,2))
		if(need <= (temp - 1)) then
			--可领奖
			data.txtInfo = ""
			data.canget = true
			self.cangetnum = self.cangetnum + 1
		else
			--不可领奖
			data.canget = false
			data.txtInfo = ("未完成")
		end
		local bossID = DataConfig:getMapById(content.need).boss.wids[1][1]
		data.conditionTxt = (addArgsToMsg(cfg[tostring(adata.info)],
			DataConfig:getMapById(content.need).name , DataConfig:getBossById(bossID).name))
	elseif (data.id == "open_service_day") then--开服天数礼包
		local zoneData = DataConfig:getZones()
		local myzone = 	PlayerData:getZone()
		local zoneStart = os.date("*t", math.floor(changeTimeStrToSec(zoneData[myzone][2]["$datetime"])))
		local startSec = os.time(
			{year = zoneStart.year,
	        month = zoneStart.month,
	        day = zoneStart.day,
	        hour = 0,
	        min = 0,
	        sec = 0})
		local temp = math.floor((TimeManager:getSvererTime() - startSec)/24/3600)	+ 1	
		if(content.need <= temp) then
			--可领奖
			data.txtInfo = ""
			data.canget = true
			self.cangetnum = self.cangetnum + 1
		else
			--不可领奖
			data.canget = false
			data.txtInfo = ("未完成")
		end
		data.conditionTxt = (addArgsToMsg(cfg[tostring(adata.info)],content.need))
	elseif (data.id == "first_recharge") then--首冲礼包
		local temp = PlayerData:getFirstPay()
		if(temp) then
			--可领奖
			data.txtInfo = ""
			data.canget = true
			self.cangetnum = self.cangetnum + 1
		else
			--不可领奖
			data.canget = false
			data.txtInfo = ("未完成")
		end
		data.conditionTxt = (addArgsToMsg(cfg[tostring(adata.info)],content.need))
	elseif (data.id == "cumulative_recharge") then--累积充值
		local temp = PlayerData:getTotalPayMoney()
		if(content.need <= temp) then
			--可领奖
			data.txtInfo = ""
			data.canget = true
			self.cangetnum = self.cangetnum + 1
		else
			--不可领奖
			data.canget = false
			data.txtInfo = (temp.."/"..content.need)
		end
		data.conditionTxt = (addArgsToMsg(cfg[tostring(adata.info)],content.need))
	end
end
function GameAwardProcessor:initData()
	self.activityData = {}
	self.cangetnum = 0
	local allData = PlayerData:getTaskData()
	local tdata
	local function sortTask(a,b)
		-- body
		if(a.canget == true and b.canget == false) then
			return true
		elseif (a.canget == false and b.canget == true) then
			return false
		else
			if(a.ttype ~= b.ttype) then
				return a.ttype < b.ttype
			else				
				return a.index < b.index				
			end
		end
	end
	for k,v in pairs(allData) do
		tdata = DataConfig:getAllTask()[k]
		if(tdata.type == 3 and tdata.need_lv <= PlayerData:getLv() ) then
			if(k ~= "open_service_day") then
				if((v+1) <= #tdata.content) then
					local data = {id = k,content = v,ttype = tdata.type,index = tdata.index}
					self:processData(data)
					table.insert(self.activityData, data)
				end
			else
				local zoneData = DataConfig:getZones()
				local myzone = 	PlayerData:getZone()
				local zoneStart = os.date("*t", math.floor(changeTimeStrToSec(zoneData[myzone][2]["$datetime"])))
				local startSec = os.time(
					{year = zoneStart.year,
			        month = zoneStart.month,
			        day = zoneStart.day,
			        hour = 0,
			        min = 0,
			        sec = 0})
				local temp = math.floor((TimeManager:getSvererTime() - startSec)/24/3600)	+ 1	
				if(temp <= #tdata.content and (v+1) <= #tdata.content) then
					local data = {id = k,content = v,ttype = tdata.type,index = tdata.index}
					self:processData(data)
					table.insert(self.activityData, data)
				end
			end
		end
	end
	table.sort(self.activityData,sortTask)
	
	self.taskData = {}
	allData = PlayerData:getTaskData()
	for k,v in pairs(allData) do
		tdata = DataConfig:getAllTask()[k]
		if((tdata.type == 1 or tdata.type == 2) and tdata.need_lv <= PlayerData:getLv()) then
			if((v+1) <= #tdata.content) then
				local data = {id = k,content = v,ttype = tdata.type,index = tdata.index}
				self:processData(data)
				table.insert(self.taskData, data)
			end
		end
	end
	table.sort(self.taskData,sortTask)
	self:sendRewardNotice(self.cangetnum)
end
---切换页签
---index  0 奖励
---		  1  邮件
function GameAwardProcessor:setShowType(index)
	self.showtype = index
	if(self.showtype == 0) then
		self:updateTask()
		self.taskBtn:setTitleColor(cc.c3b(255,255,255))
		self.activityBtn:setTitleColor(cc.c3b(255,245,135))
	elseif(self.showtype == 1) then
		self:updateActivity()
		self.activityBtn:setTitleColor(cc.c3b(255,255,255))
		self.taskBtn:setTitleColor(cc.c3b(255,245,135))
	end
end
function GameAwardProcessor:updateActivity()
	--排序
	if(self.limitTxt) then
		self.limitTxt = nil
	end
	self.scrollview:removeAllChildren()	
	local num = table.nums(self.activityData)	
    local rowPadding = 10

	local w = 545
	local h = 127
	local leftPadding = (self.scrollview:getContentSize().width - w)/2

	--滚动条宽度
	local innerWidth = self.scrollview:getInnerContainerSize().width

	local render = nil
	local hhh = 0
	local renders = {}
	for i,v in ipairs(self.activityData) do
		render = AwardItem.new()
		render:setData(v)
		hhh = hhh + render:getContentSize().height + rowPadding
		self.scrollview:addChild(render)
		renders[hhh] = render
	end
	hhh = hhh + rowPadding
	self.scrollview:setInnerContainerSize(cc.size(innerWidth,math.max(hhh,self.scrollview:getContentSize().height)))
	local innerHeight = self.scrollview:getInnerContainerSize().height
	--y起始坐标
	local ystart = innerHeight
	for k,v in pairs(renders) do
		v:setPosition(leftPadding ,ystart - k)	
	end
	self.scrollview:setInnerContainerSize(cc.size(innerWidth,innerHeight))
	if(#self.activityData == 0) then
		local cfg = DataConfig:getAllConfigMsg()	
		-- self.limitTxt = CCLabelTTF:create(cfg["20019"],DEFAULT_FONT,30,cc.size(500,50),kCCTextAlignmentCenter)
		self.limitTxt = display.newTTFLabel({
			text = cfg["20019"],
			font = DEFAULT_FONT,
			size = 30,
		})
		self.limitTxt:setColor(COLOR_RED)
		self.limitTxt:setPosition(innerWidth/2,self.scrollview:getContentSize().height/2)
		self.scrollview:addChild(self.limitTxt)
		self.scrollview:setBounceEnabled(false)
	else
		self.scrollview:setBounceEnabled(true)
	end
end
function GameAwardProcessor:updateTask()
	--排序
	if(self.limitTxt) then
		self.limitTxt = nil
	end
	self.scrollview:removeAllChildren()
	local num = table.nums(self.taskData)
	
    local rowPadding = 10

	local w = 545
	local h = 127
	local leftPadding = (self.scrollview:getContentSize().width - w)/2


	--滚动条宽度
	local innerWidth = self.scrollview:getInnerContainerSize().width

	local render = nil
	local hhh = 0
	local renders = {}
	for i,v in ipairs(self.taskData) do
		render = AwardItem.new()
		render:setData(v)
		hhh = hhh + render:getContentSize().height + rowPadding
		self.scrollview:addChild(render)
		renders[hhh] = render
	end
	hhh = hhh + rowPadding
	self.scrollview:setInnerContainerSize(cc.size(innerWidth,math.max(hhh,self.scrollview:getContentSize().height)))
	local innerHeight = self.scrollview:getInnerContainerSize().height
	--y起始坐标
	local ystart = innerHeight
	for k,v in pairs(renders) do
		v:setPosition(leftPadding ,ystart - k)	
	end
	self.scrollview:setInnerContainerSize(cc.size(innerWidth,innerHeight))
	if(#self.taskData == 0) then
		local cfg = DataConfig:getAllConfigMsg()	
		-- self.limitTxt = CCLabelTTF:create(cfg["20019"],DEFAULT_FONT,30,cc.size(500,50),kCCTextAlignmentCenter)
		self.limitTxt = display.newTTFLabel({
			text = cfg["20022"],
			font = DEFAULT_FONT,
			size = 30,
		})
		self.limitTxt:setColor(COLOR_RED)
		self.limitTxt:setPosition(innerWidth/2,self.scrollview:getContentSize().height/2)
		self.scrollview:addChild(self.limitTxt)
		self.scrollview:setBounceEnabled(false)
	else
		self.scrollview:setBounceEnabled(true)
	end
end
--改变按钮的选中状态
function GameAwardProcessor:tabIndex(index)
	if index == 1 then
		self.taskBtn:setBright(true)
		self.activityBtn:setBright(false)
	else
		self.activityBtn:setBright(true)
		self.taskBtn:setBright(false)
	end
end
--移除界面
function GameAwardProcessor:onHideView(view)
	if self.view ~= nill then
		self.view:removeFromParent(true)
		self.view = nil
		self.awardview = nil
	end
end
return GameAwardProcessor