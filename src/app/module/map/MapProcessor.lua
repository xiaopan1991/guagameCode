--世界地图
local MapProcessor = class("MapProcessor", BaseProcessor)
local MapItem = import(".ui.MapItem")

function MapProcessor:ctor()
	-- body
	self.mapItems = {}
	self.leftPadding = 0
	self.rowPadding = 6
	self.colNum = 1
	self.maxmaptipHeight = 44--滚动条最下面显示的tip
end

function MapProcessor:ListNotification()
	return {
		MapModule.SHOW_MAP,
		MapModule.USER_CHANGE_MAP,
		MapModule.BOSS_TIME_CHANGE,
		MapModule.USER_BUY_BOSS_COUNT,
		MapModule.UPDATE_MAP,
		MapModule.USER_BOSS_SWEEEP,
   }
end

function MapProcessor:handleNotification(notify, data)
	if notify == MapModule.SHOW_MAP then
		self:initUI()
		self:setData()
	elseif notify == MapModule.USER_CHANGE_MAP then
		self:handleChangeMap(data.data)
	elseif notify == MapModule.BOSS_TIME_CHANGE then
		self:handleBossTimeChange()
	elseif notify == MapModule.UPDATE_MAP then
		if(self.view) then
			self:setData()
		end
	elseif notify == MapModule.USER_BUY_BOSS_COUNT then
		local notices = {{"BOSS挑战次数+"..(data.data.data.BOSS_count - BossPvpBattleManager.bossChargeTimes),COLOR_GREEN}}
		local cost = PlayerData:getCoin() - data.data.data.coin
		table.insert(notices, {"元宝:-"..cost,COLOR_RED})
		popNotices(notices)

		BossPvpBattleManager:setBossChargeTimes(data.data.data.BOSS_count)
		BossPvpBattleManager:setBossChargeBuyTimes(data.data.data.challenge_BOSS_count)
		PlayerData:setCoin(data.data.data.coin)
	elseif notify == MapModule.USER_BOSS_SWEEEP then
		self:handleSaoDangData(data.data)
	end
end
--扫荡的数据返回
function MapProcessor:handleSaoDangData(data)
	local tempData = data.data
	--dump(tempData)
	local addExp = tempData.exp
	local addGold = tempData.gold
	local addPith = tempData.pith
	local times = tempData.BOSS_count
	
	
	local equipEid 
	local equipColor
	for k,v in pairs(tempData.equip) do
		Bag:addEquip(k,v)
		equipEid = v.eid
		equipColor = v.color
	end
	local getEquipName = DataConfig:getEquipById(equipEid).name
	local lv = tonumber(string.sub(equipEid,4,6))
	local numcolor = equipColor[1]
	local c3 = Bag:getEquipColor(numcolor)
	local namestr = "Lv"..lv.." "..getEquipName

	btns = {{text = "确定",skin = 3}}
		alert = GameAlert.new()
		richStr = {{text = "战斗胜利,",color = display.COLOR_WHITE},
		{text = "经验+"..addExp..",",color = cc.c3b(255,205,30)},
		{text = "金钱+"..addGold..",",color = display.COLOR_WHITE},
		{text = "精华+"..addPith,color = COLOR_GREEN},
		{text = "\n获得装备 ",color = COLOR_RED},
		{text = "[",color = c3},
		{text = ""..namestr,color = c3},
		{text = "]",color = c3},
		}
	alert:pop(richStr,"ui/titlebossSaodang.png",btns)

	local curGold = PlayerData:getGold()
	local changeGold = curGold + addGold
	PlayerData:setGold(changeGold)

	local curExp = PlayerData:getExp()
	local changeExp = curExp + addExp
	PlayerData:setExp(changeExp)

	local pithData = Bag:getGoodsById("I0001")
	if(pithData) then
		Bag:addGoods("I0001",pithData.num + addPith)
	else
		Bag:addGoods("I0001",addPith)
	end
	BossPvpBattleManager:setBossChargeTimes(times)
	
	self:handleBossTimeChange()


end
function MapProcessor:updateMaxMapTip()
end
function MapProcessor:handleBossTimeChange()
	if(self.view) then
		local cfg = DataConfig:getAllConfigMsg()
		local text = addArgsToMsg(cfg["30029"],BossPvpBattleManager.bossChargeTimes)
		self.txtTimes:setString(text)
		if(BossPvpBattleManager.bossChargeTimes == 0) then
			self.txtTimes:setColor(cc.c3b(255,0,0))
		else
			self.txtTimes:setColor(cc.c3b(255,255,255))
		end
		-- self.leftTimeBg:setContentSize(cc.size(self.txtTimes:getContentSize().width+60,32))
		

	end
end
--确定使用boss挑战券
function MapProcessor:sendUseBossCount()
	
end
function MapProcessor:changeTip()
	local allMap = DataConfig:getMapNum()
	local nowopen = tonumber(string.sub(Raid:getMaxRaidId(),2))
	local cha = allMap - nowopen
	local cfg = DataConfig:getAllConfigMsg()
	--先判断VIP等级
	local text = ""
	local curvip = PlayerData:getVipLv()
	if curvip >= 1 then
		text = addArgsToMsg(cfg["30079"],nowopen,cha)
	else
		text = addArgsToMsg(cfg["30031"],nowopen,cha)
	end
	self.tiptxt:setString(text)
end
function MapProcessor:handleChangeMap(data)
	Raid:changePlayRaid(data.data.mid)
	Raid:changeNextRaid(data.data.next_mid)
end
function MapProcessor:initUI()
	if(not self.view) then
		self.mapPanel = ResourceManager:widgetFromJsonFile("ui/mappanel.json")
		local Image_top = self.mapPanel:getChildByName("Image_top")
		local txtTop =  self.mapPanel:getChildByName("txtTop")
		self.txtTimes = self.mapPanel:getChildByName("txtTimes")
		-- self.leftTimeBg = self.mapPanel:getChildByName("leftTimeBg")
		self.tiptxt = self.mapPanel:getChildByName("tiptxt")
		-- self.btnClose = self.mapPanel:getChildByName("btnClose")
		-- self.btnClose:addTouchEventListener(handler(self,self.onBtnClick))
		
		self:handleBossTimeChange()
		local btnBuyTimes = self.mapPanel:getChildByName("btnBuyTimes")
		self.ScrollViewMap = self.mapPanel:getChildByName("ScrollViewMap")
		local blueBg = self.mapPanel:getChildByName("blueBg")
		self.ScrollViewBg = self.mapPanel:getChildByName("ScrollViewBg")
		local theight = 766
		self.det = display.height - 960
		if display.height > 960 then
			theight = theight + self.det
		end
		local size = self.mapPanel:getLayoutSize()
		self.mapPanel:setContentSize(cc.size(size.width,theight))

		size = self.ScrollViewMap:getContentSize()
		self.ScrollViewMap:setContentSize(cc.size(size.width,size.height + self.det))

		size = blueBg:getContentSize()
		blueBg:setContentSize(cc.size(size.width,size.height + self.det))	

		size = self.ScrollViewBg:getContentSize()
		self.ScrollViewBg:setContentSize(cc.size(size.width,size.height + self.det))	

		self:setView(self.mapPanel)
		self:addMidView(self.mapPanel,true)
		btnBuyTimes:addTouchEventListener(handler(self,self.onBuyTimesClick))
		enableBtnOutLine(btnBuyTimes,COMMON_BUTTONS.BLUE_BUTTON)

	end
end
function MapProcessor:setCurMap()
	for k,v in pairs(self.mapItems) do	
		if(v.data.mid == Raid:getCurMap()) then
			v:addTip()
		else
			v:clearTip()
		end
	end
end
function MapProcessor:setData()
	--GameInstance.uiLayer:stopTouch()--升级后修改
	self.ScrollViewMap:removeAllChildren()
	self.mapItems = {}
	self.data = DataConfig:getAliveMaps()
	TimeManager:remove(self)
	local tlen = #self.data
	local h = 125
	
	--滚动条宽度
	local innerWidth = self.ScrollViewMap:getInnerContainerSize().width
	-- local hhh = math.ceil(tlen/self.colNum) * (h + self.rowPadding)
	-- print("hhh"..hhh)
	--设置滚动条内容区域大小
	local allMap = DataConfig:getMapNum()
	local nowopen = tonumber(string.sub(Raid:getMaxRaidId(),2))
	self.minHeight = self.ScrollViewMap:getContentSize().height
	if(allMap == nowopen) then
		self.maxmaptipHeight = 0
	else
		self.maxmaptipHeight = 44
	end
	local itemsHeight = math.ceil(tlen/self.colNum) * (h + self.rowPadding) + self.rowPadding + self.maxmaptipHeight
	self.innerHeight = math.max(itemsHeight,self.minHeight)
	self.ScrollViewMap:setInnerContainerSize(cc.size(innerWidth,self.innerHeight))
	if(not TimeManager:isAdded(self)) then
		TimeManager:add(self)
	end	

	if(allMap ~= nowopen) then
		local maxmaptip = ResourceManager:widgetFromJsonFile("ui/maxmaptip.json")
		local tipy
		if(itemsHeight > self.minHeight) then
			tipy = self.rowPadding
		else
			tipy = self.minHeight-(itemsHeight - self.rowPadding)
		end
		maxmaptip:setPosition(self.leftPadding,tipy)
		self.ScrollViewMap:addChild(maxmaptip,2)
	end

	self:jumpToMap(Raid:getCurMap())
	self:handleBossTimeChange()
	self:changeTip()
end
function MapProcessor:jumpToMap(mapid)
	local mapIndex = tonumber(string.sub(mapid,2))
	local h = 125
	local mapHeight = (h + self.rowPadding)*mapIndex
	local innerContainer = self.ScrollViewMap:getInnerContainer()
	if( mapHeight <= self.minHeight) then
		self.ScrollViewMap:jumpToTop()	
	else
		innerContainer:setPositionY(mapHeight - self.innerHeight)
	end
	self:timeUpdate(0)
end
function MapProcessor:timeUpdate(dt)
	local h = 125
	local ystart = self.innerHeight - h  - self.rowPadding
	local render = nil
	local curBottomY = self.ScrollViewMap:getInnerContainer():getPositionY()
	local startindex
	if(self.innerHeight > self.minHeight) then
		startindex = math.ceil((self.innerHeight - self.rowPadding - self.maxmaptipHeight-(self.minHeight - curBottomY))/(h+self.rowPadding))
	else
		startindex = 1
	end
	local minNum = math.ceil((self.minHeight - self.rowPadding)/(h + self.rowPadding)) + 1
	for i=startindex,startindex + minNum - 1 do
		if(not self.mapItems[i]) then
			if(self.data[i]) then
				render = MapItem.new()
				if PlayerData:getVipLv() > 0 then
					local saoDangRaid = Raid:getSaoDangRaid()					
					if saoDangRaid and self.data[i].mid <= Raid:getSaoDangRaid() then
						render.btnChallenge:loadTextureNormal("ui/bossSaoDang.png")
					end
				end
				render:setData(self.data[i])
				render:setPosition(self.leftPadding , ystart - math.modf((i-1)/self.colNum)*(h + self.rowPadding))
				self.ScrollViewMap:addChild(render)
				self.mapItems[i] = render
			end
		end
	end
	self:setCurMap()
end
--购买次数点击事件
function MapProcessor:onBuyTimesClick(sender,eventType)
	if eventType == TouchEventType.ended then
		--todo
		local vipCf = DataConfig:getVIPCfg()
		local vipLv = PlayerData:getVipLv()
		local btns
		local alert
		local richStr
		if(vipCf[""..vipLv].challenge_BOSS_count > BossPvpBattleManager.bossChargeBuyTimes) then
			local prices = DataConfig.data.cfg.system_simple.BOSS_count_price
			local price = prices[1]*(BossPvpBattleManager.bossChargeBuyTimes)+prices[2]
			if(price <= PlayerData:getCoin()) then
				btns = {{text = "取消",skin = 2},{text = "确定",skin = 1,callback = handler(self,self.sendBuyChargeTime)},}
				alert = GameAlert.new()
				richStr = {{text = "是否花费",color = display.COLOR_WHITE},
					{text = ""..price,color = COLOR_RED},
					{text = "元宝购买？",color = display.COLOR_WHITE}}
				alert:pop(richStr,"ui/titlenotice.png",btns)
			else
				--notice("元宝不足",COLOR_RED)
				btns = {{text = "取消",skin = 2},{text = "充值",skin = 1,callback = handler(self,self.sendChargeView)}}
				alert = GameAlert.new()
				richStr = {{text = "您的元宝不足，请您及时充值！",color = display.COLOR_WHITE}}
				alert:pop(richStr,"ui/titlenotice.png",btns)
			end
		elseif(vipCf[""..(vipLv+1)]) then--vip等级不满级
			btns = {{text = "取消",skin = 2},{text = "充值",skin = 1,callback = handler(self,self.handleChongzhi)},}
			alert = GameAlert.new()
			richStr = {{text = "您当前",color = display.COLOR_WHITE},
			{text = "VIP"..vipLv,color = cc.c3b(255,205,30)},
			{text = ",可购买BOSS挑战",color = display.COLOR_WHITE},
			{text = ""..vipCf[""..vipLv].challenge_BOSS_count,color = COLOR_GREEN},
			{text = "次",color = display.COLOR_WHITE},
			{text = "(已用完)\n",color = COLOR_RED},
			{text = "下一级",color = display.COLOR_WHITE},
			{text = "VIP"..(vipLv+1),color = cc.c3b(255,205,30)},
			{text = ",可购买BOSS挑战",color = display.COLOR_WHITE},
			{text = ""..vipCf[""..(vipLv+1)].challenge_BOSS_count,color = COLOR_GREEN},
			{text = "次",color = display.COLOR_WHITE},
			}
			alert:pop(richStr,"ui/titlenotice.png",btns)
		else
			btns = {{text = "确定",skin = 3}}
			alert = GameAlert.new()
			richStr = {{text = "您当前",color = display.COLOR_WHITE},
			{text = "VIP"..vipLv.."(最高级)",color = cc.c3b(255,205,30)},
			{text = ",可购买BOSS挑战",color = display.COLOR_WHITE},
			{text = ""..vipCf[""..vipLv].fighting_count,color = COLOR_GREEN},
			{text = "次",color = display.COLOR_WHITE},
			{text = "(已用完)\n",color = COLOR_RED},
			}
			alert:pop(richStr,"ui/titlenotice.png",btns)
		end
	end
end
--前去充值
function MapProcessor:sendChargeView()
	Observer.sendNotification(ChargeModule.SHOW_CHARGE_VIEW)
end
function MapProcessor:handleChongzhi()
	Observer.sendNotification(ChargeModule.SHOW_CHARGE_VIEW)
end
function MapProcessor:sendBuyChargeTime()
	local net = {}
	net.method = MapModule.USER_BUY_BOSS_COUNT
	net.params = {}
	Net.sendhttp(net)
end
function MapProcessor:onHideView(view)
	if self.view ~= nil then
		self.view:removeFromParent(true)
		self.view = nil
	end
	self.isshow = false
	TimeManager:remove(self)
end
--按钮的点击事件
function MapProcessor:onBtnClick(sender,eventType)
	-- 触摸完毕再触发事件
	if  eventType ~= TouchEventType.ended then 
		return
	end

	local btn = tolua.cast(sender,"ccui.Button")
	local btnName = btn:getName()

	if btnName == "btnClose" then
		self:removePopView(self.view)
	end
end

return MapProcessor