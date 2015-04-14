--战斗时人物和怪物显示的头像
local XRichText = import("app.components.XRichText")
local PlayerHeadUI = class("PlayerHeadUI", function()
		local layout = ccui.Layout:create()
		return layout
	end)
function PlayerHeadUI:ctor()
	self.tempEffectList = {}
	if(not PlayerHeadUI.views) then
		local playerView = ResourceManager:widgetFromJsonFile("ui/playerhead.json")
		playerView:retain()
		local soliderView = ResourceManager:widgetFromJsonFile("ui/smallheadui.json")
		soliderView:retain()
		local monsterView = ResourceManager:widgetFromJsonFile("ui/monsterheadui.json")
		monsterView:retain()
		local bossView = ResourceManager:widgetFromJsonFile("ui/bossheadui.json")
		bossView:retain()
		

		PlayerHeadUI.views = {playerView,soliderView,monsterView,bossView,playerView}
	end	
	self.waitingBuffHPMPArray = {}
	self.twokindbuffers = {}
	local twobuffKeys = {'hp','mp','deff','adf','arm','cri','hit','dod','res','crd',
	'dam','cri_rate',}
	for i,v in ipairs(twobuffKeys) do
		self.twokindbuffers[v] = true
	end
	local onebuffkeys = {'reduce_dam','stun','silence','back_dam','magic_shield','suck_blood','resist_debuff','ice_armour',}
	self.onekindbuffers = {}
	for i,v in ipairs(onebuffkeys) do
		self.onekindbuffers[v] = true
	end	
end
function PlayerHeadUI:initHead(player) 
	self.player = player
	local view = PlayerHeadUI.views[player.playerType]:clone()
	local size = view:getLayoutSize()
	self:setContentSize(cc.size(size.width,size.height))

	self.headUI = view:getChildByName("headUI")
	self.imageLayer = self.headUI:getChildByName("imageLayer")
	
	self.hpBar = self.headUI:getChildByName("hpBar")
	self.headPng = self.headUI:getChildByName("headPng")
	self.hpTxt = self.headUI:getChildByName("hpTxt")
	self.nameTxt = self.headUI:getChildByName("nameTxt")
	self.mpBar = self.headUI:getChildByName("mpBar")
	
	--[[if(player.playerType < 3) then
		self.nameTxt:setColor(cc.c3b(255,255,0))
	else
		self.nameTxt:setColor(cc.c3b(255,0,0))
	end]]

	self:addChild(view)
	self.bufferTxt = XRichText.new()
	self.bufferTxt:setContentSize(cc.size(self:getContentSize().width+200,0))
	self.bufferTxt:setAnchorPoint(0.5,1)
	if(player.playerType == PlayerTypeOtherPlayer or player.playerType == PlayerTypeBoss) then
		self.bufferTxt:setPosition(self:getContentSize().width/2+122,7)
	else
		self.bufferTxt:setPosition(self:getContentSize().width/2+100,7)
	end	
	self:addChild(self.bufferTxt)

	self.nameTxt:setColor(cc.c3b(255,255,255))
	if(player.playerType == PlayerTypeSolider or player.playerType == PlayerTypeMonster) then
		self.nameTxt:setFontSize(17)
		self.viewH = self:getContentSize().height + 10
	else
		self.nameTxt:setFontSize(20)
		self.viewH = self:getContentSize().height + 10
	end

	if(player.playerType == PlayerTypeOtherPlayer) then
		self:setFlip(true)
	end
	self:setName(player.playerName,player.lv,player.playerType)
	self:updateHp()	
	self:updateMp()

	self:setHead()
	
end
function PlayerHeadUI:setHead()
	self.headPng:loadTexture(self.player.headImg)
	if(self.player.playerType == PlayerTypeMonster) then
		if(self.headPng:getContentSize().width == 52) then
			self.headPng:setScale(38/52)
		end
	end

end
function PlayerHeadUI:setFlip(bFlipX)
	self.bFlipX = bFlipX
	if(bFlipX) then
		self.headUI:setScaleX(-1)
		self.headUI:setPositionX(self:getContentSize().width)
		self.hpTxt:setScaleX(-1)
		self.nameTxt:setScaleX(-1)
	else
		self.headUI:setScaleX(1)
		self.headUI:setPositionX(0)
		self.hpTxt:setScaleX(1)
		self.nameTxt:setScaleX(1)
	end
end
function PlayerHeadUI:setName(nameStr,lv,ptype)
	local playerType = ptype or PlayerTypePlayer
	self.nameTxt:setString(nameStr.." Lv."..lv)
end
function PlayerHeadUI:updateMp()
	if(self.player.playerType == PlayerTypeBoss or self.player.playerType == PlayerTypeMonster) then
		return
	end
	local showMp = self.player.mp/self.player.maxMP*100
	showMp = math.max(showMp,1)
	self.mpBar:setPercent(showMp)
end
function PlayerHeadUI:updateHp()
	local curHp = self.player.hp
	curHp = math.max(curHp,0)
	maxHp = self.player.maxHP
	self.hpBar:setPercent(math.max(curHp/maxHp*100,0))
	self.hpTxt:setString(curHp.."/"..maxHp)
	--死亡标示
	if(self.deadImg) then
		self.deadImg:removeFromParent(true)
		self.deadImg = nil
	end
	if(curHp <= 0 ) then
		self.deadImg = ccui.ImageView:create("ui/deadsign.png")
		if(self.player.playerType == PlayerTypePlayer 
		or self.player.playerType == PlayerTypeSolider
		or self.player.playerType == PlayerTypeOtherPlayer) then
			self.deadImg:setPosition(self.hpBar:getPositionX()-10,self.hpBar:getPositionY()+3)
		else
			self.deadImg:setPosition(self.hpBar:getPositionX()+10,self.hpBar:getPositionY()+3)
		end
		
		if(self.bFlipX) then
			self.deadImg:setScaleX(-1)
		end
		self.headUI:addChild(self.deadImg)
	end
end
function PlayerHeadUI:lostHp(dam,hit,cri)
	--被击特效
	local headSpr = display.newSprite()
	local hx = self.headPng:getPositionX()
    local hy = self.headPng:getPositionY()

	local tempP = self.headPng:getParent():convertToWorldSpace(cc.p(hx,hy))
	tempP = self:getParent():convertToNodeSpace(tempP)
	headSpr:setPosition(tempP.x,tempP.y)
	self:getParent():addChild(headSpr)
	display.addSpriteFrames("ui/p102.plist","ui/p102.png")
	local frames = display.newFrames("p102_%d.png", 1,5)
	local animation = display.newAnimation(frames, 0.3 / 5) -- 1.0 秒播放 5桢
	headSpr.list = self.tempEffectList
	table.insert(self.tempEffectList,headSpr)
	headSpr:playAnimationOnce(animation,false,handler(headSpr, self.onHitEffectHide))

	--减血/闪避 数字动画
	local lostHpNum = display.newBMFontLabel({text = "",font = "ui/fnt/rednum.fnt",})		
	if(not hit) then
		lostHpNum:setBMFontFilePath("ui/fnt/rednum.fnt")
		lostHpNum:setString("m")
	else
		if(not cri) then
			lostHpNum:setBMFontFilePath("ui/fnt/rednum.fnt")
		else
			lostHpNum:setBMFontFilePath("ui/fnt/crinum.fnt")
		end
		local hpInt = checkint(dam)
		lostHpNum:setString("-"..hpInt)
	end
	self:getParent():addChild(lostHpNum)
	local targetX
	local targetY = self:getPositionY() + 84


	if(self.player.playerType == PlayerTypePlayer) then
		lostHpNum:setPosition(self:getPositionX()+50,self:getPositionY())
		targetX = self:getPositionX()
	elseif(self.player.playerType == PlayerTypeSolider) then
		lostHpNum:setPosition(self:getPositionX()+40,self:getPositionY())
		targetX = self:getPositionX()
	elseif(self.player.playerType == PlayerTypeMonster) then
		lostHpNum:setPosition(self:getPositionX()+144,self:getPositionY())
		targetX = self:getPositionX() + 194
	elseif(self.player.playerType == PlayerTypeBoss) then
		lostHpNum:setPosition(self:getPositionX()+208,self:getPositionY())
		targetX = self:getPositionX()+258
	elseif(self.player.playerType == PlayerTypeOtherPlayer) then
		lostHpNum:setPosition(self:getPositionX()+205,self:getPositionY())
		targetX = self:getPositionX()+255
	end

	lostHpNum.list = self.tempEffectList
	table.insert(self.tempEffectList,lostHpNum)
	lostHpNum:runAction(transition.sequence({
        cc.ScaleTo:create(0.15, 1.5),
        cc.ScaleTo:create(0.1, 1.0),
        cc.Spawn:create(
        	{cc.MoveTo:create(0.5, cc.p(targetX,targetY)),cc.FadeOut:create(0.5)}
        	),
        cc.CallFunc:create(handler(lostHpNum, self.onNumHide))
        }))
	
	
	--hpBar更新
	
	--self:updateHp()
end
function PlayerHeadUI:updateBufferHpMp(bType,num)--hp+mp+反伤buffer影响的头像血蓝动画
	if(not bType) then
		return
	end
	if(#self.waitingBuffHPMPArray == 0) then
		self:playBufferHpMp(bType,num)
	end
	local temp = {bType,num}
	table.insert(self.waitingBuffHPMPArray,temp)
end
function PlayerHeadUI:playBufferHpMp(bType,num)
	if(not bType) then
		self:onNextBuff()
		return 
	end
	local lostNum
	if (bType == "hp") then
		if(num >= 0) then
			lostNum = display.newBMFontLabel({text = "+"..num,
    			font = "ui/fnt/greennum.fnt",})
		else
			lostNum = display.newBMFontLabel({text = ""..num,
    			font = "ui/fnt/rednum.fnt",})
		end
	elseif (bType == "mp") then
		if(num >= 0) then
			lostNum = display.newBMFontLabel({text = "+"..num,
    			font = "ui/fnt/bluenum.fnt",})
		else
			lostNum = display.newBMFontLabel({text = ""..num,
    			font = "ui/fnt/bluenum.fnt",})
		end

	end
	local startX = self:getPositionX() + self:getContentSize().width/2
	local startY = self:getPositionY() + self:getContentSize().height/3
	local endY = self:getPositionY() + self:getContentSize().height
	lostNum:setPosition(startX, startY)
	self:getParent():addChild(lostNum)
	local action1 = cc.Spawn:create(
		{cc.MoveTo:create(0.5, cc.p(startX,endY)),
	    cc.FadeOut:create(0.5)}
	)
	local action2 = transition.sequence({
		cc.DelayTime:create(0.2),
	    cc.CallFunc:create(handler(self, self.onNextBuff)),
	})
	local action = cc.Spawn:create({action1,action2})
	lostNum:runAction(action)
	table.insert(self.tempEffectList,lostNum)
end
function PlayerHeadUI:onNextBuff()
	table.remove(self.waitingBuffHPMPArray,1)
	if(#self.waitingBuffHPMPArray > 0) then		
		self:playBufferHpMp(self.waitingBuffHPMPArray[1][1],self.waitingBuffHPMPArray[1][2])
	end
end
function PlayerHeadUI:updateBufferIcon()--buffer图标
	--buffer标示字符串
	self.bufferTxt:clear()
	local bufferNameCfg = DataConfig:getAllBufferName()	
	local bufferinfo
	local round
	local info ={}
	local fontsize = 20
	if(self.player.playerType == PlayerTypeMonster or self.player.playerType == PlayerTypeSolider ) then
		fontsize = 15
	end
	if(table.nums(self.player.buffList) > 0) then
		table.insert(info,{text = "[",color = cc.c3b(255,255,255),size = fontsize})
		for k,v in pairs(self.player.buffList) do
			for i2,v2 in ipairs(v) do
				round = math.ceil(v2[1]/self.player.battleManager:getAllFighterNum())
				if(self.onekindbuffers[k]) then
					if(k == 'stun' or k == 'silence') then
						buffername = {text = bufferNameCfg[k][1]..round,color = cc.c3b(255,53,53),size = fontsize}
					else
						buffername = {text = bufferNameCfg[k][1]..round,color = cc.c3b(68,220,33),size = fontsize}
					end				
				elseif(self.twokindbuffers[k]) then
					if(v2[2][1] < 0 or v2[2][2] < 0) then
						buffername = {text = bufferNameCfg[k][2]..round,color = cc.c3b(255,53,53),size = fontsize}
					else
						buffername = {text = bufferNameCfg[k][1]..round,color = cc.c3b(68,220,33),size = fontsize}
					end
				end
				table.insert(info,buffername)
			end
		end
		table.insert(info,{text = "]",color = cc.c3b(255,255,255),size = fontsize})
		self.bufferTxt:appendStrs(info)
	end
end
function PlayerHeadUI:onHitEffectHide()
	local eIndex = table.indexof(self.list, self)
	if(eIndex>0) then
		table.remove(self.list,eIndex)
		self:removeFromParent(true)
	end	
end
function PlayerHeadUI:onNumHide()
	local eIndex = table.indexof(self.list, self)
	if(eIndex>0) then
		table.remove(self.list,eIndex)
		self:removeFromParent(true)
	end
end
function PlayerHeadUI:onDeleteMe()	
	for k,v in pairs(self.tempEffectList) do
		v:removeFromParent(true)
	end
	self:removeFromParent(true)
end
return PlayerHeadUI