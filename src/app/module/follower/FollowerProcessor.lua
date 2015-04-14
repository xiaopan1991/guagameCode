--弟子处理器
local FollowerheadNew = import(".ui.FollowerheadNew")
local ItemFace = require("app.components.ItemFace")
local FollowerProcessor = class("FollowerProcessor",BaseProcessor)

function FollowerProcessor:ctor()
	self.curFollower = nil
	self.attrDic = {}
	self.followerHeads = {}
	self.equips = {0,2,1,3}
	self.itemDic = {}  --哈希存储
	self.skillArray = {}
	self.tipDic = {}

	--装备类型配置
	self.equipType = {
		EquipPosType.WEAPON,
		EquipPosType.HORSE,
		EquipPosType.CLOTHES,
		EquipPosType.LEG
	}
end

function FollowerProcessor:ListNotification()
	return {
		FollowerModule.SHOW_FOLLOWER_VIEW,
		FollowerModule.USER_CHANGE_FO_ACTION,
		FollowerModule.USER_FOLLOWER_EQUIP_DRESS,
		FollowerModule.FOLLOWER_SKILL_CHANGE,
		FollowerModule.FOLLOWER_FOSTER_CHANGE,
		BagModule.UPDATE_EQUIP_ATTR,  --装备属性变化
		BagModule.NOTICE_BETTER_EQUIP,--新装备提醒
	}
end

function FollowerProcessor:handleNotification(notify, data)
	if notify == FollowerModule.SHOW_FOLLOWER_VIEW then
		self:initUI()
		self:setData()
	elseif notify == FollowerModule.USER_CHANGE_FO_ACTION then
		-- dump(data.data.data)
		PlayerData:setOnworkSolider(data.data.data.on_work_fo)
		self:updateBtnState()
	elseif notify == FollowerModule.USER_FOLLOWER_EQUIP_DRESS then
		--弟子换装返回
		local sdata = PlayerData:getSoliderByID(data.data.params.fid)
		local oldData = clone(sdata.attrs)
		local oldGodData = clone(sdata.godInfo)
		self:updateSolider(data.data)
		sdata = PlayerData:getSoliderByID(data.data.params.fid)
		local newData = clone(sdata.attrs)
		local newGodData = clone(sdata.godInfo)
		self:updateNotice(oldData,oldGodData,newData,newGodData)
	elseif notify == FollowerModule.FOLLOWER_SKILL_CHANGE then
		self:updateSkills()
	elseif notify == FollowerModule.FOLLOWER_FOSTER_CHANGE then
		self:updateAttrs()
	elseif notify == BagModule.UPDATE_EQUIP_ATTR then
		--处理装备属性变化
		if data ~= nil and data.eid ~= nil then
			self:handleEquipChange(data.eid)
		end
	elseif notify == BagModule.NOTICE_BETTER_EQUIP then
		if(self.view) then
			self:updateBetterTip()
		end
	end
end
function FollowerProcessor:updateBetterTip()
	if(not self.curFollower) then
		return
	end
	local pType = tonumber(PlayerData:getSoliderByID(self.curFollower).hero_type)
	for i,v in ipairs(Bag.followerEquipNotice[pType]) do
		if(i <= EquipPosType.LEG + 1) then
			if(v) then
				self:showBetterTip(i-1)
			else
				self:hideBetterTip(i-1)
			end
		end
	end
end
function FollowerProcessor:hideBetterTip(pos)
	if(self.tipDic[pos+1] and (not tolua.isnull(self.tipDic[pos+1]))) then
		self.tipDic[pos+1]:removeFromParent(true)
		self.tipDic[pos+1] = nil
	end
end
function FollowerProcessor:showBetterTip(pos)
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
		self.equippanel:addChild(node,10)
		self.tipDic[pos+1] = node
	end
end
function FollowerProcessor:updateNotice(oldData,oldGodData,newData,newGodData)
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
		changeNum = newData[v] - oldData[v]
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
	local godcfg
	local hasShow = {}
	local curNum
	local oldNum
	local resNum
	for k,v in pairs(oldGodData) do
		if(not hasShow[k]) then
			hasShow[k] = true
			godcfg = DataConfig:getGodCfg(k)
			curNum = newGodData[k] or 0
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
	for k,v in pairs(newGodData) do
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
--初始化UI显示
-- arg  预留 没用
function FollowerProcessor:initUI(arg)
	if self.view ~= nil then
		return
	end

	self.attrDic = {}
	self.followerHeads = {}
	self.itemDic = {}
	self.skillArray = {}

	local view = ResourceManager:widgetFromJsonFile("ui/follower.json")

	local btnSkill = view:getChildByName("btnSkill")   --佣兵技能
	local btnFoster = view:getChildByName("btnFoster")   --培养
	self.btnHaveOut = view:getChildByName("btnHaveOut")  --已出站
	self.followerList = view:getChildByName("followerList")
	self.followerList:setBounceEnabled(false)
	self.nameTxt = view:getChildByName("nameTxt")
	self.nameTxt:enableOutline(cc.c4b(0,0,0,255),2)
	self.equippanel = view:getChildByName("equippanel")
	--self.equipTxtBg = self.equippanel:getChildByName("equipTxtBg")
	--self.equipTxt = self.equippanel:getChildByName("equipTxt")
	self.equipinnerbg = self.equippanel:getChildByName("equipinnerbg")
	
	self.skillpanel = view:getChildByName("skillpanel")
	--self.skillTxtBg = self.skillpanel:getChildByName("skillTxtBg")
	--self.skillTxt = self.skillpanel:getChildByName("skillTxt")
	self.skillinnerbg = self.skillpanel:getChildByName("skillinnerbg")
	
	self.imgbg = view:getChildByName("imgbg")
	self.moreAttrBtn = view:getChildByName("moreAttrBtn")


	self.attrDic["strr"] = view:getChildByName("liDaoTxt")
	self.attrDic["agi"] = view:getChildByName("shenFaTxt")
	self.attrDic["intt"] = view:getChildByName("neiJinTxt")
	self.attrDic["sta"] = view:getChildByName("tiZhiTxt")
	self.attrDic["dam"] = view:getChildByName("shangHaiTxt")
	self.attrDic["arm"] = view:getChildByName("jinGuTxt")
	self.attrDic["adf"] = view:getChildByName("neiFangTxt")
	self.attrDic["deff"] = view:getChildByName("waiFangTxt")
	self.attrDic["hit"] = view:getChildByName("mingZhongTxt")
	self.attrDic["dod"] = view:getChildByName("shanBiTxt")
	self.attrDic["cri"] = view:getChildByName("huiXinTxt")
	self.attrDic["hp"] = view:getChildByName("hpTxt")
	self.attrDic["mp"] = view:getChildByName("mpTxt")
	self.attrDic["power"] = view:getChildByName("powerTxt")

	btnFoster:addTouchEventListener(handler(self,self.onFollowerBtnClick))
	btnSkill:addTouchEventListener(handler(self,self.onFollowerBtnClick))
	self.btnHaveOut:addTouchEventListener(handler(self,self.onFollowerBtnClick))
	self.moreAttrBtn:addTouchEventListener(handler(self,self.onFollowerBtnClick))

	enableBtnOutLine(btnFoster,COMMON_BUTTONS.BLUE_BUTTON)
	enableBtnOutLine(btnSkill,COMMON_BUTTONS.BLUE_BUTTON)
	enableBtnOutLine(self.btnHaveOut,COMMON_BUTTONS.BLUE_BUTTON)
	enableBtnOutLine(self.moreAttrBtn,COMMON_BUTTONS.BLUE_BUTTON)

	local theight = 766
	self.det = display.height - 960
	if display.height > 960 then
		theight = theight + self.det
	end
	local size = view:getLayoutSize()
	view:setContentSize(cc.size(size.width,theight))
	size = self.imgbg:getLayoutSize()
	self.imgbg:setContentSize(cc.size(size.width,size.height + self.det))
	
	size = self.equippanel:getLayoutSize()
	local equippanelH = size.height + self.det/2
	self.equippanel:setContentSize(cc.size(size.width,equippanelH))
	size = self.skillpanel:getLayoutSize()
	local skillpanelH = size.height + self.det/2
	self.skillpanel:setContentSize(cc.size(size.width,skillpanelH))

	self.equipPoses = {}
	local tempX
	local tempY
	for i,v in ipairs(self.equips) do
		item = ItemFace.new()
		item.defaultimg = "ui/icon_18.png"
		item.showInfo = false --禁用鼠标事件
		item:setData()
		item:setAnchorPoint(0.5,0.5)
		--item:setScale(0.8)
		tempX = (i-2.5)*120 + 302
		tempY = equippanelH/2 - 8
		item:setPosition(tempX,self.equipinnerbg:getPositionY())
		self.equipPoses[v+1] = {tempX,tempY}
		item:setName(tostring(self.equipType[i]))
		self.equippanel:addChild(item,5)
		self.itemDic[v+1] = item
		item:setTouchEnabled(true)
		item:addTouchEventListener(handler(self,self.onEquipItemClick))
	end
	local skillnode
	local blank
	local bg
	local posx 
	local posy
	for i=1,4 do
		skillnode = display.newNode()
		posx = (i-2.5)*120 + 302
		posy = self.skillinnerbg:getPositionY()
		skillnode:setPosition(posx,posy)
		self.skillpanel:addChild(skillnode,5)
		bg = display.newSprite("ui/rankiconbg.png")
		bg:setPosition(posx,posy)
		self.skillpanel:addChild(bg)
		blank = ccui.ImageView:create("ui/90001.png")
		skillnode:addChild(blank,2,2)
		table.insert(self.skillArray,skillnode)	
	end

	self:addMidView(view,true)
	self:setView(view)
end
--按钮点击
function FollowerProcessor:onFollowerBtnClick(sender,eventType)
	if  eventType ~= TouchEventType.ended then
		return
	end
	local btn = tolua.cast(sender,"ccui.Button")
	local btnName = btn:getName()
	if btnName == "btnFoster" then
		if self.curFollower ~= nil then
			-- print("进来培养了")
			local node = display.newNode()
			node.curFollowerId = self.curFollower
			--dump(self.curFollower)
	        Observer.sendNotification(FollowerModule.SHOW_FOLLOWER_FOSTER,node)
		end
	elseif btnName == "btnHaveOut" then
		local net = {}
		net.method = FollowerModule.USER_CHANGE_FO_ACTION
		net.params = {}
		net.params.fid = self.curFollower
		Net.sendhttp(net)
	elseif btnName == "btnSkill" then
		local limit = DataConfig:getFollowerReSkillLv()
		if PlayerData:getLv() < limit then
			local btns = {{text = "确定",skin = 3,}}
			local alert = GameAlert.new()
			local richStr = {{text = "弟子技能",color = COLOR_RED},
							{text = " 角色等级"..limit.."级开启",color = COLOR_GREEN},}
			alert:pop(richStr,"ui/titlenotice.png",btns)
			return
		end
		local node = display.newNode()
		node.id = self.curFollower
		Observer.sendNotification(FollowerModule.SHOW_FOLLOWER_SKILL,node)
	elseif btnName == "moreAttrBtn" then
		self:showMoreAttr()
	end
end
function FollowerProcessor:showMoreAttr()	
	local fdata = PlayerData:getSoliderByID(self.curFollower)
	local btns = {{text = "确定",skin = 3}}
	local alert = GameAlert.new()
	local richStr = {
		{text = "Lv."..PlayerData.data.lv.." "..fdata.name.." ["..PlayerType[tonumber(fdata.hero_type)].."]\n",color = cc.c3b(0,198,255)},
		{text = "战力："..fdata.attrs.power.."\n",color = cc.c3b(255,205,30)},
		{text = "属性：总属性值".."Lv."..PlayerData.data.lv.."(对"..PlayerData.data.lv.."级玩家的效果)\n",color = cc.c3b(175,137,174)},
		
		
		{text = "            \n",color = cc.c3b(0,0,0)},		
		{text = "基础属性：\n",color = cc.c3b(255,255,255),size = 25},


		{text = "力道：",color = cc.c3b(175,137,174)},
		{text = fdata.attrs.strr,color = cc.c3b(64,227,0)},
		{text = "[外防",color = cc.c3b(175,137,174)},
		{text = "+"..math.round(fdata.attrs.strr*fdata.special_train.strr+PlayerData:calcBaseAttributesDeff(fdata.attrs.strr)),color = cc.c3b(64,227,0)},
		{text = " 命中",color = cc.c3b(175,137,174)},
		{text = "+"..math.round(PlayerData:calcBaseAttributesHit(fdata.attrs.strr)),color = cc.c3b(64,227,0)},
		{text = "]\n",color = cc.c3b(175,137,174)},

		{text = "身法：",color = cc.c3b(175,137,174)},
		{text = fdata.attrs.agi,color = cc.c3b(64,227,0)},
		{text = "[会心",color = cc.c3b(175,137,174)},
		{text = "+"..math.round(PlayerData:calcBaseAttributesCri(fdata.attrs.agi)+fdata.attrs.agi*fdata.special_train.agi),color = cc.c3b(64,227,0)},
		{text = " 闪避",color = cc.c3b(175,137,174)},
		{text = "+"..math.round(PlayerData:calcBaseAttributesDod(fdata.attrs.agi)),color = cc.c3b(64,227,0)},
		{text = "]\n",color = cc.c3b(175,137,174)},
 
		{text = "内劲：",color = cc.c3b(175,137,174)},
		{text = fdata.attrs.intt,color = cc.c3b(64,227,0)},
		{text = "[内防",color = cc.c3b(175,137,174)},
		{text = "+"..math.round(fdata.attrs.intt*fdata.special_train.intt+PlayerData:calcBaseAttributesAdf(fdata.attrs.intt)),color = cc.c3b(64,227,0)},
		{text = " 每回合魔法恢复",color = cc.c3b(175,137,174)},
		{text = "+"..math.round(PlayerData:calcBaseAttributesMps(fdata.attrs.intt)),color = cc.c3b(64,227,0)},
		{text = "]\n",color = cc.c3b(175,137,174)},

		{text = "体质：",color = cc.c3b(175,137,174)},
		{text = fdata.attrs.sta,color = cc.c3b(64,227,0)},
		{text = "[气血",color = cc.c3b(175,137,174)},
		{text = "+"..math.round(PlayerData:calcBaseAttributesHp(fdata.attrs.sta) + fdata.attrs.sta*fdata.special_train.sta),color = cc.c3b(64,227,0)},
		{text = " 招架",color = cc.c3b(175,137,174)},
		{text = "+"..math.round(PlayerData:calcBaseAttributesRes(fdata.attrs.sta)),color = cc.c3b(64,227,0)},
		{text = "]\n",color = cc.c3b(175,137,174)},

		{text = "气血：",color = cc.c3b(175,137,174)},
		{text = fdata.attrs.hp.."\n",color = cc.c3b(64,227,0)},

		{text = "内力：",color = cc.c3b(175,137,174)},
		{text = fdata.attrs.mp.."\n",color = cc.c3b(64,227,0)},


		{text = "            \n",color = cc.c3b(0,0,0)},		
		{text = "战斗属性：\n",color = cc.c3b(255,255,255),size = 25},


		{text = "最小伤害：",color = cc.c3b(175,137,174)},
		{text = fdata.attrs.minDmg.."\n",color = cc.c3b(64,227,0)},

		{text = "最大伤害：",color = cc.c3b(175,137,174)},
		{text = fdata.attrs.maxDmg.."\n",color = cc.c3b(64,227,0)},

		{text = "筋骨：",color = cc.c3b(175,137,174)},
		{text = fdata.attrs.arm,color = cc.c3b(64,227,0)},
		{text = "[减少",color = cc.c3b(175,137,174)},
		{text = checkint(PlayerData:calcBaseAttributesShowArmRate(fdata.attrs.arm,PlayerData:getLv())*100).."%" ,color = cc.c3b(64,227,0)},
		{text = "受到的伤害]\n",color = cc.c3b(175,137,174)},

		{text = "外防：",color = cc.c3b(175,137,174)},
		{text = fdata.attrs.deff,color = cc.c3b(64,227,0)},
		{text = "[减少受到的外功伤害]\n",color = cc.c3b(175,137,174)},

		{text = "内防：",color = cc.c3b(175,137,174)},
		{text = fdata.attrs.adf,color = cc.c3b(64,227,0)},
		{text = "[减少受到的内功伤害]\n",color = cc.c3b(175,137,174)},

		{text = "会心：",color = cc.c3b(175,137,174)},
		{text = fdata.attrs.cri,color = cc.c3b(64,227,0)},
		{text = "[有",color = cc.c3b(175,137,174)},
		{text = checkint(PlayerData:calcBaseAttributesShowCriRate(fdata.attrs.cri,PlayerData.data.lv)*100).."%" ,color = cc.c3b(64,227,0)},
		{text = "的概率造成",color = cc.c3b(175,137,174)},
		{text = checkint(fdata.attrs.crd*100).."%" ,color = cc.c3b(64,227,0)},
		{text = "会心一击]\n",color = cc.c3b(175,137,174)},

		{text = "命中：",color = cc.c3b(175,137,174)},
		{text = fdata.attrs.hit,color = cc.c3b(64,227,0)},
		{text = "[提高攻击命中率]\n",color = cc.c3b(175,137,174)},

		{text = "闪避：",color = cc.c3b(175,137,174)},
		{text = fdata.attrs.dod,color = cc.c3b(64,227,0)},
		{text = "[提高闪避攻击的概率]\n",color = cc.c3b(175,137,174)},

		{text = "招架：",color = cc.c3b(175,137,174)},
		{text = fdata.attrs.res,color = cc.c3b(64,227,0)},
		{text = "[降低被会心的概率]\n",color = cc.c3b(175,137,174)},


		{text = "            \n",color = cc.c3b(0,0,0)},		
		{text = "神器属性：\n",color = cc.c3b(255,255,255),size = 25},
	}
	local addMa
	local jobInfo = DataConfig:getJobById(""..fdata.hero_type)
	addMa = {
		{text = " 最小伤害",color = cc.c3b(175,137,174)},
		{text = "+"..math.round(PlayerData:calcBaseAttributesMinDmg(fdata.hero_type,fdata.attrs[jobInfo.ma])),color = cc.c3b(64,227,0)},
		{text = " 最大伤害",color = cc.c3b(175,137,174)},
		{text = "+"..math.round(PlayerData:calcBaseAttributesMaxDmg(fdata.hero_type,fdata.attrs[jobInfo.ma])),color = cc.c3b(64,227,0)},
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
	local godInfo = fdata.godInfo
	local godcfg
	local godname
	for k,v in pairs(godInfo) do
		godcfg = DataConfig:getGodCfg(k)
		if("ignore_armor" == k or "ignore_deff" == k or "ignore_adf" == k) then
			godname = godcfg.name .. " +"..v			
			table.insert(richStr, {text = godname.."(忽视敌人"..(math.floor(100*v/(v + 100))).."%的护甲)\n",color = cc.c3b(255,38,38)})
		else
			godname = godcfg.name .. " +"..v*100 .."%"
			table.insert(richStr, {text = godname.."\n",color = cc.c3b(255,38,38)})
		end
		
	end
	alert:pop(richStr,"ui/moreattrtxt.png",btns)
end
--设置数据
function FollowerProcessor:setData(data)
	self.followerList:removeAllChildren()
	self.followerHeads = {}
	local followers = PlayerData:getAllSoliders()
	local job
	local followerHead
	local w = 180
	local rowPadding = 10
	local num = table.nums(followers)
	local fdata
	local unlockseq = DataConfig.data.cfg.system_simple.follower.unlock_fo_lv
	local scrollWidth = self.followerList:getContentSize().width
	local beginx = (scrollWidth - rowPadding*(#unlockseq - 1)-w*(#unlockseq))/2
	for i,v in ipairs(unlockseq) do
		fdata = {}
		fdata.job = v[2]
		fdata.lv = v[1]
		followerHead = FollowerheadNew.new()
		if(PlayerData:getLv() >= v[1]) then
			fdata.lock = false
			for kk,vv in pairs(followers) do
				if(tonumber(vv.hero_type) == tonumber(v[2])) then
					fdata.followerID = kk
					break
				end
			end
			followerHead:setTouchEnabled(true)
			followerHead:addTouchEventListener(handler(self,self.onClickHead)) 
		else
			fdata.lock = true
			followerHead:setTouchEnabled(false)
		end
		followerHead:setData(fdata)
		followerHead:setPosition(beginx + (i-1)*(w+rowPadding), 0)		
		self.followerList:addChild(followerHead)
		table.insert(self.followerHeads,followerHead)
	end
	if(table.nums(followers) > 0) then
		self.curFollower = self.followerHeads[1].data.followerID
	else
		self.curFollower = nil
	end 
	if(self.curFollower) then
		self:updateShow()
	end
end
function FollowerProcessor:updateBtnState()
	if(self.curFollower) then
		if(PlayerData:getOnworkSolider() == self.curFollower) then
			self.btnHaveOut:setTitleText("已出战")
			self.btnHaveOut:loadTextureNormal("ui/combtnyellow.png")
			enableBtnOutLine(self.btnHaveOut,COMMON_BUTTONS.ORANGE_BUTTON)

		else
			enableBtnOutLine(self.btnHaveOut,COMMON_BUTTONS.BLUE_BUTTON)
			self.btnHaveOut:setTitleText("休息中")
			self.btnHaveOut:loadTextureNormal("ui/combtnblue.png")			
		end
	end
end
function FollowerProcessor:updateAttrs()
	if(self.curFollower) then
		local followerData = PlayerData:getSoliderByID(self.curFollower)
		for k,v in pairs(self.attrDic) do
			if(k == "dam") then
				v:setString(followerData.attrs["minDmg"].."-"..followerData.attrs["maxDmg"])
			else
				v:setString(followerData.attrs[k])
			end
		end
		for k,v in pairs(self.followerHeads) do
			if(self.curFollower == v.data.followerID) then
				v:setSelected(true)
			else
				v:setSelected(false)
			end
		end
		self.nameTxt:setString("Lv."..PlayerData:getLv().." "..followerData.name)

		self.attrDic["dam"]:setTextColor(cc.c4b(0, 255, 0, 255))

		self.attrDic["strr"]:setTextColor(cc.c4b(255, 255, 255, 255))
		self.attrDic["agi"]:setTextColor(cc.c4b(255, 255, 255, 255))
		self.attrDic["intt"]:setTextColor(cc.c4b(255, 255, 255, 255))

		if followerData.hero_type == "1" then
			self.attrDic["intt"]:setTextColor(cc.c4b(0, 255, 0, 255))
		elseif followerData.hero_type == "2" then
			self.attrDic["strr"]:setTextColor(cc.c4b(0, 255, 0, 255))
		elseif followerData.hero_type == "3" then
			self.attrDic["agi"]:setTextColor(cc.c4b(0, 255, 0, 255))
		end
	end
end
function FollowerProcessor:updateEquips()
	if(self.curFollower) then
		local followerData = PlayerData:getSoliderByID(self.curFollower)
		local equipPos
		local equipdata
		for k,v in pairs(self.itemDic) do
			v:setData()
		end
		for k,v in pairs(followerData.as_equips) do
			if(v ~= "") then
				equipdata = Bag:getEquipById(v)
				equipPos = tonumber(string.sub(equipdata.eid,3,3))
				self.itemDic[equipPos+1]:setData(equipdata)
			end
		end
	end
end
function FollowerProcessor:updateSkills()
	if(self.curFollower) then
		local followerData = PlayerData:getSoliderByID(self.curFollower)
		local tempSkillImage
		local tempSkillID
		for i=1,4 do
			if(followerData.skills[i]) then
				tempSkillID = followerData.skills[i].sid
				tempSkillImage = self.skillArray[i]:getChildByTag(1)
				if(not tempSkillImage) then
					tempSkillImage = ccui.ImageView:create()
					tempSkillImage:loadTexture("skillicon/"..tempSkillID..".png")
					self.skillArray[i]:addChild(tempSkillImage,1,1)
				else
					local imgstr = "skillicon/"..tempSkillID..".png"
					tempSkillImage:loadTexture(imgstr)
				end
				self.skillArray[i]:setVisible(true)
			else
				--self.skillArray[i]:removeChildByTag(1)
				self.skillArray[i]:setVisible(false)
			end
		end
	end
end
function FollowerProcessor:updateShow()
	self:updateAttrs()
	self:updateEquips()
	self:updateSkills()
	self:updateBtnState()

	for i,v in ipairs(self.equips) do
		self:hideBetterTip(v)
	end	
	self.tipDic = {}
	self:updateBetterTip()
end
function FollowerProcessor:onClickHead(sender,eventType)
	if  eventType ~= TouchEventType.ended then 
		return
	end
	print("点击弟子的ID=",sender.data.followerID)
	if(sender.data.followerID == self.curFollower) then
		return
	end
	self.curFollower = sender.data.followerID
	self:updateShow()
end
--装备格子点击
--根据装备格子的位置和当前弟子的职业，筛选数据
--
function FollowerProcessor:onEquipItemClick(sender,eventType)
	if  eventType ~= TouchEventType.ended then
		return
	end
	print(self.curFollower)
	local followerData = PlayerData:getSoliderByID(self.curFollower)
	local hero_type = followerData.hero_type
	local quip_pos = sender:getName()
	local pType = tonumber(PlayerData:getSoliderByID(self.curFollower).hero_type)
	Bag.followerEquipNotice[pType][tonumber(quip_pos)+1] = false
	Observer.sendNotification(BagModule.NOTICE_BETTER_EQUIP)
	print("quip_pos:"..quip_pos.." hero_type:"..hero_type)

	---如果没有装备  弹出选择装备的界面
	---如果有装备 弹出装备详情界面
	local node = display.newNode()
	node.data = sender.data
	node.user = "FollowerProcessor"
	node.callback = handler(self,self.onSelectEquipCallBack)
	node.type = "button" --单选类型 条子上显示按钮
	node.params = {tonumber(hero_type),tonumber(quip_pos)}
	if node.data == nil then
		Observer.sendNotification(BagModule.SHOW_COMMON_EQUIP_SELECT, node)
	else
		Observer.sendNotification(BagModule.SHOW_EQUIP_INFO, node)
	end
end

function FollowerProcessor:onSelectEquipCallBack(data)
	PopLayer:clearPopLayer()
	local followerData = PlayerData:getSoliderByID(self.curFollower)
	local hero_type = followerData.hero_type

	if(data.pos == "bag") then
		local itemJob = tonumber(string.sub(data.eid,2,2))	
		local playerJob = tonumber(hero_type)

		print("itemJob:"..itemJob)
		print("playerJob:"..playerJob)
		if(itemJob~=3 and (itemJob+1) ~= playerJob) then
			toastNotice("职业不符，不能装备",COLOR_RED)
			return
		end
	end


	local pos = tonumber(string.sub(data.eid,3,3))
	print("pos"..pos)
	--这是个顺序的位置
	local temp = clone(followerData.as_equips)
	if data.pos == "follower" then
		--卸下
		temp[self:getEquipPos(pos)] = ""
	else
		temp[self:getEquipPos(pos)] = data.sid	
	end
	-- followerData.as_equips[self:getEquipPos(pos)] = data.sid
	-- data.pos = "follower"
	-- item:setData(data)
	--发送换装消息
	local net = {}
	net.method = FollowerModule.USER_FOLLOWER_EQUIP_DRESS
	net.params = {}
	net.params.fid = self.curFollower
	net.params.data = clone(temp)
	Net.sendhttp(net)
end

--更新弟子属性数据
function FollowerProcessor:updateSolider(data)
	local soliders = PlayerData:getAllSoliders()
	local sid = data.params.fid
	--先把旧的弟子的装备位置 改为bag
	local so = soliders[sid]
	local eq = nil
	for k,v in pairs(so.as_equips) do
		if v ~= ""  then
			eq = Bag:getEquipById(v)
			eq.pos = "bag"
		end
	end
	soliders[sid] = data.data
	PlayerData:updateSoliderAttrsByID(sid)
	self:updateAttrs()
	self:updateEquips()

	so = soliders[sid]
	local eq = nil
	for k,v in pairs(so.as_equips) do
		if v ~= "" then
			eq = Bag:getEquipById(v)
			eq.pos = "follower"
		end
	end
end

--根据装备的穿着位置，获取位于数组的索引
function FollowerProcessor:getEquipPos(index)
	for k,v in pairs(self.equips) do
		if v == index then
			return k
		end
	end
end

--处理装备属性变化
function FollowerProcessor:handleEquipChange(equips)
	local followerData = PlayerData:getAllSoliders()

	for g,h in pairs(followerData) do
		for k,v in pairs(equips) do
			for j,l in pairs(h.as_equips) do
				if l == v then
					PlayerData:updateSoliderAttrsByID(self.curFollower)
					if not self.isshow then
						return
					end
					self:updateAttrs()
					self:updateEquips()
					return
				end
			end
		end
	end
end

return FollowerProcessor