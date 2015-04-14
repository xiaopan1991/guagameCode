local MapItem = class("MapItem", function()
	local node = ccui.Layout:create()
	cc(node):addComponent("components.behavior.EventProtocol"):exportMethods()
	node:setContentSize(cc.size(543,125))
    return node
end)
function MapItem:ctor()
	if(not MapItem.view) then
		MapItem.view = ResourceManager:widgetFromJsonFile("ui/itemmap.json")
		MapItem.view:retain()
	end
	local itemMap = MapItem.view:clone()
	local bg = itemMap:getChildByName("bg")
	self.txtLv = itemMap:getChildByName("txtLv")
	self.txtName = itemMap:getChildByName("txtName")
	self.info = itemMap:getChildByName("info")
	self.btnChallenge = itemMap:getChildByName("btnChallenge")
	self.map = itemMap:getChildByName("map")
	self:addChild(itemMap)
	self.curTip = nil
	self.txtLv:enableOutline(cc.c4b(0, 0, 0, 255), 2)
end
function MapItem:addTip()
	if(self.curTip) then
		return
	end
	self.curTip = ccui.ImageView:create("ui/icon_20.png")
	self.curTip:setPosition(self.map:getPositionX(), self.map:getPositionY() - 30)
	self:addChild(self.curTip)
end
function MapItem:clearTip()
	if(self.curTip ) then
		self.curTip:removeFromParent(true)
		self.curTip = nil
	end
end
function MapItem:setData(data)
	self.data = data
	local mapData = DataConfig:getMapById(self.data.mid)
	self.txtName:setString(mapData.name)
	-- local mid = data.mid
	local mimg = "map/"..self.data.mid..".png"
	self.map:loadTexture(mimg)
	self.map:setTouchEnabled(true)
	self.map:addTouchEventListener(handler(self,self.onClickMap)) 
	self.btnChallenge:addTouchEventListener(handler(self,self.onClickChange))
	if(data.mid == Raid:getCurMap()) then
		self:addTip()
	else
		self:clearTip()
	end
	if(#mapData.lv == 1 or(#mapData.lv == 2 and (mapData.lv[1] == mapData.lv[2]))) then
		self.txtLv:setString("怪物等级"..mapData.lv[1])
	elseif(#mapData.lv == 2) then
		self.txtLv:setString("怪物等级"..mapData.lv[1].."-"..mapData.lv[2])
	end
	
end
function MapItem:sendUseBossChallenge()
	local net = {}
	net.method = BagModule.USE_CHALLENGE_COUPON
	net.params = {}
	Net.sendhttp(net)
end
--发送扫荡
function MapItem:processSaoDang()
	if (BossPvpBattleManager.bossChargeTimes<= 0) then
		--判断背包里是否有boss挑战券
		local goods = Bag:getGoodsById("I6002")
		if (goods) then
			local bosstimes = goods.num 
			if bosstimes > 0 then
				local btns = {{text = "取消",skin = 2},{text = "确定",skin = 1,callback = handler(self,self.sendUseBossChallenge)},}
				local alert = GameAlert.new()
				local cfg = DataConfig:getAllConfigMsg()
				local textStr = addArgsToMsg(cfg["30056"],bosstimes)
				alert:pop(textStr,"ui/titlenotice.png",btns)
				return
			end
		end

	end
	local net = {}
	net.method = MapModule.USER_BOSS_SWEEEP
	net.params = {}
	net.params.mid = self.data.mid
	Net.sendhttp(net)
	
end
function MapItem:processChallenge()
	if(BossPvpBattleManager.bossChargeTimes>0) then
		if(BossPvpBattleManager.curMapID) then
			BossPvpBattleManager:setCurMap(self.data.mid)
			BossPvpBattleManager:battleBtnClick()
		else
			BossPvpBattleManager:setCurMap(self.data.mid)
			BossPvpBattleManager:requestBossChange()
		end	
	else
		local vipCf = DataConfig:getVIPCfg()
		local vipLv = PlayerData:getVipLv()
		local btns
		local alert
		local richStr
		if(Bag:getGoodsById("I6002") and Bag:getGoodsById("I6002").num > 0) then
			btns = {{text = "取消",skin = 2},{text = "确定",skin = 1,callback = handler(self,self.sendUseBossChallenge)},}
			alert = GameAlert.new()
			local msg = DataConfig:getConfigMsgByID("30056")
			richStr = {{text = addArgsToMsg(msg,Bag:getGoodsById("I6002").num),color = display.COLOR_WHITE}}
			alert:pop(richStr,"ui/titlenotice.png",btns)
		elseif(vipCf[""..vipLv].challenge_BOSS_count > BossPvpBattleManager.bossChargeBuyTimes) then
			local prices = DataConfig.data.cfg.system_simple.BOSS_count_price
			local price = prices[1]*(BossPvpBattleManager.bossChargeBuyTimes)+prices[2]
			
			btns = {{text = "取消",skin = 2},{text = "确定",skin = 1,callback = handler(self,self.sendBuyChargeTime)},}
			alert = GameAlert.new()
			richStr = {{text = "今天的BOSS挑战次数已用完，是否花费",color = display.COLOR_WHITE},
				{text = ""..price,color = COLOR_RED},
				{text = "元宝购买？",color = display.COLOR_WHITE}}
			alert:pop(richStr,"ui/titlenotice.png",btns)
		elseif(vipCf[""..(vipLv+1)]) then--vip等级不满级
			btns = {{text = "取消",skin = 2},{text = "充值",skin = 3,callback = handler(self,self.handleChongzhi)},}
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
function MapItem:onClickChange(sender,eventType)
	if  eventType ~= TouchEventType.ended then 
		return
	end
	--dump(self.data.mid)
	--local curmid = tonumber(string.sub(self.data.mid,2,4))
	--local MaxRaidId = Raid:getMaxRaidId()
	--local MaxId = tonumber(string.sub(MaxRaidId,2,4))
	if  PlayerData:getVipLv() > 0 then
		local saoDangRaid = Raid:getSaoDangRaid()
		if saoDangRaid and self.data.mid <= Raid:getSaoDangRaid() then
			self:processSaoDang()
		else
			self:processChallenge()
		end
	else
		self:processChallenge()
	end
	
end
function MapItem:handleChongzhi()
	Observer.sendNotification(ChargeModule.SHOW_CHARGE_VIEW)
end
function MapItem:sendBuyChargeTime()
	local prices = DataConfig.data.cfg.system_simple.BOSS_count_price
	local price = prices[1]*(BossPvpBattleManager.bossChargeBuyTimes)+prices[2]
	if(price > PlayerData:getCoin()) then
		toastNotice("元宝不足",COLOR_RED)
		return
	end
	local net = {}
	net.method = MapModule.USER_BUY_BOSS_COUNT
	net.params = {}
	Net.sendhttp(net)
end
function MapItem:onClickMap(sender,eventType)
	if  eventType ~= TouchEventType.ended then 
		return
	end
	if(self.data.mid == Raid:getCurMap()) then
		return
	end
	local net = {}
	net.method = MapModule.USER_CHANGE_MAP
	net.params = {}
	net.params.mid = self.data.mid
	Net.sendhttp(net)
	BattleManager:battleBtnClick()
end
return MapItem
