local ItemFace = require("app.components.ItemFace")
local NameItem = require("app.module.gamesys.ui.NameItem")
local OtherPlayerProcessor = class("OtherPlayerProcessor", BaseProcessor)
function OtherPlayerProcessor:ctor()
	self.view = nil
	self.itemDic = {}
end
function OtherPlayerProcessor:ListNotification()
	return {BagModule.SHOW_OTHER_PLAYER,
			BagModule.USER_GET_USER_INFO,}
end
function OtherPlayerProcessor:handleNotification(notify, node)
	if(notify == BagModule.SHOW_OTHER_PLAYER) then
	elseif(notify == BagModule.USER_GET_USER_INFO) then
		self:initLayer()
		self:processData(node.data)
		self:updateEquip()
	end
end
function OtherPlayerProcessor:processData(data)
	-- body
	self.data = data
	local equipNum = 0
	local godImproveLv = 0
	for k,v in pairs(data.data.as_equips) do
		local edata = nil
		edata = DataConfig:getEquipById(v.eid)
		v.edata = edata
		Bag:updateEquipAttr(v)
		v.pos = "body"
		equipNum = equipNum + 1
		if(equipNum == 1) then
			godImproveLv = v.star
		else
			if(godImproveLv > v.star) then
				godImproveLv = v.star
			end
		end
	end
	if(equipNum <10) then
		godImproveLv = 0
	end
	--计算所有装备增加的基本属性，二级属性，神属性
	local baseAttrs = {0,0,0,0}--基本属性
	local addAttrs = {hp = 0,mp = 0,minDmg = 0,maxDmg = 0,arm = 0,deff = 0,adf = 0,cri = 0,hit = 0,dod = 0,res = 0,mps = 0,}--二级属性
	local godInfo = {}--神属性
	local tempBaseAttrs
	local tempAddAttrs
	local tempGodInfo
	local godCfg = DataConfig.data.cfg.god
	for i,v in pairs(data.data.as_equips) do
		tempBaseAttrs = v.color
		tempAddAttrs = v.attrs		
		for i,vv in ipairs(baseAttrs) do
			baseAttrs[i] = baseAttrs[i] + tempBaseAttrs[i+1] 
		end
		for k,vv in pairs(tempAddAttrs) do
			addAttrs[k] = addAttrs[k] + vv
		end
		tempGodInfo = v.godInfo
		local godStar = v.god[1]
		for k,vv in pairs(tempGodInfo) do
			if(not godInfo[k]) then
				godInfo[k] = 0
			end
			godInfo[k] = godInfo[k] + vv 
			if(godImproveLv > 0) then
				local proLv = math.min(godImproveLv,godStar)
				godInfo[k] = godInfo[k] + godCfg[k].unlock_base[1]*DataConfig:getGodUnlock()[tostring(proLv)] + godCfg[k].unlock_base[2]
				godInfo[k] = formatGodinfoNum(k,godInfo[k])
			end
		end
	end
	local lv = data.data.lv
	local job = data.data.hero_type
	local vars = DataConfig.data.cfg.system_simple.formula

	local attrs = {}
	local jobInfo = DataConfig:getJobById(""..job)
	for k,v in pairs(JobAttrConst) do
		attrs[k] = jobInfo.as[v][1] + jobInfo.as[v][2] * (lv-1)--职业成长基本属性
		attrs[k] = formatAttributeNum(k,attrs[k])
		attrs[k] = attrs[k] + baseAttrs[v]--装备增加基本属性
	end
	local mainAtr =attrs[jobInfo.ma]
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
	data.data.attrs = attrs
	data.data.godInfo = godInfo
	data.data.godImproveLv = godImproveLv
end
function OtherPlayerProcessor:getImproveLv()
	return self.data.data.godImproveLv
end
function OtherPlayerProcessor:updateInfo()
	if(self.view) then
		self.liDaoTxt:setString(self.data.data.attrs.strr)
		self.shenFaTxt:setString(self.data.data.attrs.agi)
		self.neiJinTxt:setString(self.data.data.attrs.intt)
		self.tiZhiTxt:setString(self.data.data.attrs.sta)
		self.shangHaiTxt:setString(self.data.data.attrs.minDmg.."-"..self.data.data.attrs.maxDmg)
		self.jinGuTxt:setString(self.data.data.attrs.arm)
		self.neiFangTxt:setString(self.data.data.attrs.adf)
		self.waiFangTxt:setString(self.data.data.attrs.deff)
		self.mingZhongTxt:setString(self.data.data.attrs.hit)
		self.shanBiTxt:setString(self.data.data.attrs.dod)
		self.huiXinTxt:setString(self.data.data.attrs.cri)
		self.hpTxt:setString(self.data.data.attrs.hp)
		self.mpTxt:setString(self.data.data.attrs.mp)
		self.roleNameTxt:setString("Lv."..self.data.data.lv.." "..self.data.data.name)
		self.fightPowerTxt:setString(self.data.data.attrs.power)
		self.rolePng:loadTexture("rolePng/"..self.data.data.hero_type..".png")
		local player_title = self.data.data.title or ""
		if player_title == "" then
			self.txtTitle:setString("")
			self.imgTitle:setVisible(false)
		else
			local titles = DataConfig:getAllTitles()
			title = titles[player_title]
			self.txtTitle:setString(title.name)
			self.txtTitle:setColor(NameItem.colors[title.color])
			self.imgTitle:setVisible(true)
			self.imgTitle:loadTexture(NameItem.images[title.color])
		end
	end
end
function OtherPlayerProcessor:updateEquip()
	local pos
	for k,v in pairs(self.data.data.as_equips) do
		pos = tonumber(string.sub(v.eid,3,3))
		self.itemDic[pos+1]:setData(v)
		self.itemDic[pos+1]:setTouchEnabled(true)
	end
	self:updateInfo()
end
function OtherPlayerProcessor:initLayer()
	if(not self.view) then
		local view = ResourceManager:widgetFromJsonFile("ui/equipui.json")
		view:setName("OtherPlayerProcessor")
		self.btnClose = view:getChildByName('btnClose')
		local panel =view:getChildByName("EquipUI")
		self.headTitle = panel:getChildByName('headTitle')
		self.attrpanel = panel:getChildByName("attrpanel")

		local relarg = ccui.RelativeLayoutParameter:create()
        relarg:setAlign(ccui.RelativeAlign.alignParentTopCenterHorizontal)
		local margin = {}
		margin.top = 83
		relarg:setMargin(margin)
		self.attrpanel:setLayoutParameter(tolua.cast(relarg,"ccui.LayoutParameter"))

		self.liDaoTxt = self.attrpanel:getChildByName("liDaoTxt")
		self.shenFaTxt = self.attrpanel:getChildByName("shenFaTxt")
		self.neiJinTxt = self.attrpanel:getChildByName("neiJinTxt")
		self.tiZhiTxt = self.attrpanel:getChildByName("tiZhiTxt")
		self.shangHaiTxt = self.attrpanel:getChildByName("shangHaiTxt")
		self.jinGuTxt = self.attrpanel:getChildByName("jinGuTxt")
		self.neiFangTxt = self.attrpanel:getChildByName("neiFangTxt")
		self.waiFangTxt = self.attrpanel:getChildByName("waiFangTxt")
		self.mingZhongTxt = self.attrpanel:getChildByName("mingZhongTxt")
		self.shanBiTxt = self.attrpanel:getChildByName("shanBiTxt")
		self.huiXinTxt = self.attrpanel:getChildByName("huiXinTxt")
		self.hpTxt = self.attrpanel:getChildByName("hpTxt")
		self.mpTxt = self.attrpanel:getChildByName("mpTxt")
		self.moreAttrBtn = panel:getChildByName("moreAttrBtn")
		self.moreAttrBtn:removeFromParent(true)
		self.roleNameTxt = panel:getChildByName("roleNameTxt")
		self.roleNameTxt:enableOutline(cc.c4b(0,0,0,255), 2)
		relarg = ccui.RelativeLayoutParameter:create()

		relarg:setAlign(ccui.RelativeAlign.alignParentTopLeft)
		local margin = {}
		margin.top = 243
		margin.left = 36
		relarg:setMargin(margin)
		self.roleNameTxt:setLayoutParameter(tolua.cast(relarg,"ccui.LayoutParameter"))


		--self.jobTxt = panel:getChildByName("jobTxt")
		self.fightPowerTxt = panel:getChildByName("fightPowerTxt")
		--self.jobIcon = panel:getChildByName("jobIcon")
		self.equipPanel = panel:getChildByName("equipPanel")
		self.rolePng = self.equipPanel:getChildByName("rolePng")
		self.bg = view:getChildByName("bg")
		self.txtTitle = panel:getChildByName("txtTitle")
		self.imgTitle = panel:getChildByName("imgTitle")
		--self.jobIcon:setScale(0.5)

		self.txtTitle:enableOutline(cc.c4b(0,0,0,255), 2)

		self.headTitle:loadTexture('ui/comtitle2.png')
		self.btnClose:setVisible(true)
		self.btnClose:setEnabled(true)
		self.btnClose:addTouchEventListener(handler(self,self.onClose))
		
		local theight = 766
		self.det = display.height - 960
		if display.height > 960 then
			theight = theight + self.det
		end
		local size = view:getLayoutSize()
		view:setContentSize(cc.size(size.width,theight))
		panel:setContentSize(cc.size(size.width,theight))
		size = self.bg:getContentSize()
		self.bg:setContentSize(cc.size(615,size.height + self.det))

		relarg = ccui.RelativeLayoutParameter:create()

		relarg:setAlign(ccui.RelativeAlign.alignParentTopLeft)
		local margin = {}
		margin.top = 280+self.det/2
		margin.left = 0
		relarg:setMargin(margin)
		self.equipPanel:setLayoutParameter(tolua.cast(relarg,"ccui.LayoutParameter"))

		self.equipPoses = {}
		local item
		local tempX
		local tempY
		local img = nil
		for i=0,9 do
			img = self.equipPanel:getChildByName("equip"..i)
			tempX,tempY = img:getPosition()
			self.equipPanel:removeChild(img)
			self.equipPoses[i+1] = {tempX,tempY}
			item = ItemFace.new()
			item.defaultimg = "ui/icon_18.png"
			item.showInfo = false --禁用鼠标事件
			--item:setData(temps[i+1])
			item:setData()
			item:setAnchorPoint(0.5,0.5)
			item:setPosition(self.equipPoses[i+1][1], self.equipPoses[i+1][2])
			if(i > 3) then
				item:setScale(0.8)
			end
			self.equipPanel:addChild(item,2)
			self.itemDic[i+1] = item
			item:setTouchEnabled(false)
			item:addTouchEventListener(handler(self,self.onItemClick))
		end
		self.view = view
		self:setView(self.view)
	end	
	-- self:addMidView(self.view,true)
	self:addPopView(self.view,true)
end
--选择装备点击
function OtherPlayerProcessor:onItemClick(sender, eventType)
	-- 触摸完毕再触发事件
	if  eventType ~= TouchEventType.ended then 
		return
	end
	local node = display.newNode()
	node.data = sender.data
	node.user = "OtherPlayerProcessor"
	Observer.sendNotification(BagModule.SHOW_EQUIP_INFO, node)
end
function OtherPlayerProcessor:setData(data)
end
function OtherPlayerProcessor:onClose(sender,eventType)
	if  eventType ~= TouchEventType.ended then 
		return
	end

	local btn = tolua.cast(sender,"ccui.Button")
	local btnName = btn:getName()

	if btnName == "btnClose" then
		self:removePopView(self.view)
	end
end
return OtherPlayerProcessor