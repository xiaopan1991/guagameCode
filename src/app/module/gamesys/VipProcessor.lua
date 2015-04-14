local VipProcessor = class("VipProcessor", BaseProcessor)
local XRichText = require("app.components.XRichText")

function VipProcessor:ctor()
end

function VipProcessor:ListNotification()
	return {
		GamesysModule.SHOW_VIP_VIEW
	
	}
end

function VipProcessor:handleNotification(notify, data)
	print("notify", notify)
	if notify == GamesysModule.SHOW_VIP_VIEW then
		--显示VIP界面
		self:onSetView()
	end
		--dump(data.data)
		self:onSetData()
end

function VipProcessor:onSetView()
	if self.view ~= nil then
		return
	end
 	local vippanel = ResourceManager:widgetFromJsonFile("ui/vippanel.json")
 	self.panel = vippanel
 	vippanel:setTouchEnabled(false)
 	self.vipview =vippanel
 	self.imaTxt = vippanel:getChildByName("imaTxt")
 	self.txtinfo = vippanel:getChildByName("txtinfo")             --再充值提示
 	self.txtinfo:setVisible(false)
 	self.vipBar = vippanel:getChildByName("vipProgressBar")       --进度条
 	self.vipBar:setPercent(0)

 	local vipIma1_r = ccui.RelativeLayoutParameter:create()
	vipIma1_r:setAlign(ccui.RelativeAlign.alignParentTopLeft)
	vipIma1_r:setMargin({left=72, top=175})

 	local vipIma1 = ccui.ImageView:create("ui/vipimage/vip.png")
	-- vipIma1:setPosition(98,580)
	vipIma1:setLayoutParameter(tolua.cast(vipIma1_r,"ccui.LayoutParameter"))
	vippanel:addChild(vipIma1)

	local vipIma2_r = ccui.RelativeLayoutParameter:create()
	vipIma2_r:setAlign(ccui.RelativeAlign.alignParentTopLeft)
	vipIma2_r:setMargin({left=496, top=175})

	local vipIma2 = ccui.ImageView:create("ui/vipimage/vip.png")
	-- vipIma2:setPosition(523,580)
	vipIma2:setLayoutParameter(tolua.cast(vipIma2_r,"ccui.LayoutParameter"))
	vippanel:addChild(vipIma2)

	local vipIma3_r = ccui.RelativeLayoutParameter:create()
	vipIma3_r:setAlign(ccui.RelativeAlign.alignParentTopLeft)
	vipIma3_r:setMargin({left=240, top=269})

	local vipIma3 = ccui.ImageView:create("ui/vipimage/vip.png")
	-- vipIma3:setPosition(265,506)
	vipIma3:setLayoutParameter(tolua.cast(vipIma3_r,"ccui.LayoutParameter"))
	vippanel:addChild(vipIma3)

	local btnCharge = vippanel:getChildByName("btnCharge")
	local btnLeft = vippanel:getChildByName("btnLeft")
	local btnRight = vippanel:getChildByName("btnRight")
	local btnClose = vippanel:getChildByName("btnClose")
	enableBtnOutLine(btnCharge,COMMON_BUTTONS.ORANGE_BUTTON)

	-- self.det = display.height - 960
	-- local theight = 766
	-- if display.height > 960 then
	-- 	theight = 766 + self.det
	-- end
	-- local size = vippanel:getLayoutSize()
	-- vippanel:setContentSize(cc.size(size.width,theight))
	-- local bg = vippanel:getChildByName("Imabg")
	-- local bgsize = bg:getLayoutSize()
	-- bg:setContentSize(cc.size(bgsize.width,bgsize.height + self.det))
	
    --按钮点击
	btnCharge:addTouchEventListener(handler(self,self.onbtnClick))
	btnLeft:addTouchEventListener(handler(self,self.onbtnClick))
	btnRight:addTouchEventListener(handler(self,self.onbtnClick))
	btnClose:addTouchEventListener(handler(self,self.onbtnClick))

	self.btnLeft = btnLeft
	self.btnRight = btnRight

	self:addPopView(vippanel)
	self:setView(vippanel)
end
--数据
function VipProcessor:onSetData()
	self.vip = DataConfig:getVIPCfg()
	self.vipLen = table.nums(self.vip)
    --当前vip等级
	self.vipLv = PlayerData:getVipLv()

	self.btnLeft:setVisible(self.vipLv>0)
	self.btnRight:setVisible(self.vipLv<self.vipLen-1)

	-- 头部信息
	local richtext_r = ccui.RelativeLayoutParameter:create()
	richtext_r:setAlign(ccui.RelativeAlign.alignParentTopCenterHorizontal)
	richtext_r:setMargin({top=140})
	
	self.richtext = ccui.RichText:create();
	self.richtext:setLayoutParameter(tolua.cast(richtext_r,"ccui.LayoutParameter"))
	self.panel:addChild(self.richtext)

	local nextVip = {}
	local curVip = {}
	
	if self.vipLv >= self.vipLen-1 then
		--dump("进来了")
		nextVip = tostring(self.vipLv)
		curVip  = tostring(self.vipLv-1)
		--进度显示
		self.vipBar:setPercent(100)
		--提示信息
		self.richtext:pushBackElement(ccui.RichElementText:create(1,display.COLOR_WHITE,255,"当前VIP等级已经达到最大值",DEFAULT_FONT,18));
	else
		nextVip = tostring(self.vipLv+1)
		curVip  = tostring(self.vipLv)

		--进度显示
		local currPay = PlayerData:getTotalPayMoney()
		local totalPay = DataConfig:getVipTotlePay(self.vipLv+1)
		local cha = totalPay - currPay
		local bo = currPay / totalPay * 100
		self.vipBar:setPercent(bo)
		--提示信息 再充值100元宝即可成为VIP3
		self.richtext:pushBackElement(ccui.RichElementText:create(1,display.COLOR_WHITE,255,"再充值",DEFAULT_FONT,18));
		self.richtext:pushBackElement(ccui.RichElementText:create(2,display.COLOR_ORANGE,255,cha.."元",DEFAULT_FONT,18));
		self.richtext:pushBackElement(ccui.RichElementText:create(3,display.COLOR_WHITE,255,"即可成为",DEFAULT_FONT,18));
		self.richtext:pushBackElement(ccui.RichElementText:create(4,COLOR_GREEN,255,"VIP"..nextVip,DEFAULT_FONT,18));

	end
	local vipNum1 = display.newBMFontLabel({
		text = "0",
	    font = "ui/vipimage/yellowfont.fnt",
	    align = cc.TEXT_ALIGNMENT_LEFT,
    })
    vipNum1:setAnchorPoint(0, 0.5)
 	vipNum1:setString(curVip)
	vipNum1:setPosition(115,575)
	self.vipview:addChild(vipNum1)

	local vipNum2 = display.newBMFontLabel({
		text = "0",
	    font = "ui/vipimage/yellowfont.fnt",
	    align = cc.TEXT_ALIGNMENT_LEFT,
    })
    vipNum2:setAnchorPoint(0, 0.5)
	vipNum2:setString(nextVip)
	vipNum2:setPosition(540,575)
	self.vipview:addChild(vipNum2)

	local vipLvIma = display.newBMFontLabel({
		text = "0",
	    font = "ui/vipimage/yellowfont.fnt",
    })

	vipLvIma:setAnchorPoint(0, 0.5)
	vipLvIma:setPosition(285,481.5)
	self.vipview:addChild(vipLvIma)
	self.vipLvIma = vipLvIma

	-- --文字距离textView的间隔
	local textPadY = 20
	local textPadX = 10
	-- --textView距离panel的间隔
	local textViewPadX = 45
    local textViewPadTopY = 31
    local textViewPadBottomY = 120
    --文本宽度
    local txtWidth = 520
    local richTxtWidth = txtWidth - 2*textPadX - 2*textViewPadX

	
	local richtext = XRichText.new()
	richtext:setContentSize(cc.size(600,0))
	local richHeight = textPadY
	local _infoStr = self:onRichtextChange(self.vipLv)
    richtext:appendStrs(_infoStr)
    richtext.text:visit()
	richtext:setAnchorPoint(0.5,0)
	richtext:setPosition(245,richtext.text:getTextSize().height)
	self.richtext = richtext
	local conLayout =  ccui.Layout:create()
	conLayout:setContentSize(cc.size(richTxtWidth,richtext.text:getTextSize().height))
	conLayout:addChild(richtext)

	conLayout:setAnchorPoint(0,1)
	-- conLayout:setPosition(245,460)
	local conLayout_r = ccui.RelativeLayoutParameter:create()
	conLayout_r:setAlign(ccui.RelativeAlign.alignParentTopLeft)
	conLayout_r:setMargin({left=230, top=320})
	conLayout:setLayoutParameter(tolua.cast(conLayout_r,"ccui.LayoutParameter"))

	self.layout = conLayout
	self.vipview:addChild(conLayout)
  
end
--文本的变化
function VipProcessor:onRichtextChange(_dex)
	local dex = tostring(_dex)
	local fightingCount = self.vip[dex].fighting_count
	local challengeBossCount = self.vip[dex].challenge_BOSS_count
	local goldCount = self.vip[dex].gold_count
	local maxDc = self.vip[dex].max_disciple_cultivate
	local addBox = self.vip[dex].add_box
	local addLuck = self.vip[dex].add_luck
	local bossSweep = self.vip[dex].boss_sweep
	self.vipLvIma:setString(dex)
	--计算幸运值
	local luckValue = DataConfig:getLuckValue()
	for i=0,_dex do
		local dexstr = tostring(i)
		luckValue = luckValue + self.vip[dexstr].add_luck
	end
	--luckValue = luckValue*100
	local cfg = DataConfig:getAllConfigMsg()
	local maxDcStr = DataConfig:onFosterVipInfo(maxDc)
	local totalPay = {}
	if _dex ~= 0 then
		totalPay = DataConfig:getVipTotlePay(_dex)
	else
		totalPay = 0
	end

	local cfg = DataConfig:getAllConfigMsg()
	local str2 = addArgsToMsg(cfg["30043"])
	local str3 = addArgsToMsg(cfg["30044"])
	local str4 = addArgsToMsg(cfg["30045"])
	local str5 = addArgsToMsg(cfg["30046"])
	local str6 = addArgsToMsg(cfg["30047"])
	local str7 = addArgsToMsg(cfg["30048"])

	local infoStr = {
        {text = "累计充值",color = cc.c3b(255,255,255)},
        {text = totalPay.."元",color = cc.c3b(255,205,30)},
        {text = "即可享受该特权".."\n",color = cc.c3b(255,255,255)},

        {text = str2,color = cc.c3b(255,255,255)},
        {text = fightingCount.."\n",color = cc.c3b(64,227,0)},

        {text = str3,color = cc.c3b(255,255,255)},
        {text = challengeBossCount.."\n",color = cc.c3b(64,227,0)},

        {text = str4,color = cc.c3b(255,255,255)},
        {text = goldCount.."\n",color = cc.c3b(64,227,0)},

        {text = str5,color = cc.c3b(255,255,255)},
        {text = addBox.."\n",color = cc.c3b(64,227,0)},

        {text = str6,color = cc.c3b(255,255,255)},
        {text = maxDcStr.."\n",color = cc.c3b(64,227,0)},

        {text = str7,color = cc.c3b(255,255,255)},
        {text = luckValue.."%".."\n",color = cc.c3b(64,227,0)},

   }
   if bossSweep == true then
   		local str8 = addArgsToMsg(cfg["20045"])
   		local txt = {text = str8,color = cc.c3b(255,255,255)}
        local txtV = {text = "免费扫荡".."\n",color = cc.c3b(64,227,0)}
   		table.insert(infoStr,txt)
   		table.insert(infoStr,txtV)
   end
   return infoStr
end
--按钮事件的处理
function VipProcessor:onbtnClick(sender,eventType)
	if  eventType ~= TouchEventType.ended then
		return
	end
	local btn = tolua.cast(sender,"ccui.Button")
	local btnName = btn:getName()
	if btnName == "btnCharge" then
		self:removePopView(self.view)
		Observer.sendNotification(GamesysModule.HIDE_PERSON_INFO, nil)
		Observer.sendNotification(ChargeModule.SHOW_CHARGE_VIEW, nil)
	elseif btnName == "btnLeft" then
		self.vipLv = self.vipLv - 1
		if self.vipLv < 0 then
			self.vipLv = 0
			return
		end
		self.richtext:clear()
		local _infoStr = self:onRichtextChange(self.vipLv)
		self.richtext:appendStrs(_infoStr)

		self.btnLeft:setVisible(self.vipLv>0)
		self.btnRight:setVisible(self.vipLv<self.vipLen-1)

	elseif btnName == "btnRight" then
		self.vipLv = self.vipLv + 1
		if self.vipLv >= self.vipLen then
			self.vipLv = self.vipLen
			return
		end
		self.richtext:clear()
		local _infoStr = self:onRichtextChange(self.vipLv)
		self.richtext:appendStrs(_infoStr)

		self.btnLeft:setVisible(self.vipLv>0)
		self.btnRight:setVisible(self.vipLv<self.vipLen-1)
		
	elseif btnName == "btnClose" then	
		self:removePopView(self.view)
	end
end

--移除界面
function VipProcessor:onHideView(view)
	if self.view ~= nill then
		self.view:removeFromParent(true)
		self.conLayout = nil
		self.view = nils
	end
end
return VipProcessor

