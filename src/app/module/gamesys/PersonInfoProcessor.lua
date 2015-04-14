local PersonInfoProcessor = class("PersonInfoProcessor", BaseProcessor)
local XRichText = require("app.components.XRichText")
local PlayItem = import(".ui.PlayItem")
local StrTools = import("app.utils.StrTools")
local NameItem = require("app.module.gamesys.ui.NameItem")

function PersonInfoProcessor:ctor()
	-- body
end

function PersonInfoProcessor:ListNotification()
	return {
		GamesysModule.SHOW_PERSON_INFO,
		GamesysModule.USER_CHANGE_SIGNATURE,
		GamesysModule.UPDATE_USER_TITLE,
		GamesysModule.HIDE_PERSON_INFO,
		GamesysModule.USER_CHANGE_NAME
	}
end

function PersonInfoProcessor:handleNotification(notify, data)
	if notify == GamesysModule.SHOW_PERSON_INFO then
		--显示个人信息界面
		-- print("进来了")
		self:onSetView()
		self:onSetData()
	elseif notify == GamesysModule.USER_CHANGE_SIGNATURE then
		self:onChangeSignature(data.data)
	elseif notify == GamesysModule.UPDATE_USER_TITLE then
		self:updateUserTitle()
	elseif notify == GamesysModule.HIDE_PERSON_INFO then
		self:removePopView(self.view)
	elseif notify == GamesysModule.USER_CHANGE_NAME then
		self:handerChangePlayerName(data.data)
	end
end

function PersonInfoProcessor:updateUserTitle()
	local player_title = PlayerData:getTitle()
	-- print("player_title", player_title)
	if player_title == "" then
		self.txtTitleName:setString("无")
		self.txtTitleName:setTextColor(cc.c4b(255, 165, 0, 255))
		return
	end
	local titles = DataConfig:getAllTitles()
	local title = titles[player_title]
	self.txtTitleName:setString(title.name)
	self.txtTitleName:setColor(NameItem.colors[title.color])
end

function PersonInfoProcessor:onSetView()
	if self.view ~= nil then
		return
	end

	self.view = true
	self.cfg = DataConfig:getAllConfigMsg()

 	local perpanel = ResourceManager:widgetFromJsonFile("ui/personinfo.json")
 	self.perview =perpanel
 	self.txtName = perpanel:getChildByName("txtName")            --玩家名字
 	self.txtID = perpanel:getChildByName("txtID")                --ID
 	self.txtTitleName = perpanel:getChildByName("txtTitleName")  --称号
 	self.txtJob = perpanel:getChildByName("txtJob")              --职业
 	self.txtLv = perpanel:getChildByName("txtLv")                --玩家等级
 	self.txtMana = perpanel:getChildByName("txtMana")			 --威望
 	self.txtExperience = perpanel:getChildByName("txtExperience")--经验       
 	self.txtVipLv = perpanel:getChildByName("txtVipLv")          --VIP等级
 	self.txtSign = perpanel:getChildByName("txtSign")


 	self.txtName:setString("")
 	self.txtID:setString("")
 	self.txtTitleName:setString("")
 	self.txtTitleName:setColor(display.COLOR_ORANGE)
 	self.txtJob:setString("")
 	self.txtLv:setString("")
 	self.txtMana:setString("")
 	self.txtExperience:setString("")
 	self.txtVipLv:setString("")

 	local btnChangeName = perpanel:getChildByName("btnChangeName")           --更改昵称
	local btnChangeSign = perpanel:getChildByName("btnChangeSign")           --更换签名
	local btnChangeTitleName = perpanel:getChildByName("btnChangeTitleName") --更换称号
	local btnVip = perpanel:getChildByName("btnVip")                         --VIP详情
	local btnClose = perpanel:getChildByName("btnClose")                     --关闭按钮

	
    --按钮点击
	btnChangeSign:addTouchEventListener(handler(self,self.onbtnClick))
	btnChangeTitleName:addTouchEventListener(handler(self,self.onbtnClick))
	btnVip:addTouchEventListener(handler(self,self.onbtnClick))
	btnClose:addTouchEventListener(handler(self,self.onbtnClick))
	btnChangeName:addTouchEventListener(handler(self,self.onbtnClick))

	enableBtnOutLine(btnChangeName,COMMON_BUTTONS.ORANGE_BUTTON)
	enableBtnOutLine(btnChangeSign,COMMON_BUTTONS.BLUE_BUTTON)
	enableBtnOutLine(btnChangeTitleName,COMMON_BUTTONS.BLUE_BUTTON)
	enableBtnOutLine(btnVip,COMMON_BUTTONS.BLUE_BUTTON)
	

	self:addPopView(perpanel)
	self:setView(perpanel)

end
--数据
function PersonInfoProcessor:onSetData()
	
	local name = PlayerData:getPlayerName()
	self.txtName:setString(name)

	local id = PlayerData:getUid()
	self.txtID:setString("我的ID："..id)

	local player_title = PlayerData:getTitle()
	if string.len(player_title) == 0  then
		self.txtTitleName:setString("无")
		self.txtTitleName:setColor(display.COLOR_ORANGE)
	else
		local titles = DataConfig:getAllTitles()
		local title = titles[player_title]
		self.txtTitleName:setString(title.name)
		self.txtTitleName:setColor(NameItem.colors[title.color])
	end

	local tp = PlayerData:getHeroType()
	local playertp = PlayerType[tp]
	self.txtJob:setString("职业："..playertp)

	local playLv = PlayerData:getLv()
	self.txtLv:setString("等级："..playLv.."级")

	local playMana = PlayerData:getMana()
	self.txtMana:setString("威望："..playMana)

	local curexp = PlayerData:getExp()
	local tolexp = DataConfig:getUpdateExpByLvl(playLv)
	self.txtExperience:setString("经验："..curexp.."/"..tolexp)

   --当前vip等级
	local vipLv = PlayerData:getVipLv()
	self.txtVipLv:setString("VIP等级：VIP"..vipLv)

	local vipIma_r = ccui.RelativeLayoutParameter:create()
	vipIma_r:setAlign(ccui.RelativeAlign.alignParentTopLeft)
	vipIma_r:setMargin({left=82, top=235})

	local vipIma = ccui.ImageView:create("ui/vipimage/vip.png")
	-- vipIma:setPosition(107,520)
	vipIma:setLayoutParameter(tolua.cast(vipIma_r,"ccui.LayoutParameter"))
	self.perview:addChild(vipIma)

	local lvStr = tostring(vipLv)
	local vipNum = display.newBMFontLabel({
		text = "0",
	    font = "ui/vipimage/yellowfont.fnt",
    })
	vipNum:setString(lvStr)
	vipNum:setPosition(142,515)
	self.perview:addChild(vipNum)

	--头像显示
	local playHead_r = ccui.RelativeLayoutParameter:create()
	playHead_r:setAlign(ccui.RelativeAlign.alignParentTopLeft)
	playHead_r:setMargin({left=70, top=135})

	local playHead = {}
	playHead = PlayItem.new()
	playHead:setData(tp)
	-- playHead:setPosition(70,548)
	playHead:setLayoutParameter(tolua.cast(playHead_r,"ccui.LayoutParameter"))
	playHead:setTouchEnabled(false)
	self.perview:addChild(playHead)

	-- 签名
	if PlayerData:getSignature() == "" then
		local str = addArgsToMsg(self.cfg["20044"])
		self.txtSign:setString(str)
	else
		self.txtSign:setString(PlayerData:getSignature())
	end
end
--按钮事件的处理
function PersonInfoProcessor:onbtnClick(sender,eventType)
	if  eventType ~= TouchEventType.ended then
		return
	end
	local btn = tolua.cast(sender,"ccui.Button")
	local btnName = btn:getName()
	if btnName == "btnChangeSign" then
        --local callback = handler(self,self.handleChangeSign)
		local alert = GameInputAlert.new()
		local content = addArgsToMsg(self.cfg["30082"],DataConfig.data.cfg.system_simple.signature_limit)
		local infostrr = addArgsToMsg(self.cfg["20043"])
		alert:popInput(content,"ui/titlesignature.png",PlayerData:getSignature(),infostrr,handler(self,self.handleChangeSign),615,430)
		alert:setMaxLength(DataConfig.data.cfg.system_simple.signature_limit)
	  	-- self:sendChangeSign()
	elseif btnName == "btnChangeTitleName" then
		Observer.sendNotification(GamesysModule.SHOW_CHANGE_TITLE_NAME)
	elseif btnName == "btnVip" then
		Observer.sendNotification(GamesysModule.SHOW_VIP_VIEW,nil)
	elseif btnName == "btnClose" then	
		self:removePopView(self.view)
	elseif btnName == "btnChangeName" then
		local alert = GameInputAlert.new()
		self.needCoin = DataConfig.data.cfg.system_simple.rename
		local content = addArgsToMsg(self.cfg["30080"],self.needCoin)
		local infostr = addArgsToMsg(self.cfg["20040"])
		alert:popInput(content,"ui/titlechangename.png",PlayerData:getPlayerName(),infostr,handler(self,self.handleChangeName),615,405)
		alert:setMaxLength(6)
	end	
end
function PersonInfoProcessor:handleChangeName(txt)
	local judgeName = StrTools.checkName(txt)
	if  judgeName == false then
		 local str = addArgsToMsg(self.cfg["10190"])
		 toastNotice(str)
		return
	end
	self.playName = txt
	if  self.playName == PlayerData:getPlayerName() then
		local str = addArgsToMsg(self.cfg["10196"])
		toastNotice(str)
		return
	else
		local btns = {{text = "取消",skin = 2},{text = "确定",skin = 1,callback = handler(self,self.sendChangeName)}}
		local alert = GameAlert.new()
		local textStr = addArgsToMsg(self.cfg["30081"],self.needCoin)
		alert:pop(textStr,"ui/titlenotice.png",btns)
	end
end
--发送更改昵称
function PersonInfoProcessor:sendChangeName()
	local curCoin = PlayerData:getCoin()
	if curCoin < self.needCoin  then
		self:onNoticeCoin()
		return
	end
	local net = {}
	net.method = GamesysModule.USER_CHANGE_NAME
	net.params = {}
	net.params.name = self.playName
	Net.sendhttp(net)
end
--元宝不足提示框
function PersonInfoProcessor:onNoticeCoin()
	btns = {{text = "取消",skin = 2},{text = "充值",skin = 1,callback = handler(self,self.sendChargeView)}}
	alert = GameAlert.new()
	local str = addArgsToMsg(self.cfg["10189"])
	richStr = {{text = str ,color = display.COLOR_WHITE}}
	alert:pop(richStr,"ui/titlenotice.png",btns)
end
--前去充值
function PersonInfoProcessor:sendChargeView()
	PopLayer:clearPopLayer()
	Observer.sendNotification(ChargeModule.SHOW_CHARGE_VIEW)
end
--更改昵称返回
function PersonInfoProcessor:handerChangePlayerName(data)
	local nowcoin = data.data.coin
	local nowname = data.data.name
	self.txtName:setString(nowname)
	PlayerData:setCoin(nowcoin)
	PlayerData:setPlayerName(nowname)
	
	local str = addArgsToMsg(self.cfg["20042"])
	toastNotice(str,COLOR_GREEN)
	Observer.sendNotification(IndexModule.NAME_UPDATE)
end
--更改签名
function PersonInfoProcessor:handleChangeSign(txt)
	local judgeName = StrTools.checkName(txt)
	if  judgeName == false then
		 local str = addArgsToMsg(self.cfg["10197"])
		 toastNotice(str)
		return
	end
	if txt == "" then
		local str = addArgsToMsg(self.cfg["20044"])
		self.txtSign:setString(str)
	else
		self.txtSign:setString(txt)
	end
	
	local net = {}
	net.method = GamesysModule.USER_CHANGE_SIGNATURE
	net.params = {}
	net.params.sstr = txt
	Net.sendhttp(net)
end
--签名返回
function PersonInfoProcessor:onChangeSignature(data)
	PlayerData:setSignature(data.data)
end

--移除界面
function PersonInfoProcessor:onHideView(view)
	if self.view ~= nill then
		self.view:removeFromParent(true)
		self.view = nil
	end
end
return PersonInfoProcessor

