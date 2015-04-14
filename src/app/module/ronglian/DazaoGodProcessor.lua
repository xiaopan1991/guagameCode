--
-- Author: Your Name
-- Date: 2015-01-19 12:50:36
--
local DazaoGodProcessor = class("DazaoGodProcessor", BaseProcessor)
local dazaogoditem = import(".ui.dazaogoditem")
function DazaoGodProcessor:ctor()
end

function DazaoGodProcessor:ListNotification()
	return {
		RonglianModule.SHOW_DA_ZAO_GAO,
		RonglianModule.USER_SP_EQUIP_MELTE,--打造神器
		RonglianModule.USER_SP_FORGE_INFO
	}
end

function DazaoGodProcessor:handleNotification(notify, data)
	if notify == RonglianModule.SHOW_DA_ZAO_GAO then
		self:onSetView()
	elseif notify == RonglianModule.USER_SP_FORGE_INFO  then
		PlayerData:setDazaoGodList(data.data.data.sp_forge)
		self:onSetData()
	elseif notify == RonglianModule.USER_SP_EQUIP_MELTE  then
		local notices = {}
		local name
		local eqid = data.data.data.eqid
		local info = data.data.data.info
		if(eqid) then
			Bag:addEquip(eqid,info)
			local msg = DataConfig:getConfigMsgByID("30051")
			local lv = tonumber(string.sub(info.eid,4,6))
			name = DataConfig:getEquipById(info.eid).name
			table.insert(notices,{addArgsToMsg(msg,lv,name),COLOR_GREEN})
		end
		PlayerData:setMelte(data.data.data.melte)
		PlayerData:setMana(data.data.data.mana)
		local msg = DataConfig:getConfigMsgByID("30054")
		self.shengwangTxt:setString(addArgsToMsg(msg,PlayerData:getMana()))
		Observer.sendNotification(BagModule.EQUIP_NUM_UPDATE) --数量更新
		Observer.sendNotification(RonglianModule.MELTE_UPDATE)
		popNotices(notices)
	end
end

function DazaoGodProcessor:onSetData()
	self.data = PlayerData:getDazaoGodList()
	if(self.data == nil or #self.data == 0) then
		local net = {}
		net.method = RonglianModule.USER_SP_FORGE_INFO
		net.params = {}
		Net.sendhttp(net)
		return
	end
	if(type(self.data) ~= "table") then
		self.data = {}
	end
	self.scrollview:removeAllChildren()	
	local num = table.nums(self.data)	
    local rowPadding = 6

	local h = 128

	--滚动条宽度
	local innerWidth = self.scrollview:getInnerContainerSize().width
	--设置滚动条内容区域大小
	self.scrollview:setInnerContainerSize(cc.size(innerWidth,math.max(num * (h + rowPadding) + rowPadding,self.scrollview:getContentSize().height)))

	local render = nil
	local innerHeight = self.scrollview:getInnerContainerSize().height
	--y起始坐标
	local ystart = innerHeight 

	local i = 1

	for k,v in ipairs(self.data) do
		render = dazaogoditem.new()
		render:setData(v.info,i-1)
		render:setPosition(0 ,ystart - i*(h + rowPadding))
		self.scrollview:addChild(render)
		i = i + 1
	end
end
function DazaoGodProcessor:onSetView()
	if(not self.view) then
		local dazaogod = ResourceManager:widgetFromJsonFile("ui/dazaogod.json")
		local btnClose = dazaogod:getChildByName("btnClose")
		local helpBtn = dazaogod:getChildByName("helpBtn")
		self.shengwangTxt = dazaogod:getChildByName("shengwangTxt")
		local msg = DataConfig:getConfigMsgByID("30054")
		self.shengwangTxt:setString(addArgsToMsg(msg,PlayerData:getMana()))
		msg = DataConfig:getConfigMsgByID("20024")
		self.dscTxt = dazaogod:getChildByName("dscTxt")
		self.dscTxt:setString(msg)
		self.scrollview = dazaogod:getChildByName("scrollview")
		helpBtn:addTouchEventListener(handler(self,self.onBtnClick))
		btnClose:addTouchEventListener(handler(self,self.onBtnClick))
		self:setView(dazaogod)
		self:addPopView(dazaogod)
		self:onSetData()
	end
end
function DazaoGodProcessor:onBtnClick(sender,eventType)
	if  eventType ~= TouchEventType.ended then
		return
	end
	local btn = tolua.cast(sender,"ccui.Button")
	local btnName = btn:getName()
	if btnName == "helpBtn" then
		local alert = GameAlert.new()
		alert:popHelp("newbie_guide_5")
	elseif btnName == "btnClose" then
		self:removePopView(self.view)
	end
end
return DazaoGodProcessor