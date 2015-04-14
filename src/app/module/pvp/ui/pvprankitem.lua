local XRichText = import("app.components.XRichText")
local pvprankitem = class("pvprankitem", function()
	local layout = ccui.Layout:create()
	layout:setContentSize(cc.size(545,108))
	return layout
end)
function pvprankitem:ctor()
	if(not pvprankitem.view) then
		pvprankitem.view = ResourceManager:widgetFromJsonFile("ui/pvproleitem.json")
		pvprankitem.view:retain()
	end	
	self.view = pvprankitem.view:clone()
	self.bg1 = self.view:getChildByName("bg1")
	self.bg2 = self.view:getChildByName("bg2")
	self.challengebtn = self.view:getChildByName("challengebtn")
	self.headpng = self.view:getChildByName("headpng")
	self.lvtxt = self.view:getChildByName("lvtxt")
	--self.iconbg = self.view:getChildByName("iconbg")
	--self.icon = self.view:getChildByName("icon")
	self:addChild(self.view)
	self.headpng:setTouchEnabled(true)
	self.headpng:addTouchEventListener(handler(self,self.onClick))

	self.infoTxt = XRichText.new()
	self.infoTxt:setContentSize(cc.size(270,0))
	self.infoTxt:setAnchorPoint(0.5,1)
	self.infoTxt:setPosition(260,98)
	self.view:addChild(self.infoTxt)

	self.challengebtn:setVisible(false)
	self.challengebtn:setEnabled(false)

	self.iconbg = ccui.ImageView:create("ui/rankiconbg.png")
	self.iconbg:setContentSize(cc.size(95, 95))
	-- self.iconbg:setContentSize(cc.size(95, 95))
	-- self.iconbg:ignoreAnchorPointForPosition(true)
	--self.iconbg:setScale9Enabled(true)
	--self.iconbg:setCapInsets(cc.rect(15,20,425,57))
	self.iconbg:setPosition(self.challengebtn:getPositionX()+5,self.challengebtn:getPositionY()+5)
	self.view:addChild(self.iconbg)

	self.icon = ccui.ImageView:create("ui/blank.png")
	self.icon:setPosition(self.challengebtn:getPositionX(),self.challengebtn:getPositionY())
	self.view:addChild(self.icon)
end
function pvprankitem:setData(data)
	self.data = data
	-- dump(data)
	local herotype = self.data.hero_type
	local lv = self.data.lv
	local power = self.data.power
	local info ={
		{text = self.data.name.."\n",color = cc.c3b(255,255,255),size = 16},
		-- {text = "["..self.data.name.."]\n",color = cc.c3b(184,134,192),size = 16},
		{text = "排名:",color = cc.c3b(0,191,255),size = 16},
		{text = self.data.rank.." ",color = cc.c3b(255,215,0),size = 16},
		{text = "战力:",color = cc.c3b(0,191,255),size = 16},
		{text = power.."\n",color = cc.c3b(255,215,0),size = 16},
		{text = self.data.signature or "",color = cc.c3b(250,5,215),size = 16},
	}
	self.infoTxt:appendStrs(info)
	self.lvtxt:setString("Lv."..lv)
	self.headpng:loadTexture("ui/head/"..herotype..".png")

	if self.data.rank <= 3 then
		self.icon:loadTexture("ui/pvp_rank_"..self.data.rank..".png")		
	end
end
function pvprankitem:onClick(sender,eventType)
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
			local btns = {{text = "确定",skin = 3,}}
	        local alert = GameAlert.new()
	        local richStr = {{text = "今日竞技场挑战次数已用尽",color = display.COLOR_WHITE},
	        }
	        alert:pop(richStr,"ui/titlenotice.png",btns)
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
return pvprankitem