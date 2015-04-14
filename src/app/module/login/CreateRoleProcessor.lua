--创建角色处理器
local CreateRoleProcessor = class("CreateRoleProcessor", BaseProcessor)
local XRichText = import("app.components.XRichText")
local UIEditBox = import("app.components.UIEditBox")
local StrTools = import("app.utils.StrTools")


function CreateRoleProcessor:ctor()
	-- body
end

function CreateRoleProcessor:ListNotification()
	return {
		LoginModule.SHOW_CREAT_ROLE_VIEW,
		LoginModule.USERINIT_USER
	}
end

function CreateRoleProcessor:handleNotification(notify, data)
	if notify == LoginModule.SHOW_CREAT_ROLE_VIEW then
		self:initUI()
		self:setData()
	elseif notify == LoginModule.USERINIT_USER then
		self:handleCreatUserData(data.data)
	end
end

--显示界面
function CreateRoleProcessor:initUI()
	math.randomseed(tostring(os.time()):reverse():sub(1, 6))

	self.cfg = DataConfig:getAllConfigMsg()
	-- role.json
	local view = ResourceManager:widgetFromJsonFile("ui/role.json")
	local imgTitle = view:getChildByName("imgTitle")
	local imgTitleBg = view:getChildByName("imgTitleBg")
	local imaGai = view:getChildByName("imaGai")
	local imaE = view:getChildByName("imaE")
	local imaWu = view:getChildByName("imaWu")
	local role1 = view:getChildByName("role1")
	local role2 = view:getChildByName("role2")
	local role3 = view:getChildByName("role3")
	self.kuang1 = view:getChildByName("kuang1")
	self.kuang2 = view:getChildByName("kuang2")
	self.kuang3 = view:getChildByName("kuang3")
	local info = view:getChildByName("info")
	local boxBg = view:getChildByName("boxBg")
	local btnRandom = view:getChildByName("btnRandom")
	local txtMsg = view:getChildByName("txtMsg")
	local txt = addArgsToMsg(self.cfg["20059"])
	txtMsg:setString(txt)

	self.richtext = XRichText.new()
    self.richtext:setContentSize(cc.size(550,200))
    self.richtext:setPosition(320,220)
    view:addChild(self.richtext,10)

	role1:setTouchEnabled(true)
	role2:setTouchEnabled(true)
	role3:setTouchEnabled(true)
	role1:addTouchEventListener(handler(self,self.onClickRole))
	role2:addTouchEventListener(handler(self,self.onClickRole))
	role3:addTouchEventListener(handler(self,self.onClickRole))
	self.role1 = role1
	self.role2 = role2
	self.role3 = role3
	self.curType = 2   --当前选中的职业
	self:selectRole(self.curType)

	self.btnCreate = view:getChildByName("btnCreate")
	self.btnReturn = view:getChildByName("btnReturn")
	btnRandom:addTouchEventListener(handler(self,self.onRandomClick))
	self.btnCreate:addTouchEventListener(handler(self,self.onCreatClick))
	self.btnReturn:addTouchEventListener(handler(self,self.onReturnClick))

	if display.height > 960 then
		local offsetY = (display.height - 960) / 2
		imgTitle:pos(imgTitle:getPositionX(), imgTitle:getPositionY() + offsetY)
		imgTitleBg:pos(imgTitleBg:getPositionX(), imgTitleBg:getPositionY() + offsetY)
		self.btnReturn:pos(self.btnReturn:getPositionX(), self.btnReturn:getPositionY() - offsetY)
		self.btnCreate:pos(self.btnCreate:getPositionX(), self.btnCreate:getPositionY() - offsetY)
		view:pos(0, offsetY)
	end

	GameInstance.loginScene:addMidView(view)
	--print("创建角色界面")


    
    --local txtName = UIEditBox.new(180,41,"ui/blank.png")
    local txtName = ccui.EditBox:create(cc.size(180, 41), "ui/blank.png")
	txtName:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)
	txtName:setFontSize(26)
	txtName:setFontColor(cc.c3b(255,255,255))
	txtName:setFontName(DEFAULT_FONT)
	txtName:setPosition(328,191)
	txtName:setMaxLength(6)
	-- txtName:setMinLength(2)

	txtName:setPlaceHolder("输入玩家姓名")
	txtName:setPlaceholderFont(DEFAULT_FONT,20)
	txtName:setPlaceholderFontColor(cc.c3b(255,255,255))
	view:addChild(txtName,3)

	self.txtName = txtName
	self:setView(view)

	local key = PlayerData:getUid()..PlayerData:getZone().."firstCreateRole"
	if(cc.UserDefault:getInstance():getIntegerForKey(key,0) == 0) then
		cc.UserDefault:getInstance():setIntegerForKey(key, 1)
		local alert = GameAlert.new()
   		alert:popHelp("newbie_guide_1","ui/titlenotice.png")--挂机介绍
	end
end

function CreateRoleProcessor:setData()
	self:onRichtxtInfo("hero_info_2")
end
function CreateRoleProcessor:onRichtxtInfo(helpid)
	local infodata = DataConfig:getHelpInfoByID(helpid)
	local infoStr = {}
	for k,v in pairs(infodata) do
		--print(v)
		--self.richtext = {text = v.content,color = cc.c3b(v.color[1],v.color[2],v.color[3]),size = v.size,}
		infoStr[#infoStr+1] = {text = v.content,color = cc.c3b(v.color[1],v.color[2],v.color[3]),size = v.size}
    
	end
	self.richtext:appendStrs(infoStr)

end

function CreateRoleProcessor:onClickRole(sender,eventType)
	if  eventType ~= TouchEventType.ended then 
		return
	end
	local btnName = sender:getName()
	self.richtext:clear()
	if btnName == "role1" then
		--print("role1")
		self:selectRole(1)
		self:onRichtxtInfo("hero_info_1")
	elseif btnName == "role2" then
		self:selectRole(2)
		self:onRichtxtInfo("hero_info_2")
		--print("role2")
	elseif btnName == "role3" then
		self:selectRole(3)
		self:onRichtxtInfo("hero_info_3")
		--print("role3")
	end
end

--选择门派
function CreateRoleProcessor:selectRole(index)
	self.curType = index
	if index == 1 then	
		self.role1:setColor(cc.c3b(255, 255, 255))
		self.role2:setColor(cc.c3b(73, 73, 73))
		self.role3:setColor(cc.c3b(73, 73, 73))
		self.kuang3:loadTexture("ui/cardbrightkuang.png")
		self.kuang1:loadTexture("ui/cardkuang.png")
		self.kuang2:loadTexture("ui/cardkuang.png")
	elseif index == 2 then
		self.role1:setColor(cc.c3b(73, 73, 73))
		self.role2:setColor(cc.c3b(255, 255, 255))
		self.role3:setColor(cc.c3b(73, 73, 73))
		self.kuang1:loadTexture("ui/cardbrightkuang.png")
		self.kuang2:loadTexture("ui/cardkuang.png")
		self.kuang3:loadTexture("ui/cardkuang.png")
	elseif index == 3 then
		self.role1:setColor(cc.c3b(73, 73, 73))
		self.role2:setColor(cc.c3b(73, 73, 73))
		self.role3:setColor(cc.c3b(255, 255, 255))
		self.kuang2:loadTexture("ui/cardbrightkuang.png")
		self.kuang1:loadTexture("ui/cardkuang.png")
		self.kuang3:loadTexture("ui/cardkuang.png")
	end
end
--从服务器随机获取名字
function CreateRoleProcessor:onRandomClick(sender,eventType)
	if  eventType ~= TouchEventType.ended then 
		return
	end
	local tname = DataConfig:getRoleRandomName()
    self.txtName:setText(tname)
    --dump(tname)
	
end

--创建按钮click
function CreateRoleProcessor:onCreatClick(sender,eventType)
	if  eventType ~= TouchEventType.ended then 
		return
	end
	local txtName = self.txtName:getText()
	if txtName == "" then
		local str = addArgsToMsg(self.cfg["10195"])
		toastNotice(str)
		return
	end
	--非特殊字符
	local judgeName = StrTools.checkName(txtName) 
	if judgeName == false then
		local str = addArgsToMsg(self.cfg["10190"])
		toastNotice(str)
		return
	end
	-- local len = string.utf8len(txtName)
	-- if len > 6 then
	-- 	self.txtName:setText("")
	-- 	local str = addArgsToMsg(self.cfg["10194"])
	-- 	toastNotice(str)
	-- 	return
	-- end
    local data = {}
	data.method = LoginModule.USERINIT_USER
	data.params = {}
	data.params.hero_type = self.curType
	data.params.name = txtName
	Net.sendhttp(data)
end

--创建结果返回
function CreateRoleProcessor:handleCreatUserData(data)
	--用户创建成功的话return_code == 0 进入主界面
	if data.return_code ~= 0 then
		toastNotice("创建角色失败")
		return
	end
	print("创建角色成功")
	--dump(data,nil,999)
	--成功
	PlayerData:setHeroType(data.params.hero_type)
	PlayerData:setPlayerName(data.params.name)
	--计算玩家属性
	PlayerData:calcAttributes()
	--计算所有佣兵属性
	PlayerData:updateAllSolidersAttrs()

	--从服务器得到当前地图
	Raid:changePlayRaid(data.data.mid)
	--从服务器得到下一幅地图
	Raid:changeNextRaid(data.data.next_mid)	
	--从服务器得到当前最大开放地图
	Raid:changeMaxRaid(data.data.max_mid)
	Raid:changeSaoDangRaid(data.data.beat_mid)


	local nTime = changeTimeStrToSec(data.server_now["$datetime"])
	TimeManager:setSvererTime(nTime)
	local hTime = changeTimeStrToSec(data.data.hang_time["$datetime"])
	BattleManager:initBattleHangTime(hTime)	
	App:enterScene("MainScene")
end

--返回按钮点击
function CreateRoleProcessor:onReturnClick(sender,eventType)
	if  eventType ~= TouchEventType.ended then 
		return
	end
	GameInstance.loginScene.gua:setVisible(true)
	Observer.sendNotification(LoginModule.SHOW_LOGINVIEW)
end

return CreateRoleProcessor