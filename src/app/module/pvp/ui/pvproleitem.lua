local XRichText = import("app.components.XRichText")
local pvproleitem = class("pvproleitem", function()
		local layout = ccui.Layout:create()
		layout:setContentSize(cc.size(545,108))
		return layout
	end)
function pvproleitem:ctor()
	if(not pvproleitem.view) then
		pvproleitem.view = ResourceManager:widgetFromJsonFile("ui/pvproleitem.json")
		pvproleitem.view:retain()
	end	
	self.view = pvproleitem.view:clone()
	self.bg1 = self.view:getChildByName("bg1")
	self.bg2 = self.view:getChildByName("bg2")
	self.challengebtn = self.view:getChildByName("challengebtn")
	self.headpng = self.view:getChildByName("headpng")
	self.lvtxt = self.view:getChildByName("lvtxt")
	self.challengebtn:addTouchEventListener(handler(self,self.onClick))
	self:addChild(self.view)
	self.headpng:setTouchEnabled(true)
	self.headpng:addTouchEventListener(handler(self,self.onClick))

	self.infoTxt = XRichText.new()
	self.infoTxt:setContentSize(cc.size(270,0))
	self.infoTxt:setAnchorPoint(0.5,1)
	self.infoTxt:setPosition(260,98)
	self.view:addChild(self.infoTxt)

	self.rewardTxt = XRichText.new()
	self.rewardTxt:setContentSize(cc.size(210,0))
	self.rewardTxt:setAnchorPoint(0.5,1)
	self.rewardTxt:setPosition(300,57)
	self.view:addChild(self.rewardTxt)
end
function pvproleitem:hideBg()
	self.challengebtn:removeFromParent(true)
	self.bg1:removeFromParent(true)
	self.bg2:removeFromParent(true)
	self.challengebtn = nil
	self.bg1 = nil
	self.bg2 = nil
end
function pvproleitem:setData(data)
	self.data = data
	local herotype
	local power
	local lv

	if(self.data.uid ~= PlayerData:getUid() ) then
		herotype = self.data.hero_type
		lv = self.data.lv
		power = self.data.power
	else
		herotype = PlayerData:getHeroType()
		lv = PlayerData:getLv()
		power = PlayerData.data.power
	end
	local info ={
			{text = ""..self.data.name.."\n",color = cc.c3b(255,255,255),size = 16},
			{text = "排名:",color = cc.c3b(0,191,255),size = 16},
			{text = self.data.rank.." ",color = cc.c3b(255,215,0),size = 16},
			{text = "战力:",color = cc.c3b(0,191,255),size = 16},
			{text = power.."\n",color = cc.c3b(255,215,0),size = 16},
			{text = "排名奖励:",color = cc.c3b(250,5,215),size = 16},
		}
	local cfg = DataConfig:getPVPRewards().lv

	local curRewardKey
	for i=1,(#cfg-1) do
		if(cfg[i]<=self.data.rank and (cfg[i+1] == nil or cfg[i+1]>self.data.rank)) then
			curRewardKey = cfg[i]
			break
		end
	end
	local reward = {}
	local curReward = DataConfig:getPVPRewards().gift[tostring(curRewardKey)]
	table.insert(reward, {text = "元宝",color = cc.c3b(0,255,255),size = 16})
	table.insert(reward, {text = "*"..curReward["coin"].." ",color = cc.c3b(0,255,0),size = 16})
	table.insert(reward, {text = "威望",color = cc.c3b(0,255,255),size = 16})
	table.insert(reward, {text = "*"..curReward["mana"].." \n",color = cc.c3b(0,255,0),size = 16})
	table.insert(reward, {text = "银两",color = cc.c3b(0,255,255),size = 16})
	table.insert(reward, {text = "*"..curReward["gold"],color = cc.c3b(0,255,0),size = 16})
	self.infoTxt:appendStrs(info)
	self.rewardTxt:appendStrs(reward)
	self.lvtxt:setString("Lv."..lv)
	self.headpng:loadTexture("ui/head/"..herotype..".png")
end
function pvproleitem:onClick(sender,eventType)
	if  eventType ~= TouchEventType.ended then 
		return
	end
	local btnName = sender:getName()
	if btnName == "challengebtn" then
		if(BossPvpBattleManager.pvpChargeTimes > 0) then
			local lastpvpsec = changeTimeStrToSec(PlayerData:getLastPvpTime())
			local endCoolSec = DataConfig:getPVPCoolDownMinute()*60 + lastpvpsec
			local needsec = endCoolSec - TimeManager:getSvererTime()
			if(needsec <= 0) then
				if(BossPvpBattleManager.curMapID) then
					BossPvpBattleManager:setCurMap(self.data)
					BossPvpBattleManager:battleBtnClick()
				else
					BossPvpBattleManager:setCurMap(self.data)
					BossPvpBattleManager:requestBossChange()
				end
			else
				local btns = {{text = "确定",skin = 3,}}
		        local alert = GameAlert.new()
		        local richStr = {{text = "竞技场挑战冷却中,请稍后再试",color = display.COLOR_WHITE},
		        }
		        alert:pop(richStr,"ui/titlenotice.png",btns)
			end
		else
			-- local btns = {{text = "确定",skin = 3,}}
	  --       local alert = GameAlert.new()
	  --       local richStr = {{text = "今日竞技场挑战次数已用尽",color = display.COLOR_WHITE},
	  --       }
	  --       alert:pop(richStr,"ui/titlenotice.png",btns)
			self.data.jjcProcessor:onBtnClick(self.data.jjcProcessor.btnBuyAll, ccui.TouchEventType.ended)
		end
	elseif btnName == "headpng" then
		if (self.data.uid == PlayerData:getUid()) then
			--[[Observer.sendNotification(BagModule.OPEN_EQUIP,nil)
			Bag.mainEquipNotice = false				
			local tempNode = display.newNode()
			local data = {}
			tempNode.data = data
			Observer.sendNotification(BagModule.NOTICE_BETTER_EQUIP,tempNode)]]
		else
			local net = {}
			net.method = BagModule.USER_GET_USER_INFO
			net.params = {}
			net.params.uid = self.data.uid
			Net.sendhttp(net)
		end
	end
end
return pvproleitem