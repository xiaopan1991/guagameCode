PlayerTypePlayer = 1
PlayerTypeSolider = 2
PlayerTypeMonster = 3
PlayerTypeBoss = 4
PlayerTypeOtherPlayer = 5
local Player = class("Player",function(playerType,id,manager)
	-- body	
	local p = {}
	p.playerType = playerType
	p.id = id
	p.battleManager = manager
	return p
	end
)
function Player:ctor()
	self:updateAttribute()
	self:initAttrBuffers()
end
--得到计算buffer之后的战斗属性--{'deff','adf','arm','cri','hit','dod','res','crd'}
--initAttrBuffers里的那些
function Player:getBattleAttrCalBuffer(bKey)
	
	--{'deff','adf','arm','cri','hit','dod','res','crd'}会立刻生效，与角色本身属性相加并缓存最终数值
	--'dam','cri_rate'，缓存【百分比，绝对值】，与角色属性无关，计算伤害时生效
	--'hp','mp',缓存增加的数值，角色行动前生效，如果显示上加血还需要一个个的显示，这里就不能加起来
	if(bKey == "deff" or bKey == "adf" or bKey == "arm" or bKey == "cri" or bKey == "hit" or bKey == "dod" or bKey == "res" or bKey == "crd") then
		self.attrCalBuffers[bKey] =  math.toint(self.attrBuffers[bKey][1]*self[bKey] + self.attrBuffers[bKey][2])
		self.attrCalBuffers[bKey] = self.attrCalBuffers[bKey] + self[bKey]
		--这里存的是所有此类型的buffer计算完成后的玩家的最终属性值
	elseif(bKey == "hp") then
		self.attrCalBuffers[bKey] =  self.attrBuffers[bKey][1]*self.maxHP + self.attrBuffers[bKey][2]
		--这里存的是每一个hp的buffer单独增加的属性值
	elseif(bKey == "mp") then
		self.attrCalBuffers[bKey] =  self.attrBuffers[bKey][1]*self.maxMP + self.attrBuffers[bKey][2]
		--这里存的是每一个mp的buffer单独增加的属性值
	elseif(bKey == "cri_rate" or bKey == "dam" or bKey == "reduce_dam") then
		self.attrCalBuffers[bKey] = self.attrBuffers[bKey]
		--这里存的是所有此类型的buffer增加的（百分比和绝对值的和）
	end
end
--初始化可叠加buffer
function Player:initAttrBuffers()
	local buffKeys = {'hp','mp','deff','adf','arm','cri','hit','dod','res','crd',
	'dam','cri_rate','reduce_dam',}
	for i,v in ipairs(buffKeys) do
		self.attrBuffers[v] = {0,0}
		self:getBattleAttrCalBuffer(v)
	end
end
--增加buffer后更新buffer属性
--initAttrBuffers里的那些
function Player:addAttrBuffers(bKey,bValue)
	if(self.attrBuffers[bKey]) then
		self.attrBuffers[bKey][1] = self.attrBuffers[bKey][1] + bValue[2][1] 
		self.attrBuffers[bKey][2] = self.attrBuffers[bKey][2] + bValue[2][2]*bValue[3]		
		self:getBattleAttrCalBuffer(bKey)
	end
end
--移除buffer后更新buffer属性
--initAttrBuffers里的那些
function Player:removeAttrBuffers(bKey,bValue)
	if(self.attrBuffers[bKey]) then
		self.attrBuffers[bKey][1] = self.attrBuffers[bKey][1] - bValue[2][1]
		self.attrBuffers[bKey][2] = self.attrBuffers[bKey][2] - bValue[2][2]*bValue[3]
		self:getBattleAttrCalBuffer(bKey)
	end
end
function Player:addBuffer(bID,buffData,sLv)
	local bDebuff = false
	if(bID == "stun" or bID == "silence") then
		bDebuff = true
	elseif(self.attrBuffers[bID]) then
		if(bID == "reduce_dam") then
			if(buffData[3][1] < 0 or buffData[3][2] < 0) then
				bDebuff = true
			end
		else
			if(buffData[4][1] < 0 or buffData[4][2] < 0) then
				bDebuff = true
			end
		end
	end
	if(bDebuff) then
		local allRate = 0
		if(self.buffList and self.buffList["resist_debuff"]) then
	    	for i3,v3 in ipairs(self.buffList["resist_debuff"]) do
	    		allRate = allRate + v3[2]
	    	end
	    end
	    if(self.godInfo and self.godInfo["resist_debuff"]) then
	    	allRate = allRate + self.godInfo["resist_debuff"]
	    end
	    if(allRate > 0 and self.battleManager:getRandomCanHappen(allRate)) then
    		return
    	end
	end

	if(not self.buffList[bID]) then
		self.buffList[bID] = {}
	end

	local bValue
	if(bID == "stun") then
		table.insert(self.buffList[bID], {buffData[3]*self.battleManager:getAllFighterNum()}) 
	elseif(bID == "silence") then
		table.insert(self.buffList[bID], {buffData[3]*self.battleManager:getAllFighterNum()})
	elseif(bID == "back_dam") then
		bValue = {buffData[1]*self.battleManager:getAllFighterNum(),buffData[2],buffData[3]}
		table.insert(self.buffList[bID],bValue)
	elseif(bID == "magic_shield" or bID == "suck_blood" or bID == "resist_debuff") then
		bValue = {buffData[3]*self.battleManager:getAllFighterNum(),buffData[4],}
		table.insert(self.buffList[bID],bValue)
	elseif(bID == "ice_armour") then
		bValue = {buffData[3]*self.battleManager:getAllFighterNum(),buffData[4],buffData[5]}
		table.insert(self.buffList[bID],bValue)
	elseif(bID == "dot") then
		table.insert(self.buffList[bID], {buffData[4]*self.battleManager:getAllFighterNum(),buffData[3],sLv})
	elseif(bID == "reduce_dam") then
		bValue = {buffData[4]*self.battleManager:getAllFighterNum(),buffData[3],1}
		table.insert(self.buffList[bID], bValue)
		self:addAttrBuffers(bID,bValue)
	else--initAttrBuffers里除了reduce_dam的那些
		bValue = {buffData[5]*self.battleManager:getAllFighterNum(),buffData[4],sLv}
		table.insert(self.buffList[bID], bValue)
		self:addAttrBuffers(buffData[1],bValue)
	end 
	self:sendBufferUpdateInfo(self)
	--
end
function Player:updateBuffer()
	self.stun = false
	self.silence = false
	--计算属性
	for k,v in pairs(self.buffList) do
		local index = 1
		local vv
		while(index <= #v) do
			vv  = v[index]
			vv[1] = vv[1] - 1
			if(vv[1] == 0) then
				table.remove(v,index)
				self:removeAttrBuffers(k,vv)
			else
				index = index + 1
			end
		end
		if(#v == 0) then
			self.buffList[k] = nil
		end
	end
	if(self.buffList["stun"]) then
		self.stun = true
	end
	if(self.buffList["silence"]) then
		self.silence = true
	end
	self:sendBufferUpdateInfo(self)
end
--初始化属性，从表里或者服务端返回数据中
function Player:updateAttribute()
	--战斗时使用的技能列表，按要求将自己选中的技能由上到下排列，并在最后插两个0，表示普攻。每当更改技能列表时记得更新。
	--技能是有cd的，cd中用普攻代替--后来技能没有cd了，完全的顺序攻击.蓝不够用普攻代替
	self.fightSkillList = {}
	--一个不大于#self.fightSkillList的数，用来记录当前的攻击是哪一个。当技能列表更新时，记得处理一下，现在没时间纠结。
	self.fightskillIndex = 0
	--战斗时buff列表
	self.buffList = {} 
	--buff增加的各种值
	self.attrBuffers = {}
	----计算完buffer后的各种属性值
	self.attrCalBuffers = {}

	self.dead = false

	if(self.playerType == PlayerTypeMonster ) then
		local mData = DataConfig:getMonsterById(self.id)		
		self.minDmg = mData.dam[1]
		self.maxDmg = mData.dam[2]
		local tempAttrs = {'lv','hp','mp','deff','adf','arm','cri','hit','dod','res','crd'}
		for i=1,#tempAttrs do
			self[tempAttrs[i]] = mData[tempAttrs[i]]
		end
		self.playerName = mData.name
		local headStr
		if(self.battleManager.battleType == BattleModule.GUAJI) then
			headStr = self:getMonsterHeadByMapIDAndBattleType(BattleModule.GUAJI,self.battleManager.curMapID)
		else
			headStr = self:getMonsterHeadByMapIDAndBattleType(BattleModule.BOSS_PVP,self.battleManager.curMapID)
		end
		self.headImg = "circlehead/"..headStr..".png"
	elseif self.playerType == PlayerTypeSolider then
		local soliderData = PlayerData:getSoliderByID(self.id)
		self.lv = PlayerData:getLv()
		local tempAttrs = {'hp','mp','mps','strr','agi','intt','sta','minDmg','maxDmg','arm_rate','deff','adf','arm','cri','hit','dod','res','crd'}
		for i,v in ipairs(tempAttrs) do
			self[v] = soliderData.attrs[v]
		end	
		self.playerName = soliderData.name
		self.headImg = "circlehead/follower"..soliderData.hero_type..".png"
		self.fightSkillList = {}
		for i,v in ipairs(soliderData.skills) do
			self.fightSkillList[i] = {v.sid,v.lv}
		end
		self.godInfo = clone(soliderData.godInfo)
	elseif self.playerType == PlayerTypeOtherPlayer then
		local tempAttrs = {'hp','mp','mps','strr','agi','intt','sta','minDmg','maxDmg','arm_rate','deff','adf','arm','cri','hit','dod','res','crd'}
		for i,v in ipairs(tempAttrs) do
			self[v] = BossPvpBattleManager.pvpData.pvp_info.attrs[v]
		end		
		self.lv = BossPvpBattleManager.pvpData.pvp_info.lv
		self.headImg = "circlehead/"..BossPvpBattleManager.pvpData.pvp_info.hero_type..".png"--BossPvpBattleManager.pvpData.pvp_info.hero_type决定头像
		self.playerName = BossPvpBattleManager.pvpData.pvp_info.name
		self.fightSkillList = clone(BossPvpBattleManager.pvpData.pvp_info.skills)
		self.godInfo = clone(BossPvpBattleManager.pvpData.pvp_info.godInfo)
	elseif(self.playerType == PlayerTypePlayer) then
		local tempAttrs = {'lv','hp','mp','mps','strr','agi','intt','sta','minDmg','maxDmg','arm_rate','deff','adf','arm','cri','hit','dod','res','crd'}
		for i,v in ipairs(tempAttrs) do
			self[v] = PlayerData.data[v]
		end		
		self.headImg = "circlehead/"..PlayerData:getHeroType()..".png"
		self.playerName = PlayerData.data.name

		self.fightSkillList = {}
		local skills = PlayerData:getAllOpenSkills()
		local battleSkills
		if(self.battleManager.battleType == BattleModule.BOSS_PVP and self.battleManager.modle == "pvp") then
			battleSkills = PlayerData:getPvpSkills()
		else
			battleSkills = PlayerData:getBattleSkills()
		end
		
		for i,v in ipairs(battleSkills) do
			self.fightSkillList[i] = {v,skills[v].lv}
		end
		local godInfo = PlayerData:getGodInfo()
		self.godInfo = clone(godInfo)
	elseif(self.playerType == PlayerTypeBoss) then
		local mData = DataConfig:getBossById(self.id)
		self.headImg = "circlehead/"..self.id..".png"
		self.playerName = mData.name
		self.minDmg = mData.dam[1]
		self.maxDmg = mData.dam[2]
		local tempAttrs = {'lv','hp','mp','deff','adf','arm','cri','hit','dod','res','crd'}
		for i=1,#tempAttrs do
			self[tempAttrs[i]] = mData[tempAttrs[i]]
		end
	end
	self.maxHP = self.hp
	self.maxMP = self.mp
	--这里需要读配置，因为当时没有，所以先自己写了
	for i=1,DataConfig.data.cfg.system_simple.skill_cd do
		table.insert(self.fightSkillList,0)
	end
end
--行动前+-血蓝一类
function Player:processBeforeAttack()
	--抵消不良状态
	if(self.buffList and table.nums(self.buffList)>0) then
		local allRate = 0
		if(self.buffList and self.buffList["resist_debuff"]) then
	    	for i3,v3 in ipairs(self.buffList["resist_debuff"]) do
	    		allRate = allRate + v3[2]
	    	end
	    end
	    if(self.godInfo and self.godInfo["resist_debuff"]) then
	    	allRate = allRate + self.godInfo["resist_debuff"]
	    end
	    if(allRate>0 and self.battleManager:getRandomCanHappen(allRate)) then
	    	print("resist_debuff=",self.playerName)
    		for k,v in pairs(self.buffList) do
    			if(self.attrBuffers[k]) then
					local index = 1
					local vv
					while(index <= #v) do
						vv  = v[index]
						local bdel = false
						if(vv[2][1]<0 or vv[2][2]<0) then
							bdel = true
						end
						if(bdel) then
							table.remove(v,index)
							self:removeAttrBuffers(k,vv)
						else
							index = index + 1
						end
					end
					if(#v == 0) then
						self.buffList[k] = nil
					end
				end
			end
			if(self.buffList["stun"]) then
				self.buffList["stun"] = nil
				self.stun = false
			end
			if(self.buffList["silence"]) then 
				self.buffList["silence"] = nil
				self.silence = false
			end
			self:sendBufferUpdateInfo(self)
    	end
	end

	if(self.mps and self.mps > 0) then
		self:changeMP(self.mps)
	end
	if(self.godInfo and self.godInfo["restore_hp"]) then--神属性回血
		self:changeHP(math.toint(self.godInfo["restore_hp"]*self.maxHP))
	end

	if(self.buffList["hp"]) then
		local changehp
		local bdead
		for i,v in ipairs(self.buffList["hp"]) do
			changehp = math.toint(v[2][1]*self.maxHP + v[2][2]*v[3])
			bdead = self:changeHP(changehp)
		end
		if(bdead) then
			return bdead
		end
	end
	if(self.buffList["mp"]) then
		local changemp
		for i,v in ipairs(self.buffList["mp"]) do
			changemp = math.toint(v[2][1]*self.maxMP + v[2][2]*v[3])
			self:changeMP(changemp)
		end		
	end
end
function Player:attack()
	BattlePrint('___________________________________')
    BattlePrint('行动者--name is ',self.playerName)
    BattlePrint('行动者 maxHp is', self.maxHp)
	if(self.stun) then
		self:sendStateInfo("眩晕中,跳过战斗")
		return
	end
	self.fightskillIndex = self.fightskillIndex + 1
	if(self.fightskillIndex > #self.fightSkillList) then
		self.fightskillIndex = 1
	end
	local skill = self.fightSkillList[self.fightskillIndex]
	--如果是技能且被沉默，则插一个普攻
	if(self.silence and skill~=0) then
		skill = 0 
		self.fightskillIndex = self.fightskillIndex - 1
		if(self.fightskillIndex == 0 ) then
			self.fightskillIndex = #self.fightSkillList
		end
		self:sendStateInfo("沉默中,无法释放技能")
	end

	local attacked--随即得到攻击单位，在下面赋值
	local attackPower
	--如果是技能，但是蓝不够,则插一个普攻
	local costMp
	if(skill ~= 0)then
		costMp = DataConfig:getSkillMpByIdLv(skill[1],skill[2])
		if(self.mp == nil or self.mp < costMp)then--蓝不够，使用普通攻击
			skill = 0
			self.fightskillIndex = self.fightskillIndex - 1
			if(self.fightskillIndex == 0 ) then
				self.fightskillIndex = #self.fightSkillList
			end
		end
	end
	if(skill == 0)then--普通攻击
		attacked = self.battleManager:getRandomPlayers(self,1,true)
		self.attackPower = self.battleManager:getAttackPower(self)
		self:calFightDamage(attacked,self.attackPower)		
	else--技能攻击
		self:changeMP(-costMp,true)		--
		local skillLv = skill[2]--暂无技能等级数据，代替
		skill = skill[1]
		local skillData = DataConfig:getSkillById(skill)
		self:sendUseSkillInfo(skillData.name)
		BattlePrint('使用技能 ', skillData.name)
		local skillEffect = skillData.skill
		local skillHit 
		local bAlliance--change_attr的buffer的命中率只有对敌方才考虑命中率
		for i,v in ipairs(skillEffect) do
			for k,vv in pairs(v) do				
				if(k == "stun" or k == "silence" or k == "internal_dam" or k == "external_dam" or k=="dot") then
					--二：人数; 三:回合数，四：触发概率
					--每个效果单独算命中（除了dam）技能命中公式= （技能等级+技能解锁等级）/敌方玩家等级					
					--根据vv[1]和（i==1,不跟随上一个效果的作用对象）选择作用对象
					if(vv[1] ==0) then--作用对象0：敌方随机,
						attacked = 	self.battleManager:getRandomPlayers(self,vv[2],true)
					elseif(vv[1] ==1)  then--1：跟随上个目标，
						attacked = self.battleManager:getTargetsFromLast(attacked,vv[2])
					elseif(vv[1] ==2)  then--2:敌方气血百分比最低
						attacked = self.battleManager:getLeastHpPlayers(self.playerType,vv[2],true)
					end 
				elseif(k == "change_attr") then
					--作用对象0：自己，1：跟随上个目标，2：友方，3敌方,4本方气血百分比最低，5敌方气血百分比最低
					if(vv[2] ==0) then
						attacked = 	{self}
					elseif(vv[2] ==1)  then
						attacked = self.battleManager:getTargetsFromLast(attacked,vv[3])
					elseif(vv[2] ==2)  then
						attacked = self.battleManager:getRandomPlayers(self,vv[3],false)
					elseif(vv[2] ==3)  then
						attacked = self.battleManager:getRandomPlayers(self,vv[3],true)
					elseif(vv[2] ==4)  then
						attacked = self.battleManager:getLeastHpPlayers(self.playerType,vv[3],false)
					elseif(vv[2] ==5)  then
						attacked = self.battleManager:getLeastHpPlayers(self.playerType,vv[3],true)
					end 
				elseif(k == "back_dam") then
					attacked = 	{self}
				--这些是后来加的技能
				--[[
				#reduce_dam(减少伤害)[0,1,[0.5,0] ,3] #1.作用对象; 2.作用人数; 3.[百分比,绝对值]; 4.回合数
				#change_hp_skill(改变生命)[0,1,[0.1,0] 本回合行为 #1.作用对象; 2.作用人数; 3.[百分比,绝对值];
				#change_mp_skill(改变魔法)[0,1,[0.1,0] 本回合行为 #1.作用对象; 2.作用人数; 3.[百分比,绝对值];
				#ice_armour(冰甲术)[0,1,3,0.5,2] #buff,1.作用对象; 2.作用人数;3.回合数,4.触发概率,5.触发stun回合数
				#magic_shield(魔法护盾)[0,1,5,2] #buff 1.作用对象; 2.作用人数;3.回合数,4抵消伤害比率
				#suck_blood(吸血)[0,1,3,0.8] #buff 1.作用对象; 2.作用人数;3.回合数,4,吸血百分比
				#resist_debuff(抵消所有不良buff)[0,1,3,1]#buff 1.作用对象; 2.作用人数;3.回合数,4抵消概率
				]]
				elseif(k == "reduce_dam" or k == "change_hp_skill" or k == "change_mp_skill" or 
					k == "ice_armour" or k == "magic_shield" or k == "suck_blood" or k == "resist_debuff") then
					if(vv[1] ==0) then
						attacked = 	{self}
					elseif(vv[1] ==1)  then
						attacked = self.battleManager:getTargetsFromLast(attacked,vv[2])
					elseif(vv[1] ==2)  then
						attacked = self.battleManager:getRandomPlayers(self,vv[2],false)
					elseif(vv[1] ==3)  then
						attacked = self.battleManager:getRandomPlayers(self,vv[2],true)
					elseif(vv[1] ==4)  then
						attacked = self.battleManager:getLeastHpPlayers(self.playerType,vv[2],false)
					elseif(vv[1] ==5)  then
						attacked = self.battleManager:getLeastHpPlayers(self.playerType,vv[2],true)
					end 
				end
				if(k == "stun" or k == "silence") then
					--遍历作用对象，判断命中
					--技能命中公式= （技能等级+技能解锁等级）/敌方玩家等级
					--如果命中，判断触发概率，添加buff
					for i2,v2 in ipairs(attacked) do
						skillHit = (skillLv+skillData.unlock_lv)/v2.lv
						--if(self.battleManager:getRandomCanHappen(skillHit)) then
						--这里本来是计算技能命中率的，现在不算了
						--end
						if(self.battleManager:getRandomCanHappen(vv[4])) then
							v2:addBuffer(k,vv)
						end
					end	
				elseif(k == "back_dam" or k == "reduce_dam" or k == "ice_armour" or
				 k == "magic_shield" or k == "suck_blood" or k == "resist_debuff") then
					for i2,v2 in ipairs(attacked) do
						v2:addBuffer(k,vv)					
					end
				elseif(k == "dot") then--据说不要这个了，有一些逻辑没处理
					for i2,v2 in ipairs(attacked) do
						skillHit = (skillLv+skillData.unlock_lv)/v2.lv
						if(self.battleManager:getRandomCanHappen(skillHit)) then
							v2:addBuffer(k,vv,skillLv)
						end
					end
				elseif(k == "change_attr") then
					for i2,v2 in ipairs(attacked) do
						v2:addBuffer(vv[1],vv,skillLv)--一开始都计算命中，现在改成只有stun和silence计算命中了。(skillLv+skillData.unlock_lv)/v2.lv
					end
				elseif(k == "internal_dam") then
					self.attackPower = self.battleManager:getAttackPower(self)
					attackPower = self.attackPower + math.toint(self.attackPower*(vv[3][1]) + skillLv*vv[3][2])
					self:calFightDamage(attacked,attackPower,true,skillData.name)
				elseif(k == "external_dam") then
					self.attackPower = self.battleManager:getAttackPower(self)
					attackPower = self.attackPower + math.toint(self.attackPower*(vv[3][1]) + skillLv*vv[3][2])
					self:calFightDamage(attacked,attackPower,false,skillData.name)
				elseif(k == "change_hp_skill") then
					local addhp
					for k,v in pairs(attacked) do
						addhp = math.toint(v.maxHP*vv[3][1] + vv[3][2])
						v:changeHP(addhp)
						self:sendSkillHPMPChangeInfo(v,skillData.name,addhp,"hp")
					end
				elseif(k == "change_mp_skill") then
					local addmp
					for k,v in pairs(attacked) do
						addmp = math.toint(v.maxMP*vv[3][1] + vv[3][2])
						v:changeMP(addmp)
						self:sendSkillHPMPChangeInfo(v,skillData.name,addmp,"mp")
					end
				end
			end
		end
	end
	
	--attacked头像回调，战斗日志界面回调
	
end
function Player:changeHP(addhp,beAttack)--这里要区分攻击掉血与其他掉血，beAttack为nil表示非攻击掉血
	if(addhp ~= 0) then
		if(addhp < 0 ) then
			--魔法护盾magic_shield
			if(self.buffList["magic_shield"]) then
    			local rate = 0
    			for i,v in ipairs(self.buffList["magic_shield"]) do
    				rate = rate + v[2]
    			end
    			local costmp = math.ceil(-addhp/rate)
    			if(self.mp < costmp) then
    				addhp = addhp + math.floor(self.mp*rate)
    				self:changeMP(-self.mp,true)
				else
					self:changeMP(-costmp,true)
    				addhp = 0
				end
    		end
		end
		self.hp = self.hp + addhp
		if(self.hp > self.maxHP) then
			self.hp = self.maxHP
		end
		if(self.hp <= 0) then
			self.hp = 0
			self.dead = true
		else
			self.dead = false
		end
		if(not beAttack) then			
			self:sendBufferHpMpInfo("hp",addhp)
		else
			self:sendBufferHpMpInfo()
		end
		
		return self.dead
	end
end
function Player:changeMP(addmp,beAttack)
	if(addmp ~= 0) then
		self.mp = self.mp + addmp
		if(self.mp > self.maxMP) then
			self.mp = self.maxMP
		end
		if(self.mp < 0) then
			self.mp = 0
		end
		if(not beAttack) then
			self:sendBufferHpMpInfo("mp",addmp)
		else
			self:sendBufferHpMpInfo()
		end
	end
end
function Player:calFightDamage(attacked,aPower,bAdf,skillInfo)
	local dam
	local bCri
	local bHit
	--战斗相关配置
	local hitRateCf = DataConfig.data.cfg.system_simple.formula["hit_rate"]
	local criRateCf = DataConfig.data.cfg.system_simple.formula["cri_rate"]
	local armRateCf = DataConfig.data.cfg.system_simple.formula["arm_rate"]
	local combat_coefficient = DataConfig.data.cfg.system_simple.combat_coefficient

	--local attackPower = aPower
	--attackPower =attackPower + math.floor(self.attrCalBuffers["dam"][1]*self.attackPower + self.attrCalBuffers["dam"][2])
	for k,v in pairs(attacked) do
		local attackPower = aPower
		dam = 0
		if(bAdf ~= nil) then
			BattlePrint("技能攻击必命中")
			bHit = true
		else
			--命中率hit_rate = min((a * (攻击者等级 / 防守方等级) * (攻击者命 / 防守方闪) + b) , 1) 小数点后两位, 直接截取
			local hitparam1 = self.lv
			local hitparam2 = v.lv
			local hitparam3 = self.attrCalBuffers.hit
			local hitparam4 = v.attrCalBuffers.dod
			local hit_rate = hitRateCf[1]*(hitparam1/hitparam2)*(hitparam3/hitparam4) + hitRateCf[2]
			hit_rate = math.floor(hit_rate*100)/100
			hit_rate = math.limitTo(hit_rate,0,1)
			BattlePrint("普通攻击命中率=",hit_rate)
			bHit = self.battleManager:getBoolHit(hit_rate)
		end
		if(bHit) then
			local cri_rate = self.attrCalBuffers.cri/(self.attrCalBuffers.cri+v.attrCalBuffers.res*criRateCf[3]+criRateCf[1]*v.lv^2+criRateCf[2])
			cri_rate = math.ceil(cri_rate*100)/100
			cri_rate =cri_rate + self.attrBuffers["cri_rate"][1]*cri_rate + self.attrBuffers["cri_rate"][2]
			cri_rate = math.limitTo(cri_rate,0,1)
			if(self.battleManager:getBoolCri(cri_rate)) then
				attackPower = attackPower * self.attrCalBuffers.crd
				bCri = true
			else--未会心
				bCri = false
			end
			BattlePrint("是否会心计算后伤害值=",attackPower)
			local lastArm = v.attrCalBuffers.arm
			BattlePrint("总护甲=",lastArm)
			if(self.godInfo and self.godInfo["ignore_armor"]) then--攻击忽视敌方护甲百分比
				lastArm = lastArm - math.floor(lastArm*self.godInfo["ignore_armor"]/(self.godInfo["ignore_armor"] + 100))
			end
			BattlePrint("计算完忽视护甲后的护甲=",lastArm)
			local temp_arm_rate = PlayerData:calcBaseAttributesArmRate(lastArm,self.lv)
			temp_arm_rate = math.floor(temp_arm_rate*100)/100
			temp_arm_rate = math.limitTo(temp_arm_rate,0,1)
			
			BattlePrint("免伤率=",temp_arm_rate)

			local def
			local parm
			local a = combat_coefficient[1]
			local b = combat_coefficient[2]
			local c = combat_coefficient[3]
			local d = combat_coefficient[4]
			if(bAdf) then
				def = v.attrCalBuffers.adf
				parm = d
				if(self.godInfo and self.godInfo["ignore_adf"]) then
					def = def - math.floor(def*self.godInfo["ignore_adf"]/(self.godInfo["ignore_adf"] + 100))
				end
			else
				def = v.attrCalBuffers.deff
				parm = c
				if(self.godInfo and self.godInfo["ignore_deff"]) then
					def = def - math.floor(def*self.godInfo["ignore_deff"]/(self.godInfo["ignore_deff"] + 100))
				end
			end
			
			--抗性免伤率=守方抗性/(守方抗性+50*攻方等级+50)
			local antidam = def/(def+parm+parm*self.lv)
			dam = math.ceil((attackPower*a + b)*(1-temp_arm_rate)*(1-antidam))
    		--免伤buff处理
    		local reducedDam = math.floor(v.attrCalBuffers["reduce_dam"][1]*dam + v.attrCalBuffers["reduce_dam"][2])
    		dam = dam - reducedDam
    		BattlePrint("减少伤害之后的伤害=",dam)
    		local lasthp = v.hp    		
    		v:changeHP(-dam,true)
    		BattlePrint("攻击最终造成的生命减少=",lasthp - v.hp)
    		self:sendOneAttackInfo(self,v,skillInfo,dam,bAdf,bHit,bCri)
    		if(not v.dead) then--被打人没死才能吸血
    			if(self.buffList["suck_blood"]) then
    				for i3,v3 in ipairs(self.buffList["suck_blood"]) do
						local addhp = math.toint(dam*v3[2])
						BattlePrint("buffer吸血=",addhp)
						if(addhp > 0) then
							self:changeHP(addhp)
						end	
	    			end
    			end
    			if(self.godInfo and self.godInfo["suck_blood"]) then--吸血
    				local gethp = math.toint(dam*self.godInfo["suck_blood"])
    				BattlePrint("神属性吸血=",gethp)
    				if(gethp > 0) then
    					self:changeHP(gethp)
    				end
				end
    		end
    		if(not v.dead) then
    			if(v.buffList["back_dam"]) then
    				for i3,v3 in ipairs(v.buffList["back_dam"]) do
	    				if(self.battleManager:getRandomCanHappen(v3[2])) then
							local antiDam = math.toint(dam*v3[3])
							BattlePrint("buffer反伤=",antiDam)
							if(antiDam > 0) then 
								self:changeHP(-antiDam)
							end
		    				
		    				if(self.dead) then
		    					break
		    				end
						end
	    			end
	    			if(self.dead) then
    					break
    				end
    			end
    			if(v.godInfo and v.godInfo["anti_dam"]) then
    				local antiDam = math.toint(dam*v.godInfo["anti_dam"])
    				BattlePrint("神属性反伤=",antiDam)
    				if(antiDam > 0) then 
    					self:changeHP(-antiDam)
    				end
    				if(self.dead) then
    					break
    				end
    			end
    		end
    		--冰甲术ice_armour--这个地方需要判断被打的人是否死亡吗？
    		if((not v.dead) and v.buffList["ice_armour"]) then
    			for i,vvv in ipairs(v.buffList["ice_armour"]) do
    				if(self.battleManager:getRandomCanHappen(vvv[2])) then
    					self:addBuffer("stun", {0,0,vvv[3]})
    					BattlePrint("冰甲术生效，攻击者眩晕两回合")
    				end
    			end
    		end
		else--未命中
			bHit = false
			bCri = false
			self:sendOneAttackInfo(self,v,skillInfo,dam,bAdf,bHit,bCri)
		end
	end
end
--xx使用xx移除(回复)xx xx点xx值
function Player:sendSkillHPMPChangeInfo(target,skillname,num,attrtype)
	local info = {
		{self.battleManager.circleNum,},
		{self.playerName,},
		{skillname,{68,220,33}},
		{"",},
		{target.playerName,},
		{num,{255,53,53}},
		{"",},
		}	
	if(self.playerType < 3) then
		info[2][2] = {209,47,255}
	else
		info[2][2] = {1,144,254}
	end
	if(target.playerType < 3) then
		info[5][2] = {209,47,255}
	else
		info[5][2] = {1,144,254}
	end
	if(self.playerType == target.playerType and self.playerName == target.playerName) then
		info[5][1] = "自己"
	end
	if(num > 0) then
		info[4][1] = "恢复"
	else
		info[4][1] = "移除"
		info[6][1] = -num
	end
	if(attrtype == "hp") then
		info[7][1] = "点生命值"
	elseif(attrtype == "mp") then
		info[7][1] = "点魔法值"
	end
	self.battleManager:sendBattleLog("s29",info)
end
--xx处于xx
function Player:sendStateInfo(state)
	local info = {
		{self.battleManager.circleNum,},
		{self.playerName,},
		{state,},
		}
	if(self.playerType < 3) then
		info[2][2] = {209,47,255}
	else
		info[2][2] = {1,144,254}
	end
	self.battleManager:sendBattleLog("s28",info)
end
--xx释放技能xx
function Player:sendUseSkillInfo(skillname)
	local info = {
	{self.battleManager.circleNum,},
	{self.playerName,},
	{skillname,{68,220,33}},
	}
	if(self.playerType < 3) then
		info[2][2] = {209,47,255}
	else
		info[2][2] = {1,144,254}
	end
	self.battleManager:sendBattleLog("s27",info)
end
function Player:sendOneAttackInfo(attacker,beAttacked,skillInfo,dam,bAdf,bHit,bCri)
	local tempNode = display.newNode()
	local data = {}
	tempNode.data = data			
	data.attacker = attacker
	data.beAttacked = beAttacked
	data.skillInfo = skillInfo
	data.dam = dam
	data.bAdf = bAdf
	data.bHit = bHit
	data.bCri = bCri
	if(self.battleType == BattleModule.GUAJI) then
		Observer.sendNotification(BattleModule.GUAJI_ATTACK_ONE,tempNode)
	else
		Observer.sendNotification(BattleModule.BOSS_PVP_ATTACK_ONE,tempNode)
	end
end
function Player:sendBufferUpdateInfo(player)--buffer更新
	local tempNode = display.newNode()
	local data = {}
	tempNode.data = data			
	data.player = player
	if(self.battleType == BattleModule.GUAJI) then
		Observer.sendNotification(BattleModule.GUAJI_BUFFER_UPDATE,tempNode)
	else
		Observer.sendNotification(BattleModule.BOSS_PVP_BUFFER_UPDATE,tempNode)
	end
end
function Player:sendBufferHpMpInfo(bType,num)--buffer影响的+—血蓝，反伤-蓝
	local tempNode = display.newNode()
	local data = {}
	tempNode.data = data			
	data.player = self
	data.bType = bType
	data.num = num
	if(self.battleType == BattleModule.GUAJI) then
		Observer.sendNotification(BattleModule.GUAJI_BUFFER_HP_MP,tempNode)
	else
		Observer.sendNotification(BattleModule.BOSS_PVP_BUFFER_HP_MP,tempNode)
	end
end
function Player:clearAfterFight()
end
--策划的要求怪物的头像是随机的，而且在boss模式和挂机模式不一样的随机规则
--每十个是一个教
function Player:getMonsterHeadByMapIDAndBattleType(bType,mapID)
	local head
	local mapindex = tonumber(string.sub(mapID,2))
	local bang = math.floor((mapindex -1)/10)
	local bosses = {}
	if(bType == BattleModule.GUAJI) then		
		local tempstr
		local bossnum
		if(bang == 3) then
			bossnum = 1
		else
			bossnum = 10
		end
		for i=1,bossnum do
			tempstr = string.format("B%03d",(bang*10 + i))
			table.insert(bosses,tempstr)			
		end
		for i=1,2 do
			table.insert(bosses,string.format("guai%d%02d",bang,i))
		end
	else
		for i=1,2 do
			table.insert(bosses,string.format("guai%d%02d",bang,i))
		end
	end
	return bosses[math.random(1,#bosses)]	
end
return Player