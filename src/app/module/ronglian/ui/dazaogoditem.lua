--
-- Author: Your Name
-- Date: 2015-01-19 14:05:05
--
local ItemFace = require("app.components.ItemFace")
local dazaogoditem = class("dazaogoditem", function()
		local layout = ccui.Layout:create()
		layout:setContentSize(cc.size(546,128))
		return layout
	end)
function dazaogoditem:ctor()
	if(not dazaogoditem.view) then
		dazaogoditem.view = ResourceManager:widgetFromJsonFile("ui/dazaogoditem.json")
		dazaogoditem.view:retain()
	end	
	self.view = dazaogoditem.view:clone()
	self.itemlayer = self.view:getChildByName("itemlayer")
	self.nametxt = self.view:getChildByName("nametxt")
	self.attrtxt = self.view:getChildByName("attrtxt")
	self.godtxt = self.view:getChildByName("godtxt")
	self.godtxt2 = self.view:getChildByName("godtxt2")
	self.pospng = self.view:getChildByName("pospng")
	self.dazaobtn = self.view:getChildByName("dazaobtn")
	self.dazaobtn:addTouchEventListener(handler(self,self.onClick))
	enableBtnOutLine(self.dazaobtn,COMMON_BUTTONS.BLUE_BUTTON)

	local itemface = ItemFace.new()
	itemface.showInfo = false --禁用鼠标事件
	itemface:setAnchorPoint(cc.p(0.5,0.5))
	self.itemlayer:addChild(itemface)
	self.itemface = itemface

	self:addChild(self.view)
end

function dazaogoditem:setData(data,index)
	self.index = index
	self.data = data
	self.itemface:setData(self.data)
	local eid = self.data.eid
	local lv = tonumber(string.sub(eid,4,6))
	local name = DataConfig:getEquipById(eid).name
	self.nametxt:setString("Lv"..lv.." "..name)
	local attrstr
	local edata = DataConfig:getEquipById(eid)
	for k,v in pairs(edata) do
		if(k~="name") then
			if(k == "dam") then
				attrstr = Bag:getAttrName(k).." "..v[1].."-"..v[2]
			else
				attrstr = Bag:getAttrName(k).." +"..v
			end
		end
	end
	self.attrtxt:setString(attrstr)

	local godstr
	local godcfg = DataConfig:getGodCfg(self.data.god[3])
	if("ignore_armor" == self.data.god[3] or "ignore_deff" == self.data.god[3] or "ignore_adf" == self.data.god[3]) then
		godstr = godcfg.name .. " +"..(godcfg.lv_base[1]+godcfg.lv_base[2])
	else
		godstr = godcfg.name .. " +"..(godcfg.lv_base[1]+godcfg.lv_base[2])*100 .."%"
	end
	self.godtxt:setString(godstr)

	if(self.data.god[4]) then
		godcfg = DataConfig:getGodCfg(self.data.god[4])
		if("ignore_armor" == self.data.god[4] or "ignore_deff" == self.data.god[4] or "ignore_adf" == self.data.god[4]) then
			godstr = godcfg.name .. " +"..(godcfg.lv_base[1]+godcfg.lv_base[2])
		else
			godstr = godcfg.name .. " +"..(godcfg.lv_base[1]+godcfg.lv_base[2])*100 .."%"
		end
		self.godtxt2:setString(godstr)
	else
		self.godtxt2:setString("")
	end

	local equipPos = tonumber(string.sub(eid,3,3))
	self.pospng:loadTexture("ui/e"..equipPos..".png")
end
function dazaogoditem:onClick(sender,eventType)
	if  eventType ~= TouchEventType.ended then 
		return
	end
	local cost
	if(not self.data.god[4]) then
		cost = DataConfig:getOneGodsDaZaoNeed()
	else
		cost = DataConfig:getTwoGodsDaZaoNeed()
	end

	local costMana = cost[1]
	local costRongLian = cost[2]
	if(costMana > PlayerData:getMana()) then
		toastNotice(addArgsToMsg(DataConfig:getConfigMsgByID("30053"),costMana))
		return
	end

	if(costRongLian > PlayerData:getMelte() ) then
		toastNotice(addArgsToMsg(DataConfig:getConfigMsgByID("30052"),costRongLian))
		return
	end
	local btns = {{text = "取消",skin = 2},{text = "确定",skin = 1,callback = handler(self,self.sendDaZaoGodRequest)},}
	local alert = GameAlert.new()
	local msg = DataConfig:getConfigMsgByID("30055")
	local name = DataConfig:getEquipById(self.data.eid).name
	local richStr = {{text = addArgsToMsg(msg,name,costMana,costRongLian),color = display.COLOR_WHITE}}
	local equipPos = tonumber(string.sub(self.data.eid,3,3))
	alert:pop(richStr,"ui/dazaogode"..equipPos..".png",btns)
end
function dazaogoditem:sendDaZaoGodRequest()
	local net = {}
	net.method = RonglianModule.USER_SP_EQUIP_MELTE
	net.params = {}
	net.params.index = self.index
	Net.sendhttp(net)
end


return dazaogoditem