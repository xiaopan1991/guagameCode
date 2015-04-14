--
-- Author: Your Name
-- Date: 2015-01-22 19:03:17
--
local MultiBattlePlayerCell = class("MultiBattlePlayerCell", function()
		local layout = ccui.Layout:create()
		layout:setContentSize(cc.size(609,125))
		return layout
	end)
function MultiBattlePlayerCell:ctor()
	if MultiBattlePlayerCell.skin == nil then
		MultiBattlePlayerCell.skin = ResourceManager:widgetFromJsonFile("ui/MultiBattlePlayerCell.json")
		MultiBattlePlayerCell.skin:retain()
	end
	self.view = MultiBattlePlayerCell.skin:clone()
	self.bg = self.view:getChildByName("bg")
	self.kickbtn = self.view:getChildByName("kickbtn")
	self.captiansign = self.view:getChildByName("captiansign")
	self.headpng = self.view:getChildByName("headpng")
	self.nametxt = self.view:getChildByName("nametxt")
	self.powertxt = self.view:getChildByName("powertxt")
	self.skilllayer = self.view:getChildByName("skilllayer")
	self:addChild(self.view)

	self.headpng:setTouchEnabled(true)
	self.headpng:addTouchEventListener(handler(self,self.onClick))
	self.kickbtn:addTouchEventListener(handler(self,self.onClick))
end
function MultiBattlePlayerCell:setData(data)
	self.data = data
	self.nametxt:setString(data.name)
	self.headpng:loadTexture('ui/head/'..data.hero_type..'.png')
	self.powertxt:setString('战力：'..data.power)
	if data.is_leader == 1 then
		self.captiansign:setVisible(true)
		self.kickbtn:setVisible(false)
		self.kickbtn:setEnabled(false)
	else
		self.captiansign:setVisible(false)
		self.kickbtn:setVisible(true)
		self.kickbtn:setEnabled(true)
	end
	for i,v in pairs(data.combat_skills) do
		-- print(v)
		local imgSkill = ccui.ImageView:create('skillicon/'..v..'.png')
		imgSkill:setPosition(30 + (i-1) * 65, 30)
		imgSkill:setScale(0.6)
		self.skilllayer:addChild(imgSkill)
		local imgSkillBorder = ccui.ImageView:create('ui/90001.png')
		imgSkillBorder:setPosition(30 + (i-1) * 65, 30)
		imgSkillBorder:setScale(0.6)
		self.skilllayer:addChild(imgSkillBorder)
	end
end
function MultiBattlePlayerCell:onClick(sender,eventType)
	if  eventType ~= TouchEventType.ended then 
		return
	end
	local btnName = sender:getName()
	if btnName == "kickbtn" then
		local pvp = DataConfig.data.cfg.system_simple.multiplayer_pvp
		local cfg = DataConfig:getAllConfigMsg()
		local alert = GameAlert.new()

		local startTime = string.gsub(string.sub(DataConfig.data.mb.stage.time[2]['$datetime'], 1, 19), ' ', '`') 
		-- dump(PlayerData.data.records.kick_out_count)
		-- print(startTime)
		local kickCount = PlayerData.data.records.kick_out_count[startTime] or 0
		local payCoin = kickCount * pvp.kick_out_coin + pvp.kick_out_coin

		-- 检查钻石 提示信息
		if PlayerData:getCoin() < payCoin then
			local btns = {{text = "取消",skin = 2},{text = "充值",skin = 3,callback = function()
				PopLayer:clearPopLayer()
				Observer.sendNotification(ChargeModule.SHOW_CHARGE_VIEW)
			end}}
			richStr = {{text = "您的元宝不足，请您及时充值！",color = display.COLOR_WHITE}}
			alert:pop(richStr,"ui/titlenotice.png",btns)
			return
		end

		local btns = {{text = "取消",skin = 2},{text = "确定",skin = 1,callback = function()
			local net = {}
			net.method = MultiBattleModule.USER_KICK_OUT
			net.params = {}
			net.params.uid = self.data.uid
			Net.sendhttp(net)
		end, args = true}}
		alert:pop(addArgsToMsg(cfg["30074"],payCoin),"ui/titlenotice.png",btns)
	elseif btnName == "headpng" then
		local net = {}
		net.method = BagModule.USER_GET_USER_INFO
		net.params = {}
		net.params.uid = self.data.uid
		Net.sendhttp(net)
	end
end
return MultiBattlePlayerCell