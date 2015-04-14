local PlayerHeadUI = require("app.components.PlayerHeadUI")
local XRichText = import("app.components.XRichText")
local BattleProcessor = class("BattleProcessor", BaseProcessor)
function BattleProcessor:ctor()
	self.mapLayer = nil
	self.keepLogNum = 15--只保留这些数目的记录，其他删除
	self.lastRecord = nil
	self.rewardAlert = nil
	self.uivisible = false
	self.firstshow = true
	self.logs = {}
end
function BattleProcessor:ListNotification()
	return {
		BattleModule.GUAJI_WAIT_FOR_FIGHT,
		BattleModule.GUAJI_BEGIN_FIGHT,
		BattleModule.GUAJI_ATTACK_ONE,
		BattleModule.GUAJI_FIGHT_END,
		BattleModule.GUAJI_ADD_BATTLE_LOG,
		BattleModule.BOSS_PVP_WAIT_FOR_FIGHT,
		BattleModule.BOSS_PVP_BEGIN_FIGHT,
		BattleModule.BOSS_PVP_ATTACK_ONE,
		BattleModule.BOSS_PVP_FIGHT_END,
		BattleModule.BOSS_PVP_ADD_BATTLE_LOG,
		BattleModule.SHOW_BATTLE_UI,
		BattleModule.UPDATE_SWITCH, 
		BattleModule.USER_PK_COMBAT_MAIN,
		BattleModule.USER_GET_PK_BOSS_REWARD,
		BattleModule.USER_HANG_CLEAR,
		BattleModule.GUAJI_SKILL_COST_MP,
		BattleModule.BOSS_PVP_SKILL_COST_MP,
		BattleModule.GUAJI_BUFFER_HP_MP,
		BattleModule.BOSS_PVP_BUFFER_HP_MP,
		BattleModule.GUAJI_BUFFER_UPDATE,
		BattleModule.BOSS_PVP_BUFFER_UPDATE,
		BattleModule.BOSS_PVP_SHOW_NEXT,
		BattleModule.USER_UPGRADE,
	}
end
--处理消息
function BattleProcessor:handleNotification(notify,node)
	BattleModule.processor = self
	local signStr = string.sub(notify,1,5)
	if(BattleModule.CUR_SHOW_TYPE == BattleModule.BOSS_PVP and signStr =="GUAJI") then
		return
	end
	if (notify == BattleModule.SHOW_BATTLE_UI) then
		self:setUIVisible()
	elseif (notify == BattleModule.UPDATE_SWITCH) then
		self:updateMapLayer()
	elseif (notify == BattleModule.GUAJI_BUFFER_UPDATE) then
		local head = self:getHead(node.data.player)
		if(head) then
			head:updateBufferIcon()
		end
	elseif (notify == BattleModule.BOSS_PVP_BUFFER_UPDATE) then
		local head = self:getHead(node.data.player)
		if(head) then
			head:updateBufferIcon()
		end
	elseif (notify == BattleModule.GUAJI_BUFFER_HP_MP) then
		self:updateBufferHpMpInfo(node.data)
	elseif (notify == BattleModule.BOSS_PVP_BUFFER_HP_MP) then
		self:updateBufferHpMpInfo(node.data)
	elseif (notify == BattleModule.GUAJI_SKILL_COST_MP) then
		self:updateHeadsMp(node.data.player)	
	elseif (notify == BattleModule.BOSS_PVP_SKILL_COST_MP) then
		self:updateHeadsMp(node.data.player)	
	elseif (notify == BattleModule.BOSS_PVP_BEGIN_FIGHT) then
		self:initMapLayer()
		self:hideNextTip()
	elseif(notify == BattleModule.GUAJI_BEGIN_FIGHT) then
		self:initMapLayer()
	elseif(notify == BattleModule.BOSS_PVP_ADD_BATTLE_LOG) then
		self:updateBattleLogLayer(node.data)
	elseif(notify == BattleModule.GUAJI_ADD_BATTLE_LOG) then
		self:updateBattleLogLayer(node.data)
	elseif(notify == BattleModule.BOSS_PVP_ATTACK_ONE) then
		self:updateOneAttack(node.data)
	elseif(notify == BattleModule.GUAJI_ATTACK_ONE) then
		self:updateOneAttack(node.data)
	elseif(notify == BattleModule.BOSS_PVP_WAIT_FOR_FIGHT) then
		--更新等待时间
		self:updateWaitTime(node.data.time,node.data.type)
	elseif(notify == BattleModule.GUAJI_WAIT_FOR_FIGHT) then
		--更新等待时间
		self:updateWaitTime(node.data.time,node.data.type)
	elseif(notify == BattleModule.BOSS_PVP_FIGHT_END) then
		if(node.data.result) then
			self:popImg("ui/images/victory.png",{self.mapLayer:getContentSize().width/2,70},
				0.5,2,0.8,0.5)
		else
			self:popImg("ui/images/failuretxt.png",{self.mapLayer:getContentSize().width/2,70},
				0.5,2,0.8,0.5)
			if(self.uivisible and BossPvpBattleManager.modle == "boss") then
				local alert = GameAlert.new()
				alert:popHelp("newbie_guide_4","ui/titlenotice.png")
			end
		end
		--显示正在搜索敌人
		self:showSearchTip()
	elseif(notify == BattleModule.GUAJI_FIGHT_END) then
		self:popImg("ui/images/victory.png",{self.mapLayer:getContentSize().width/2,70},
		0.5,2,0.8,0.5)
		--显示正在搜索敌人
		self:showSearchTip()
	elseif(notify == BattleModule.USER_HANG_CLEAR) then
		self:handleHangClear(node.data)
	elseif(notify == BattleModule.USER_GET_PK_BOSS_REWARD) then
		print("收到boss战结束后奖励")
		local tempData = node.data.data
		if(tempData == nil) then
			return
		end
		local bUpdateBag = false
		for i,v in pairs(tempData.equip) do
			local itemNum =table.nums(Bag:getAllEquip(nil,"bag"))
			 	Bag:addEquip(i,v)
			 	bUpdateBag= true
		end
		if(tempData.pith) then
			bUpdateBag= true
			local pithData = Bag:getGoodsById("I0001")
			if(pithData) then
				Bag:addGoods("I0001",pithData.num + tempData.pith)
			else
				Bag:addGoods("I0001",tempData.pith)
			end
		end
		if(bUpdateBag) then
			Observer.sendNotification(BagModule.EQUIP_NUM_UPDATE) --数量更新
		end	
		--max_mid
		Raid:changeMaxRaid(tempData.hang.max_mid)
		Raid:changePlayRaid(tempData.hang.mid)
		Raid:changeSaoDangRaid(tempData.hang.beat_mid)
		Raid:changeNextRaid(tempData.hang.next_mid)
		Observer.sendNotification(MapModule.UPDATE_MAP, nil)
		BossPvpBattleManager:setBossChargeTimes(tempData.BOSS_count)
		BossPvpBattleManager:getReward(tempData)	
	elseif(notify == BattleModule.USER_PK_COMBAT_MAIN) then
		--收到boss战请求结果
		local tempData = node.data.data
		BossPvpBattleManager:setTestResult(tempData.data_info)
		GameInstance.getBossBattleSeedFromServer(tempData.seed)
		BattleModule.CUR_SHOW_TYPE = BattleModule.BOSS_PVP
		BattlePrint("0000000000000000tempData.seed=",tempData.seed)
		self:updateMapLayer()	
		BossPvpBattleManager:battleBtnClick()
	elseif notify == BattleModule.BOSS_PVP_SHOW_NEXT then
		self:showNextTip(node.data.nextType)
	elseif notify == BattleModule.USER_UPGRADE then
		PlayerData:setLv(node.data.data.lv)
		PlayerData:setTaskData(node.data.data.task)
		PlayerData:setAllSoliders(node.data.data.follower)
		PlayerData:updateAllSolidersAttrs()
	end
end
function BattleProcessor:showSearchTip()
	if(not self.battlePanel.waitTxt) then
		self.battlePanel.waitTxt = ccui.ImageView:create("ui/images/searchtxt.png")
		self.battlePanel.waitTxt:setAnchorPoint(0.5,0)
		self.battlePanel.waitTxt:setPosition(display.width/2,580-570)
		self.battlePanel:addChild(self.battlePanel.waitTxt)
		local big = cc.ScaleTo:create(1, 0.85)
		local small = cc.ScaleTo:create(1, 1)
		local temp = transition.sequence({
			big,
		    small,
		})
		local re = cc.RepeatForever:create(temp)
		self.battlePanel.waitTxt:runAction(re)
	end
end
function BattleProcessor:showNextTip(nextType)--0,boss;1,pvp
	self:hideNextTip()
	if(not self.battlePanel.nextTxt) then
		if(nextType == 0) then
			self.battlePanel.nextTxt = ccui.ImageView:create("ui/img_194.png")
		else
			self.battlePanel.nextTxt = ccui.ImageView:create("ui/img_202.png")
		end
		self.battlePanel.nextTxt:setAnchorPoint(0.5,0)
		self.battlePanel.nextTxt:setPosition(display.width/2,580-500)
		self.battlePanel:addChild(self.battlePanel.nextTxt)
	end
end
function BattleProcessor:hideNextTip()
	if(self.battlePanel.nextTxt) then
		self.battlePanel.nextTxt:removeFromParent(true)
		self.battlePanel.nextTxt = nil
	end
end
function BattleProcessor:processHangClearData(data)
	local addGold = data.data.get_gold
	local findBox = data.data.get_box or {}
	local usekey = data.data.use_key or {}
	local boxGift = data.data.box_gift or {}


	PlayerData:setGold(data.data.gold)
	local addExp = data.data.get_exp
	local curLv = data.data.lv
	PlayerData:setLv(curLv)
	PlayerData:setExp(data.data.exp)
	PlayerData:setQuickBattles(data.data.fighting_count)
	PlayerData:setCoin(data.data.coin)
	
	for k,v in pairs(data.data.new_equip_dict) do
		Bag:addEquip(k,v)
		bagUpdate = true
	end
	if(bagUpdate) then
		Observer.sendNotification(BagModule.EQUIP_NUM_UPDATE) --数量更新
	end

	if(data.data.count == 0) then
		return
	end


	local richStr = {
		{text = "正在计算战斗结果...\n",color = display.COLOR_WHITE},

		{text = "在 ",color = display.COLOR_WHITE},
		{text = ""..changeSecToDHMSStr(tonumber(data.data.conn_time)),color = cc.c3b(64,227,0)},
		{text = " 内\n",color = display.COLOR_WHITE},
		
		{text = "您在地图",color = display.COLOR_WHITE},
		{text = DataConfig:getMapById(data.data.hang.mid).name,color = cc.c3b(64,227,0)},
		{text = "战斗了",color = display.COLOR_WHITE},
		{text = ""..data.data.count,color = cc.c3b(64,227,0)},
		{text = "次\n",color = display.COLOR_WHITE},

		{text = "战胜：",color = display.COLOR_WHITE},
		{text = data.data.count.."\n",color = cc.c3b(64,227,0)},

		{text = "获得经验：",color = display.COLOR_WHITE},
		{text = addExp.."\n",color = cc.c3b(64,227,0)},
		{text = "获得银两：",color = display.COLOR_WHITE},
		{text = addGold.."\n",color = cc.c3b(64,227,0)},

		
	}
	local colorStrs = {"白色","绿色","蓝色","紫色","橙色"}
	for i,v in ipairs(data.data.get_equips_nums) do
		if(v>0) then
			table.insert(richStr,
				{text = "获得：",color = display.COLOR_WHITE}
			)
			table.insert(richStr,
				{text = colorStrs[i].."装备*"..v.."\n",color = getEquipCCC3Color(i-1)}
			)
		end
	end
	table.insert(richStr,
		{text = "自动卖出：",color = display.COLOR_WHITE}
	)
	table.insert(richStr,
		{text = data.data.sell_equips_nums.."\n",color = cc.c3b(64,227,0)}
	)

	local unopen = {}
	if(table.nums(findBox) > 0) then
		table.insert(richStr,
			{text = "发现：",color = display.COLOR_WHITE}
		)
		local tempStr = ""
		local boxkeys = {"I5001","I5002","I5003"}
		for i,b in ipairs(boxkeys) do
			local k = b
			local v = findBox[k]
			if(v) then
				unopen[k] = v - (usekey["I3"..string.sub(k,3)] or 0)
				tempStr = tempStr.." "..DataConfig:getGoodByID(k).name.."*"..v
			end
		end
		tempStr =tempStr.."\n"
		table.insert(richStr,
			{text = tempStr,color = COLOR_GREEN}
		)
	end
	if(table.nums(usekey) > 0) then
		table.insert(richStr,
			{text = "使用：",color = display.COLOR_WHITE}
		)
		local tempStr = ""
		local keykeys = {"I3001","I3002","I3003"}
		for i,b in ipairs(keykeys) do
			local k = b
			local v = usekey[k]
			if(v) then
				tempStr = tempStr.." "..DataConfig:getGoodByID(k).name.."*"..v
				Bag:plusGoods(k,-1*v)
			end
		end
		
		tempStr =tempStr.."\n"
		table.insert(richStr,
			{text = tempStr,color = display.COLOR_YELLOW}
		)
	end
	local bagUpdate = false
	if(table.nums(boxGift) > 0) then
		table.insert(richStr,
			{text = "打开宝箱获得：",color = display.COLOR_WHITE}
		)
		local tempStr = ""
		for k,v in pairs(boxGift) do
			local giftName
			if(k == "coin") then
				giftName = "元宝"
			elseif(k == "gold") then
				giftName = "银两"
			else
				giftName = DataConfig:getGoodByID(k).name
				bagUpdate = true
				local pithData = Bag:getGoodsById(k)
				if(pithData) then
					Bag:addGoods(k,pithData.num + v)
				else
					Bag:addGoods(k,v)
				end
			end
			tempStr = tempStr.." "..giftName.."*"..v
		end
		tempStr =tempStr.."\n"
		table.insert(richStr,
			{text = tempStr,color = display.COLOR_YELLOW}
		)
	end
	if(table.nums(unopen) > 0) then
		local tempStr = ""
		local bshow = false
		for k,v in pairs(unopen) do
			if(v > 0) then
				bshow = true
				break
			end
		end
		local boxkeys = {"I5001","I5002","I5003"}
		if(bshow) then
			table.insert(richStr,
				{text = "无法打开：",color = display.COLOR_WHITE}
			)
			for i,v in ipairs(boxkeys) do
				if(unopen[v] and unopen[v] >0) then
					tempStr = tempStr.." "..DataConfig:getGoodByID(v).name.."*"..unopen[v]
				end
			end
			tempStr = tempStr..",没有相应的钥匙,灰溜溜的走开\n"
			table.insert(richStr,
				{text = tempStr,color = COLOR_RED}
			)
		end
	end

	
	local title
	if(data.params.fighting) then
		title = "ui/titlenotice.png"
	else
		title = "ui/offlinelog.png"
	end
	self:popRewardAlert(richStr,title)
end
function BattleProcessor:popRewardAlert(richStr,title)
	self:hideRewardAlert()
	local btns = {{text = "确定",skin = 3,callback = handler(self,self.hideRewardAlert)}}
	self.rewardAlert = GameAlert.new()
	self.rewardAlert:pop(richStr,title,btns)
end
function BattleProcessor:hideRewardAlert()
	if(self.rewardAlert) then
		PopLayer:removePopView(self.rewardAlert)
		self.rewardAlert = nil
	end
end
function BattleProcessor:handleHangClear(data)
	if(data.params.fighting) then --快速戰斗
		self:processHangClearData(data)		
	else
		local hTime = changeTimeStrToSec(data.data.hang.hang_time["$datetime"])
		if(((not TimeManager.started)) or (TimeManager.started and TimeManager:getSvererTime() < hTime)) then
			self:processHangClearData(data)			
			BattleManager:initBattleHangTime(hTime)
			local nTime = changeTimeStrToSec(data.server_now["$datetime"])
			TimeManager:setSvererTime(nTime)
			TimeManager:start()
	    	BattleManager:start()
	    	if(data.data.hang_equip_num) then
	    		GameInstance.setHangEquipNum(data.data.hang_equip_num)
	    	end
		end
	end
end
function BattleProcessor:setUIVisible()
	if(self.mapLayer) then
		self.uivisible = true
		self:addMidView(self.mapLayer,true)
		self.mapLayer:setLocalZOrder(0)
		self:setBtnTouchAble(true)
		self:showAllLog()
		if(self.firstshow) then
			self.firstshow = false
		end
		self:updateNotice()
	end
end
function BattleProcessor:updateMapLayer()
	--清理等待数字和“正在搜索敌人”
	self:clearWaitAndTime()
	if(BattleModule.CUR_SHOW_TYPE == BattleModule.GUAJI) then
		self.mapNameTxt:setString(DataConfig:getMapById(Raid.curMapID).name)
		self:hideNextTip()
	else
		if(BossPvpBattleManager.modle == "boss") then
			self.mapNameTxt:setString(DataConfig:getMapById(BossPvpBattleManager.curMapID).name)
		else
			self.mapNameTxt:setString("竞技")
		end
	end	
	--self.nameBg:setContentSize(cc.size(self.mapNameTxt:getContentSize().width + 50,32))
	self:setView(self.mapLayer)
	self:initHeads()	
end
function BattleProcessor:initMapLayer()
	if(not self.mapLayer) or (tolua.isnull(self.mapLayer)) then
		local view = ResourceManager:widgetFromJsonFile("ui/guajiui.json")
		view:setName("BossPvpBattleView")
		self.panel =view:getChildByName("GuaJiUI")
		self.battlePanel = self.panel:getChildByName("battlePanel")
		self.logBtn = self.panel:getChildByName("logBtn")
		self.btncontainer = self.panel:getChildByName("btncontainer")
		self.mapBtn = self.btncontainer:getChildByName("mapBtn")
		self.nameBg = self.panel:getChildByName("nameBg")
		self.quickBtn = self.btncontainer:getChildByName("quickBtn")
		self.mapNameTxt = self.panel:getChildByName("mapNameTxt")
		self.logcontainer = self.panel:getChildByName("logcontainer")
		self.logView = self.logcontainer:getChildByName("logView")
		self.logBtn:addTouchEventListener(handler(self,self.onBtnClick))
		self.mapBtn:addTouchEventListener(handler(self,self.onBtnClick))
		self.quickBtn:addTouchEventListener(handler(self,self.onBtnClick))

		
		
		local title = self.quickBtn:getTitleText()
		self.quickBtn:setTitleText('')
		self.quickBtn:setTitleText(title)

		enableBtnOutLine(self.quickBtn,COMMON_BUTTONS.ORANGE_BUTTON)
		enableBtnOutLine(self.mapBtn,COMMON_BUTTONS.BLUE_BUTTON)

		self.mapNameTxt:setFontSize(20)
		self.mapNameTxt:setColor(cc.c3b(248,194,7))


		local theight = 756
		self.det = display.height - 960
		if display.height > 960 then
			theight = theight + self.det
		end
		local size = view:getLayoutSize()
		view:setContentSize(cc.size(size.width,theight))
		self.panel:setContentSize(cc.size(size.width,theight))


		size = self.logcontainer:getContentSize()
		self.logcontainer:setContentSize(cc.size(size.width,size.height + self.det))	
		self.logcontainer:setTouchEnabled(false)

		size = self.logView:getContentSize()
		self.logView:setContentSize(cc.size(size.width,size.height + self.det))	
		self.logView:setTouchEnabled(false)

		self.mapLayer = view
		self:addMidView(self.mapLayer,true)
	end
	self:updateMapLayer()
	--弹出开始战斗
	self:popImg("ui/images/starttxt.png",{self.mapLayer:getContentSize().width/2,70},
		0.5,2,1.0,0.5)
	
end
function BattleProcessor:updateNotice()
	local key = PlayerData:getUid()..PlayerData:getZone().."firstClickMap"
	if(cc.UserDefault:getInstance():getIntegerForKey(key,0) == 0) then
		if(not self.mapNotice) then
			display.addSpriteFrames("ui/new.plist","ui/new.png")
			local frames = display.newFrames("xin%04d.png", 1,7)
			local animation = display.newAnimation(frames, 0.5 / 7) -- 0.5 秒播放 10桢
			local spr = display.newSprite()
			spr:playAnimationForever(animation)
			local node = display.newNode()
			node:addChild(spr)
			node:setPosition(200,70)
			self.mapNotice = node
			self.btncontainer:addChild(node,2)
		end
	else
		if(self.mapNotice) then
			self.mapNotice:removeFromParent(true)
			self.mapNotice = nil
		end
	end
end
function BattleProcessor:clearWaitAndTime()
	if(self.battlePanel.waitTxt) then
		self.battlePanel.waitTxt:removeFromParent(true)
		self.battlePanel.waitTxt = nil
	end
	if(self.battlePanel.timeImg) then
		self.battlePanel.timeImg:removeFromParent(true)
		self.battlePanel.timeImg = nil
	end
	self.timeNum = nil
end
function BattleProcessor:onBtnClick(sender,eventType)
	if  eventType ~= TouchEventType.ended then 
		return
	end
	local btnName = sender:getName()
	if btnName == "mapBtn" then
		local key = PlayerData:getUid()..PlayerData:getZone().."firstClickMap"
		if(cc.UserDefault:getInstance():getIntegerForKey(key,0) == 0) then
			cc.UserDefault:getInstance():setIntegerForKey(key, 1)
			local alert = GameAlert.new()
	   		alert:popHelp("newbie_guide_3","ui/titlenotice.png")
	   		if(self.mapNotice) then
				self.mapNotice:removeFromParent(true)
				self.mapNotice = nil
			end
		end 
	   Observer.sendNotification(MapModule.SHOW_MAP, nil)
	elseif btnName == "logBtn" then
		local rewardGold =(DataConfig:getMapById(BattleManager.curMapID).hang.gold[1]+DataConfig:getMapById(BattleManager.curMapID).hang.gold[2])/2
		if(BattleManager.curPlayer.godInfo and BattleManager.curPlayer.godInfo["add_gold"]) then--击败敌人银两增加
			rewardGold = math.floor(rewardGold*(1 + BattleManager.curPlayer.godInfo["add_gold"]))
		end

		local rewardExp =(tonumber(DataConfig:getMapById(BattleManager.curMapID).hang.exp[1])+tonumber(DataConfig:getMapById(BattleManager.curMapID).hang.exp[2]))/2
		local expCriPro = DataConfig.data.cfg.system_simple.get_exp
		rewardExp = rewardExp*(expCriPro[1]*expCriPro[2]+1-expCriPro[1])
		if(BattleManager.curPlayer.godInfo and BattleManager.curPlayer.godInfo["add_exp"]) then
			rewardExp = rewardExp*(1 + BattleManager.curPlayer.godInfo["add_exp"])
		end
		local fightNum = math.floor(3600/BattleManager.fightOneTime)
		local needexp = DataConfig:getUpdateExpByLvl(PlayerData:getLv()) - PlayerData:getExp()
		local needsec = math.ceil(needexp/rewardExp*BattleManager.fightOneTime)
		local drop = DataConfig:getDropRateByMapIdAndPlayerLV(BattleManager.curMapID)
		local richStr = {
		{text = "当前挂机地图："..tostring(DataConfig:getMapById(BattleManager.curMapID).name).."\n",color = display.COLOR_WHITE},
		{text = "战斗次数："..tostring(fightNum).."/小时\n",color = display.COLOR_WHITE},
		{text = "平均战斗时长："..tostring(BattleManager.fightOneTime).."秒/场\n",color = display.COLOR_WHITE},
		{text = "胜率："..tostring(100).."%\n",color = display.COLOR_WHITE},
		{text = "装备掉率：每只怪"..tostring(math.round(drop*10000)/100).."%\n",color = display.COLOR_WHITE},
		{text = "经验获得：",color = display.COLOR_WHITE},
		{text = tostring(math.floor(fightNum*rewardExp)).."/小时\n",color = COLOR_GREEN},
		{text = "银两获得：",color = display.COLOR_WHITE},
		{text = tostring(math.floor(fightNum*rewardGold)).."/小时\n",color = COLOR_GREEN},			
		}
		if(PlayerData:getLv() < DataConfig:getMaxCfgLV()) then
			table.insert(richStr, {text = "人物升级至 Lv "..tostring(PlayerData:getLv()+1).." 还需经验 "..tostring(needexp)..", 约需要 "..changeSecToDHMSStr(needsec),color = cc.c3b(255,0,255)})
		end
		local btns = {{text = "确定",skin = 3}}
		local alert = GameAlert.new()
		alert:pop(richStr,"ui/titlenotice.png",btns)
	elseif(btnName == "quickBtn") then
		local vipCf = DataConfig:getVIPCfg()
		local vipLv = PlayerData:getVipLv()
		local btns
		local alert
		local richStr
		if(vipCf[""..vipLv].fighting_count > PlayerData:getQuickBattles()) then--快速战斗次数小于vip的限制快速战斗次数
			btns = {{text = "取消",skin = 2},{text = "确定",skin = 1,callback = handler(self,self.sendQuickBattle)},}
			alert = GameAlert.new()
			richStr = {{text = "即将快速战斗"..DataConfig:getQuickFightLastTime().."分钟，将消耗",color = display.COLOR_WHITE},
			{text = DataConfig:getCostZuanshi(PlayerData:getQuickBattles()),color = COLOR_RED},
			{text = "元宝，确定继续？",color = display.COLOR_WHITE}}
			alert:pop(richStr,"ui/titlenotice.png",btns)
		elseif(vipCf[""..(vipLv+1)]) then--vip等级不满级
			btns = {{text = "取消",skin = 2},{text = "充值",skin = 1,callback = handler(self,self.handleChongzhi)},}
			alert = GameAlert.new()
			richStr = {{text = "您当前",color = display.COLOR_WHITE},
			{text = "VIP"..vipLv,color = cc.c3b(255,205,30)},
			{text = ",可进行快速战斗",color = display.COLOR_WHITE},
			{text = ""..vipCf[""..vipLv].fighting_count,color = COLOR_GREEN},
			{text = "次",color = display.COLOR_WHITE},
			{text = "(已用完)\n",color = COLOR_RED},
			{text = "下一级",color = display.COLOR_WHITE},
			{text = "VIP"..(vipLv+1),color = cc.c3b(255,205,30)},
			{text = ",可进行快速战斗",color = display.COLOR_WHITE},
			{text = ""..vipCf[""..(vipLv+1)].fighting_count,color = COLOR_GREEN},
			{text = "次",color = display.COLOR_WHITE},
			}
			alert:pop(richStr,"ui/titlenotice.png",btns)
		else
			btns = {{text = "确定",skin = 3}}
			alert = GameAlert.new()
			richStr = {{text = "您当前",color = display.COLOR_WHITE},
			{text = "VIP"..vipLv.."(最高级)",color = cc.c3b(255,205,30)},
			{text = ",可进行快速战斗",color = display.COLOR_WHITE},
			{text = ""..vipCf[""..vipLv].fighting_count,color = COLOR_GREEN},
			{text = "次",color = display.COLOR_WHITE},
			{text = "(已用完)\n",color = COLOR_RED},
			}
			alert:pop(richStr,"ui/titlenotice.png",btns)
		end
	end
end
function BattleProcessor:handleChongzhi()
	Observer.sendNotification(ChargeModule.SHOW_CHARGE_VIEW)
end
function BattleProcessor:sendQuickBattle()
	BattleModule:sendHangclear(true)
end
function BattleProcessor:updateWaitTime(timeNum,showType)
	if(timeNum >= 1) then
		if(not self.battlePanel.timeImg) then
			self.battlePanel.timeImg = display.newBMFontLabel({text = "",font = "ui/fnt/yelnum.fnt",})
			self.battlePanel.timeImg:setPosition(display.width/2,700-579)
			self.battlePanel:addChild(self.battlePanel.timeImg)
		end
		if(self.timeNum ~= timeNum) then
			self.timeNum = timeNum
			self.battlePanel.timeImg:setString(timeNum)
		end
		
	else
		self:clearWaitAndTime()
	end
	local txtFormat
	if(showType and showType == 2) then
		if(BossPvpBattleManager.modle == "boss") then
			txtFormat= "s13"
		else
			txtFormat= "s22"
		end
	elseif(showType and showType == 3) then
		if(BossPvpBattleManager.modle == "boss") then
			txtFormat= "s12"
		else
			txtFormat= "s21"
		end
	else
		txtFormat= "s8"
	end
	--[[
	if(self.lastRecord == txtFormat) then
		self.logView:removeChild(self.logView:getChildByTag(self.txtTag))
		local eTxt = XRichText.new()
		eTxt:setContentSize(cc.size(526,0))
		eTxt:append(txtFormat,{{"("..timeNum..")"},})
		eTxt.text:visit()
		local txtHeight = eTxt.text:getTextSize().height
		eTxt:setAnchorPoint(0.5,1)
		eTxt:setPosition(263, txtHeight)
		self.logView:addChild(eTxt,0,self.txtTag)
	else
		local waitdata = {}
		waitdata.strFormat = txtFormat
		waitdata.args = {{"("..timeNum..")"},}
		self:updateBattleLogLayer(waitdata)
	end	]]
end
function BattleProcessor:popImg(img,pos,startScale,endScale,lastTime,yAnchor)
	local imgView = ccui.ImageView:create(img)
	imgView:setPosition(pos[1],pos[2])
	imgView:setScale(startScale)
	imgView:setAnchorPoint(0.5,yAnchor)
	self.battlePanel:addChild(imgView,2)
	imgView:runAction(transition.sequence({
		cc.EaseInOut:create(cc.ScaleTo:create(lastTime, endScale), 3),
        cc.CallFunc:create(handler(imgView, self.onPopHide))
        }))
end
function BattleProcessor:onPopHide()
	self:removeFromParent(true)
	self = nil
end
function BattleProcessor:initHeads()
	if(self.mapLayer) then
		if(self.battlePanel.playHeads) then
			for i,v in ipairs(self.battlePanel.playHeads) do
				v:onDeleteMe()
			end
		end
		if(self.battlePanel.enemyHeads) then
			for i,v in ipairs(self.battlePanel.enemyHeads) do
				v:onDeleteMe()
			end
		end
		self.battlePanel.playHeads = {}
		self.battlePanel.enemyHeads = {}
		local headUI
		local curManager
		if(BattleModule.CUR_SHOW_TYPE == BattleModule.GUAJI) then
			curManager = BattleManager
		else
			curManager = BossPvpBattleManager
		end
		for i,v in ipairs(curManager.playerList) do
			headUI = PlayerHeadUI.new()
			headUI:initHead(v)
			if(i>1) then
				local temp = self.battlePanel.playHeads[i-1]
				headUI:setPosition(25,temp:getPositionY() - temp.viewH)
			else
				headUI:setPosition(25,self.battlePanel:getContentSize().height - headUI:getContentSize().height -50)
			end
			self.battlePanel:addChild(headUI)
			self.battlePanel.playHeads[i] = headUI
		end
		for i,v in ipairs(curManager.enemyList) do
			headUI = PlayerHeadUI.new()
			headUI:initHead(v)
			if(i>1) then
				local temp = self.battlePanel.enemyHeads[i-1]
				headUI:setPosition(self.battlePanel:getContentSize().width - headUI:getContentSize().width-25,
					temp:getPositionY() - temp.viewH)
			else
				headUI:setPosition(self.battlePanel:getContentSize().width - headUI:getContentSize().width-25,
					self.battlePanel:getContentSize().height - headUI:getContentSize().height - 50)
			end
			self.battlePanel:addChild(headUI)
			self.battlePanel.enemyHeads[i] = headUI
		end
	end
end
function BattleProcessor:getHead(player)
	local pType = player.playerType
	local pIndex
	local temp
	if(pType == PlayerTypePlayer or pType ==PlayerTypeSolider) then
		temp = self.battlePanel.playHeads
		pIndex = table.indexof(player.battleManager.playerList, player)
	else
		temp = self.battlePanel.enemyHeads
		pIndex = table.indexof(player.battleManager.enemyList, player)
	end
	if(temp) then
		return temp[pIndex]
	end	
end
function BattleProcessor:updateBufferHpMpInfo(data)
	local head = self:getHead(data.player)
	if(head) then
		if(self.uivisible) then
			head:updateBufferHpMp(data.bType,data.num)
		end
		head:updateHp()
		head:updateMp()
	end
end
function BattleProcessor:updateHeadsMp(player)
	local head = self:getHead(player)
	if(head) then
		head:updateMp()
	end
end
function BattleProcessor:updateHeadsHp(data)
	local beAttackedHead = self:getHead(data.beAttacked)
	if(beAttackedHead and self.uivisible) then
		beAttackedHead:lostHp(data.dam,data.bHit,data.bCri)
	end
end
function BattleProcessor:updateOneAttack(data)
	local logData = {}
	if(data.attacker.playerType < 3) then
		logData.strFormat = "s25"
	else
		logData.strFormat = "s26"
	end
	--技能名称
	local sName = {"普通攻击",}
	if(data.skillInfo) then
		sName = {data.skillInfo,{68,220,33}}
	end
	logData.args = {
	 	{data.attacker.battleManager.circleNum,},
		{data.attacker.playerName,},
		sName,
		{data.beAttacked.playerName,},
		{data.dam,{255,53,53}},
	 }
	if(data.attacker.playerType < 3) then
		logData.args[2][2] = {209,47,255}
		logData.args[4][2] = {1,144,254}
	else
		logData.args[2][2] = {1,144,254}
		logData.args[4][2] = {209,47,255}
	end
	if(data.bCri and data.bHit) then
		table.insert(logData.args,{"",})
		logData.args[6][1] = "(会心)"
	elseif(not data.bHit) then
		table.insert(logData.args,{"",})
		logData.args[6][1] = "(闪避)"
	end
	self:updateBattleLogLayer(logData)
	self:updateHeadsHp(data)
end
function BattleProcessor:showAllLog()
	local begin = 1
	if(self.keepLogNum < #self.logs) then
		begin = #self.logs - self.keepLogNum + 1
	end
	for i=begin,#self.logs do
		self:updateBattleLogLayer(self.logs[i])
	end
	self.logs = {}
end
function BattleProcessor:updateBattleLogLayer(data)
	if(self.logView) then
		if(not self.uivisible) then
			table.insert(self.logs,data)
			return
		end
		if(not self.txtTag) then
			self.txtTag = 1
		else
			self.txtTag = self.txtTag + 1
		end
		local eTxt = XRichText.new()
		eTxt:setContentSize(cc.size(466,0))
		eTxt:append(data.strFormat, data.args)
		self.lastRecord = data.strFormat
		eTxt.text:visit()
		local txtHeight = eTxt.text:getTextSize().height
		local allTxtNum = self.logView:getChildrenCount()
		local tempTxt
		--将最近的keepLogNum个位置上移
		for i=self.txtTag-1,self.txtTag-self.keepLogNum,-1 do
			if(i>0) then
				tempTxt = self.logView:getChildByTag(i)
				tempTxt:setPositionY(tempTxt:getPositionY() + txtHeight)
			end
		end
		--将最近的keepLogNum之外的删除
		if(allTxtNum > self.keepLogNum) then
			for i=self.txtTag - allTxtNum ,self.txtTag - self.keepLogNum-1  do
				tempTxt = self.logView:getChildByTag(i)
				self.logView:removeChild(tempTxt)
			end
		end
		eTxt:setAnchorPoint(0.5,1)
		eTxt:setPosition(233, txtHeight)
		self.logView:addChild(eTxt,0,self.txtTag)
		self.logView:jumpToBottom()


		--[[if(BossPvpBattleManager.bStart) then
			local strtable = XRichText.getStrTable(data.strFormat, data.args)
			local str = ""
			for i,v in ipairs(strtable) do
				str = str..v[1]
			end
			print(str)
		end]]
	end
end
function BattleProcessor:setBtnTouchAble(able)
	self.logBtn:setTouchEnabled(able)
	self.mapBtn:setTouchEnabled(able)
	self.quickBtn:setTouchEnabled(able)
end
function BattleProcessor:onHideView(view)
	-- body
	--[[if self.mapLayer == view then
		--self.mapLayer:retain()
		--self.mapLayer:removeFromParent()
		
	end]]
	self.mapLayer:setVisible(false)
	self.mapLayer:setLocalZOrder(-100)
	self:setBtnTouchAble(false)
	self.uivisible = false
	self.logs = {}
end
return BattleProcessor