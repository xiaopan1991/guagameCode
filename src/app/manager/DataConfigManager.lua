--数据配置管理器
local DataConfigManager = class("DataConfig")

--构造
function DataConfigManager:ctor()
	self.data = nil
end

--设置数据
function DataConfigManager:setData(data)
	self.data = data
end

--根据ID 获取装备的静态配置
--id 字符串
function DataConfigManager:getEquipById(id)
	return self.data.cfg.equip[id]
end

--根据ID获取道具静态配置
function DataConfigManager:getGoodByID(id)
	return self.data.cfg.goods[id]
end

--获取分区列表
function DataConfigManager:getZones()
	return self.data.cfg.zone_config
end

--根据ID获取分区
function DataConfigManager:getZoneById(id)
	return self.data.cfg.zone_config[id]
end

--获取配置文件的版本号
function DataConfigManager:getConfigVersion()
	return self.data.cfg_version
end

--根据ID获取monster
function DataConfigManager:getMonsterById(id)
	return self.data.cfg.enemy[id]
end
--根据ID获取skill
function DataConfigManager:getSkillById(id)
	return self.data.cfg.skill[id]
end
--获取skill耗蓝
function DataConfigManager:getSkillMpByIdLv(id,lv)
	return self.data.cfg.skill[id].mp[1]*lv + self.data.cfg.skill[id].mp[2]
end
--skill数据配置整理成按照职业和解锁等级读取
function DataConfigManager:getReconfigSkill()
	if(not self.jobSkillDic) then
		self.jobSkillDic = {}
		local job
		for k,v in pairs(self.data.cfg.skill) do
			v.id = k
			job = tonumber(string.sub(k,3,3))
			if(not self.jobSkillDic[job]) then
				self.jobSkillDic[job] = {}
			end
			table.insert(self.jobSkillDic[job],v)
		end
		for k,v in pairs(self.jobSkillDic) do
			table.sort( v, 
			function (a,b)
				return a.unlock_lv < b.unlock_lv
			end
		 )
		end		
	end	
	return self.jobSkillDic
end
--战斗中解锁的技能数量与对应的等级
function DataConfigManager:getUnlockBattleSkillCfg()
	return self.data.cfg.system_simple.unlock_skill_bar
end
--根据ID获取Boss
function DataConfigManager:getBossById(id)
	return self.data.cfg.boss[id]
end
--根据ID获取map
function DataConfigManager:getMapById(id)
	return self.data.cfg.map[id]
end
--根据地图id，玩家等级获取地图装备掉率
function DataConfigManager:getDropRateByMapIdAndPlayerLV(mapid)
	local cfg = self.data.cfg.system_simple.map_drop
	local map_lv = self.data.cfg.map[mapid].map_lv
	local lv = PlayerData:getLv()
	return math.floor(((cfg[1] * map_lv + cfg[2]) * ((map_lv - lv) / (map_lv + lv) + 1)) * 10000)/10000 --取小数点后4位,直接截取

end
--获取map数量
function DataConfigManager:getMapNum()
	return table.nums(self.data.cfg.map)
end

--获取某副本之前的所有副本
function DataConfigManager:getMapsBefore(id)
	local result = {}
	local map = self.data.cfg.map
	local mapid = tonumber(string.sub(id,2))
	function makeMapId(index)
		local re = "M"
		local znum = 3 - string.len(tostring(index))
		if znum > 0 then
			for i=1,znum do
				re = re.."0"
			end
		end
		re = re..index
		return re
	end
	for i=1,mapid do
		local newid = makeMapId(i)
		map[newid].mid = newid
		result[#result + 1] = map[newid]
	end
	return result
end

--获取当前激活的地图
function DataConfigManager:getAliveMaps()
	return self:getMapsBefore(Raid:getMaxRaidId())
end

--职业信息as中属性对应的index
--力道（力） 身法（敏） 智（内劲） 体质（耐） 筋骨（护甲）
JobAttrConst = {}
JobAttrConst["strr"] = 1
JobAttrConst["agi"] = 2
JobAttrConst["intt"] = 3
JobAttrConst["sta"] = 4
--JobAttrConst["arm"] = 5
--根据ID获取职业信息
function DataConfigManager:getJobById(id)
	return self.data.cfg.hero[id]
end
--当前开放玩家升级最大等级
function DataConfigManager:getMaxCfgLV()
	return DataConfig.data.cfg.system_simple.exp_config[4]
end
--根据等级获取本级到下一级的升级经验
--lv 等级
--exp: lv = 10
--return 10 -- 11级的升级经验
--等级对应的经验公式
function DataConfigManager:getUpdateExpByLvl(lv)
	local specialLv = DataConfig.data.cfg.system_simple.up_exp
	local calVars = DataConfig.data.cfg.system_simple.exp_config
	if (specialLv[lv]) then
		return specialLv[lv]
	end
	if (specialLv[tostring(lv)]) then
		return specialLv[tostring(lv)]
	end
	--#100級前召唤师经验公式为ax^3+bx^2+c，配置中为（a，b，c）三个参数, 召唤师等级上限
	return calVars[1]*lv^3 + calVars[2]*lv^2 + calVars[3]
end

--获取背包的配置文件
function DataConfigManager:getBagConfig()
	return self.data.cfg.system_simple.enhance_bag
end

--获取打造花费的熔炼值
--color 装备 颜色
--是否神器 如果是神器 直接返回第六个
--'exchange_price': [100,200,300,500,1500,3000], #(打造)打造装备所需熔炉值(白绿蓝紫橙神)
function DataConfigManager:getDazaoCost(color,god)
	if god then
		return self.data.cfg.system_simple.forge.exchange_price[6]
	else
		return self.data.cfg.system_simple.forge.exchange_price[color]
	end
end

--获取装备评分配置
function DataConfigManager:getEquipScoreCfg()
	return self.data.cfg.system_simple.equip_score
end

--获得神属性配置
-- godname 神属性的名字
function DataConfigManager:getGodCfg(godname)
	return self.data.cfg.god[godname]
end

--根据装备位置获取神属性的名字
function DataConfigManager:getGodNameByPos(pos)
	return self.data.cfg.system_simple.equip_god[pos]
end
--获取打造刷新花费
function DataConfigManager:getDazaoRefreshCost()
	return self.data.cfg.system_simple.forge.refresh_price
end


--获取强化所需强化精华
function DataConfigManager:getQianghuaCostJinghua(data)
	local eid  = data.eid   --装备id
	local star = data.star --装备强化等级
	local lv   = tonumber(string.sub(eid,4,6))
	local pos  = tonumber(string.sub(eid,3,3)) --位置
	local color = self.data.cfg.system_simple.equip_strengthen.color 			--颜色参数
	local coefficient = self.data.cfg.system_simple.equip_strengthen.coefficient 	--参数
	local pith_star = self.data.cfg.system_simple.equip_strengthen.pith_star 		--精华参数
	local location = self.data.cfg.system_simple.equip_strengthen.location 			--位置参数
	--强化精华
	local cost = color[data.color[1] + 1] * (coefficient[1]*lv+coefficient[2])*location[pos+1]*pith_star[star+1]
	cost = math.modf(cost + 0.5) --向上取整
	return cost
end

--获取强化所需银两
function DataConfigManager:getQianghuaCostYinliang(data)
	local eid  = data.eid   --装备id
	local star = data.star --装备强化等级
	local lv   = tonumber(string.sub(eid,4,6))
	local pos  = tonumber(string.sub(eid,3,3)) --位置
	local color = self.data.cfg.system_simple.equip_strengthen.color 			--颜色参数
	local coefficient = self.data.cfg.system_simple.equip_strengthen.coefficient 	--参数
	local gold_star = self.data.cfg.system_simple.equip_strengthen.gold_star 		--银两参数
	local location = self.data.cfg.system_simple.equip_strengthen.location 			--位置参数
	--银两
	local cost = color[data.color[1] + 1]*(coefficient[1]*lv+coefficient[2])*location[pos+1]*gold_star[star+1]
	cost = math.modf(cost + 0.5) --向上取整
	return cost
end

--获取强化增长属性百分比
--返回 0-100
function DataConfigManager:getQianghuaAdd(data)
	local star = data.star --装备强化等级
	local attribute_star = self.data.cfg.system_simple.equip_strengthen.attribute_star
	--local color = self.data.cfg.system_simple.equip_strengthen.color 			--颜色参数
	local result = (data.color[1] + 1)*attribute_star[star + 1]
	return result*100
end

--获取洗练花费
function DataConfigManager:getWashCost(data)
	local color = self.data.cfg.system_simple.equip_washs.color 			--颜色参数
	local coefficient = self.data.cfg.system_simple.equip_washs.coefficient --计算参数
	local location = self.data.cfg.system_simple.equip_washs.location 		--位置参数
	local eid  = data.eid   --装备id
	local lv = tonumber(string.sub(eid,4,6))
	local pos  = tonumber(string.sub(eid,3,3)) --位置
	local cost = (color[data.color[1]+1])*(coefficient[1]*lv+coefficient[2])*location[pos+1]
	cost = math.modf(cost + 0.5) --向上取整
	return cost
end

--获取刷新普通商店的价格
function DataConfigManager:getRefreshShopCost()
	local cfg = self.data.cfg.shop.refresh_coin
	local count = PlayerData:getShopRefreshCount()
	return count*cfg[1] + cfg[2]
end
--获取刷新VIP商店的价格
function DataConfigManager:getRefreshVipShopCost()
	local cfg = self.data.cfg.shop.vip_shop.refresh_coin
	local count = PlayerData:getVipShopRefreshCount()
	return count*cfg[1] + cfg[2]
end

--获取银两商城的配置
function DataConfigManager:getGoldShopCfg()
	return self.data.cfg.system_simple.buy_gold
end
--获取VIP配置
function DataConfigManager:getVIPCfg()
	return self.data.cfg.vip
end

--根据颜色获取装备最大打孔数
--color 装备颜色
function DataConfigManager:getEquipHoldNum(color)
	local color_limit = self.data.cfg.system_simple.equip_hole.color_limit
	return color_limit[color + 1]
end

--获取装备打孔最低玩家等级
function DataConfigManager:getEquipHoldLimitUserLv()
	return self.data.cfg.system_simple.equip_hole.user_lv_limit
end

--获取装备打孔装备最低等级
function DataConfigManager:getEquipHoldLimitLv()
	return self.data.cfg.system_simple.equip_hole.equip_lv_limit
end

--获取打孔花费
function DataConfigManager:getEquipPunch()
	return self.data.cfg.system_simple.equip_punch
end
--神属性升级经验
function DataConfigManager:getGodLvExp(lv)
	--dump(lv)
	local lvExp = self.data.cfg.system_simple.god_devour.god_lv_exp
	local limit = lvExp[3]
	if lv >= limit then
		return 0
	end
	return math.floor(lvExp[1])*lv+math.floor(lvExp[2])
end
--根据快速战斗次数获取消耗元宝数目
function DataConfigManager:getCostZuanshi(num)
	local vars = self.data.cfg.system_simple.fighting_coin
	return vars[1] * num + vars[2]
end
--获取快速战斗时长,分钟
function DataConfigManager:getQuickFightLastTime()
	local vars = self.data.cfg.system_simple.fighting_coin
	return vars[3]
end

--神属性解锁
function DataConfigManager:getGodUnlock()
	return self.data.cfg.system_simple.god_unlock
end
--神属性需要花费银两
--gold = 花费常量（10000） + ((目标装备等级/5)+((目标装备等级-源装备等级)/5)^3) * 1(第二个系数) * quality * location * god_lv
--gold = gold + ((to_eqid_lv/5)+((to_eqid_lv-from_eqid_lv)/5)**2) * a * quality * location * god_lv

--gold = (花费常量（10） +((目标装备等级-源装备等级)/5)^3) * 1(第二个系数) * quality * location * god_lv
function DataConfigManager:getGodCost(eid,eid2,lvdex)

	local lvFrom = tonumber(string.sub(eid,4,6))
	local lvTo = tonumber(string.sub(eid2,4,6))
	local index = tonumber(string.sub(eid,3,3))
	local qua = tonumber(string.sub(eid,7,7))

	local location = self.data.cfg.system_simple.god_inherit.location
	local gold = self.data.cfg.system_simple.god_inherit.god_inherit_gold
	local const = gold[1]
	local b = gold[2] 
	local quality = self.data.cfg.system_simple.god_inherit.quality
	local god_lv = self.data.cfg.system_simple.god_inherit.god_lv
	local cost = (const + math.pow((lvTo-lvFrom)/5,3))* b * quality[qua+1] * location[index+1] * god_lv[lvdex]
	if lvFrom >= lvTo then
		return 10000
	elseif lvFrom < lvTo then
		return math.ceil(cost)
	end
end
--强化基础参数
function DataConfigManager:getEquipStrengthenVars()
	return self.data.cfg.system_simple.equip_strengthen.attribute_star
end
--强化增长属性计算公式
function DataConfigManager:getEquipStrengthenAddAttr(color,lv)
	local vars = self:getEquipStrengthenVars()
	return (color+1)*vars[lv]
end
--强化后的属性计算公式
function DataConfigManager:getEquipStrengthenAttrs(attr,color,lv)
	local allAdds = 1
	for i=1,lv do
		allAdds = allAdds + self:getEquipStrengthenAddAttr(color,i)
	end
	return attr*allAdds
end
--获取物品的卖出价格
function DataConfigManager:getItemSellMoney(eColor,eid)
	local cfg = self.data.cfg.system_simple.equip_sell
	local equip_lv = tonumber(string.sub(eid,4,6))
	return  checkint(cfg.color[eColor+1]*(cfg.coefficient[1]*equip_lv + cfg.coefficient[2]))
end
--培养时,需要消耗的元宝或者元宝
function DataConfigManager:onFosterNeedCoin(dex)
	local consume = self.data.cfg.system_simple.follower.train.consume[dex]
	return consume
end
--专精培养时，需要消耗的元宝
function DataConfigManager:getSpecialNeedCoin()
	local lockcoin = self.data.cfg.system_simple.follower.special_train.lock_coin
	return lockcoin
end
--专精培养时，需要消耗的元宝
function DataConfigManager:getSpecialNeedGold()
	local spgold = self.data.cfg.system_simple.follower.special_train.gold
	return spgold
end
--专精培养，根据等级获得系数
function DataConfigManager:getSpecialLvRange()
	local range = self.data.cfg.system_simple.follower.special_train.lv_range
	local playLv = PlayerData:getLv()
	local getRange = {}
	for k,v in pairs(range) do
		local nums = string.split(k,"-")
		if playLv >= tonumber(nums[1]) and playLv <= tonumber(nums[2]) then
			getRange = v[1]
			return getRange
		end
	end
end
--佣兵在培养时,vip等级限制
function DataConfigManager:onFosterVipLimite(index)
	local vipLv = self.data.cfg.system_simple.follower.train.vip_lv[index]
	return vipLv
end
--佣兵培养时信息
function DataConfigManager:onFosterVipInfo(index)
	local vipInfo = self.data.cfg.system_simple.follower.train.info[index]
	return vipInfo
end
--获取佣兵技能刷新的所需的人物最低等级
function DataConfigManager:getFollowerReSkillLv()
	local lv = self.data.cfg.system_simple.follower.unlock_fo_skill_lv
	return lv
end
--获取佣兵技能开启最低等级
function DataConfigManager:getFollowerSkillLimitLv()
	local lv = self.data.cfg.system_simple.follower.fo_skills_num[1]
	return lv
end
--获取佣兵技能开启最低等级
function DataConfigManager:getFollowerSpecialFosterLimitLv()
	local lv = self.data.cfg.system_simple.follower.unlock_fo_sp_tr
	return lv
end
--获取角色随机昵称(顺序：adj..name_0..name_1)
function DataConfigManager:getRoleRandomName()
	
	local uname = self.data.cfg.uname
	local name_0 = uname["name_0"]
	local name_1 = uname["name_1"]

	local rname_0 = name_0[math.random(1,#name_0)]
	local rname_1 = name_1[math.random(1,#name_1)]

	local txtname = rname_0..rname_1
	return txtname
end
--获取所有任务和活动
function DataConfigManager:getAllTask()
	return self.data.cfg.task
end
--获取所有提示信息
function DataConfigManager:getAllConfigMsg()
	return self.data.cfg.return_msg_config
end
--根据ID获取提示信息
function DataConfigManager:getConfigMsgByID(msgid)
	return self.data.cfg.return_msg_config[msgid]
end
-- 获取所有称号
function DataConfigManager:getAllTitles()
	return self.data.cfg.title;
end
-- 获取pvp奖励信息
function DataConfigManager:getPVPRewards()
	return self.data.cfg.pvp_reward
end
--VIP累计充值的数据
function DataConfigManager:getVipTotlePay(dex)
	return self.data.cfg.system_simple.vip_lv[dex]
end-- 获取pvp冷却时间
function DataConfigManager:getPVPCoolDownMinute()
	return self.data.cfg.system_simple.pvp_colldown
end
-- 获取宝石升级配置
function DataConfigManager:getGemUpLv()
	return self.data.cfg.system_simple.gem_up_lv
end
-- 获取宝箱数据
function DataConfigManager:getGiftBoxByID(boxid)
	return self.data.cfg.system_simple.open_box.box_type[boxid]
end
-- 获取宝箱开出数量的区间
function DataConfigManager:getGiftBoxGiftNumAreaByID(boxid)
	return self.data.cfg.system_simple.open_box.box_gift[boxid]
end
-- 获取pvp奖励信息
function DataConfigManager:getHelpInfoByID(helpid)
	return self.data.cfg.game_help[helpid]
end
--获取弟子技能刷新的价格
function DataConfigManager:getFoSkillPrice()
	return self.data.cfg.system_simple.follower.fo_refresh_coin
end
--获取弟子技能免费刷新次数
function DataConfigManager:getFoSkillFreeCount()
	return self.data.cfg.system_simple.follower.fo_refresh_skill_num
end
--获取所有buffer说明
function DataConfigManager:getAllBufferName()
	return self.data.cfg.system_simple.buff_state
end
--获取充值数据
function DataConfigManager:getChargeData()
	return self.data.cfg.pay
end

--获取神器吞噬消耗银两数
function DataConfigManager:getGodTunshiCost(lv1,star1,pos1,lv2,star2,pos2)
	local god_devour_gold = self.data.cfg.system_simple.god_devour.god_devour_gold
	local location = self.data.cfg.system_simple.god_devour.location
	local c = god_devour_gold[1]
	local d = god_devour_gold[2]
	local e = god_devour_gold[3]
	local f = god_devour_gold[4]

	local cost = c*(d*lv1+e*lv2+f)*star1*(math.floor(math.pow(star2,1.5)))*location[pos1+1]*location[pos2+1]
	return cost
end
--威望商店刷新价格
function DataConfigManager:getManaRefreshPrice()
	return self.data.cfg.system_simple.mana_shop.refresh_price
end
--商店中，获取每天初始幸运值
function DataConfigManager:getLuckValue()
	return self.data.cfg.shop.luck
end
--商店中，获取当前VIP等级对应的商品数量
function DataConfigManager:getGoodsNumInShopByVIPLv()
	local viplv = PlayerData:getVipLv() or 0
	return (self.data.cfg.shop.shop_count + self:getVIPCfg()[tostring(viplv)].add_box)
end
--获取神器合成所需碎片数量
function DataConfigManager:getGodsHeChengNeedNum()
	return self.data.cfg.system_simple.artifact_pieces
end
--获取单神属性神器打造所需
function DataConfigManager:getOneGodsDaZaoNeed()
	return self.data.cfg.system_simple.forge.one_fore_price
end
--获取双神属性神器打造所需
function DataConfigManager:getTwoGodsDaZaoNeed()
	return self.data.cfg.system_simple.forge.two_fore_price
end
--根据地图id获取一回合战斗时间
function DataConfigManager:getRoundTimeByMapID(mapid)
	local time_round = DataConfig.data.cfg.system_simple.time_round
	local mapIndex = self:getMapById(mapid).map_lv
	for i,v in ipairs(time_round) do
		if(v[1][1]<=mapIndex and v[1][2]>=mapIndex) then
			return v[2]
		end
	end
end
--[[
 'lv_limit' : 40,    #等级限制
        'colldown_time' : 60*5, #挑战失败冷却时间(秒)
        'sweep_vip_lv' : 1, #一键扫荡VIP开启等级
        'colldown_coin' : 10, #消除冷却时间消耗的元宝
        'first_pass' : ['1', '2', '3'], #首次通关给予的称号[3种难度]]
--获取光明顶开启等级限制
function DataConfigManager:getGMDLvLimit()
	return self.data.cfg.system_simple.top_fight.lv_limit
end
--获取光明顶挑战冷却时间
function DataConfigManager:getGMDColldownTime()
	return self.data.cfg.system_simple.top_fight.colldown_time 
end
--获取光明顶扫荡VIP等级限制
function DataConfigManager:getGMDSaoDangVIPLvLimit()
	return self.data.cfg.system_simple.top_fight.sweep_vip_lv
end
--获取光明顶清除冷却消耗金钱
function DataConfigManager:getGMDClearCooldownCost()
	return self.data.cfg.system_simple.top_fight.colldown_coin
end
--获取光明顶通关后称号
function DataConfigManager:getGMDFirstPassTitle()
	return self.data.cfg.system_simple.top_fight.first_pass
end
--获取光明顶战胜后reward
function DataConfigManager:getGMDVictoryReward(hard,index)
	return self.data.cfg.system_simple.top_fight.reward[hard][index]
end
--根据难度和索引获取光明顶某一BOSS配置数据
function DataConfigManager:getGMDBossByHardAndIndex(hard,index)
	return self.data.cfg.top_fight_BOSS[string.format("T%d%02d",hard,index)]
end
return DataConfigManager