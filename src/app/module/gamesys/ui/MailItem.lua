local XRichText = import("app.components.XRichText")
local MailItem = class("MailItem", function()
		local layout = ccui.Layout:create()
		layout:setContentSize(cc.size(545,127))
		return layout
	end)
--235,229,201  255,215,0
function MailItem:ctor()
	if(not MailItem.view) then
		MailItem.view = ResourceManager:widgetFromJsonFile("ui/mailitem.json")
		MailItem.view:retain()		
	end
	self.view = MailItem.view:clone()
	self.rewardbtn = self.view:getChildByName("rewardbtn")
	self.delBtn = self.view:getChildByName("delBtn")
	self.lookbtn = self.view:getChildByName("lookbtn")
	self.bg = self.view:getChildByName("bg")
	self.infobg = self.view:getChildByName("infobg")
	self.titletxt = self.view:getChildByName("titletxt")
	self.titletxt:getVirtualRenderer():setMaxLineWidth(380)
	self.titletxt:getVirtualRenderer():setLineBreakWithoutSpace(true)
	self.dateTxt = self.view:getChildByName("dateTxt")
	self.rewardtiptxt = self.view:getChildByName("rewardtiptxt")
	self.rewardtxt = self.view:getChildByName("rewardtxt")
	self.rewardtxt:getVirtualRenderer():setMaxLineWidth(380)
	self.rewardtxt:getVirtualRenderer():setLineBreakWithoutSpace(true)

	
	self.rewardbtn:addTouchEventListener(handler(self,self.onClick))
	self.delBtn:addTouchEventListener(handler(self,self.onClick))
	self.lookbtn:addTouchEventListener(handler(self,self.onLookClick))
	self:addChild(self.view)

	--enableBtnOutLine(self.delBtn, COMMON_BUTTONS.BLUE_BUTTON)
	enableBtnOutLine(self.lookbtn, COMMON_BUTTONS.ORANGE_BUTTON)	
end
function MailItem:setData(data)
	self.data = data
	self.id = data.id
	local chDic = {coin = "元宝",exp = "经验",melte = "熔炼值",
	pith = "强化精华",silver = "银两",gold = "银两",mana = "威望",}
	local state = 0--奖励，1，多人团战信息，2，只有删除按钮的信息
	self.delBtn:setEnabled(false)
	self.delBtn:setVisible(false)
	self.lookbtn:setEnabled(false)
	self.lookbtn:setVisible(false)
	self.rewardbtn:setEnabled(false)
	self.rewardbtn:setVisible(false)
	self.rewardtiptxt:setVisible(false)
	self.rewardtxt:setVisible(false)
	if(data.gift_dict and table.nums(data.gift_dict) >= 1) then
		self.rewardtiptxt:setVisible(true)
		self.rewardtxt:setVisible(true)
		self.rewardtiptxt:setString("获得奖励:")
		local info = ""
		for k,v in pairs(data.gift_dict) do
			if(chDic[k]) then
				info = info..chDic[k].."*"..v.." "
			elseif(k == "goods") then
				for kk,vv in pairs(v) do
					info = info..DataConfig:getGoodByID(kk).name.." *"..vv.." "
				end
			end
		end
		local equip = data.gift_dict["equip"]
		if(equip) then
			for kk,vv in pairs(equip) do
				info = DataConfig:getEquipById(kk).name.." *"..vv[1].." "
			end
		end
		self.rewardtxt:setString(info)
		self.rewardbtn:setEnabled(true)
		self.rewardbtn:setVisible(true)		
	elseif(data.info_type == "multiplayer_pvp_records_msg") then		
		self.delBtn:setEnabled(true)
		self.delBtn:setVisible(true)
		self.lookbtn:setEnabled(true)
		self.lookbtn:setVisible(true)
		state = 1
	else
		self.delBtn:setEnabled(true)
		self.delBtn:setVisible(true)
		state = 2
	end

	for k,v in pairs(data.info_data) do
		if(k == "admin_msg") then
			self.titletxt:setString(v)
		end
	end

	local time = string.split(data.time["$datetime"], ".")
	self.dateTxt:setString(time[1])
	local txts
	if(state == 0) then
		txts = {self.dateTxt,self.rewardtxt,self.rewardtiptxt,self.titletxt,}
	else
		txts = {self.dateTxt,self.titletxt,}
	end
	local txtsHeight = 36
	for i,v in ipairs(txts) do	
		if(i ~= 1) then
			txtsHeight = txtsHeight + v:getVirtualRendererSize().height + 1
		end
		v:setPositionY(txtsHeight)
	end
	hh = txtsHeight + 11
	if(hh < 127) then
		hh = 127
		txtsHeight = 36
		txts = {self.dateTxt,self.rewardtxt,self.rewardtiptxt,self.titletxt,}
		for i,v in ipairs(txts) do
			v:setPositionY((i-1)*26 + 36)
		end
	end
	self.bg:setContentSize(cc.size(545,hh))
	self.view:setContentSize(cc.size(545,hh))
	self.infobg:setContentSize(cc.size(400,hh-22))
	self:setContentSize(cc.size(545,hh))
	self.infobg:setPosition(215, hh/2)
	if(state == 0) then
		self.rewardbtn:setPositionY(hh/2)
	elseif(state == 1) then
		self.lookbtn:setPositionY(hh*2/3+5)		
		self.delBtn:setPositionY(hh*1/3-5)
	elseif(state == 2) then
		self.delBtn:setPositionY(hh/2)
	end	
end
function MailItem:onLookClick(sender,eventType)
	if  eventType ~= TouchEventType.ended then
		return
	end
	local tempNode = display.newNode()
	local data = {}
	tempNode.data = self.data.multiplayer_pvp
	Observer.sendNotification(MultiBattleModule.SHOW_MULTI_BATTLE_RESULT,tempNode)
end
function MailItem:onClick(sender,eventType)
	if  eventType ~= TouchEventType.ended then
		return
	end
	local net = {}
	net.method = GamesysModule.USER_GET_GIFT_MSG
	net.params = {}
	net.params.gk = self.id
	Net.sendhttp(net)
end
return MailItem