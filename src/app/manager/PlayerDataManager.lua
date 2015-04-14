--玩家数据管理者
--玩家的昵称、等级、货币 都在这里

local PlayerDataManager = class("PlayerDataManager")

function PlayerDataManager:ctor()
	self.data = nil
	self.login = false  --是否已经登录
	self.dazaoData = nil  --打造数据
	self.shopData = {} --商城数据  缓存
	self.dazaoOKData = nil -- 打造好的数据
end

--登录时初始化数据
function PlayerDataManager:setData(data)
	-- body
	self.data = data
	self.login = true
end
--计算Hp公式
function PlayerDataManager:calcBaseAttributesHp(sta)
	local vars = DataConfig.data.cfg.system_simple.formula
	local useSta = (sta or self.data.sta)
	local baseNum = (vars["hp"][1]* useSta + vars["hp"][2])
	return formatAttributeNum("hp",baseNum)
end
--计算Mp公式
function PlayerDataManager:calcBaseAttributesMp(lv)
	local vars = DataConfig.data.cfg.system_simple.formula
	local useLv = (lv or self.data.lv)
	local baseNum  = (vars["mp"][1]* useLv + vars["mp"][2])
	return formatAttributeNum("mp",baseNum)
end
--计算最小伤害公式
function PlayerDataManager:calcBaseAttributesMinDmg(heroType,mainAtr)
	local useHType = (heroType or self:getHeroType())
	local jobInfo = DataConfig:getJobById(""..useHType)
	local useAtr = (mainAtr or self.data[jobInfo.ma])
	local vars = DataConfig.data.cfg.system_simple.formula
	local baseNum  =(useAtr * vars["min_dam"][1] + vars["min_dam"][2])
	return formatAttributeNum("min_dam",baseNum)
end
--计算最大伤害公式
function PlayerDataManager:calcBaseAttributesMaxDmg(heroType,mainAtr)
	local useHType = (heroType or self:getHeroType())
	local jobInfo = DataConfig:getJobById(""..useHType)
	local useAtr = (mainAtr or self.data[jobInfo.ma])
	local vars = DataConfig.data.cfg.system_simple.formula
	local baseNum  =(useAtr * vars["max_dam"][1] + vars["max_dam"][2])
	return formatAttributeNum("max_dam",baseNum)
end
--计算筋骨公式--2014年12月4号此函数阵亡。玩家的arm只有穿装备得到，不能由其他属性衍生出来
function PlayerDataManager:calcBaseAttributesArm(strr)
	local vars = DataConfig.data.cfg.system_simple.formula
	local useStrr = (strr or self.data.strr)
	local baseNum  = (vars["arm"][1]* useStrr + vars["arm"][2])
	--return baseNum
	return 0
end
--计算免伤公式,arm是被攻击者的护甲，lv是攻击者的等级
function PlayerDataManager:calcBaseAttributesArmRate(arm,lv)
	local vars = DataConfig.data.cfg.system_simple.formula
	local useArm = (arm or self.data.arm)
	local useLv = (lv or self.data.lv)
	local arm_rate_str = (useArm/(useArm + vars["arm_rate"][1]*(useLv^2)+vars["arm_rate"][2]))
	local baseNum  = arm_rate_str
	return baseNum
end
--计算免伤公式,只是为了"更多属性"里的显示,守方护甲，守方等级
function PlayerDataManager:calcBaseAttributesShowArmRate(arm,lv)
	return arm/(arm+3*(arm^2)+50)
end
--计算会心公式,只是为了"更多属性"里的显示,攻方会心点数,攻方等级
function PlayerDataManager:calcBaseAttributesShowCriRate(cri,lv)
	return cri/(cri+3*lv*lv+3*lv+50)
end
--计算deff公式
function PlayerDataManager:calcBaseAttributesDeff(strr)
	local useAtr = (strr or self.data.strr)
	local vars = DataConfig.data.cfg.system_simple.formula
	local baseNum  = (useAtr * vars["deff"][1] + vars["deff"][2])
	return formatAttributeNum("deff",baseNum)
end
--计算adf公式
function PlayerDataManager:calcBaseAttributesAdf(intt)
	local useAtr = (intt or self.data.intt)
	local vars = DataConfig.data.cfg.system_simple.formula
	local baseNum  = (useAtr * vars["adf"][1] + vars["adf"][2])
	return formatAttributeNum("adf",baseNum)
end
--计算cri公式
function PlayerDataManager:calcBaseAttributesCri(agi)
	local vars = DataConfig.data.cfg.system_simple.formula
	local useAgi = (agi or self.data.agi)
	local baseNum  = (vars["cri"][1]* useAgi + vars["cri"][2])
	return formatAttributeNum("cri",baseNum)
end
--计算hit公式
function PlayerDataManager:calcBaseAttributesHit(strr)
	local vars = DataConfig.data.cfg.system_simple.formula
	local useStrr = (strr or self.data.strr)
	local baseNum  = (vars["hit"][1]* useStrr + vars["hit"][2])
	return formatAttributeNum("hit",baseNum)
end
--计算dod公式
function PlayerDataManager:calcBaseAttributesDod(agi)
	local vars = DataConfig.data.cfg.system_simple.formula
	local useAgi = (agi or self.data.agi)
	local baseNum  = (vars["dod"][1]* useAgi + vars["dod"][2])
	return formatAttributeNum("dod",baseNum)
end
--计算res公式
function PlayerDataManager:calcBaseAttributesRes(sta)
	local vars = DataConfig.data.cfg.system_simple.formula
	local useSta = (sta or self.data.sta)
	local baseNum  = (vars["res"][1]* useSta + vars["res"][2])
	return formatAttributeNum("res",baseNum)
end
--计算crd公式
function PlayerDataManager:calcBaseAttributesCrd(lv)
	local vars = DataConfig.data.cfg.system_simple.formula
	local useLv = (lv or self.data.lv)
	local baseNum  = vars["crd"][1]* useLv + vars["crd"][2]
	return formatAttributeNum("crd",baseNum)
end
--计算mps公式
function PlayerDataManager:calcBaseAttributesMps(intt)
	local vars = DataConfig.data.cfg.system_simple.formula
	local useIntt = (intt or self.data.intt)
	local baseNum  = math.min(vars["mps"][1]* useIntt + vars["mps"][2],vars["mps"][3])
	return formatAttributeNum("mps",baseNum)
end
--装备属性重计算
function PlayerDataManager:calcEquipAttributes()
	local bodyEquips = Bag:getAllEquip(true,"body")

	--计算神属性提升等级
	if(#bodyEquips < 10) then
		self.godImproveLv = 0
	else
		self.godImproveLv = bodyEquips[1].star
		for k,v in pairs(bodyEquips) do
			if(v.star < self.godImproveLv) then
				self.godImproveLv = v.star
			end
		end
	end
	--计算基本属性，二级属性，神属性
	local baseAttrs = {0,0,0,0}--基本属性
	local addAttrs = {hp = 0,mp = 0,minDmg = 0,maxDmg = 0,arm = 0,deff = 0,adf = 0,cri = 0,hit = 0,dod = 0,res = 0,mps = 0,}--二级属性
	local godInfo = {}--神属性
	local tempBaseAttrs
	local tempAddAttrs
	local tempGodInfo
	local godCfg = DataConfig.data.cfg.god
	for i,v in pairs(bodyEquips) do
		tempBaseAttrs = Bag:getEquipById(v.sid).color
		tempAddAttrs = Bag:getEquipById(v.sid).attrs		
		for i,vv in ipairs(baseAttrs) do
			baseAttrs[i] = baseAttrs[i] + tempBaseAttrs[i+1] 
		end
		for k,vv in pairs(tempAddAttrs) do
			addAttrs[k] = addAttrs[k] + vv
		end
		tempGodInfo = Bag:getEquipById(v.sid).godInfo
		local godStar = Bag:getEquipById(v.sid).god[1]
		for k,vv in pairs(tempGodInfo) do
			if(not godInfo[k]) then
				godInfo[k] = 0
			end
			godInfo[k] = godInfo[k] + vv 
			if(self.godImproveLv > 0) then
				local proLv = math.min(self.godImproveLv,godStar)
				godInfo[k] = godInfo[k] + godCfg[k].unlock_base[1]*DataConfig:getGodUnlock()[tostring(proLv)] + godCfg[k].unlock_base[2]
				godInfo[k] = formatGodinfoNum(k,godInfo[k])
			end
		end
	end
	return 	baseAttrs,addAttrs,godInfo
end
--属性重计算
--人物等级 装备等重新计算人物血量
function PlayerDataManager:calcAttributes()
	-- body
	--裝備属性信息
	local baseAttrs
	local addAttrs
	local godInfo
	baseAttrs,addAttrs,godInfo = self:calcEquipAttributes()
	self.godInfo = godInfo
	--计算玩家基本属性
	local jobInfo = DataConfig:getJobById(""..self:getHeroType())
	for k,v in pairs(JobAttrConst) do
		self.data[k] = jobInfo.as[v][1] + jobInfo.as[v][2] * (self:getLv()-1)--职业成长基本属性
		self.data[k] = formatAttributeNum(k,self.data[k])
		self.data[k] = self.data[k] + baseAttrs[v]--装备增加基本属性
	end
	--print("arm=",self.data.arm)
	--[[
'formula': [(10, 0), (7, -65), (0.5, 5),(1, 10),(2, 3.5),(0.25, 2.5),(0.25, 2.5),(1, 0),(1, 0),(0.2, 0),(1, 0)],
#1：气血Hp=a*体质sta+b; 2: 内力mp=a*内劲int+b; 3:最小伤害：a*主属性+b 4：最大伤害：a*主属性+b 
5:免伤arm_rate=护甲arm/(lv(敌方的等级)^a*b) 6:外防def=a*主属性+b  
7:内防adf=a*主属性+b 8: 会心cri= a*身法agi+b 9:命中hit=a*力道str+b; 
10:闪避dod=a*身法agi+b 11: 招架res=a*体质sta+b
	]]
	if(jobInfo.ma == "int") then
		jobInfo.ma = "intt"
	end
	if(jobInfo.ma == "str") then
		jobInfo.ma = "strr"
	end
	--计算玩家二级属性（基本属性生成+装备加成）
	self.data.hp = self:calcBaseAttributesHp() + addAttrs.hp
	self.data.mp = self:calcBaseAttributesMp() + addAttrs.mp
	self.data.minDmg = self:calcBaseAttributesMinDmg() + addAttrs.minDmg
	self.data.maxDmg = self:calcBaseAttributesMaxDmg() + addAttrs.maxDmg
	self.data.arm = self:calcBaseAttributesArm() + addAttrs.arm
	self.data.deff = self:calcBaseAttributesDeff() + addAttrs.deff
	self.data.adf = self:calcBaseAttributesAdf() + addAttrs.adf
	self.data.cri = self:calcBaseAttributesCri() + addAttrs.cri
	self.data.hit = self:calcBaseAttributesHit() + addAttrs.hit
	self.data.dod = self:calcBaseAttributesDod() + addAttrs.dod
	self.data.res = self:calcBaseAttributesRes() + addAttrs.res
	self.data.mps = self:calcBaseAttributesMps() + addAttrs.mps
	--self.data.hit_rate
	--self.data.cri_rate
	self.data.crd = self:calcBaseAttributesCrd()


	--神属性影响某些属性，计算
	if(godInfo["add_dam"]) then
		self.data.minDmg = self.data.minDmg*(1+godInfo["add_dam"])
		self.data.minDmg = formatAttributeNum("minDmg",self.data.minDmg)
		self.data.maxDmg = self.data.maxDmg*(1+godInfo["add_dam"])
		self.data.maxDmg = formatAttributeNum("maxDmg",self.data.maxDmg)
	end
	if(godInfo["add_hp"]) then
		self.data.hp = self.data.hp*(1+godInfo["add_hp"])
		self.data.hp = formatAttributeNum("hp",self.data.hp)
	end
	if(godInfo["add_crd"]) then
		self.data.crd = self.data.crd+godInfo["add_crd"]
		self.data.crd = formatAttributeNum("crd",self.data.crd)
	end
	if(godInfo["add_armor"]) then
		self.data.arm = self.data.arm*(1+godInfo["add_armor"])
		self.data.arm = formatAttributeNum("arm",self.data.arm)
	end
	if(godInfo["add_deff"]) then
		self.data.deff = self.data.deff*(1+godInfo["add_deff"])
		self.data.deff = formatAttributeNum("deff",self.data.deff)
	end
	if(godInfo["add_adf"]) then
		self.data.adf = self.data.adf*(1+godInfo["add_adf"])
		self.data.adf = formatAttributeNum("adf",self.data.adf)
	end
	if(godInfo["add_dod"]) then
		self.data.dod = self.data.dod*(1+godInfo["add_dod"])
		self.data.dod = formatAttributeNum("dod",self.data.dod)
	end
	if(godInfo["add_cri"]) then
		self.data.cri = self.data.cri*(1+godInfo["add_cri"])
		self.data.cri = formatAttributeNum("cri",self.data.cri)
	end
	if(godInfo["add_hit"]) then
		self.data.hit = self.data.hit*(1+godInfo["add_hit"])
		self.data.hit = formatAttributeNum("hit",self.data.hit)
	end
	if(godInfo["add_res"]) then
		self.data.res = self.data.res*(1+godInfo["add_res"])
		self.data.res = formatAttributeNum("res",self.data.res)
	end
	self.data.arm_rate = self:calcBaseAttributesArmRate()




	local powerVars = DataConfig.data.cfg.system_simple.combat_effective
	local power = 0
	if(powerVars) then
		local nums = {self.data.hp,self.data.mp,
		self.data.minDmg,self.data.maxDmg,self.data.arm,self.data.deff,
		self.data.adf,self.data.cri,self.data.res,self.data.hit,self.data.dod}
		for i,v in ipairs(powerVars) do
			power = power + powerVars[i]*nums[i]
		end
		--[[+攻击力均值(最小伤害最大伤害相加除以2)*吸血率*回合均值(5)*0.1
		+攻击力均值*0.1*护甲无视率
		+反伤率*最大生命值*0.1
		+抵消不良概率*最大生命值*0.1]]
		local godparam = DataConfig.data.cfg.system_simple.get_power
		if(godInfo["suck_blood"]) then
			power = power + godparam[1]*godInfo["suck_blood"]*self.data.hp*0.1
		end
		if(godInfo["ignore_armor"]) then
			--攻击力均值 * 0.5 * 护甲无视率(ignore_armor)
			power = power + godparam[2]*godInfo["ignore_armor"]/(godInfo["ignore_armor"] + 100)*0.5*self.data.hp
		end  
		if(godInfo["anti_dam"]) then
			power = power + godparam[3]*godInfo["anti_dam"]*0.1*self.data.hp
		end
		if(godInfo["resist_debuff"]) then
			power = power + godparam[4]*godInfo["resist_debuff"]*0.1*self.data.hp
		end
	end
	self.data.power = math.floor(power)
end

--返回玩家姓名
function PlayerDataManager:getPlayerName()
	return self.data.name
end
--设置玩家姓名
function PlayerDataManager:setPlayerName(str)
	self.data.name = str
end
--等级
function PlayerDataManager:getLv()
	return self.data.lv
end
function PlayerDataManager:setLv(lv)
	if(self.data.lv ~= lv) then
		self.data.lv = lv
		Observer.sendNotification(IndexModule.LEVEL_UPDATE)
		self:calcAttributes()
		Observer.sendNotification(BagModule.UPDATE_EQUIP_ATTR)
		self:updateUnlockBattleSkillsNum()
		self:updateAllOpenSkills()
		Observer.sendNotification(skillmodule.UPDATE_SKILL_UNLOCK)
		
		local net = {}
		net.method = BattleModule.USER_UPGRADE
		net.params = {}
		Net.sendhttp(net)
		Observer.sendNotification(GamesysModule.UPDATE_GAME_TASK)--任务更新
	end
end
--session key
function PlayerDataManager:getSessionKey()
	return self.data.session_key
end
function PlayerDataManager:setSessionKey(key)
	self.data.session_key = key
end
--session id
function PlayerDataManager:getSessionId()
	return self.data.sessionid
end
function PlayerDataManager:setSeesionId(id)
	self.data.sessionid = id
end
--uid
function PlayerDataManager:getUid()
	return self.data.uid
end
function PlayerDataManager:setUid(id)
	self.data.uid = id
end
--元宝
function PlayerDataManager:getCoin()
	return self.data.coin
end
function PlayerDataManager:setCoin(num)
	self.data.coin = num
	Observer.sendNotification(IndexModule.MONEY_UPDATE)
end
--银两
function PlayerDataManager:getGold()
	return self.data.gold
end
function PlayerDataManager:setGold(num)
	self.data.gold = num
	Observer.sendNotification(IndexModule.MONEY_UPDATE)
end
--经验
function PlayerDataManager:getExp()
	return self.data.exp
end
function PlayerDataManager:setExp(exp) 
	local maxLv = DataConfig.data.cfg.system_simple.exp_config[4]
	local curExp = exp
	local curLv = self:getLv()
	local lvExp = DataConfig:getUpdateExpByLvl(curLv)
	local caling = (curExp >= lvExp)
	while (caling) do
		curExp = curExp - lvExp
		curLv = curLv + 1
		lvExp = DataConfig:getUpdateExpByLvl(curLv)
		if(curLv > maxLv) then
			curLv = curLv - 1
			curExp = DataConfig:getUpdateExpByLvl(curLv)
			caling = false
		else
			caling = (curExp >= lvExp)
		end
	end
	self.data.exp = curExp
	self:setLv(curLv)
	if(curLv >= DataConfig:getMaxCfgLV()) then
		curLv = DataConfig:getMaxCfgLV()
		self.data.exp = 0
	end
	Observer.sendNotification(IndexModule.EXP_UPDATE)
end



--通过key来获取属性 
--attrname 属性名称 字符串
function PlayerDataManager:getattr(attrname)
	return self.data[attrname]
end
--门派hero_type
function PlayerDataManager:getHeroType()
	return self.data.hero_type
end
function PlayerDataManager:setHeroType(id)
	self.data.hero_type = id
end
--VIP
function PlayerDataManager:getVipLv()
	return self.data.vip_lv
end
function PlayerDataManager:setVipLv(id)
	self.data.vip_lv = id
end
--返回所有的装备
function PlayerDataManager:getAllEquip()
	return self.data.equips
end
--当前熔炼值
function PlayerDataManager:getMelte()
	return self.data.melte
end
function PlayerDataManager:setMelte(num)
	self.data.melte = num
	Observer.sendNotification(RonglianModule.MELTE_UPDATE)
end
--当前威望
function PlayerDataManager:getMana()
	return self.data.mana
end
function PlayerDataManager:setMana(mana)
	self.data.mana = mana
	Observer.sendNotification(IndexModule.MONEY_UPDATE)
end
--需要打造的装备
function PlayerDataManager:setDazaoData(data)
	self.dazaoData = data
end
function PlayerDataManager:getDazaoData()
	return self.dazaoData
end
--获取当前的背包上限
function PlayerDataManager:getBagMax()
	local buycount = self.data.attrs.bag_buy_count
	local bagcofig = DataConfig:getBagConfig()
	local a = bagcofig[1] --背包基数
	-- local b = bagcofig[2]
	local c = bagcofig[3]   --每次购买增加背包格子数
	return a + c * buycount
end
--获取购买次数
--扩展背包 'enhance_bag':[50,200,10,10,90] ,#初始背包容量; 背包容量上限; 每次提升的容量数 消耗元宝数量a*次数+b
--购买次数=（上限-现有）/每次提升的
function PlayerDataManager:getKuoZhanBag()

	local bagcofig = DataConfig:getBagConfig()
	local base = bagcofig[1]
	local maxBag = bagcofig[2]
	local tiSheng = bagcofig[3] --每次提升格子数
	-- local cost = bagcofig[4]　　--每次扩展的花费
	local cost = bagcofig[4]
	local b = bagcofig[5]
	local count = self.data.attrs.bag_buy_count  --已经购买的次数
	local coin = 0 
	if (count*tiSheng + base) == maxBag then
		coin = -1 --扩展到最大　不能再扩展了
	else
		coin = cost*count + b
	end
	

	local have = count * tiSheng + base
	local times = (maxBag - have)/tiSheng

	return tiSheng,coin,times
end
--更新扩展背包里的购买次数
function PlayerDataManager:getBuyCount()
	return self.data.attrs.bag_buy_count
end
function PlayerDataManager:setBuyCount(num)
	self.data.attrs.bag_buy_count = num
end
--获取商城数据
function PlayerDataManager:getShopData(type)
	return self.shopData
end
--缓存商城数据
function PlayerDataManager:setShopData(data)
	self.shopData = data
	local index = 0
	for k,v in pairs(self.shopData) do
		if string.sub(v.id_type,1,1) == "E" then
			v.edata = DataConfig:getEquipById(v.id_type)
		else
			v.edata = DataConfig:getGoodByID(v.id_type)
		end
		v.eid = v.id_type
		v.index = index
		v.color = {v.color}
		index = index + 1
	end
end

--获取装备打造刷新次数
function PlayerDataManager:getEquipForgeRefresh()
	return self.data.records.equip_forge_refresh
end
--设置装备打造刷新次数
function PlayerDataManager:setEquipForgeRefresh(num)
	self.data.records.equip_forge_refresh = num
end

--获取VIP商城刷新次数
function PlayerDataManager:getVipShopRefreshCount()
	return self.data.records.vip_shop_refresh_count
end
--设置VIP商城刷新次数
function PlayerDataManager:setVipShopRefreshCount(count)
	self.data.records.vip_shop_refresh_count = count
end

--获取普通商城刷新次数
function PlayerDataManager:getShopRefreshCount()
	return self.data.records.shop_refresh_count
end
--设置普通商城刷新次数
function PlayerDataManager:setShopRefreshCount(count)
	self.data.records.shop_refresh_count = count
end

--银两商城购买次数
function PlayerDataManager:getShopGoldCount()
	return self.data.records.shop_gold_count
end

function PlayerDataManager:setShopGoldCount(count)
	self.data.records.shop_gold_count = count
end
--今日快速战斗次数
function PlayerDataManager:setQuickBattles(quickBattles)
	self.quickBattles = quickBattles
end
function PlayerDataManager:getQuickBattles()
	return self.quickBattles
end
--所有开放技能
function PlayerDataManager:setAllOpenSkills(sData)
	self.data.attrs.skills = sData
end
function PlayerDataManager:updateAllOpenSkills()
	local jobSkills = DataConfig:getReconfigSkill()[self:getHeroType()]
	for i,v in ipairs(jobSkills) do
		if(v.unlock_lv>self:getLv()) then
			break
		end
		if(not self.data.attrs.skills[v.id]) then
			self.data.attrs.skills[v.id] = {}
			self.data.attrs.skills[v.id].lv = 1
		end
	end
end
function PlayerDataManager:getAllOpenSkills()
	return self.data.attrs.skills
end
--所有战斗中使用技能
function PlayerDataManager:setBattleSkills(sData)
	self.data.attrs.combat_skills = sData
	Observer.sendNotification(skillmodule.UPDATE_SKILL_UNLOCK)
end
function PlayerDataManager:getBattleSkills()
	return self.data.attrs.combat_skills
end
function PlayerDataManager:setPvpSkills(sData)
	self.data.attrs.pvp_skills = sData
	Observer.sendNotification(skillmodule.UPDATE_SKILL_UNLOCK_PVP)
end
function PlayerDataManager:getPvpSkills()
	return self.data.attrs.pvp_skills
end
--战斗中解锁的技能数量 he 开放技能 随等级的更新
function PlayerDataManager:updateUnlockBattleSkillsNum()
	local cfg = DataConfig:getUnlockBattleSkillCfg()
	local num = 0
	for i,v in ipairs(cfg) do
		if(self:getLv()<v) then
			break
		end
		num = i
	end
	if(self.data.attrs.unlockBattleSkillsNum ~= num) then
		self.data.attrs.unlockBattleSkillsNum = num
	end
end
function PlayerDataManager:getUnlockBattleSkillsNum()
	if(not self.data.attrs.unlockBattleSkillsNum) then
		self:updateUnlockBattleSkillsNum()
	end
	return self.data.attrs.unlockBattleSkillsNum
end
--神器效果提升等级（全身部位装备最小强化等级）
function PlayerDataManager:getGodImproveLv()
	return self.godImproveLv
end
--身上所有神器效果
function PlayerDataManager:getGodInfo()
	return self.godInfo
end
--[[
佣兵数据
"follower" = {
[6.6362] -                 "152" = {
[6.6379] -                     "as_equips" = {
[6.6387] -                         1 = ""
[6.6395] -                         2 = ""
[6.6401] -                         3 = ""
[6.6425] -                         4 = ""
[6.6435] -                     }
[6.6445] -                     "hero_type"     = "2"
[6.6452] -                     "name"          = "挣扎的希维尔"
[6.6462] -                     "skills" = {
[6.6467] -                         1 = {
[6.6472] -                             "S_2001" = {
[6.6476] -                                 "lv" = 1
[6.6482] -                             }
[6.6486] -                         }
[6.6492] -                     }
[6.6496] -                     "special_train" = {
[6.6501] -                         "agi"  = 0
[6.6506] -                         "intt" = 0
[6.6513] -                         "sta"  = 0
[6.6519] -                         "strr" = 0
[6.6525] -                     }
[6.6531] -                     "train" = {
[6.6539] -                         "agi"  = 0
[6.6544] -                         "intt" = 0
[6.6553] -                         "sta"  = 0
[6.6569] -                         "strr" = 0
[6.6576] -                     }
[6.6583] -                 }

]]
--计算所有佣兵的属性数据（在上线后和升级后执行）
function PlayerDataManager:updateAllSolidersAttrs()
	local allSoliders = self:getAllSoliders()
	if(allSoliders) then 
		for k,v in pairs(allSoliders) do
			self:updateSoliderAttrsByID(k)
		end
	end
end
--获得当前出战弟子ID
function PlayerDataManager:getOnworkSolider()
	return self.data.attrs.on_work_fo
end
--设置当前出战弟子ID
function PlayerDataManager:setOnworkSolider(id)
	if(self.data.attrs.on_work_fo ~= id) then
		self.data.attrs.on_work_fo = id
	end
end
--获得玩家所有佣兵数据
function PlayerDataManager:getAllSoliders()
	return self.data.follower
end
--设置玩家所有佣兵数据
function PlayerDataManager:setAllSoliders(fdatas)
	self.data.follower = fdatas
end
--根据佣兵ID获得玩家的某一个佣兵
function PlayerDataManager:getSoliderByID(soliderID)
	return self.data.follower[soliderID]
end
--根据佣兵ID获得玩家的某一个佣兵的专精培养数据
function PlayerDataManager:getSoliderSpecialTrainByID(soliderID)
	return self.data.follower[soliderID].special_train
end
--根据佣兵ID设置玩家的某一个佣兵的专精培养数据
function PlayerDataManager:setSoliderSpecialTrainByID(soliderID,data)
	self.data.follower[soliderID].special_train = data
end
--增加玩家的某一个佣兵的train属性
function PlayerDataManager:addSoliderTrainAttrsByID(soliderID,addTrains)
	local sData = self.data.follower[soliderID]
	for k,v in pairs(addTrains) do
		sData.train[k] =  v
	end
end
--计算某一佣兵数据,佣兵的装备数据也必须跟玩家一样在初始化和更新的时候重新计算，为了避免每次使用都要计算
function PlayerDataManager:updateSoliderAttrsByID(soliderID)
	local sData = self:getSoliderByID(soliderID)
	local bodyEquips = sData.as_equips
	--计算基本属性，二级属性，神属性
	local baseAttrs = {0,0,0,0}--基本属性
	local addAttrs = {hp = 0,mp = 0,minDmg = 0,maxDmg = 0,arm = 0,deff = 0,adf = 0,cri = 0,hit = 0,dod = 0,res = 0,mps = 0,}--二级属性
	local godInfo = {}--神属性
	local tempBaseAttrs
	local tempAddAttrs
	local tempGodInfo
	local godCfg = DataConfig.data.cfg.god
	for i,v in pairs(bodyEquips) do
		if(v ~= "") then
			tempBaseAttrs = Bag:getEquipById(v).color
			tempAddAttrs = Bag:getEquipById(v).attrs		
			for i,vv in ipairs(baseAttrs) do
				baseAttrs[i] = baseAttrs[i] + tempBaseAttrs[i+1] 
			end
			for k,vv in pairs(tempAddAttrs) do
				addAttrs[k] = addAttrs[k] + vv
			end
			tempGodInfo = Bag:getEquipById(v).godInfo
			local godStar = Bag:getEquipById(v).god[1]
			for k,vv in pairs(tempGodInfo) do
				if(not godInfo[k]) then
					godInfo[k] = 0
				end
				godInfo[k] = godInfo[k] + vv 
			end
		end
	end
	local attrs = {}
	local jobAttrs = {}
	--计算弟子基本属性
	local jobInfo = DataConfig:getJobById(""..sData.hero_type)
	for k,v in pairs(JobAttrConst) do
		jobAttrs[k] = jobInfo.as[v][1] + jobInfo.as[v][2] * (self:getLv()-1)--职业成长基本属性
		jobAttrs[k] = formatAttributeNum(k,jobAttrs[k])
		attrs[k] = jobAttrs[k] + baseAttrs[v]--装备增加基本属性
	end
	--培养增加的基本属性
	for k,v in pairs(sData.train) do
		attrs[k] = attrs[k] + v
	end
	--[[
'formula': [(10, 0), (7, -65), (0.5, 5),(1, 10),(2, 3.5),(0.25, 2.5),(0.25, 2.5),(1, 0),(1, 0),(0.2, 0),(1, 0)],
#1：气血Hp=a*体质sta+b; 2: 内力mp=a*内劲int+b; 3:最小伤害：a*主属性+b 4：最大伤害：a*主属性+b 
5:免伤arm_rate=护甲arm/(lv(敌方的等级)^a*b) 6:外防def=a*主属性+b  
7:内防adf=a*主属性+b 8: 会心cri= a*身法agi+b 9:命中hit=a*力道str+b; 
10:闪避dod=a*身法agi+b 11: 招架res=a*体质sta+b
	]]
	if(jobInfo.ma == "int") then
		jobInfo.ma = "intt"
	end
	if(jobInfo.ma == "str") then
		jobInfo.ma = "strr"
	end
	local mainAtr =attrs[jobInfo.ma]
	local job = sData.hero_type
	local lv = self:getLv()
	--计算玩家二级属性（基本属性生成+装备加成）
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


	--专精培养增加的基本属性
	--[["special_train" = {
                "agi"  = 0 cri
                "intt" = 0 adf
                "sta"  = 0 hp
                "strr" = 0 deff
                }]]
    local trainDic = {agi = "cri",intt = "adf",sta = "hp",strr = "deff",}
	if(sData.special_train) then
		for k,v in pairs(sData.special_train) do
			attrs[trainDic[k]] = attrs[trainDic[k]] + v*attrs[k]
			attrs[trainDic[k]] = formatAttributeNum(trainDic[k],attrs[trainDic[k]])
		end
	end
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
	sData.attrs = attrs
	sData.godInfo = godInfo
	sData.jobAttrs = jobAttrs
end
--获得佣兵普通培养时未保存的数据
--fid
function PlayerDataManager:getFosterKeepData(fid)
	return self.data.attrs.follower_train_value[fid]
end
function PlayerDataManager:setFosterKeepData(trainValue)
	self.data.attrs.follower_train_value = trainValue
end
--获得佣兵专精培养时未保存的数据
function PlayerDataManager:getSpecialKeepData(fid)
	return self.data.attrs.follower_special_train_value[fid]
end
function PlayerDataManager:setSpecialKeepData(sptrainValue)
	self.data.attrs.follower_special_train_value = sptrainValue
end
--存一下系数值
function PlayerDataManager:getSpecialCoeData()
	return self.CoeData
end
function PlayerDataManager:setSpecialCoeData(spValue)
	self.CoeData = spValue
end
--设置任务数据
function PlayerDataManager:setTaskData(tdata)
	self.data.task = tdata
	Observer.sendNotification(GamesysModule.UPDATE_GAME_TASK)
end
--得到任务数据
function PlayerDataManager:getTaskData()
	return self.data.task
end
--得到每日任务PVP数量
function PlayerDataManager:getPVPTaskCompletedCount()
	return self.data.records.PVP_task_count
end
--set每日任务PVP数量
function PlayerDataManager:setPVPTaskCompletedCount(pvpcount)
	self.data.records.PVP_task_count = pvpcount
	Observer.sendNotification(GamesysModule.UPDATE_GAME_TASK)
end
--累积登陆天数
function PlayerDataManager:getTotalLogin()
	return self.data.total_login
end
function PlayerDataManager:setTotalLogin(lnum)
	self.data.total_login = lnum
end
--累计充值获得的总元宝，包括额外增加的
function PlayerDataManager:getTotalPay()
	return self.data.total_coin
end
function PlayerDataManager:setTotalPay(tcoin)
	self.data.total_coin = tcoin
end
--首冲
function PlayerDataManager:getFirstPay()--1表示已首冲，0表示未
	return (self.data.attrs.pay_first_gift == 1)
end
function PlayerDataManager:setFirstPay(bpay)
	self.data.attrs.pay_first_gift = bpay
	Observer.sendNotification(GamesysModule.UPDATE_GAME_TASK)
end
--分区信息
function PlayerDataManager:getZone()
	return self.data.zone
end
--当前用户装备的称号
function PlayerDataManager:getTitle()
	return self.data.attrs.title or ""
end
--设置当前用户装备的称号
function PlayerDataManager:setTitle(title)
	self.data.attrs.title = title
	Observer.sendNotification(GamesysModule.UPDATE_USER_TITLE)
end
--当前用户拥有的称号库
function PlayerDataManager:getTitles()
	return self.data.attrs.titles or ""
end
--设置当前用户拥有的称号库
function PlayerDataManager:setTitles(titles)
	self.data.attrs.titles = titles
	Observer.sendNotification(GamesysModule.UPDATE_USER_TITLES)
end
--设置用户签名
function PlayerDataManager:setSignature(text)
	self.data.attrs.signature = text
end
--获取用户签名
function PlayerDataManager:getSignature()
	return self.data.attrs.signature or ""
end
--获取上一次pvp时间
function PlayerDataManager:getLastPvpTime()
	return self.data.attrs.pvp_time["$datetime"] or ""
end
--设置上一次pvp时间
function PlayerDataManager:setLastPvpTime(pvptime)
	self.data.attrs.pvp_time["$datetime"] = pvptime
end
-- 设置宝石升级幸运值
function PlayerDataManager:setGemUpLuck(value)
	self.data.attrs.gem_luck = value
end
-- 获取宝石升级幸运值
function PlayerDataManager:getGemUpLuck()
	return self.data.attrs.gem_luck or 0
end
--获取玩家商店购买次数
function PlayerDataManager:getShopBuyCount()
	return self.data.records.shop_buy_count
end
--设置玩家商店购买次数
function PlayerDataManager:setShopBuyCount(count)
	self.data.records.shop_buy_count = count
end
--获取弟子技能刷新次数
function PlayerDataManager:getFoSkillReCount()
	return self.data.records.fo_refresh_skill_num
end
--设置弟子技能刷新次数
function PlayerDataManager:setFoSkillReCount(count)
	self.data.records.fo_refresh_skill_num = count
end
--累计充值的人民币
function PlayerDataManager:getTotalPayMoney()
	return self.data.total_pay_money
end
function PlayerDataManager:setTotalPayMoney(money)
	self.data.total_pay_money = money
end
--获取玩家是否首冲
function PlayerDataManager:getFirstCharge()
	return self.data.attrs.pay_first
end
function PlayerDataManager:setFirstCharge(paydata)
	self.data.attrs.pay_first = paydata
end
--获得玩家打造神器列表
function PlayerDataManager:getDazaoGodList()
	return self.data.records.sp_forge
end
--设置玩家打造神器列表
function PlayerDataManager:setDazaoGodList(sp_forge)
	self.data.records.sp_forge = sp_forge
end

return PlayerDataManager