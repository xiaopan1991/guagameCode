--工具条处理器
local ToolbarProcessor = class("ToolbarProcessor", BaseProcessor)

--构造
function ToolbarProcessor:ctor()
	-- body
	self.name = "ToolbarProcessor"
	self.notices = {}
end

--关心的消息列表
function ToolbarProcessor:ListNotification()
	-- body
	return {
		MainSceneModule.SHOW_TOOLBAR,
		BagModule.UPDATE_EQUIP_ATTR,
		BagModule.NOTICE_BETTER_EQUIP,
		BagModule.EQUIP_NUM_UPDATE,
		IndexModule.CHAT_NOTICE,
		IndexModule.REWARD_NOTICE,
		IndexModule.MAIL_NOTICE,
		IndexModule.LEVEL_UPDATE,
	}
end

--消息处理
--notify 	消息名
--data 		数据
function ToolbarProcessor:handleNotification(notify, data)
	if notify == MainSceneModule.SHOW_TOOLBAR then
		self:onSetView(data)
	elseif notify == BagModule.UPDATE_EQUIP_ATTR then
		if(self.view) then
			self:updateBag()
		end
	elseif notify == BagModule.EQUIP_NUM_UPDATE then
		if(self.view) then
			self:updateBag()
		end
	elseif notify == BagModule.NOTICE_BETTER_EQUIP then
		if(self.view) then
			self:updateNoticeTip("equip")
			self:updateNoticeTip("fequip")
		end
	elseif notify == IndexModule.CHAT_NOTICE then
		if self.view then
			self:updateNoticeTip("chat")
		end
	elseif notify == IndexModule.REWARD_NOTICE then
		if self.view then
			if(data.data.rewardNum > 0) then
				self:showNoticeTip("reward")
			else
				self:hideNoticeTip("reward")
			end
		end
	elseif notify == IndexModule.MAIL_NOTICE then
		if self.view then
			if(data.data.mailNum > 0) then
				self:showNoticeTip("mail")
			else
				self:hideNoticeTip("mail")
			end
		end
	elseif notify == IndexModule.LEVEL_UPDATE then
		if self.view then
			self:updateLvNotice()
		end
	end
end

--设置view
function ToolbarProcessor:onSetView(view)
    local toolbar = ResourceManager:widgetFromJsonFile("ui/toolbar.json")

    self:setView(toolbar)
    self:addBottomView(toolbar)

	local btnIndex = toolbar:getChildByName("btnIndex")
    self.btnFight = toolbar:getChildByName("btnFight")
    self.btnEquip = toolbar:getChildByName("btnEquip")
    self.btnBag = toolbar:getChildByName("btnBag")
    self.btnSkill = toolbar:getChildByName("btnSkill")
    self.btnSoldier = toolbar:getChildByName("btnSoldier")
    self.btnSystem = toolbar:getChildByName("btnSystem")
    self.btnChat = toolbar:getChildByName("btnChat")
    self.btnGift = toolbar:getChildByName("btnGift")
    self.btnMail = toolbar:getChildByName("btnMail")
    self.btnGonggao = toolbar:getChildByName("btnGonggao")
    self.btnRank = toolbar:getChildByName("btnRank")
    
    btnIndex:addTouchEventListener(handler(self,self.onToolbarClick))
    self.btnFight:addTouchEventListener(handler(self,self.onToolbarClick))
    self.btnEquip:addTouchEventListener(handler(self,self.onToolbarClick))
    self.btnBag:addTouchEventListener(handler(self,self.onToolbarClick))
   	self.btnSkill:addTouchEventListener(handler(self,self.onToolbarClick))
    self.btnSoldier:addTouchEventListener(handler(self,self.onToolbarClick))
    self.btnSystem:addTouchEventListener(handler(self,self.onToolbarClick))
    self.btnChat:addTouchEventListener(handler(self,self.onToolbarClick))
    self.btnGift:addTouchEventListener(handler(self,self.onToolbarClick))
    self.btnMail:addTouchEventListener(handler(self,self.onToolbarClick))
    self.btnGonggao:addTouchEventListener(handler(self,self.onToolbarClick))
    self.btnRank:addTouchEventListener(handler(self,self.onToolbarClick))
  
    local btns = {self.btnFight,self.btnEquip,self.btnBag,
    self.btnSkill,self.btnSoldier,btnSystem,self.btnChat,self.btnGift,self.btnMail}
    for i,v in ipairs(btns) do
    	v:setPressedActionEnabled(true)
    end
	self.notices = {}
    self:updateBag()
    
	
    self:updateNoticeTip("equip")
    self:updateNoticeTip("fequip")

    local key = PlayerData:getUid()..PlayerData:getZone().."firstBattle"
    if(cc.UserDefault:getInstance():getIntegerForKey(key,0) == 0) then
    	self:showNoticeTip("btnFight")
    end
    local key = PlayerData:getUid()..PlayerData:getZone().."firstSys"
    if(cc.UserDefault:getInstance():getIntegerForKey(key,0) == 0) then
    	self:showNoticeTip("btnSystem")
    	print("btnSystem")
    end
    self:updateLvNotice()
end
function ToolbarProcessor:updateLvNotice()
	if(PlayerData:getLv() >= DataConfig:getUnlockBattleSkillCfg()[1]) then
		local key = PlayerData:getUid()..PlayerData:getZone().."firstSkill"
		if(cc.UserDefault:getInstance():getIntegerForKey(key,0) == 0) then
			self:showNoticeTip("btnSkill")
    		print("000000000000000000000000000000000btnSkill")
		end
	end
	local follower_unlock_fo_lv = GameInstance.config.cfg.system_simple.follower.unlock_fo_lv[1][1]
	if PlayerData:getLv() >= follower_unlock_fo_lv then
		local key = PlayerData:getUid()..PlayerData:getZone().."firstSolider"
		if(cc.UserDefault:getInstance():getIntegerForKey(key,0) == 0) then
			self:showNoticeTip("btnSoldier")
		end
	end
end
--工具条按钮点击
function ToolbarProcessor:onToolbarClick(sender,eventType) 
	-- 触摸完毕再触发事件
	if  eventType ~= TouchEventType.ended then 
		return
	end
	local btn = tolua.cast(sender,"ccui.Button")
	local btnName = btn:getName()

	print("touch toolbar btn:"..btnName)

	if btnName == "btnIndex" then 
		Observer.sendNotification(IndexModule.SHOW_INDEX,nil)
	elseif btnName == "btnFight" then
		--self:testSocket()
		local key = PlayerData:getUid()..PlayerData:getZone().."firstBattle"
		if(cc.UserDefault:getInstance():getIntegerForKey(key,0) == 0) then
			cc.UserDefault:getInstance():setIntegerForKey(key, 1)
			self:hideNoticeTip("btnFight")
			local alert = GameAlert.new()
	   		alert:popHelp("newbie_guide_2","ui/titlenotice.png")
		end 
		BattleManager:battleBtnClick()
	elseif btnName == "btnEquip" then
		Observer.sendNotification(BagModule.OPEN_EQUIP,nil)
		Bag.mainEquipNotice = false				
		local tempNode = display.newNode()
		local data = {}
		tempNode.data = data
		Observer.sendNotification(BagModule.NOTICE_BETTER_EQUIP,tempNode)
	elseif btnName == "btnBag" then
		Observer.sendNotification(BagModule.SHOW_BAG,nil)
	elseif btnName == "btnSkill" then
		if(PlayerData:getLv() >= DataConfig:getUnlockBattleSkillCfg()[1]) then
			local key = PlayerData:getUid()..PlayerData:getZone().."firstSkill"
			if(cc.UserDefault:getInstance():getIntegerForKey(key,0) == 0) then
				cc.UserDefault:getInstance():setIntegerForKey(key, 1)
				self:hideNoticeTip("btnSkill")
				local alert = GameAlert.new()
				alert:popHelp("newbie_guide_6","ui/titlenotice.png")
			end 
			Observer.sendNotification(skillmodule.SHOW_SKILL)
		else
			local content = "技能系统".. DataConfig:getUnlockBattleSkillCfg()[1] .. "级开启"
			local btns = {{text = "确定",skin = 3,}}
			local alert = GameAlert.new()
			alert:pop(content, "ui/titlenotice.png", btns)
		end
	elseif btnName == "btnSoldier" then
		Bag.fEquipNotice = false
		Observer.sendNotification(BagModule.NOTICE_BETTER_EQUIP)
		local follower_unlock_fo_lv = GameInstance.config.cfg.system_simple.follower.unlock_fo_lv[1][1];
		if PlayerData:getLv() < follower_unlock_fo_lv then
			local content = "弟子系统".. follower_unlock_fo_lv .. "级开启"
			local btns = {{text = "确定",skin = 3,}}
			local alert = GameAlert.new()
			alert:pop(content, "ui/titlenotice.png", btns)
		else
			local key = PlayerData:getUid()..PlayerData:getZone().."firstSolider"
			if(cc.UserDefault:getInstance():getIntegerForKey(key,0) == 0) then
				cc.UserDefault:getInstance():setIntegerForKey(key, 1)
				self:hideNoticeTip("btnSoldier")
				local alert = GameAlert.new()
				alert:popHelp("newbie_guide_7","ui/titlenotice.png")
			end 
			Observer.sendNotification(FollowerModule.SHOW_FOLLOWER_VIEW)
		end
	elseif btnName == "btnSystem" then
		local key = PlayerData:getUid()..PlayerData:getZone().."firstSys"
		if(cc.UserDefault:getInstance():getIntegerForKey(key,0) == 0) then
			cc.UserDefault:getInstance():setIntegerForKey(key, 1)
			self:hideNoticeTip("btnSystem")
			local alert = GameAlert.new()
			alert:popHelp("system_prompt","ui/titlenotice.png")
		end
        Observer.sendNotification(GamesysModule.SHOW_GAME_SET,nil)
    elseif btnName == "btnChat" then
    	self:hideNoticeTip("chat")
    	Observer.sendNotification(ChatModule.SHOW_CHAT)
    elseif btnName == "btnGift" then
    	Observer.sendNotification(GamesysModule.SHOW_GAME_TASK,nil)
    elseif btnName == "btnMail" then
    	Observer.sendNotification(GamesysModule.SHOW_GAME_MAIL)
    elseif btnName == "btnGonggao" then
    	local alert = GameAlert.new()
		alert:popNotice()
	elseif btnName == "btnRank" then
    	local net = {}
		net.method =GamesysModule.USER_FIRST_RANK
		net.params = {}
		Net.sendhttp(net)
	end
end


function ToolbarProcessor:testSocket()
	local t = {}
	t.id = 10000
	t.name = "this is a test"
	local str = json.encode(t)
	print(str)
	Net.sendsocket(t)
end

function ToolbarProcessor:updateBag()
	local quips = Bag:getAllEquip(nil,"bag")
	local nowNum = table.nums(quips)
	local maxNum = PlayerData:getBagMax()
	if nowNum >= maxNum then
		--增加满的标志
		self:showNoticeTip("bag")
	else
		--移除满的标志
		self:hideNoticeTip("bag")
	end
end
function ToolbarProcessor:showNoticeTip(tipType)
	if(not self.notices[tipType]) then
		local tempX
		local tempY
		local spr
		local frames
		local animation
		if(tipType == "equip") then
			tempX,tempY = self.btnEquip:getPosition()
			tempX = tempX
			tempY = tempY
		elseif(tipType == "btnFight") then
			tempX,tempY = self.btnFight:getPosition()
			tempX = tempX
			tempY = tempY
		elseif(tipType == "btnSkill") then
			tempX,tempY = self.btnSkill:getPosition()
			tempX = tempX
			tempY = tempY			
		elseif(tipType == "btnSoldier") then
			tempX,tempY = self.btnSoldier:getPosition()
			tempX = tempX - 10
			tempY = tempY
		elseif(tipType == "bag") then
			tempX,tempY = self.btnBag:getPosition()
			tempX = tempX
			tempY = tempY
		elseif(tipType == "chat") then
			tempX,tempY = self.btnChat:getPosition()
			tempX = tempX - 10
			tempY = tempY - 10
		elseif(tipType == "mail") then
			tempX,tempY = self.btnMail:getPosition()
			tempX = tempX - 15
			tempY = tempY - 10
		elseif(tipType == "btnSystem") then
			tempX,tempY = self.btnSystem:getPosition()
			tempX = tempX - 10
			tempY = tempY - 10
		elseif(tipType == "reward") then
			tempX,tempY = self.btnGift:getPosition()
			tempX = tempX - 13
			tempY = tempY - 12
		elseif(tipType == "fequip") then
			tempX,tempY = self.btnSoldier:getPosition()
			tempX = tempX - 10
			tempY = tempY
		end
		if(tipType == "bag") then
			display.addSpriteFrames("ui/man.plist","ui/man.png")
			frames = display.newFrames("man%04d.png", 1,7)
			animation = display.newAnimation(frames, 0.5 / 7) -- 0.5 秒播放 10桢
			spr = display.newSprite()
			spr:playAnimationForever(animation)
		elseif(tipType == "equip" or tipType == "btnFight" 
			or tipType == "btnSkill" or tipType == "btnSoldier" or tipType == "fequip" or tipType == "btnSystem") then

			display.addSpriteFrames("ui/new.plist","ui/new.png")
			frames = display.newFrames("xin%04d.png", 1,7)
			animation = display.newAnimation(frames, 0.5 / 7) -- 0.5 秒播放 10桢
			spr = display.newSprite()
			spr:playAnimationForever(animation)
		else
			spr = display.newSprite("ui/newtip.png")
		end
		
		local node = display.newNode()
		node:addChild(spr)
		node:setPosition(tempX+38,tempY+38)
		self.view:addChild(node,3)
		self.notices[tipType] = node
	end
end
function ToolbarProcessor:hideNoticeTip(tipType)
	if(self.notices[tipType]) then
		self.notices[tipType]:removeFromParent(true)
		self.notices[tipType] = nil
	end
end
function ToolbarProcessor:updateNoticeTip(tipType)
	if(tipType == "equip") then--新装备
		if(Bag.mainEquipNotice) then
			if(GameInstance.mainScene and GameInstance.mainScene.midview and GameInstance.mainScene.midview:getName() ~= "equipui") then
				self:showNoticeTip(tipType)
			end
		else
			self:hideNoticeTip(tipType)
		end
	elseif(tipType == "fequip") then--弟子新装备
		if(Bag.fEquipNotice) then
			if(GameInstance.mainScene and GameInstance.mainScene.midview and GameInstance.mainScene.midview:getName() ~= "followerpanel") then
				self:showNoticeTip(tipType)
			end
		else
			self:hideNoticeTip(tipType)
		end
	elseif(tipType == "chat") then
		self:showNoticeTip(tipType)
	end
end

return ToolbarProcessor
