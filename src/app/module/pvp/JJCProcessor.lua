--竞技场处理器
local pvproleitem = import(".ui.pvproleitem")
local JJCProcessor = class("JJCProcessor", BaseProcessor)

function JJCProcessor:ctor()
	-- body
end

function JJCProcessor:ListNotification()
	return {
		PVPModule.UPDATE_PVP_ROLE,
		PVPModule.USER_GET_MY_RANK,
		PVPModule.USER_PK_COMBAT_PVP,
		PVPModule.PVP_TIMES_CHANGE,
		PVPModule.USER_BUY_PVP_COUNT,
	}
end

function JJCProcessor:handleNotification(notify, data)
	if notify == PVPModule.UPDATE_PVP_ROLE then
		if(self.view) then
			self:setData()
		end
	elseif notify == PVPModule.USER_PK_COMBAT_PVP then
		if(data.data.return_code == 0) then
			local pvpData = data.data.data
			BossPvpBattleManager:setTestResult(pvpData.data_info)
			PlayerData:setLastPvpTime(pvpData.pvp_time["$datetime"])
			PlayerData:setPVPTaskCompletedCount(pvpData.PVP_task_count)
			if(pvpData.sign == 1) then
				Observer.sendNotification(GamesysModule.UPDATE_GAME_TASK)--任务更新
			end
			if(self.view) then
				self:updateCoolDown()
			end
			self:updateOtherPlayerData(pvpData)
			BossPvpBattleManager:setPVPData(pvpData)
			GameInstance.getBossBattleSeedFromServer(pvpData.seed)
			BattlePrint("PVP seed = ", pvpData.seed)
			BattleModule.CUR_SHOW_TYPE = BattleModule.BOSS_PVP
			BossPvpBattleManager:battleBtnClick()
		end
	elseif notify == PVPModule.USER_GET_MY_RANK then
		if(self.view) then
			self:setData(data.data)       
		end
	elseif notify == PVPModule.PVP_TIMES_CHANGE then
		if(self.view) then
			self:updateChargeTime()
		end
	elseif notify == PVPModule.USER_BUY_PVP_COUNT then
		BossPvpBattleManager:setPVPChargeTimes(data.data.data.PVP_count)
		BossPvpBattleManager:setPVPChargeBuyTimes(data.data.data.challenge_PVP_count)
		local cost = PlayerData:getCoin() - data.data.data.coin
		
		PlayerData:setCoin(data.data.data.coin)
		local notices = {{"元宝:-"..cost},{"竞技场挑战次数+1",COLOR_GREEN}}
		popNotices(notices)
	end
end
function JJCProcessor:sendRequest(bRefresh)
	local net = {}
	net.method = PVPModule.USER_GET_MY_RANK
	net.params = {}
	net.params.refresh = bRefresh
	Net.sendhttp(net)
end
--根据服务器返回的其他玩家的基本数据刷新计算其他玩家的所有属性
function JJCProcessor:updateOtherPlayerData(data)
	local equipNum = 0
	local godImproveLv = 0
	for k,v in pairs(data.pvp_info.as_equips) do
		local edata = nil
		edata = DataConfig:getEquipById(v.eid)
		v.edata = edata
		Bag:updateEquipAttr(v)
		equipNum = equipNum + 1
		if(equipNum == 1) then
			godImproveLv = v.star
		else
			if(godImproveLv > v.star) then
				godImproveLv = v.star
			end
		end
	end
	if(equipNum <10) then
		godImproveLv = 0
	end
	--计算所有装备增加的基本属性，二级属性，神属性
	local baseAttrs = {0,0,0,0}--基本属性
	local addAttrs = {hp = 0,mp = 0,minDmg = 0,maxDmg = 0,arm = 0,deff = 0,adf = 0,cri = 0,hit = 0,dod = 0,res = 0,mps = 0,}--二级属性
	local godInfo = {}--神属性
	local tempBaseAttrs
	local tempAddAttrs
	local tempGodInfo
	local godCfg = DataConfig.data.cfg.god
	for i,v in pairs(data.pvp_info.as_equips) do
		tempBaseAttrs = v.color
		tempAddAttrs = v.attrs
		for i,vv in ipairs(baseAttrs) do
			baseAttrs[i] = baseAttrs[i] + tempBaseAttrs[i+1]
		end
		for k,vv in pairs(tempAddAttrs) do
			addAttrs[k] = addAttrs[k] + vv
		end
		tempGodInfo = v.godInfo
		local godStar = v.god[1]
		for k,vv in pairs(tempGodInfo) do
			if(not godInfo[k]) then
				godInfo[k] = 0
			end
			godInfo[k] = godInfo[k] + vv 
			if(godImproveLv > 0) then
				local proLv = math.min(godImproveLv,godStar)
				godInfo[k] = godInfo[k] + godCfg[k].unlock_base[1]*DataConfig:getGodUnlock()[tostring(proLv)] + godCfg[k].unlock_base[2]
				godInfo[k] = formatGodinfoNum(k,godInfo[k])
			end
		end
	end
	local lv = data.pvp_info.lv
	local job = data.pvp_info.hero_type
	local vars = DataConfig.data.cfg.system_simple.formula

	local attrs = {}
	local jobInfo = DataConfig:getJobById(""..job)
	for k,v in pairs(JobAttrConst) do
		attrs[k] = jobInfo.as[v][1] + jobInfo.as[v][2] * (lv-1)--职业成长基本属性
		attrs[k] = formatAttributeNum(k,attrs[k])
		attrs[k] = attrs[k] + baseAttrs[v]--装备增加基本属性
	end
	local mainAtr =attrs[jobInfo.ma]
	attrs.hp = PlayerData:calcBaseAttributesHp(attrs.sta) + addAttrs.hp
	attrs.mp = (PlayerData:calcBaseAttributesMp(lv) + addAttrs.mp)
	attrs.minDmg = PlayerData:calcBaseAttributesMinDmg(job,mainAtr) + addAttrs.minDmg
	attrs.maxDmg = PlayerData:calcBaseAttributesMaxDmg(job,mainAtr) + addAttrs.maxDmg
	attrs.arm = PlayerData:calcBaseAttributesArm(attrs.strr) + addAttrs.arm
	attrs.deff = (PlayerData:calcBaseAttributesDeff(attrs.strr) + addAttrs.deff)
	attrs.adf = (PlayerData:calcBaseAttributesAdf(attrs.intt) + addAttrs.adf)
	attrs.cri = (PlayerData:calcBaseAttributesCri(attrs.agi) + addAttrs.cri)
	attrs.hit = (PlayerData:calcBaseAttributesHit(attrs.strr) + addAttrs.hit)
	attrs.dod = (PlayerData:calcBaseAttributesDod(attrs.agi) + addAttrs.dod)
	attrs.res = (PlayerData:calcBaseAttributesRes(attrs.sta) + addAttrs.res)
	attrs.crd = PlayerData:calcBaseAttributesCrd(lv)
	attrs.mps = (PlayerData:calcBaseAttributesMps(attrs.intt) + addAttrs.mps)


	--神属性影响某些属性，计算
	if(godInfo["add_dam"]) then
		attrs.minDmg = attrs.minDmg*(1+godInfo["add_dam"])
		attrs.minDmg = formatAttributeNum("minDmg",attrs.minDmg)
		attrs.maxDmg = attrs.maxDmg*(1+godInfo["add_dam"])
		attrs.maxDmg = formatAttributeNum("maxDmg",attrs.maxDmg)
	end
	if(godInfo["add_hp"]) then
		attrs.hp = (attrs.hp*(1+godInfo["add_hp"]))
		attrs.hp = formatAttributeNum("hp",attrs.hp)
	end
	if(godInfo["add_crd"]) then
		attrs.crd = attrs.crd+godInfo["add_crd"]
		attrs.crd = formatAttributeNum("crd",attrs.crd)
	end
	if(godInfo["add_armor"]) then
		attrs.arm = (attrs.arm*(1+godInfo["add_armor"]))
		attrs.arm = formatAttributeNum("arm",attrs.arm)
	end
	if(godInfo["add_deff"]) then
		attrs.deff = attrs.deff*(1+godInfo["add_deff"])
		attrs.deff = formatAttributeNum("deff",attrs.deff)
	end
	if(godInfo["add_adf"]) then
		attrs.adf = attrs.adf*(1+godInfo["add_adf"])
		attrs.adf = formatAttributeNum("adf",attrs.adf)
	end
	if(godInfo["add_dod"]) then
		attrs.dod = attrs.dod*(1+godInfo["add_dod"])
		attrs.dod = formatAttributeNum("dod",attrs.dod)
	end
	if(godInfo["add_cri"]) then
		attrs.cri = attrs.cri*(1+godInfo["add_cri"])
		attrs.cri = formatAttributeNum("cri",attrs.cri)
	end
	if(godInfo["add_hit"]) then
		attrs.hit = attrs.hit*(1+godInfo["add_hit"])
		attrs.hit = formatAttributeNum("hit",attrs.hit)
	end
	if(godInfo["add_res"]) then
		attrs.res = attrs.res*(1+godInfo["add_res"])
		attrs.res = formatAttributeNum("res",attrs.res)
	end
	attrs.arm_rate = PlayerData:calcBaseAttributesArmRate(attrs.arm,lv)
	local powerVars = DataConfig.data.cfg.system_simple.combat_effective
	local power = 0
	if(powerVars) then
		local nums = {attrs.hp,attrs.mp,
		attrs.minDmg,attrs.maxDmg,attrs.arm,attrs.deff,
		attrs.adf,attrs.cri,attrs.res,attrs.hit,attrs.dod}
		for i,v in ipairs(powerVars) do
			power = power + powerVars[i]*nums[i]
		end
		local godparam = DataConfig.data.cfg.system_simple.get_power
		if(godInfo["suck_blood"]) then
			power = power + godparam[1]*godInfo["suck_blood"]*attrs.hp*0.1
		end
		if(godInfo["ignore_armor"]) then
			power = power + godparam[2]*godInfo["ignore_armor"]/(godInfo["ignore_armor"] + 100)*0.5*attrs.hp
		end  
		if(godInfo["anti_dam"]) then
			power = power + godparam[3]*godInfo["anti_dam"]*0.1*attrs.hp
		end
		if(godInfo["resist_debuff"]) then
			power = power + godparam[4]*godInfo["resist_debuff"]*0.1*attrs.hp
		end
	end
	attrs.power = math.floor(power)
	data.pvp_info.attrs = attrs
	data.pvp_info.godInfo = godInfo
	return data
end
--初始化UI显示
-- arg  预留 没用
function JJCProcessor:initUI(view)
	self:setView(view)
	self.scrollview = view:getChildByName("jjclist")
	self.toplayer = view:getChildByName("toplayer")
	self.btnBuyAll = view:getChildByName("btnBuyAll")
	self.btnRefresh = view:getChildByName("btnRefresh")	
	self.timesTxt = view:getChildByName("timesTxt")
	self.cooldownTxt = view:getChildByName("cooldownTxt")
	self.txtInfo = view:getChildByName("txtInfo")
	self.btnBuyAll:addTouchEventListener(handler(self,self.onBtnClick))
	self.btnRefresh:addTouchEventListener(handler(self,self.onBtnClick))
	self.cooldownleft = nil
	--self.cooldownTxt:setColor(cc.c3b(255,0,0))
	self:updateCoolDown()
	self:updateChargeTime()
end
function JJCProcessor:updateChargeTime()
	self.timesTxt:setString("今日剩余竞技场挑战次数："..BossPvpBattleManager.pvpChargeTimes)
	if(BossPvpBattleManager.pvpChargeTimes > 0) then
		self.timesTxt:setColor(cc.c3b(255,255,255))
	else
		self.timesTxt:setColor(cc.c3b(255,0,0))
	end
end
--
function JJCProcessor:updateCoolDown()
	local lastpvpsec = changeTimeStrToSec(PlayerData:getLastPvpTime())
	local endCoolSec = DataConfig:getPVPCoolDownMinute()*60 + lastpvpsec
	local needsec = endCoolSec - TimeManager:getSvererTime()
	if(needsec <= 0) then
		self.cooldownTxt:setVisible(false)
		TimeManager:remove(self)
	else
		self.cooldownTxt:setVisible(true)
		TimeManager:add(self)
		needsec = math.ceil(needsec)
		if(self.cooldownleft ~= needsec) then
			self.cooldownleft = needsec
			self.cooldownTxt:setString("挑战冷却时间:"..changeSecToDHMSStr(self.cooldownleft))
		end
	end
end
function JJCProcessor:clearAfterRemove()
	TimeManager:remove(self)
	self.cooldownleft = nil
end
function JJCProcessor:timeUpdate(dt)
	self:updateCoolDown()
end

function JJCProcessor:onBtnClick(sender, eventType)
print("eventType: ", eventType, TouchEventType.ended)
	if eventType ~= TouchEventType.ended then
		return
	end

	local btnName = sender:getName()
	print("btnName "..btnName)
	if btnName == "btnBuyAll" then
		local btns
		local alert
		local richStr
		if(DataConfig.data.cfg.system_simple.challenge_PVP_count <= BossPvpBattleManager.pvpChargeBuyTimes) then
			btns = {{text = "取消",skin = 3},}
			alert = GameAlert.new()
			richStr = {{text = "您今天的购买竞技场挑战次数已用完",color = COLOR_RED},}
			alert:pop(richStr,"ui/titlenotice.png",btns)
		else			
			local prices = DataConfig.data.cfg.system_simple.PVP_count_price
			local price = prices[1]*(BossPvpBattleManager.pvpChargeBuyTimes)+prices[2]
			btns = {{text = "取消",skin = 2},{text = "确定",skin = 1,callback = handler(self,self.sendBuyChargeTime)},}
			alert = GameAlert.new()
			richStr = {{text = "是否花费",color = display.COLOR_WHITE},
				{text = ""..price,color = COLOR_RED},
				{text = "元宝购买一次竞技场挑战次数？",color = display.COLOR_WHITE}}
			alert:pop(richStr,"ui/titlenotice.png",btns)
		end
	elseif btnName == "btnRefresh" then
		self:sendRequest(true)
	end
end
function JJCProcessor:sendBuyChargeTime()
	local prices = DataConfig.data.cfg.system_simple.PVP_count_price
	local price = prices[1]*(BossPvpBattleManager.pvpChargeBuyTimes)+prices[2]
	if(price > PlayerData:getCoin()) then
		--notice("元宝不足",COLOR_RED)
		btns = {{text = "取消",skin = 2},{text = "充值",skin = 1,callback = handler(self,self.sendChargeView)}}
		alert = GameAlert.new()
		richStr = {{text = "您的元宝不足，请您及时充值！",color = display.COLOR_WHITE}}
		alert:pop(richStr,"ui/titlenotice.png",btns)
		return
	end
	local net = {}
	net.method = PVPModule.USER_BUY_PVP_COUNT
	net.params = {}
	Net.sendhttp(net)
end
--前去充值
function JJCProcessor:sendChargeView()
	Observer.sendNotification(ChargeModule.SHOW_CHARGE_VIEW)
end
--设置数据
function JJCProcessor:setData(data)
	self.data = data
	self.scrollview:removeAllChildren()	
	local num = table.nums(self.data.data.pvp_list)	
    local rowPadding = 6
	local colNum = 1

	local w = 545
	local h = 108
	local leftPadding = (self.scrollview:getContentSize().width - w)/2

	--滚动条宽度
	local innerWidth = self.scrollview:getInnerContainerSize().width
	--设置滚动条内容区域大小
	self.scrollview:setInnerContainerSize(cc.size(innerWidth,math.max(math.ceil(num/colNum) * (h + rowPadding) + 20,self.scrollview:getContentSize().height)))

	local render = nil
	local innerHeight = self.scrollview:getInnerContainerSize().height
	--y起始坐标
	local ystart = innerHeight 

	local i = 1
	for k,v in pairs(self.data.data.pvp_list) do
		render = pvproleitem.new()
		v.jjcProcessor = self
		render:setData(v)
		render:setPosition(leftPadding ,ystart - math.modf(i/colNum)*(h + rowPadding))
		self.scrollview:addChild(render)
		i = i + 1
	end

	--显示自己
	self.toplayer:removeAllChildren()
	render = pvproleitem.new()
	render:setData(self.data.data.my_rank)
	render:hideBg()
	render:setPosition(10,0)
	self.toplayer:addChild(render)

	local msgs = DataConfig:getAllConfigMsg()
	self.txtInfo:setString(msgs["20015"])
	self:updateCoolDown()
end

return JJCProcessor