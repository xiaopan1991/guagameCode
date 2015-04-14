--游戏提示框 通用简单提示框
local XRichText = import(".XRichText")

local GameAlert = class("GameAlert",function()
		local layout =  ccui.Layout:create()
		layout:setContentSize(cc.size(640,960))
		return layout
	end)

function GameAlert:ctor()
	self.view = ResourceManager:widgetFromJsonFile("ui/gamealert.json")
	self:addChild(self.view)

	self.panel = self.view:getChildByName("panel")
	self.txtTitle = self.panel:getChildByName("txtTitle")
	self.titleImg = self.panel:getChildByName("titleImg")
	self.btnClose = self.panel:getChildByName("btnClose")
	self.btnClose:removeFromParent(true)
	self.titleBg = self.panel:getChildByName("Image_3")
	self.textView = self.panel:getChildByName("textView")
	self.midbg	= self.panel:getChildByName("midbg")
end

-- 黄,蓝,蓝
--黄：1.确定按钮 ,或者其他情况的(充值)
--蓝：2.取消按钮
--蓝：3.只有一个确定或取消按钮，
GameAlert.btnskin = {"ui/combtnyellow.png","ui/combtnblue.png","ui/combtnblue.png"}
--最大高度
GameAlert.maxSizeHeight = display.height*2/3
--textView距离panel的间隔
GameAlert.textViewPadX = 25
GameAlert.textViewPadTopY = 25
GameAlert.textViewPadBottomY = 80
--文字距离textView的间隔
GameAlert.textPadX = 20
GameAlert.textPadY = 20


--位置和大小更新
function GameAlert:updatePosition(txtWidth,txtHeight)
	if(txtHeight>GameAlert.maxSizeHeight) then
		self.panel:setContentSize(cc.size(txtWidth,GameAlert.maxSizeHeight))
	else
		self.panel:setContentSize(cc.size(txtWidth,txtHeight))
	end

	local panelSize = self.panel:getContentSize()
	self.panel:setPosition((display.width - panelSize.width)/2,(960 - panelSize.height)/2 + 20)
	self.txtTitle:setPosition(panelSize.width/2,panelSize.height + 25)
	self.titleBg:setPosition(panelSize.width/2,panelSize.height)
	self.titleImg:setPosition(panelSize.width/2,panelSize.height + 23.5)

	local tw = 	panelSize.width - 2*GameAlert.textViewPadX
	local th = panelSize.height - GameAlert.textViewPadTopY - GameAlert.textViewPadBottomY
	local th2 = txtHeight - GameAlert.textViewPadTopY - GameAlert.textViewPadBottomY
	self.textView:setContentSize(cc.size(tw,th))
	self.textView:setInnerContainerSize(cc.size(tw,th2))
	self.textView:setPosition(GameAlert.textViewPadX, GameAlert.textViewPadBottomY)

	self.midbg:setContentSize(cc.size(tw+6,th+6))
	self.midbg:setPosition(GameAlert.textViewPadX + tw/2, GameAlert.textViewPadBottomY + th/2)
end
--显示弹出框
--content 	文本内容 是一个2维table 或者一个string
-- 			table = {{text = "" ,color = xx,size = 20,font = "xx",tag=1}}
--title 	标题
--btns 		按钮及其回调
-- 			btns = {
-- 				{text = "",  skin = 1 , callback = function ,args = ...}
-- 			}
--			skin 1 2 3 对应GameAlert.btnskin里的123
function GameAlert:pop(content,title,btns,txtWidth)
	if(not txtWidth) then
		txtWidth = 615
	end

	local richTxtWidth = txtWidth - 2*GameAlert.textPadX - 2*GameAlert.textViewPadX
	local richtext = XRichText.new()
	self.richtext = richtext
	richtext:setContentSize(cc.size(richTxtWidth,0))
	local richHeight = GameAlert.textPadY
	if type(content) == "string" then
		richtext:appendStr(content,nil,20)
	elseif type(content) == "table" then	
		richtext:appendStrs(content)
	end
	richtext.text:visit()
	local addHeight = richtext.text:getTextSize().height
	if(self.minRichHeight) then
		addHeight = math.max(addHeight,self.minRichHeight)
	end
	richHeight = richHeight + addHeight + GameAlert.textPadY

	local txtHeight = richHeight +  GameAlert.textViewPadTopY + GameAlert.textViewPadBottomY 
	self:updatePosition(txtWidth,txtHeight)
	local posY = richHeight - GameAlert.textPadY

	richtext:setAnchorPoint(0.5,0)
	richtext:setPosition(richTxtWidth/2,addHeight)

	local conLayout =  ccui.Layout:create()
	conLayout:setContentSize(cc.size(richTxtWidth,addHeight))
	conLayout:addChild(richtext)

	--conLayout:

	conLayout:setAnchorPoint(0,1)
	conLayout:setPosition(GameAlert.textPadX,posY)


	self.textView:addChild(conLayout)
	self.textView:jumpToBottom()
	--test begin 

	-- local args = {
	-- 	{"猎人",{255,0,0}},
	-- 	{"杀戮射击",{255,0,0}},
	-- 	{"圣骑士",{255,0,0}},
	-- 	{"100",{255,0,0}},
	-- }

	-- self.richtext:append("s1", args)
	--test end

	local txtSize
	if(string.find(title,".png")) then
		self.txtTitle:setString("")
		self.titleImg:loadTexture(title)
		txtSize= self.titleImg:getContentSize()
	else
		self.txtTitle:setString(title)
		txtSize= self.txtTitle:getContentSize()
		self.titleImg:setVisible(false)
	end
	local titleSize = self.titleBg:getContentSize()
	if(txtSize.width > 120) then
		--self.titleBg:setContentSize(cc.size(titleSize.width + txtSize.width - 110,titleSize.height))
	end

	--self.btnClose:addTouchEventListener(handler(self,self.onCloseClick))
	PopLayer:popView(self)

	--处理按钮
	self.btns = {}
	if btns ~= nil then
		for k,v in pairs(btns) do
			local btn =ccui.Button:create()
			btn:setTouchEnabled(true)
			btn:setTitleText(v.text)
			btn:setTitleFontSize(22)
			btn:setTitleFontName(DEFAULT_FONT)
			--btn:setTitleColor(cc.c3b(255, 246, 194))
			v.skin = v.skin or 3
			btn:loadTextures(GameAlert.btnskin[v.skin], "", "")
			btn:addTouchEventListener(handler(self,self.onBtnClick))
			if(v.skin == 1) then
				enableBtnOutLine(btn,COMMON_BUTTONS.ORANGE_BUTTON)
			else
				enableBtnOutLine(btn,COMMON_BUTTONS.BLUE_BUTTON)
			end
			self.btns[#self.btns + 1] = {btn = btn,callback = v.callback , args = v.args}
			self.panel:addChild(btn)
		end
	end

	if #self.btns == 1 then
		self.btns[1].btn:setPosition(txtWidth/2,47)
	end

	if #self.btns == 2 then 
		self.btns[1].btn:setPosition(txtWidth/3,47)
		self.btns[2].btn:setPosition(txtWidth*2/3,47)
	end
end
--专门用来显示帮助
function GameAlert:popHelp(helpid,title,width)
	local helpdata = DataConfig:getHelpInfoByID(helpid)
	local richStr = {}
	
	if(helpdata) then
		if(helpdata.is_random) then
			local info = helpdata.info[math.random(1,#helpdata.info)]
			for i,v in ipairs(info) do
				richStr[i] = {text = v.content,color = cc.c3b(v.color[1],v.color[2],v.color[3]),size = v.size,}
			end
		else
			if(#helpdata > 0) then
				for i,v in ipairs(helpdata) do
					richStr[i] = {text = v.content,color = cc.c3b(v.color[1],v.color[2],v.color[3]),size = v.size,}
				end
			else
				richStr[1] = {text = "暂无帮助信息,自己玩吧",color = cc.c3b(255,0,0),size = 30,}
			end
		end
	else
		richStr[1] = {text = "暂无帮助信息,自己玩吧",color = cc.c3b(255,0,0),size = 30,}
	end
	local btns = {{text = "确定",skin = 2,}}
	local helptitle = title or "ui/gamehelp.png"
	self:pop(richStr,helptitle,btns,width)
end
--专门用来显示公告
function GameAlert:popNotice()
	self.minRichHeight = GameAlert.maxSizeHeight - (
		GameAlert.textViewPadTopY + GameAlert.textViewPadBottomY + 2*GameAlert.textPadY)
	self:popHelp("game_notice","ui/noticetitletxt.png",555)
	self.titleImg:setPosition(self.titleImg:getPositionX(), self.titleImg:getPositionY()-2)
	self.titleBg:loadTexture("ui/noticetbg.png")
	self.titleBg:setPosition(self.titleBg:getPositionX()-2, self.titleBg:getPositionY()-50)
	--self.titleBg:setContentSize(cc.size(606,151))
	self:setPosition(self:getPositionX(), self:getPositionY()-40)
end
--自定义按钮点击
function GameAlert:onBtnClick(sender,eventType)
	if  eventType ~= TouchEventType.ended then
		return
	end
	for k,v in pairs(self.btns) do
		if v.btn == sender then
			if v.callback ~= nil then
				v.callback(v.args)
			end
			break
		end
	end
	PopLayer:removePopView(self)
end
return GameAlert