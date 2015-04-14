scheduler = require("framework.scheduler")
Player = require("app.components.Player")		--角色
local BattleManager = class("BattleManager")
--战斗过程中，是不能更改技能和队友的，更换操作后，这一局战斗胜利后，下一场生效
BattleDebug = false
function BattlePrint(...)
	local tempStr = ""
	--if(BattleDebug and BattleModule.CUR_SHOW_TYPE == BattleModule.BOSS_PVP) then
	if(BattleDebug) then
		arg = {...}
		for i,v in ipairs(arg) do
			tempStr = tempStr..tostring(v)
		end
		print(tempStr)
		if(not battlelog) then
			battlelog = assert(io.open("battlelog.log", 'w'))
		end
		battlelog:write(tempStr.."\n")
 	end
end
function BattleManager:ctor()
	--队友列表
	self.playerList = {}
	--敌人列表
	self.enemyList = {}
	--当前攻击者索引
	self.curFightIndex = 1
	--回合数
	self.circleNum = 0
	self.battleType = BattleModule.GUAJI
	self.curPlayer = nil
	self.bStart = false
	self.curFightNum = 0
	self.circleAttactTime = 0--一回合所有活人攻击一遍的时间

	self.state = nil--等待 或者 战斗状态
	self.stateStartTime = nil--当前状态开始时间
	self.stateEndTime = nil--当前状态持续到时间
	self.stateOneTime = nil--当前一次完整状态的时间
	self.fightEndTime = nil--一场结束时间
	self.fightOneTime = nil--一场时间
	self.fightLastTime = nil--一场已持续时间
	self.startedTime = nil--已开始时间
	self.curMapID = nil
end
function BattleManager:setCurState(state)
	self.state = state
end
function BattleManager:initBattleHangTime(btime)
	self.startHangTime = btime
end
function BattleManager:timeUpdate(dt)
	self.startedTime = TimeManager:getSvererTime()
	if(self.startedTime >= self.stateEndTime) then
		local lastTime = (self.startedTime - self.stateStartTime)
		while (lastTime-self.stateOneTime >= 0) do
			lastTime = lastTime - self.stateOneTime
			if(self.state == "wait") then
				self:updateWaitTime()--超过fightEndTime，改变状态为fight
			elseif(self.state == "fight") then
				self:updateOneAttack()--处理胜利，超时。 
				--设置attackStartTime等于上一个的attackEndTime，设置attackEndTime等于attackStartTime+oneAttackTime。如果全灭改变状态为wait}
			end
		end
	end
end
function BattleManager:start()
	self.startedTime = self.startHangTime
	self.fightEndTime = 0
	self.stateEndTime = self.startHangTime
	self.fightLastTime = 0
	self:initFight()	
	if(not TimeManager:isAdded(self)) then
		TimeManager:add(self)
	end
	self.bStart = true 
	if(TimeManager:getSvererTime() - self.startHangTime> 0) then
		self:timeUpdate(TimeManager:getSvererTime() - self.startHangTime)
	end
	--Observer.sendNotification(BattleModule.SHOW_BATTLE_UI)
end
function BattleManager:updateOneAttack()--更新一次攻击
	self.fightLastTime = self.fightLastTime + self.stateOneTime
	local curFighter
	while (not curFighter) do
		local tempIndex = self.curFightIndex % (#self.playerList + #self.enemyList)
		if(tempIndex == 1) then
			self.circleNum = self.circleNum + 1	
		end
		curFighter = self:getCurFighter()
	 	if(curFighter) then
	 		curFighter:processBeforeAttack()
	 		if(not curFighter.dead) then
				curFighter:attack()
			end
			self.result = self:bSucessed()
			if(self.result == true) then --提前胜利
				self:sendFightEnd()
				self:sendBattleLog("s4",{{"敌方全灭",},})
				self:sendBattleLog("s7",{{"",},})

				if(self.fightLastTime >= self.fightOneTime) then
					self:getReward()
					--初始化战斗
					self.fightLastTime = self.fightLastTime - self.fightOneTime
					self:initFight()
					while true do
						return
					end
				else
					--if(tempIndex == 0) then
					self.stateOneTime = 0.1
					self:setCurState("wait")
					--end
					self.stateStartTime = self.stateEndTime
					self.stateEndTime = self.stateStartTime + self.stateOneTime
					self:sendWaitNotification(self.fightOneTime - self.fightLastTime)
				end
				--print(self.fightLastTime)
				--print("胜利后等待时间",self.fightOneTime - self.fightLastTime)
			elseif(self.result == false) then
				self:sendFightEnd()
				for i,v in ipairs(self.playerList) do
					v:changeHP(v.maxHP)
				end
				for i,v in ipairs(self.enemyList) do
					v:changeHP(-v.maxHP,true)
					local data = {}
					data.beAttacked = v
					data.dam = v.maxHP
					data.bHit = true
					BattleModule.processor:updateHeadsHp(data)
				end
				self:sendBattleLog("s4",{{DataConfig:getAllConfigMsg()['20017'],},})
				self:sendBattleLog("s7",{{"",},})
				--player  changeHP(player.maxHP)
				--enemy
				--所有队友加满血
				--所有敌人造成999999999伤害


				if(self.fightLastTime >= self.fightOneTime) then
					self:getReward()
					self.fightLastTime = self.fightLastTime - self.fightOneTime
					self:initFight()
					while true do
						return
					end
				else
					--if(tempIndex == 0) then
					self.stateOneTime = 0.1
					self:setCurState("wait")
					--end
					self.stateStartTime = self.stateEndTime
					self.stateEndTime = self.stateStartTime + self.stateOneTime			
					self:sendWaitNotification(self.fightOneTime - self.fightLastTime)
				end	
			elseif(self.fightLastTime >= self.fightOneTime) then
				self:sendFightEnd(true)
				self:sendBattleLog("s4",{{"怪物突然记起要回家吃药，丢下你落荒而逃",},})
				self:getReward()
				self:sendBattleLog("s7",{{"",},})

				--初始化战斗
				self.fightLastTime = self.fightLastTime - self.fightOneTime
				self:initFight()
				while true do
					return
				end
			else
				self.stateOneTime = self.circleAttactTime/(self.liveAlliance + self.liveEnemy)
				self.stateStartTime = self.stateEndTime
				self.stateEndTime = self.stateStartTime + self.stateOneTime 
			end
		end
		self.curFightIndex = self.curFightIndex + 1
	end
end

function BattleManager:updateWaitTime()
	self.fightLastTime = self.fightLastTime + self.stateOneTime
	if(self.fightLastTime >= self.fightOneTime) then
		--初始化战斗
		if(self.fightLastTime - self.stateOneTime < self.fightOneTime) then
			self:sendWaitNotification(0)
		end
		self.fightLastTime = self.fightLastTime - self.fightOneTime
		self:getReward()		
		self:initFight()
	else
		self.stateOneTime = 0.1
		self.stateStartTime = self.stateEndTime
		self.stateEndTime = self.stateStartTime + self.stateOneTime 
		--更新界面
		self:sendWaitNotification(self.fightOneTime - self.fightLastTime)
	end	
end
--初始化战斗数据,因为地图，技能，装备等改变时，在下一次初始化才生效，所以这里不能是直接引用，要是深度拷贝
function BattleManager:initFight()
	--初始化
	self.curFightNum = self.curFightNum + 1
	self.playerList = {}
	self.enemyList = {}
	self.curFightIndex = 1
	self.circleNum = 0
	Raid:updateNextRaid()
	self.curMapID = Raid.curMapID
	local round_time = DataConfig:getRoundTimeByMapID(self.curMapID)
	self.circleAttactTime = round_time/1000
	--更改队友和敌人列表
	local enemys = self:getRandomMonsterFromMapID(self.curMapID)
	local newPlayer
	for i,v in ipairs(enemys) do
		newPlayer = Player.new(PlayerTypeMonster,v,self) 
		newPlayer.battleType = self.battleType
		newPlayer.battleIndex = i
		table.insert(self.enemyList,newPlayer)		
	end
	self.curPlayer = Player.new(PlayerTypePlayer,"W000",self)
	self.curPlayer.battleType = self.battleType
	self.curPlayer.battleIndex = 1
	table.insert(self.playerList, self.curPlayer)
	local curSolider = PlayerData:getOnworkSolider()
	if(curSolider and curSolider ~= "") then
		newPlayer = Player.new(PlayerTypeSolider,curSolider,self)
		newPlayer.battleType = self.battleType
		newPlayer.battleIndex = 2
		table.insert(self.playerList, newPlayer)
	end	
	self.liveAlliance = #self.playerList
	self.liveEnemy = #self.enemyList
	--更改技能列表
	--更改一场战斗的时间
	if(self.battleType == BattleModule.GUAJI) then		
		if(not DataConfig.data.cfg.system_simple.max_round) then
			DataConfig.data.cfg.system_simple.max_round = 0.125
		end
		self.fightOneTime =  DataConfig:getMapById(self.curMapID).hang.cd/1000 + DataConfig.data.cfg.system_simple.max_round*(DataConfig:getMapById(self.curMapID).map_lv - self.curPlayer.lv)
		self.fightOneTime = math.floor(math.floor(self.fightOneTime)/self.circleAttactTime)*self.circleAttactTime
	else
		self.fightOneTime = DataConfig.data.cfg.system_simple.round_max * self.circleAttactTime
	end
	--发送战斗通知
	
	Observer.sendNotification(BattleModule.GUAJI_BEGIN_FIGHT)
	for i,v in ipairs(self.enemyList) do
		self:sendBattleLog("s9",{{""..v.lv,},{v.playerName,{1,144,254}},{""..v.hp,},})
	end
	
	self:setCurState("fight")
	self.stateOneTime = self.circleAttactTime/(self.liveAlliance + self.liveEnemy)
	self.stateStartTime = self.stateEndTime
	self.stateEndTime = self.stateStartTime + self.stateOneTime 
	self.fightEndTime = self.fightEndTime + self.fightOneTime
end
function BattleManager:getAllFighterNum()
	return #self.playerList + #self.enemyList
end
function BattleManager:updateBuffer()
	for i,v in ipairs(self.playerList) do
		if(v.dead == false) then
			v:updateBuffer()
		end
	end
	for i,v in ipairs(self.enemyList) do
		if(v.dead == false) then
			v:updateBuffer()
		end
	end
end
function BattleManager:getCurFighter()
	local result
	local tempIndex = self.curFightIndex % (self:getAllFighterNum())
	if(tempIndex == 0) then
		result = self.enemyList[#self.enemyList]
	elseif(tempIndex <= #self.playerList) then
		result = self.playerList[tempIndex]
	elseif(tempIndex > #self.playerList) then
		result = self.enemyList[tempIndex - #self.playerList]
	end
	self:updateBuffer()
	--判斷是否死亡，死亡就一直找到同陣營的一個活的
	if(result and (result.dead == false) )then
		return result
	end
end
function BattleManager:sendWaitNotification(sec)
	local tempNode = display.newNode()
	local data = {}
	tempNode.data = data
	local left = sec
	data.time = math.ceil(left)
	if(left < 0.1) then
		data.time = 0
	end
	if(data.time == 0) then
		data.time = 0
	end
	Observer.sendNotification(BattleModule.GUAJI_WAIT_FOR_FIGHT,tempNode)
end
function BattleManager:sendFightEnd(bTimeOver)--bTimeOver是否时间耗尽
	local tempData = {}
	local tempNode = display.newNode()
	tempNode.data = tempData
	tempData.bTimeOver = bTimeOver
	Observer.sendNotification(BattleModule.GUAJI_FIGHT_END,tempNode)
end
function BattleManager:sendBattleLog(strFormat,strArgs)
	local tempData = {}
	local tempNode = display.newNode()
	tempNode.data = tempData
	tempData.strFormat = strFormat
	tempData.args = strArgs
	Observer.sendNotification(BattleModule.GUAJI_ADD_BATTLE_LOG,tempNode)
end
--战斗胜利(对方全死)返回true，失败（己方全死）返回false，未完成返回nil
function BattleManager:bSucessed()
	local liveAlliance = 0
	local liveEnemy = 0
	for k,v in pairs(self.enemyList) do
		if(v.dead == false) then
			liveEnemy = liveEnemy + 1
		end
	end
	for k,v in pairs(self.playerList) do
		if(v.dead == false) then
			liveAlliance = liveAlliance + 1
		end
	end

	self.liveAlliance = liveAlliance
	self.liveEnemy = liveEnemy

	if(liveEnemy == 0) then
		return true
	end
	if(liveAlliance == 0) then
		return false
	end
end
function BattleManager:getLivePlayers(playerType,bEnemy)
	local live = {}
	local temp
	if (playerType == PlayerTypePlayer or playerType == PlayerTypeSolider) then
		if(bEnemy) then
			temp = self.enemyList
		else
			temp = self.playerList
		end
	else
		if(bEnemy) then
			temp = self.playerList
		else
			temp = self.enemyList
		end
	end
	for k,v in pairs(temp) do
		if(v.dead == false) then
			table.insert(live, v)
		end
	end
	return live
end
function BattleManager:getRandomMonsterFromMapID(mapid)
	local monsters = DataConfig:getMapById(mapid).hang.wids
	monsters = monsters[math.random(#monsters)]
	return monsters
end
function BattleManager:battleBtnClick()
	if(not self.bStart) then
		self:start()
	end
	Observer.sendNotification(BattleModule.SHOW_BATTLE_UI)
end
function BattleManager:getReward()
	self:getRewardItem()
	self:getRewardExp()
	self:getRewardGold()
end
function BattleManager:getRewardExp()
	local curSeed = GameInstance.getServerRandom()
	BattlePrint("随机到经验seed=",curSeed)
	local rewardExp =math.randint(tonumber(DataConfig:getMapById(self.curMapID).hang.exp[1]),
		tonumber(DataConfig:getMapById(self.curMapID).hang.exp[2]),curSeed)
	BattlePrint("随机到经验=",rewardExp)
	local expCriPro = DataConfig.data.cfg.system_simple.get_exp
	local curSeed = GameInstance.getServerRandom()
	BattlePrint("随机到经验是否会心seed=",curSeed)
	local boolExpCri = math.random_occur2(expCriPro[1],curSeed)
	if(boolExpCri) then
		rewardExp = math.round(rewardExp * expCriPro[2])
		BattlePrint("暴击经验=",rewardExp)
	end
	if(self.curPlayer.godInfo and self.curPlayer.godInfo["add_exp"]) then--击败敌人经验获得增加
		rewardExp = math.floor(rewardExp*(1 + self.curPlayer.godInfo["add_exp"]))
		BattlePrint("神属性加成后经验=",rewardExp)
	end
	self:sendBattleLog("s5",{{""..rewardExp,},})
	--rewardExp = 0
	PlayerData:setExp(PlayerData:getExp() + rewardExp)
	return rewardExp
end
function BattleManager:getRewardGold()
	local curSeed = GameInstance.getServerRandom()
	BattlePrint("随机到金钱seed=",curSeed)
	local rewardGold =math.randint(DataConfig:getMapById(self.curMapID).hang.gold[1],
		DataConfig:getMapById(self.curMapID).hang.gold[2],curSeed)
	BattlePrint("随机到金钱=",rewardGold)
	if(self.curPlayer.godInfo and self.curPlayer.godInfo["add_gold"]) then--击败敌人银两增加
		rewardGold = math.floor(rewardGold*(1 + self.curPlayer.godInfo["add_gold"]))
		BattlePrint("神属性加成后金钱=",rewardGold)
	end
	self:sendBattleLog("s6",{{""..rewardGold,},})
	PlayerData:setGold(PlayerData:getGold() + rewardGold) 
	return rewardGold
end
function BattleManager:getRewardItem()
	--是否可随机到装备
	local curSeed = GameInstance.getServerRandom()
	local drop = DataConfig:getDropRateByMapIdAndPlayerLV(self.curMapID)
	BattlePrint("是否可随机到掉落seed=",curSeed)
	local bGetItem = math.random_occur2(drop,curSeed)
	BattlePrint("是否随机到掉落=",bGetItem)
	if(not bGetItem) then
		return
	end
	--随机到装备的eid
	local eid
	local tempPros ={}
	for i,v in ipairs(DataConfig:getMapById(self.curMapID).hang.equip.eids) do
		table.insert(tempPros,{v,1000})
	end
	curSeed = GameInstance.getServerRandom()
	BattlePrint("随机到掉落seed=",curSeed)
	eid = math.random_choice2(tempPros,curSeed)
	--如果随机到宝箱
	if(string.sub(eid,1,2) == "I5") then
		BattlePrint("随机到宝箱")
		BattlePrint("随机到宝箱eid=",eid)
		local giftkeyID = "I3"..string.sub(eid,3)
		local giftkey = Bag:getGoodsById(giftkeyID)
		BattlePrint("giftkeyID=",giftkeyID)
		if(giftkey and giftkey.num >0) then
			BattlePrint("giftkey.num=",giftkey.num)
			Bag:addGoods(giftkeyID,giftkey.num-1)
			local gifts = DataConfig:getGiftBoxByID(eid)
			local giftPros = DataConfig:getGiftBoxGiftNumAreaByID(eid)
			curSeed = GameInstance.getServerRandom()
			BattlePrint("seed=",curSeed)
			local giftKind = math.random_choice2(gifts,curSeed)

			local resNum
			if(giftKind == "coin") then
				curSeed = GameInstance.getServerRandom()
				BattlePrint("coin seed=",curSeed)
				resNum = math.randint(giftPros.coin[1], giftPros.coin[2], curSeed)
				PlayerData:setCoin(resNum + PlayerData:getCoin())
				self:sendBattleLog("s24",{{DataConfig:getGoodByID(eid).name..",开出元宝*"..resNum},})
			elseif(giftKind == "gold") then
				curSeed = GameInstance.getServerRandom()
				BattlePrint("gold seed=",curSeed)
				resNum = math.randint(giftPros.gold[1], giftPros.gold[2], curSeed)
				PlayerData:setGold(resNum + PlayerData:getGold())
				self:sendBattleLog("s24",{{DataConfig:getGoodByID(eid).name..",开出银两*"..resNum},})
			elseif(giftKind == "I0001") then
				curSeed = GameInstance.getServerRandom()
				BattlePrint("I0001 seed=",curSeed)
				resNum = math.randint(giftPros.I0001[1], giftPros.I0001[2], curSeed)
				local tempData = Bag:getGoodsById("I0001")
				if(tempData) then
					Bag:addGoods("I0001",tempData.num + resNum)
				else
					Bag:addGoods("I0001",1)
				end
				self:sendBattleLog("s24",{{DataConfig:getGoodByID(eid).name..",开出强化精华*"..resNum},})
				Observer.sendNotification(BagModule.UPDATE_EQUIP_ATTR)
			else
				BattlePrint("giftKind =",giftKind)
				BattlePrint("do not need seed")
				local tempData = Bag:getGoodsById(giftKind)
				if(tempData) then
					Bag:addGoods(giftKind,tempData.num + 1)
				else
					Bag:addGoods(giftKind,1)
				end
				self:sendBattleLog("s24",{{DataConfig:getGoodByID(eid).name..",开出 "..DataConfig:getGoodByID(giftKind).name},})
				Observer.sendNotification(BagModule.UPDATE_EQUIP_ATTR)
			end	
		else
			self:sendBattleLog("s24",{{DataConfig:getGoodByID(eid).name..",没有"..DataConfig:getGoodByID(giftkeyID).name..",灰溜溜的走开"},})
		end
		return
	end
	--如果随机到的不是宝箱
	--随即到装备的品质
	BattlePrint("随机到装备")
	BattlePrint("随机到装备eid=",eid)
	local resColor
	local color_cf = DataConfig:getMapById(self.curMapID).hang.equip.color or DataConfig.data.cfg.system_simple.random_color
	color_cf = clone(color_cf)
	if(self.curPlayer.godInfo and self.curPlayer.godInfo["add_chance"]) then--提高高品质装备（紫颜色及以上）的掉率,
		for i=4,#color_cf do
			color_cf[i][2] = math.round(color_cf[i][2]*(1+self.curPlayer.godInfo["add_chance"]))
		end
	end
	local is_god = false
	curSeed = GameInstance.getServerRandom()
	BattlePrint("随机到品质seed=",curSeed)
    resColor = math.random_choice2(color_cf, curSeed)
    BattlePrint("随机到品质=",resColor)
    if (resColor == 5) then
        is_god = true
        resColor = 4
    end

    local itemNum =table.nums(Bag:getAllEquip(nil,"bag"))
    local iData = DataConfig:getEquipById(eid)
	self:sendBattleLog("s10",{{iData.name,getEquipColor(resColor)},})

    local bSell = false
    if(itemNum>=PlayerData:getBagMax()) then
    	bSell = true
    else
    	if(GameInstance.autosellcolor[resColor+1] and GameInstance.autosellcolor[resColor+1] == 1) then
			bSell = true
		end
    	if(GameInstance.autoselljob == true) then
    		local equipJob = tonumber(string.sub(eid,2,2))
    		local playerJob = tonumber(PlayerData:getHeroType())
    		if((equipJob ~= 3) and (equipJob+1 ~= playerJob) and (resColor < 4)) then
    			bSell = true
    		end
    	end
    end
    if(bSell) then
    	--自动卖出并获得银两    	
    	local addMoney = DataConfig:getItemSellMoney(resColor,eid)
    	PlayerData:setGold(PlayerData:getGold() + addMoney)
    	self:sendBattleLog("s14",{{iData.name,getEquipColor(resColor)},{""..addMoney,{0,0,0}},})
    	return
    end
    --根据装备的品质随机出属性类型
    --[[
	白-0个属性
	绿-1个属性（4个基础属性里随机选1个）
	蓝-2个属性（4个基础属性里随机选2个）+
	紫-3个属性（4个基础属性里随机选3个）
	橙-4个属性
	神器-4个属性
	]]
	local dataAttr = {0,0,0,0}
	local resAttrs = {}
    local attrs = {1,2,3,4}--力敏智耐
    for i=1,resColor do
    	local tempAttrs = {}
    	for i,v in ipairs(attrs) do
			table.insert(tempAttrs,{v,1000})
		end
		curSeed = GameInstance.getServerRandom()
		BattlePrint("随机到第"..i.."个属性seed=",curSeed)
		local curAttr = math.random_choice2(tempAttrs,curSeed)
		table.removebyvalue(attrs, curAttr)
		resAttrs[i] = curAttr--添加curAttr
	end
	--【按照力敏智耐的顺序随机出属性数值，随机出是否会心】
	local e_lv = checkint(string.sub(eid, 4, -2))
	if(resColor>0) then
		local vars = DataConfig.data.cfg.system_simple.equip_make.equip_attrs
		for i,v in ipairs(resAttrs) do
			curSeed = GameInstance.getServerRandom()
			BattlePrint("随机到第"..i.."个g--->seed=",curSeed)
			local g = math.randfloat(0,vars[4],curSeed)
			dataAttr[v] =   (g+1)*(vars[1]*e_lv*e_lv + vars[2]*e_lv + vars[3])
			local equipPosition = tonumber(string.sub(eid, 3, 3))
			local locations = DataConfig.data.cfg.system_simple.equip_make.location
			if(locations) then
				dataAttr[v] = dataAttr[v] * locations[equipPosition+1]
			end
			curSeed = GameInstance.getServerRandom()
			BattlePrint("随机到属性会心seed=",curSeed)
			if(math.random_occur2(vars[5],curSeed)) then
				dataAttr[v] = vars[6] * dataAttr[v]
			end
			dataAttr[v] = math.ceil(dataAttr[v])
		end
	end
	table.insert(dataAttr,1,resColor)		
	--随机出打孔的数量
	local holes = {}
	local hole_cf = DataConfig:getMapById(self.curMapID).hang.equip.hole or DataConfig.data.cfg.system_simple.equip_hole.random_pro
	local h_cf
	local holeNum
	if(PlayerData:getLv() >= DataConfig.data.cfg.system_simple.equip_hole.user_lv_limit and e_lv >= DataConfig.data.cfg.system_simple.equip_hole.equip_lv_limit) then
		local tempArray
		local minLv
		local maxLv
		for i,v in ipairs(hole_cf) do
			tempArray = string.split(v[1],"-")
			minLv = tonumber(tempArray[1])
			maxLv = tonumber(tempArray[2])
			if(e_lv >= minLv and e_lv <= maxLv) then
				h_cf = v[2]
				break
			end
		end
	end
	if(not h_cf) then
		holeNum = 0
	else
		curSeed = GameInstance.getServerRandom()
		BattlePrint("随机到打孔数量seed=",curSeed)
		holeNum = math.random_choice2(h_cf,curSeed)
		holeNum = math.min(DataConfig.data.cfg.system_simple.equip_hole.color_limit[resColor+1],holeNum)
	end
	for i=1,holeNum do
		table.insert(holes,"")
	end
	--神器处理
	local god_info
	if(is_god) then
		god_info = {1,0}
		local godCfg = DataConfig.data.cfg.system_simple.equip_god
		local p1 = tonumber(string.sub(eid,3,3))
		for i,v in ipairs(godCfg[p1+1]) do
			curSeed = GameInstance.getServerRandom()
			BattlePrint("随机神属性seed=",curSeed)
			if(math.random_occur2(v[2],curSeed)) then
				table.insert(god_info,v[1])
			end			
		end		
	else
		god_info = {}
	end
	--强化等级
	local star = 0

	--生成装备数据
	local equipData = {}
	equipData['eid'] = eid
    equipData['color'] = dataAttr
    equipData['star'] = 0
    equipData['god'] = god_info
    equipData['hole'] = holes

	local sid = GameInstance.getNextHangEquipNum()
	Bag:addEquip("eh"..sid,equipData)
	Observer.sendNotification(BagModule.EQUIP_NUM_UPDATE) --数量更新
	Observer.sendNotification(BagModule.UPDATE_EQUIP_ATTR)
    return equipData
end
--获得随机num个攻击单位
function BattleManager:getRandomPlayers(aPlayer,num,bEnemy)
	local temp = self:getLivePlayers(aPlayer.playerType,bEnemy)
	if(#temp <= num) then
		return temp
	end
	local result = {}
	local index
	--math.randomseed(tostring(os.time()):reverse():sub(1, 6))
	for i=1,num do
		index = math.random(#temp)
		table.insert(result,temp[index])
		table.remove(temp,index)
	end
	return result
end
--某一方当前气血最低的对象
function BattleManager:getLeastHpPlayers(pType,num,bEnemy)
	local temp = self:getLivePlayers(pType,bEnemy)
	if(#temp <= num) then
		return temp
	end
	
	table.sort( temp, 
		function (a,b)
			if(a.hp/a.maxHP ~= b.hp/b.maxHP) then
				return a.hp/a.maxHP < b.hp/b.maxHP
			end
			return a.battleIndex < b.battleIndex
		end
	 )
	local result = {}
	for i=1,num do
		table.insert(result,temp[i])
	end
	return result
end
--跟随上次攻击目标选择这一次的目标（多余随机取，不够从其他活人中补）
function BattleManager:getTargetsFromLast(lastAttacked,curNum)
	local result = {}
	local curSeed
	local tempEnemy
	if(#lastAttacked > curNum) then
		--math.randomseed(tostring(os.time()):reverse():sub(1, 6))
		for i=1,curNum do
			index = math.random(#lastAttacked)
			table.insert(result,lastAttacked[index])
			table.remove(lastAttacked,index)
		end
	elseif(#lastAttacked < curNum) then
		local temp = self:getLivePlayers(lastAttacked[1].playerType,false)
		if(#temp <= curNum) then
			result = temp
		else
			local addNum = (curNum - #lastAttacked)
			for i,v in ipairs(lastAttacked) do
				for i2,v2 in ipairs(temp) do
					if(v2 == v) then
						table.remove(temp,i2)
						break
					end
				end
			end
			--math.randomseed(tostring(os.time()):reverse():sub(1, 6))
			for i=1,addNum do
				index = math.random(#temp)
				table.insert(lastAttacked,temp[index])
				table.remove(temp,index)
			end
			result = lastAttacked
		end		
	else
		result = lastAttacked
	end
	return result
end
--获得神属性抵挡不良状态是否生效
function BattleManager:getGodProtectSuc(rate)
	--math.randomseed(tostring(os.time()):reverse():sub(1, 6))
	if(math.random() <= rate) then
		return true
	else
		return false
	end
end
--获得是否概率发生
function BattleManager:getRandomCanHappen(rate)
	--math.randomseed(tostring(os.time()):reverse():sub(1, 6))
	if(math.random() <= rate) then
		return true
	else
		return false
	end
end
--获得是否命中
function BattleManager:getBoolHit(rate)
	--math.randomseed(tostring(os.time()):reverse():sub(1, 6))
	if(math.random() <= rate) then
		return true
	else
		return false
	end
end
--获得是否会心
function BattleManager:getBoolCri(rate)
	--math.randomseed(tostring(os.time()):reverse():sub(1, 6))
	if(math.random() <= rate) then
		return true
	else
		return false
	end
end
--获得外攻
function BattleManager:getAttackPower(aPlayer)
	local tempMin = aPlayer.minDmg + math.toint(aPlayer.attrCalBuffers["dam"][1]*aPlayer.minDmg
		+aPlayer.attrCalBuffers["dam"][2])
	local tempMax = aPlayer.maxDmg + math.toint(aPlayer.attrCalBuffers["dam"][1]*aPlayer.maxDmg
		+aPlayer.attrCalBuffers["dam"][2])
	return math.random(tempMin,tempMax)
end
--离线挂机奖励
function BattleManager:noticeOffLineReward()
	BattleModule:sendHangclear(false)
end
function BattleManager:clear()
	TimeManager:remove(self)
	--队友列表
	self.playerList = {}
	--敌人列表
	self.enemyList = {}
	--当前攻击者索引
	self.curFightIndex = 1
	--回合数
	self.circleNum = 0
	self.battleType = BattleModule.GUAJI
	self.curPlayer = nil
	self.bStart = false
	self.curFightNum = 0
	self.circleAttactTime = 0--一回合所有活人攻击一遍的时间

	self.state = nil--等待 或者 战斗状态
	self.stateStartTime = nil--当前状态开始时间
	self.stateEndTime = nil--当前状态持续到时间
	self.stateOneTime = nil--当前一次完整状态的时间
	self.fightEndTime = nil--一场结束时间
	self.fightOneTime = nil--一场时间
	self.fightLastTime = nil--一场已持续时间
	self.startedTime = nil--已开始时间
	self.startHangTime = nil
	BattleModule.CUR_SHOW_TYPE = BattleModule.GUAJI
end
return BattleManager