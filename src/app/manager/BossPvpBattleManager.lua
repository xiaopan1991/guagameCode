scheduler = require("framework.scheduler")
Player = require("app.components.Player")		--角色
local BossPvpBattleManager = class("BossPvpBattleManager")
--战斗过程中，是不能更改技能和队友的，更换操作后，这一局战斗胜利后，下一场生效
function BossPvpBattleManager:ctor()
	--队友列表
	self.playerList = {}
	--敌人列表
	self.enemyList = {}
	--当前攻击者索引
	self.curFightIndex = 1
	--回合数
	self.circleNum = 0
	self.battleType = BattleModule.BOSS_PVP
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
	self.nextMapID = nil
	self.result = nil
	self.startWaitTime = 3
	self.endWaitTime = 3
end
function BossPvpBattleManager:setCurState(state)
	self.state = state
end

function BossPvpBattleManager:setPVPChargeBuyTimes(times)
	self.pvpChargeBuyTimes = times
end

function BossPvpBattleManager:setPVPChargeTimes(times)
	self.pvpChargeTimes = times
	Observer.sendNotification(PVPModule.PVP_TIMES_CHANGE)
end
function BossPvpBattleManager:setBossChargeBuyTimes(times)
	self.bossChargeBuyTimes = times
end
function BossPvpBattleManager:setTestResult(testResult)
	self.testResult = testResult
end
function BossPvpBattleManager:setBossChargeTimes(times)
	self.bossChargeTimes = times
	Observer.sendNotification(MapModule.BOSS_TIME_CHANGE)
end
function BossPvpBattleManager:requestReward()
	if(self.result and self.modle == "boss") then
	    local net = {}
		net.method = BattleModule.USER_GET_PK_BOSS_REWARD
		net.params = {}
		Net.sendhttp(net)	    
	elseif(self.modle == "pvp") then
		if(self.pvpData and self.pvpData.PVP_count) then
			self:setPVPChargeTimes(self.pvpData.PVP_count)
		end
		if(self.pvpData) then
			PlayerData:setGold(PlayerData:getGold()+self.pvpData.pvp_reward.gold)
			PlayerData:setMana(PlayerData:getMana()+self.pvpData.pvp_reward.mana)
			self:sendBattleLog("s6",{{""..self.pvpData.pvp_reward.gold,},})
			self:sendBattleLog("s30",{{""..self.pvpData.pvp_reward.mana,},}) 
		end
	end
end
function BossPvpBattleManager:getReward(data)
	self:sendBattleLog("s5",{{""..data.exp,},})
	self:sendBattleLog("s6",{{""..data.gold,},}) 
	PlayerData:setGold(PlayerData:getGold() + data.gold) 
	PlayerData:setExp(PlayerData:getExp() + data.exp)
	--Bag:addEquip("eh11",self.result.item)
	local iData
	for k,v in pairs(data.equip) do
		iData = DataConfig:getEquipById(v.eid)
	    self:sendBattleLog("s10",{{iData.name,getEquipColor(v.color[1])},})
	end
	if(data.pith) then
		self:sendBattleLog("s10",{{"强化精华*"..data.pith,{0,255,0}},})
	end   
    self:sendBattleLog("s7",{{"",},})
end
function BossPvpBattleManager:setPVPData(data)
	self.pvpData = data
end
function BossPvpBattleManager:setCurMap(mapID)
	if(self.curMapID) then
		self.nextMapID = mapID
		local tempNode = display.newNode()
		local data = {}
		tempNode.data = data
		if(type(mapID) == "string") then
			data.nextType = 0
		else
			data.nextType = 1
		end
		Observer.sendNotification(BattleModule.BOSS_PVP_SHOW_NEXT,tempNode)		
	else
		self.curMapID = mapID
	end
	
end
function BossPvpBattleManager:timeUpdate(dt)
	dt = math.min(dt,0.1)--boss战不需要跟服务端时间严格一致，所以不需要一定要跳跃
	self.startedTime = self.startedTime + dt
	if(self.startedTime > self.stateEndTime) then
		local lastTime = (self.startedTime - self.stateStartTime)
		while (lastTime-self.stateOneTime > 0) do
			lastTime = lastTime-self.stateOneTime
			if(self.state == "wait") then
				self:updateWaitTime()--超过fightEndTime，改变状态为fight
			elseif(self.state == "fight") then
				self:updateOneAttack()--处理胜利，超时。
				--设置attackStartTime等于上一个的attackEndTime，设置attackEndTime等于attackStartTime+oneAttackTime。如果全灭改变状态为wait}
			end
		end
	end
end
function BossPvpBattleManager:start()
	if(not self.curMapID) then
		return
	end
	self.startedTime = 0
	self.fightEndTime = 0
	self.stateEndTime = 0
	self.fightLastTime = 0
	self:initFight()
	if(not TimeManager:isAdded(self)) then
		TimeManager:add(self)
	end
	self.bStart = true 
	Observer.sendNotification(BattleModule.SHOW_BATTLE_UI)
end
function BossPvpBattleManager:requestBossChange()
	if(type(self.curMapID) == "string") then
		local net = {}
		net.method = BattleModule.USER_PK_COMBAT_MAIN
		net.params = {}
		net.params.mid = self.curMapID
		Net.sendhttp(net)
	else
		local net = {}
		net.method = PVPModule.USER_PK_COMBAT_PVP
		net.params = {}
		net.params.uid = self.curMapID.uid
		net.params.rank = self.curMapID.rank
		Net.sendhttp(net)
	end
end
function BossPvpBattleManager:over()
	if(self.nextMapID) then
		if(type(self.nextMapID) == "string") then
			if(self.bossChargeTimes > 0) then--挑战次数是否大于0
				self.curMapID = self.nextMapID
			else
				self.curMapID = nil
			end
		else
			if(self.pvpChargeTimes > 0) then
				self.curMapID = self.nextMapID
			else
				self.curMapID = nil
			end
		end
		self.nextMapID = nil
	else
		self.curMapID = nil
		self.nextMapID = nil
	end
	self.bStart = false
	if(not self.curMapID) then
		BattleModule.CUR_SHOW_TYPE = BattleModule.GUAJI
		Observer.sendNotification(BattleModule.UPDATE_SWITCH)		
	else
		self:requestBossChange()
	end
	TimeManager:remove(self)
end
function BossPvpBattleManager:updateBossSkill()--更新一次攻击
	if(self.modle == "boss") then
		if(not self.bossPlayer.dead) then
			local bossskill = DataConfig.data.cfg.system_simple.boss_crazy
	        local can
	        for i,v in ipairs(bossskill.start_round) do
	        	if(self.circleNum == v) then
	        		can = true
	        		break
	        	end
	        end
	        if(can) then
	        	local addrate = bossskill.add_rate[1]*self.bossPlayer.lv + bossskill.add_rate[2]
	        	for k,v in pairs(bossskill.add_attr) do
	        		self.bossPlayer:addBuffer(v,{v,0,0,{addrate,0},bossskill.last_round},1)
	        	end
	        	self.bossPlayer:sendUseSkillInfo(bossskill.name)
	        end		
		end
	end
end
function BossPvpBattleManager:updateOneAttack()--更新一次攻击
	self.fightLastTime = self.fightLastTime + self.stateOneTime
	local curFighter
	while (not curFighter)  do
	 	--todo
	 	local tempIndex = self.curFightIndex % (#self.playerList + #self.enemyList)
		if(tempIndex == 1) then
			self.circleNum = self.circleNum + 1	
			self:updateBossSkill()
            BattlePrint('--------------------', self.circleNum ,'--------------------')
            BattlePrint('--------------------队伍A--------------------')
			for i,v in ipairs(self.playerList) do
				BattlePrint('name is ', v.playerName)
				BattlePrint('hp is ', v.hp)
				BattlePrint('mp is ', v.mp)
			end	
            BattlePrint('--------------------队伍B--------------------')
			for i,v in ipairs(self.enemyList) do
				BattlePrint('name is ', v.playerName)
				BattlePrint('hp is ', v.hp)
				BattlePrint('mp is ', v.mp)
			end
			if(self.circleNum > DataConfig.data.cfg.system_simple.round_max) then
				self:sendFightEnd(false)
				self:sendBattleLog("s11",{{"时间耗尽，挑战失败",{0,255,0}},})
				self:sendBattleLog("s7",{{"",},})
				self:setCurState("wait")
				self.stateOneTime = 0.1
				self.stateStartTime = self.stateEndTime
				self.stateEndTime = self.stateStartTime + self.stateOneTime
				--self.fightOneTime =  self.fightLastTime + 3
				self:requestReward()
				return
			end	
		end		
	 	curFighter = self:getCurFighter()
	 	if(curFighter) then
	 		curFighter:processBeforeAttack()
			if(not curFighter.dead) then
				curFighter:attack()
			end
			self.result = self:bSucessed()
			if(self.result == true) then --提前胜利
				self:sendFightEnd(self.result)
				if(self.modle == "boss") then
					self:sendBattleLog("s4",{{"挑战成功，你干掉了BOSS",},})
				else
					self:sendBattleLog("s4",{{"挑战成功，你干掉了对手",},})
				end
				self:sendBattleLog("s7",{{"",},})
				self:setCurState("wait")
				self.stateOneTime = 0.1
				self.stateStartTime = self.stateEndTime
				self.stateEndTime = self.stateStartTime + self.stateOneTime
				self.fightOneTime =  self.fightLastTime + self.endWaitTime
				self:requestReward()
				--self:sendWaitNotification(self.fightOneTime - self.fightLastTime,2)
			elseif(self.result == false) then
				self:sendFightEnd(self.result)
				if(self.modle == "boss") then
					self:sendBattleLog("s11",{{"挑战失败，你被BOSS干掉了",{0,255,0}},})
				else
					self:sendBattleLog("s11",{{"挑战失败，你被对手干掉了",{0,255,0}},})
				end		
				self:sendBattleLog("s7",{{"",},})
				self:setCurState("wait")
				self.stateOneTime = 0.1
				self.stateStartTime = self.stateEndTime
				self.stateEndTime = self.stateStartTime + self.stateOneTime
				self.fightOneTime =  self.fightLastTime + self.endWaitTime
				self:requestReward()
				--self:sendWaitNotification(self.fightOneTime - self.fightLastTime,2)
			elseif(self.fightLastTime >= self.fightOneTime-self.endWaitTime) then
				self:sendFightEnd(false)
				self:sendBattleLog("s11",{{"时间耗尽，挑战失败",{0,255,0}},})
				self:sendBattleLog("s7",{{"",},})
				self:setCurState("wait")
				self.stateOneTime = 0.1
				self.stateStartTime = self.stateEndTime
				self.stateEndTime = self.stateStartTime + self.stateOneTime
				--self.fightOneTime =  self.fightLastTime + 3
				self:requestReward()
				--self:sendWaitNotification(self.fightOneTime - self.fightLastTime,2)
			else
				self.stateOneTime = self.circleAttactTime/(self.liveAlliance + self.liveEnemy)
				self.stateStartTime = self.stateEndTime
				self.stateEndTime = self.stateStartTime + self.stateOneTime 
			end
 		end
 		self.curFightIndex = self.curFightIndex + 1
	 end	
end
function BossPvpBattleManager:updateWaitTime()
	self.fightLastTime = self.fightLastTime + self.stateOneTime
	if(self.fightLastTime >= self.fightOneTime) then
		self:sendWaitNotification(0,2)
		self:over()
	elseif(self.fightLastTime >= self.fightOneTime - self.endWaitTime) then--战斗结束后等待3！2！1！
		self:setCurState("wait")
		self.stateOneTime = 1
		self.stateStartTime = self.stateEndTime
		self.stateEndTime = self.stateStartTime + self.stateOneTime 
		--更新界面
		self:sendWaitNotification(self.fightOneTime - self.fightLastTime,2)
	elseif(self.fightLastTime >= self.startWaitTime) then--开始等待之后，开始战斗
		self:setCurState("fight")
		self.stateOneTime = self.circleAttactTime/(self.liveAlliance + self.liveEnemy)
		self.stateStartTime = self.stateEndTime
		self.stateEndTime = self.stateStartTime + self.stateOneTime
		self:sendWaitNotification(0,3)
	else--开始等待3！2！1!
		self.stateOneTime = 1
		self.stateStartTime = self.stateEndTime
		self.stateEndTime = self.stateStartTime + self.stateOneTime 
		--更新界面
		self:sendWaitNotification(self.startWaitTime - self.fightLastTime,3)
	end	
end
--初始化战斗数据,因为地图，技能，装备等改变时，在下一次初始化才生效，所以这里不能是直接引用，要是深度拷贝
function BossPvpBattleManager:initFight()
	--初始化
	self.curFightNum = self.curFightNum + 1
	self.playerList = {}
	self.enemyList = {}
	self.curFightIndex = 1
	self.circleNum = 0
	
	--更改队友和敌人列表
	if(type(self.curMapID) == "string") then
		local round_time = DataConfig:getRoundTimeByMapID(self.curMapID)
		self.circleAttactTime = round_time/1000
		self.modle = "boss"
		local bosses = DataConfig:getMapById(self.curMapID).boss.wids[1]	
		for i,v in ipairs(bosses) do
			local bossPlayer
			if(DataConfig:getBossById(v)) then
				bossPlayer= Player.new(PlayerTypeBoss,v,self)
				self.bossPlayer = bossPlayer
			else
				bossPlayer= Player.new(PlayerTypeMonster,v,self)
			end		 
			bossPlayer.battleType = self.battleType
			bossPlayer.battleIndex = i
			table.insert(self.enemyList,bossPlayer)
		end
	else
		self.circleAttactTime = DataConfig.data.cfg.system_simple.round_time / 1000
		self.modle = "pvp"
		local pvplayer = Player.new(PlayerTypeOtherPlayer,pvpData,self)
		pvplayer.battleType = self.battleType
		pvplayer.battleIndex = 1
		table.insert(self.enemyList,pvplayer)
	end
	self.curPlayer = Player.new(PlayerTypePlayer,"W000",self)
	self.curPlayer.battleType = self.battleType
	self.curPlayer.battleIndex = 1
	table.insert(self.playerList, self.curPlayer)
	local curSolider = PlayerData:getOnworkSolider()
	if(self.modle == "boss" and curSolider and curSolider ~= "") then
		newPlayer = Player.new(PlayerTypeSolider,curSolider,self) 
		newPlayer.battleType = self.battleType
		newPlayer.battleIndex = 2
		table.insert(self.playerList, newPlayer)
	end

	self.liveAlliance = #self.playerList
	self.liveEnemy = #self.enemyList
	--更改技能列表
	--更改一场战斗的时间
	if(self.battleType == 1) then		
		if(not DataConfig.data.cfg.system_simple.max_round) then
			DataConfig.data.cfg.system_simple.max_round = 0.125
		end
		self.fightOneTime =  DataConfig:getMapById(Raid.curMapID).hang.cd/1000 + DataConfig.data.cfg.system_simple.max_round*(DataConfig:getMapById(Raid.curMapID).map_lv - self.curPlayer.lv)

		self.fightOneTime = math.floor(math.floor(self.fightOneTime)/self.circleAttactTime)*self.circleAttactTime
	else
		self.fightOneTime = DataConfig.data.cfg.system_simple.round_max * self.circleAttactTime
		--self.fightOneTime = 5
	end
	--发送战斗通知
	Observer.sendNotification(BattleModule.BOSS_PVP_BEGIN_FIGHT)
	for i,v in ipairs(self.enemyList) do
		self:sendBattleLog("s9",{{""..v.lv,},{v.playerName,{1,144,254}},{""..v.hp,},})
	end


	self.fightOneTime = self.fightOneTime + self.endWaitTime +self.startWaitTime
	self:setCurState("wait")
	self.stateOneTime = 0.1
	self.stateStartTime = self.stateEndTime
	self.stateEndTime = self.stateStartTime + self.stateOneTime 
	self.fightEndTime = self.fightEndTime + self.fightOneTime
end
function BossPvpBattleManager:getAllFighterNum()
	return #self.playerList + #self.enemyList
end
function BossPvpBattleManager:updateBuffer()
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
function BossPvpBattleManager:getCurFighter()
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
	if( result and (result.dead == false) )then
		return result
	end
end
function BossPvpBattleManager:sendWaitNotification(sec,type)
	local tempNode = display.newNode()
	local data = {}
	tempNode.data = data
	data.time = math.ceil(sec)
	if(sec < 0.1) then
		data.time = 0
	end
	data.type = type
	if(data.time == 0) then
		data.time = 0
	end
	Observer.sendNotification(BattleModule.BOSS_PVP_WAIT_FOR_FIGHT,tempNode)
end
function BossPvpBattleManager:sendFightEnd(result)
	--[[local btns = {{text = "取消",skin = 2},}
	local alert = GameAlert.new()
	for i,v in ipairs(self.testResult.team_a) do
		if(self.playerList[i].playerName ~= v.name) then
			alert:pop({{text = "BOSS战斗PVP战斗测试数据顺序不对"}},"ui/titlenotice.png",btns)
			return
		end
		if(self.playerList[i].hp ~= v.hp) then
			alert:pop({{text = "名字"..v.name.."  客户端hp="..self.playerList[i].hp.."  服务端hp="..v.hp}},"ui/titlenotice.png",btns)
			return
		end
		if(self.playerList[i].mp ~= v.mp) then
			alert:pop({{text = "名字"..v.name.."  客户端mp="..self.playerList[i].mp.."  服务端mp="..v.mp}},"ui/titlenotice.png",btns)
			return
		end
	end
	for i,v in ipairs(self.testResult.team_b) do
		if(self.enemyList[i].playerName ~= v.name) then
			alert:pop({{text = "BOSS战斗PVP战斗测试数据顺序不对"}},"ui/titlenotice.png",btns)
			return
		end
		if(self.enemyList[i].hp ~= v.hp) then
			alert:pop({{text = "名字"..v.name.."  客户端hp="..self.enemyList[i].hp.."  服务端hp="..v.hp}},"ui/titlenotice.png",btns)
			return
		end
		if(self.enemyList[i].mp ~= v.mp) then
			alert:pop({{text = "名字"..v.name.."  客户端mp="..self.enemyList[i].mp.."  服务端mp="..v.mp}},"ui/titlenotice.png",btns)
			return
		end
	end]]

	local tempData = {}
	local tempNode = display.newNode()
	tempNode.data = tempData
	tempData.result = result
	Observer.sendNotification(BattleModule.BOSS_PVP_FIGHT_END,tempNode)
end
function BossPvpBattleManager:sendBattleLog(strFormat,strArgs)
	local tempData = {}
	local tempNode = display.newNode()
	tempNode.data = tempData
	tempData.strFormat = strFormat
	tempData.args = strArgs
	Observer.sendNotification(BattleModule.BOSS_PVP_ADD_BATTLE_LOG,tempNode)
end
--战斗胜利(对方全死)返回true，失败（己方全死）返回false，未完成返回nil
function BossPvpBattleManager:bSucessed()
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
function BossPvpBattleManager:getLivePlayers(playerType,bEnemy)
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
function BossPvpBattleManager:battleBtnClick()
	if(not self.bStart) then
		self:start()
	end
	Observer.sendNotification(BattleModule.SHOW_BATTLE_UI)
end
function BossPvpBattleManager:getRandomPlayers(aPlayer,num,bEnemy)
	local temp = self:getLivePlayers(aPlayer.playerType,bEnemy)
	if(#temp <= num) then
		return temp
	end
	local result = {}
	local pros = {}
	for i,v in ipairs(temp) do
		table.insert(pros,{v,1000})
	end
	local curSeed
	local tempEnemy
	for i=1,num do
		curSeed = GameInstance.getBossBattleServerRandom()
		tempEnemy = math.random_choice2(pros,curSeed)
		table.insert(result,tempEnemy)
		for ii,v in ipairs(pros) do
			if(v[1] == tempEnemy) then
				table.remove(pros,ii)
				break
			end
		end
	end
	
	return result
end
--某一方当前气血最低的对象
function BossPvpBattleManager:getLeastHpPlayers(pType,num,bEnemy)
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
function BossPvpBattleManager:getTargetsFromLast(lastAttacked,curNum)
	local result = {}
	local curSeed
	local tempEnemy
	local pros = {}
	if(#lastAttacked > curNum) then
		for i,v in ipairs(lastAttacked) do
			table.insert(pros,{v,1000})
		end
		for i=1,curNum do
			curSeed= GameInstance.getBossBattleServerRandom()
			tempEnemy = math.random_choice2(pros,curSeed)
			table.insert(result,tempEnemy)
			for i2,v in ipairs(pros) do
				if(v[1] == tempEnemy) then
					table.remove(pros,i2)
					break
				end
			end
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
			for i,v in ipairs(temp) do
				table.insert(pros,{v,1000})
			end
			for i=1,addNum do
				curSeed= GameInstance.getBossBattleServerRandom()
				tempEnemy = math.random_choice2(pros,curSeed)
				table.insert(lastAttacked,tempEnemy)
				for i2,v in ipairs(pros) do
					if(v[1] == tempEnemy) then
						table.remove(pros,i2)
						break
					end
				end
			end
			result = lastAttacked
		end
	else
		result = lastAttacked
	end
	return result
end
--获得神属性抵挡不良状态是否生效
function BossPvpBattleManager:getGodProtectSuc(rate)
	local curSeed = GameInstance.getBossBattleServerRandom()

	return math.random_occur2(rate, curSeed)
end
--获得是否概率发生
function BossPvpBattleManager:getRandomCanHappen(rate)
	local curSeed = GameInstance.getBossBattleServerRandom()
	local can = math.random_occur2(rate, curSeed)
	return can
end
--获得是否命中
function BossPvpBattleManager:getBoolHit(rate)
	local curSeed = GameInstance.getBossBattleServerRandom()
	local hit = math.random_occur2(rate, curSeed)
	BattlePrint("随机得到是否命中的seed=",curSeed)
	BattlePrint("随机得到是否命中=",hit)
	return hit
end
--获得是否会心
function BossPvpBattleManager:getBoolCri(rate)
	BattlePrint("会心率=",rate)
	local curSeed = GameInstance.getBossBattleServerRandom()
	local cri = math.random_occur2(rate, curSeed)
	BattlePrint("随机得到是否会心的seed=",curSeed)
	BattlePrint("随机得到是否会心=",cri)
	return cri
end
--获得外攻
function BossPvpBattleManager:getAttackPower(aPlayer)
	local curSeed = GameInstance.getBossBattleServerRandom()
	local tempMin = aPlayer.minDmg + (aPlayer.attrCalBuffers["dam"][1]*aPlayer.minDmg
		+aPlayer.attrCalBuffers["dam"][2])
	tempMin = math.toint(tempMin)
	local tempMax = aPlayer.maxDmg + (aPlayer.attrCalBuffers["dam"][1]*aPlayer.maxDmg
		+aPlayer.attrCalBuffers["dam"][2])
	tempMax = math.toint(tempMax)
	local apower = math.randint(tempMin,tempMax,curSeed)
	BattlePrint("最小伤害=",tempMin)
	BattlePrint("最大伤害=",tempMax)
	BattlePrint("随机得到攻击力的seed=",curSeed)
	BattlePrint("随机得到攻击力=",apower)
	return apower
end
function BossPvpBattleManager:clear()
	TimeManager:remove(self)
	--队友列表
	self.playerList = {}
	--敌人列表
	self.enemyList = {}
	--当前攻击者索引
	self.curFightIndex = 1
	--回合数
	self.circleNum = 0
	self.battleType = BattleModule.BOSS_PVP
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
	self.nextMapID = nil
	self.result = nil
	self.startWaitTime = 3
	self.endWaitTime = 3
end
return BossPvpBattleManager