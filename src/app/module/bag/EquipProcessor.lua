local ItemFace = require("app.components.ItemFace")
local NameItem = require("app.module.gamesys.ui.NameItem")
local EquipProcessor = class("EquipProcessor", BaseProcessor)
function EquipProcessor:ctor()
	self.view = nil
	self.itemDic = {}
	self.tipDic = {}
end
function EquipProcessor:ListNotification()
	return {
		BagModule.OPEN_EQUIP,
		BagModule.UPDATE_EQUIP_ATTR,
		BagModule.USER_EQUIP_DRESS,
		BagModule.NOTICE_BETTER_EQUIP,
	}
end
--处理消息
function EquipProcessor:handleNotification(notify, node)
	if (notify == BagModule.OPEN_EQUIP) then
		self:initLayer()
	elseif(notify == BagModule.UPDATE_EQUIP_ATTR) then
		if self.view ~= nil then
			PlayerData:calcAttributes()
			self:updateEquip()
		end
	elseif(notify == BagModule.NOTICE_BETTER_EQUIP) then
		if(self.view) then
			self:updateBetterTip()
			--self:showBetterTip(node.data.pos)
		end
	elseif(notify == BagModule.USER_EQUIP_DRESS) then
		local oldData = clone(PlayerData.data)
		local oldGodData = clone(PlayerData.godInfo)
		-- dump(node.data.data)
		Bag:updateDress(node.data.data.as_equips)
		PlayerData:calcAttributes()
		self:updateEquip()
		self:updateNotice(oldData,oldGodData)
		Observer.sendNotification(BagModule.EQUIP_NUM_UPDATE) --数量更新
	end
end
function EquipProcessor:updateNotice(oldData,oldGodData)
	local changeAttrs = {"strr","agi","intt","sta","hp","mp","minDmg","maxDmg","arm","deff","adf","cri","hit","dod","res"}
	local content
	local color
	local enname
	local chname
	local changeNum
	local notices = {}
	for i,v in ipairs(changeAttrs) do
		enname,chname = getAttrName(v)
		content = chname.."："
		changeNum = PlayerData.data[v] - oldData[v]
		if(changeNum > 0) then
			content = content.."+"..changeNum
			color = COLOR_GREEN
			table.insert(notices,{content,color})
		elseif(changeNum < 0) then
			content = content..changeNum
			color = COLOR_RED
			table.insert(notices,{content,color})
		end		
	end
	local curGodInfo = PlayerData:getGodInfo()
	local godcfg
	local hasShow = {}
	local curNum
	local oldNum
	local resNum
	for k,v in pairs(oldGodData) do
		if(not hasShow[k]) then
			hasShow[k] = true
			godcfg = DataConfig:getGodCfg(k)
			curNum = curGodInfo[k] or 0
			
			resNum = curNum - v
			if(resNum>0) then
				if("ignore_armor" == k or "ignore_deff" == k or "ignore_adf" == k) then
					content = godcfg.name .. " +"..resNum
				else
					content = godcfg.name .. " +"..resNum*100 .."%"
				end
				
				color = COLOR_GREEN
				table.insert(notices,{content,color})
			elseif(resNum<0) then
				if("ignore_armor" == k or "ignore_deff" == k or "ignore_adf" == k) then
					content = godcfg.name..(resNum)
				else
					content = godcfg.name..(resNum*100).."%"
				end
				color = COLOR_RED
				table.insert(notices,{content,color})
			end
		end
	end
	for k,v in pairs(curGodInfo) do
		if(not hasShow[k]) then
			hasShow[k] = true
			godcfg = DataConfig:getGodCfg(k)
			oldNum = oldGodData[k] or 0
			resNum = v - oldNum
			if(resNum>0) then
				if("ignore_armor" == k or "ignore_deff" == k or "ignore_adf" == k) then
					content = godcfg.name .. " +"..resNum
				else
					content = godcfg.name .. " +"..resNum*100 .."%"
				end
				color = COLOR_GREEN
				table.insert(notices,{content,color})
			elseif(resNum<0) then
				if("ignore_armor" == k or "ignore_deff" == k or "ignore_adf" == k) then
					content = godcfg.name..(resNum)
				else
					content = godcfg.name..(resNum*100).."%"
				end
				color = COLOR_RED
				table.insert(notices,{content,color})
			end
		end
	end
	popNotices(notices)
end
function EquipProcessor:updateBetterTip()
	for i,v in ipairs(Bag.playerEquipNotice) do
		if(v) then
			self:showBetterTip(i-1)
		else
			self:hideBetterTip(i-1)
		end
	end
end
function EquipProcessor:hideBetterTip(pos)
	if(self.tipDic[pos+1]) then
		self.tipDic[pos+1]:removeFromParent(true)
		self.tipDic[pos+1] = nil
	end
end
function EquipProcessor:showBetterTip(pos)
	if(not self.tipDic[pos+1]) then
		display.addSpriteFrames("ui/new.plist","ui/new.png")
		local frames = display.newFrames("xin%04d.png", 1,7)
		local animation = display.newAnimation(frames, 0.5 / 7) -- 0.5 秒播放 10桢
		local spr = display.newSprite()
		spr:playAnimationForever(animation)
		local node = display.newNode()
		node:addChild(spr)
		local osize = self.itemDic[pos+1]:getContentSize()
		local scale = self.itemDic[pos+1]:getScaleX()
		local posx = self.equipPoses[pos+1][1] + osize.width*scale/2 - 10
		local posy = self.equipPoses[pos+1][2] + osize.height*scale/2 - 10
		
		node:setPosition(posx,posy)
		self.equipPanel:addChild(node,3)
		self.tipDic[pos+1] = node
	end
end
function EquipProcessor:updateInfo()
	if(self.view) then
		self.liDaoTxt:setString(PlayerData.data.strr)
		self.shenFaTxt:setString(PlayerData.data.agi)
		self.neiJinTxt:setString(PlayerData.data.intt)
		self.tiZhiTxt:setString(PlayerData.data.sta)
		self.shangHaiTxt:setString(PlayerData.data.minDmg.."-"..PlayerData.data.maxDmg)
		self.shangHaiTxt:setTextColor(cc.c4b(0, 255, 0, 255))
		self.jinGuTxt:setString(PlayerData.data.arm)
		self.neiFangTxt:setString(PlayerData.data.adf)
		self.waiFangTxt:setString(PlayerData.data.deff)
		self.mingZhongTxt:setString(PlayerData.data.hit)
		self.shanBiTxt:setString(PlayerData.data.dod)
		self.huiXinTxt:setString(PlayerData.data.cri)
		self.hpTxt:setString(PlayerData.data.hp)
		self.mpTxt:setString(PlayerData.data.mp)
		self.roleNameTxt:setString("Lv."..PlayerData.data.lv.." "..PlayerData.data.name)
		self.fightPowerTxt:setString(PlayerData.data.power)
		self.rolePng:loadTexture("rolePng/"..PlayerData:getHeroType()..".png")
		self.liDaoTxt:setTextColor(cc.c4b(255, 255, 255, 255))
		self.shenFaTxt:setTextColor(cc.c4b(255, 255, 255, 255))
		self.neiJinTxt:setTextColor(cc.c4b(255, 255, 255, 255))
		if PlayerData:getHeroType() == 1 then
			self.neiJinTxt:setTextColor(cc.c4b(0, 255, 0, 255))
		elseif PlayerData:getHeroType() == 2 then
			self.liDaoTxt:setTextColor(cc.c4b(0, 255, 0, 255))
		elseif PlayerData:getHeroType() == 3 then
			self.shenFaTxt:setTextColor(cc.c4b(0, 255, 0, 255))
		end
		local player_title = PlayerData:getTitle()
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
function EquipProcessor:updateEquip()
	local temps = {}
	local bodyEquips = Bag:getAllEquip(true,"body")
	local poses = {0,1,2,3,4,5,6,7,8,9}
	local pos
	for k,v in pairs(bodyEquips) do
		pos = tonumber(string.sub(v.eid,3,3))
		self.itemDic[pos+1]:setData(v)
		table.removebyvalue(poses, pos)
	end
	for i,v in ipairs(poses) do
		self.itemDic[v+1]:setData(nil)
	end
	self:updateInfo()
end
function EquipProcessor:initLayer()
	if(not self.view) then
		local view = ResourceManager:widgetFromJsonFile("ui/equipui.json")
		self.btnClose = view:getChildByName("btnClose")
		self.btnClose:setVisible(false)
		self.btnClose:setEnabled(false)
		self.btnClose:addTouchEventListener(handler(self,self.onClose))

		local panel =view:getChildByName("EquipUI")
		self.attrpanel = panel:getChildByName("attrpanel")
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
		enableBtnOutLine(self.moreAttrBtn,COMMON_BUTTONS.BLUE_BUTTON)
		self.moreAttrBtn:setPressedActionEnabled(true)
		self.moreAttrBtn:addTouchEventListener(handler(self,self.onClickMoreAttr))
		self.roleNameTxt = panel:getChildByName("roleNameTxt")
		self.roleNameTxt:enableOutline(cc.c4b(0,0,0,255), 2)
		self.fightPowerTxt = panel:getChildByName("fightPowerTxt")
		--self.jobIcon = panel:getChildByName("jobIcon")
		self.equipPanel = panel:getChildByName("equipPanel")
		self.rolePng = self.equipPanel:getChildByName("rolePng")
		self.bg = view:getChildByName("bg")
		--self.jobIcon:setScale(0.5)
		self.txtTitle = panel:getChildByName("txtTitle")
		self.imgTitle = panel:getChildByName("imgTitle")

		self.txtTitle:enableOutline(cc.c4b(0,0,0,255), 2)

		local jobInfo = DataConfig:getJobById(""..PlayerData:getHeroType())
		if(jobInfo.ma == "intt") then
			self.neiJinTxt:setColor(cc.c3b(0,255,0))
		elseif(jobInfo.ma == "strr") then
			self.liDaoTxt:setColor(cc.c3b(0,255,0))
		elseif(jobInfo.ma == "agi") then
			self.shenFaTxt:setColor(cc.c3b(0,255,0))
		end



		local theight = 766
		self.det = display.height - 960
		if display.height > 960 then
			theight = theight + self.det
		end
		local size = view:getLayoutSize()
		view:setContentSize(cc.size(size.width,theight))
		panel:setContentSize(cc.size(size.width,theight))
		size = self.bg:getContentSize()
		self.bg:setContentSize(cc.size(size.width,size.height + self.det))

		relarg = ccui.RelativeLayoutParameter:create()

		relarg:setAlign(ccui.RelativeAlign.alignParentTopLeft)
		local margin = {}
		margin.top = 280 +self.det/2
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
			if i > 3 then
				item:setScale(0.88)
			else
				item:setScale(1.15)
			end
			self.equipPanel:addChild(item,2)
			self.itemDic[i+1] = item
			item:setTouchEnabled(true)
			item:addTouchEventListener(handler(self,self.onItemClick))
		end
		self.view = view
		self:setView(self.view)
		self:updateEquip()
		self.tipDic = {}
		self:updateBetterTip()
	end	
	self:addMidView(self.view,true)
end
function EquipProcessor:onClickMoreAttr(sender,eventType)
	if  eventType ~= TouchEventType.ended then 
		return
	end
	--更多属性
	local btns = {{text = "确定",skin = 3}}
	local alert = GameAlert.new()
	local richStr = {
		{text = "Lv."..PlayerData.data.lv.." "..PlayerData.data.name.." ["..PlayerType[PlayerData:getHeroType()].."]\n",color = cc.c3b(0,198,255)},
		{text = "战力："..PlayerData.data.power.."\n",color = cc.c3b(255,205,30)},
		{text = "属性：总属性值".."Lv."..PlayerData.data.lv.."(对"..PlayerData.data.lv.."级玩家的效果)\n",color = cc.c3b(175,137,174)},
		
		
		{text = "            \n",color = cc.c3b(0,0,0)},		
		{text = "基础属性：\n",color = cc.c3b(255,255,255),size = 25},


		{text = "力道：",color = cc.c3b(175,137,174)},
		{text = PlayerData.data.strr,color = cc.c3b(64,227,0)},
		{text = "[外防",color = cc.c3b(175,137,174)},
		{text = "+"..math.round(PlayerData:calcBaseAttributesDeff()),color = cc.c3b(64,227,0)},
		{text = " 命中",color = cc.c3b(175,137,174)},
		{text = "+"..math.round(PlayerData:calcBaseAttributesHit()),color = cc.c3b(64,227,0)},
		{text = "]\n",color = cc.c3b(175,137,174)},

		{text = "身法：",color = cc.c3b(175,137,174)},
		{text = PlayerData.data.agi,color = cc.c3b(64,227,0)},
		{text = "[会心",color = cc.c3b(175,137,174)},
		{text = "+"..math.round(PlayerData:calcBaseAttributesCri()),color = cc.c3b(64,227,0)},
		{text = " 闪避",color = cc.c3b(175,137,174)},
		{text = "+"..math.round(PlayerData:calcBaseAttributesDod()),color = cc.c3b(64,227,0)},
		{text = "]\n",color = cc.c3b(175,137,174)},
 
		{text = "内劲：",color = cc.c3b(175,137,174)},
		{text = PlayerData.data.intt,color = cc.c3b(64,227,0)},
		{text = "[内防",color = cc.c3b(175,137,174)},
		{text = "+"..math.round(PlayerData:calcBaseAttributesAdf()),color = cc.c3b(64,227,0)},
		{text = " 每回合魔法恢复",color = cc.c3b(175,137,174)},
		{text = "+"..math.round(PlayerData:calcBaseAttributesMps()),color = cc.c3b(64,227,0)},
		{text = "]\n",color = cc.c3b(175,137,174)},

		{text = "体质：",color = cc.c3b(175,137,174)},
		{text = PlayerData.data.sta,color = cc.c3b(64,227,0)},
		{text = "[气血",color = cc.c3b(175,137,174)},
		{text = "+"..math.round(PlayerData:calcBaseAttributesHp()),color = cc.c3b(64,227,0)},
		{text = " 招架",color = cc.c3b(175,137,174)},
		{text = "+"..math.round(PlayerData:calcBaseAttributesRes()),color = cc.c3b(64,227,0)},
		{text = "]\n",color = cc.c3b(175,137,174)},

		{text = "气血：",color = cc.c3b(175,137,174)},
		{text = PlayerData.data.hp.."\n",color = cc.c3b(64,227,0)},

		{text = "内力：",color = cc.c3b(175,137,174)},
		{text = PlayerData.data.mp.."\n",color = cc.c3b(64,227,0)},


		{text = "            \n",color = cc.c3b(0,0,0)},		
		{text = "战斗属性：\n",color = cc.c3b(255,255,255),size = 25},


		{text = "最小伤害：",color = cc.c3b(175,137,174)},
		{text = PlayerData.data.minDmg.."\n",color = cc.c3b(64,227,0)},

		{text = "最大伤害：",color = cc.c3b(175,137,174)},
		{text = PlayerData.data.maxDmg.."\n",color = cc.c3b(64,227,0)},

		{text = "筋骨：",color = cc.c3b(175,137,174)},
		{text = PlayerData.data.arm,color = cc.c3b(64,227,0)},
		{text = "[减少",color = cc.c3b(175,137,174)},
		{text = checkint(PlayerData:calcBaseAttributesShowArmRate(PlayerData.data.arm,PlayerData.data.lv)*100).."%" ,color = cc.c3b(64,227,0)},
		{text = "受到的伤害]\n",color = cc.c3b(175,137,174)},

		{text = "外防：",color = cc.c3b(175,137,174)},
		{text = PlayerData.data.deff,color = cc.c3b(64,227,0)},
		{text = "[减少受到的外功伤害]\n",color = cc.c3b(175,137,174)},

		{text = "内防：",color = cc.c3b(175,137,174)},
		{text = PlayerData.data.adf,color = cc.c3b(64,227,0)},
		{text = "[减少受到的内功伤害]\n",color = cc.c3b(175,137,174)},

		{text = "会心：",color = cc.c3b(175,137,174)},
		{text = PlayerData.data.cri,color = cc.c3b(64,227,0)},
		{text = "[有",color = cc.c3b(175,137,174)},
		{text = checkint(PlayerData:calcBaseAttributesShowCriRate(PlayerData.data.cri,PlayerData.data.lv)*100).."%" ,color = cc.c3b(64,227,0)},
		{text = "的概率造成",color = cc.c3b(175,137,174)},
		{text = checkint(PlayerData.data.crd*100).."%" ,color = cc.c3b(64,227,0)},
		{text = "会心一击]\n",color = cc.c3b(175,137,174)},

		{text = "命中：",color = cc.c3b(175,137,174)},
		{text = PlayerData.data.hit,color = cc.c3b(64,227,0)},
		{text = "[提高攻击命中率]\n",color = cc.c3b(175,137,174)},

		{text = "闪避：",color = cc.c3b(175,137,174)},
		{text = PlayerData.data.dod,color = cc.c3b(64,227,0)},
		{text = "[提高闪避攻击的概率]\n",color = cc.c3b(175,137,174)},

		{text = "招架：",color = cc.c3b(175,137,174)},
		{text = PlayerData.data.res,color = cc.c3b(64,227,0)},
		{text = "[降低被会心的概率]\n",color = cc.c3b(175,137,174)},


		{text = "            \n",color = cc.c3b(0,0,0)},		
		{text = "神器属性：\n",color = cc.c3b(255,255,255),size = 25},
	}
	local addMa
	local jobInfo = DataConfig:getJobById(""..PlayerData:getHeroType())
	addMa = {
		{text = " 最小伤害",color = cc.c3b(175,137,174)},
		{text = "+"..math.round(PlayerData:calcBaseAttributesMinDmg()),color = cc.c3b(64,227,0)},
		{text = " 最大伤害",color = cc.c3b(175,137,174)},
		{text = "+"..math.round(PlayerData:calcBaseAttributesMaxDmg()),color = cc.c3b(64,227,0)},
	}
	--主属性影响
	local index
	if(jobInfo.ma == "strr") then
		index = 11
	elseif(jobInfo.ma == "agi") then
		index = 18
	elseif(jobInfo.ma == "intt") then
		index = 25
	elseif(jobInfo.ma == "sta") then
		index = 32
	end
	for i,v in ipairs(addMa) do
		table.insert(richStr, index + i,v)
	end
	--神属性
	local godInfo = PlayerData:getGodInfo()
	local godcfg
	local godname
	for k,v in pairs(godInfo) do
		godcfg = DataConfig:getGodCfg(k)
		if("ignore_armor" == k or "ignore_deff" == k or "ignore_adf" == k) then
			godname = godcfg.name .. " +"..v			
			table.insert(richStr, {text = godname.."(忽视敌人"..(math.floor(100*v/(v + 100))).."%的护甲)\n",
				color = cc.c3b(255,38,38)})
		else
			godname = godcfg.name .. " +"..v*100 .."%"
			table.insert(richStr, {text = godname.."\n",color = cc.c3b(255,38,38)})
		end
	end
	alert:pop(richStr,"ui/moreattrtxt.png",btns)
end
--选择装备点击
function EquipProcessor:onItemClick(sender, eventType)
	-- 触摸完毕再触发事件
	if  eventType ~= TouchEventType.ended then
		return
	end
	local node = display.newNode()
	node.data = sender.data
	-- print("-----------------",node.pos)
	node.callback = handler(self,self.onSelectCallBack)
	node.type = "button" --单选类型 条子上显示按钮
	node.user = "EquipProcessor"
	local posi = table.indexof(self.itemDic, sender) -1
	node.params = {tonumber(PlayerData:getHeroType()),posi}
	if node.data == nil then
		Observer.sendNotification(BagModule.SHOW_COMMON_EQUIP_SELECT, node)
	else
		Observer.sendNotification(BagModule.SHOW_EQUIP_INFO, node)
	end
	Bag.playerEquipNotice[posi+1] = false				
	local tempNode = display.newNode()
	local data = {}
	tempNode.data = data
	data.pos = posi
	Observer.sendNotification(BagModule.NOTICE_BETTER_EQUIP,tempNode)
end
function EquipProcessor:onSelectCallBack(data)
	PopLayer:clearPopLayer()
	if(data.pos == "bag") then	
		local itemJob = tonumber(string.sub(data.eid,2,2))	
		local playerJob = tonumber(PlayerData:getHeroType())

		if(itemJob~=3 and (itemJob+1) ~= playerJob) then
			toastNotice("职业不符，不能装备",COLOR_RED)
			return
		end
	end		
	local bodyEquips = Bag:getAllEquip(true,"body")
	local poses = {"","","","","","","","","","",}
	local pos
	for k,v in pairs(bodyEquips) do
		pos = tonumber(string.sub(v.eid,3,3))
		poses[pos + 1] = v.sid
	end
	pos = tonumber(string.sub(data.eid,3,3))
	if(data.pos == "bag") then		
		poses[pos + 1] = data.sid
	else
		poses[pos + 1] = ""
	end
	

	local net = {}
	net.method = BagModule.USER_EQUIP_DRESS
	net.params = {}
	net.params.data = poses
	Net.sendhttp(net)

end
function EquipProcessor:sendEquipDress()
	-- body
	
end
function EquipProcessor:onClose(sender,eventType)
	if  eventType ~= TouchEventType.ended then 
		return
	end

	local btn = tolua.cast(sender,"ccui.Button")
	local btnName = btn:getName()

	if btnName == "btnClose" then
		self:removePopView(self.view)
	end
end
return EquipProcessor