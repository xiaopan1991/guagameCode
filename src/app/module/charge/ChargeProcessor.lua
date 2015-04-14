--充值处理器
local ChargeProcessor = class("ChargeProcessor", BaseProcessor)
local PayItem = import(".ui.PayItem")
local XRichText = require("app.components.XRichText")

function ChargeProcessor:ctor()
	-- body
	self.head_info_init = false
end

function ChargeProcessor:ListNotification()
	return {
		ChargeModule.SHOW_CHARGE_VIEW,
		ChargeModule.USER_LOCAL_PAY_TEST,
		ChargeModule.USER_GET_COIN 
	}
end

function ChargeProcessor:handleNotification(notify, data)
	if notify == ChargeModule.SHOW_CHARGE_VIEW then
		--显示充值界面
		self:initUI()
		self:setData()
	elseif notify == ChargeModule.USER_LOCAL_PAY_TEST then
		self:handlePayData(data.data)
	elseif notify == ChargeModule.USER_GET_COIN  then
		self:handleCoinData(data.data)
	end

end

function ChargeProcessor:initUI()
	if self.view ~= nil then
		return
	end

 	local panel = ResourceManager:widgetFromJsonFile("ui/chargepanel.json")
 	self.panel = panel
    local theight = 766
	self.det = display.height - 960
	if display.height > 960 then
		theight = 766 + self.det
	end
	local size = panel:getLayoutSize()
	panel:setContentSize(cc.size(size.width,theight))
	local bg = panel:getChildByName("Imabg")
	local bgsize = bg:getLayoutSize()
	bg:setContentSize(cc.size(bgsize.width,bgsize.height + self.det))

	self.txtinfo = panel:getChildByName("txtInfo")             --再充值提示
 	self.txtinfo:setString("")
 	self.txtinfo:setVisible(false)
 	self.vipBar = panel:getChildByName("ProgressBar")          --进度条
 	self.vipBar:setPercent(0) 
 	local bgview = panel:getChildByName("bgview")
 	self.paylist = panel:getChildByName("paylist")
	local btnVipVilege = panel:getChildByName("btnVipVilege")  --vip特权

	local paylistsize = self.paylist:getLayoutSize()
	self.paylist:setContentSize(cc.size(paylistsize.width,paylistsize.height + self.det))
	local bgviewsize = bgview:getLayoutSize()
	bgview:setContentSize(cc.size(bgviewsize.width,bgviewsize.height + self.det))
	
	btnVipVilege:addTouchEventListener(handler(self,self.onBtnClick))
	enableBtnOutLine(btnVipVilege,COMMON_BUTTONS.BLUE_BUTTON)

	-- 头部信息
	local richtext_r = ccui.RelativeLayoutParameter:create()
	richtext_r:setAlign(ccui.RelativeAlign.alignParentTopCenterHorizontal)
	richtext_r:setMargin({top=116})
	self.richtext = ccui.RichText:create();
	self.richtext:setLayoutParameter(tolua.cast(richtext_r,"ccui.LayoutParameter"))
	self.panel:addChild(self.richtext)
	self.richtext:retain()

	-- vip等级数
	local vipNum1_r = ccui.RelativeLayoutParameter:create()
	vipNum1_r:setAlign(ccui.RelativeAlign.alignParentTopLeft)
	vipNum1_r:setMargin({left=120, top=147})

    local vipNum1 = ccui.TextBMFont:create()
	vipNum1:setFntFile("ui/vipimage/yellowfont.fnt")
	vipNum1:setAnchorPoint(0, 0.5)
	vipNum1:setLayoutParameter(tolua.cast(vipNum1_r,"ccui.LayoutParameter"))
	self.panel:addChild(vipNum1)
	self.vipNum1 = vipNum1

	local vipNum2_r = ccui.RelativeLayoutParameter:create()
	vipNum2_r:setAlign(ccui.RelativeAlign.alignParentTopLeft)
	vipNum2_r:setMargin({left=545, top=147})

	local vipNum2 = ccui.TextBMFont:create()
	vipNum2:setFntFile("ui/vipimage/yellowfont.fnt")
	vipNum2:setAnchorPoint(0, 0.5)
	vipNum2:setLayoutParameter(tolua.cast(vipNum2_r,"ccui.LayoutParameter"))
	self.panel:addChild(vipNum2)
	self.vipNum2 = vipNum2

	self:setView(panel)
	self:addMidView(panel,true)
end
function ChargeProcessor:setData()
	local vip = DataConfig:getVIPCfg()
	local vipLen = table.nums(vip)

    --当前vip等级
	local vipLv = PlayerData:getVipLv()
	local nextVip = {}
	local curVip = {}
	
	if vipLv >= vipLen-1 then
		--dump("进来了")
		nextVip = tostring(vipLv)
		curVip  = tostring(vipLv-1)
		--进度显示
		self.vipBar:setPercent(100)
		--提示信息
		--self.txtinfo:setString("当前VIP等级已经达到最大值")
		self.richtext:clear()
		self.richtext:pushBackElement(ccui.RichElementText:create(5,display.COLOR_WHITE,255,"当前VIP等级已经达到最大值",DEFAULT_FONT,18))
	else
		nextVip = tostring(vipLv+1)
		curVip  = tostring(vipLv)

		--进度显示
		local currPay = PlayerData:getTotalPayMoney()
		local totalPay = DataConfig:getVipTotlePay(vipLv+1)
		local cha = totalPay - currPay
		local bo = currPay / totalPay * 100
		self.vipBar:setPercent(bo)

		--提示信息
		self.richtext:clear()
		self.richtext:pushBackElement(ccui.RichElementText:create(1,display.COLOR_WHITE,255,"再充值",DEFAULT_FONT,18))
		self.richtext:pushBackElement(ccui.RichElementText:create(2,display.COLOR_ORANGE,255,cha.."元",DEFAULT_FONT,18))
		self.richtext:pushBackElement(ccui.RichElementText:create(3,display.COLOR_WHITE,255,"即可成为",DEFAULT_FONT,18))
		self.richtext:pushBackElement(ccui.RichElementText:create(4,COLOR_GREEN,255,"VIP"..nextVip,DEFAULT_FONT,18))
	end
	
	self.vipNum1:setString(curVip)
	self.vipNum2:setString(nextVip)

	--
	local leftPadding = 3
	local rowPadding = 5
	local colPadding = 12
	local colNum = 3

	local w = 173
	local h = 227
	--数据长度
	--测试数据
	local testData = {
		["1"] = 3000,
		["2"] = 500,
		["3"] = 1000,
		["4"] = 100,
		["5"] = 800,
		["6"] = 40,
	}
	local chargeData = DataConfig:getChargeData()
	local payfirst =  PlayerData:getFirstCharge()
	--dump(chargeData)
	local keys = {"coin7","coin9","coin8","coin4","coin2","coin10"}
	self.keys = keys
	if chargeData ~= nil then
		local tlen = table.nums(chargeData)
		--滚动条宽度
		local innerWidth = self.paylist:getInnerContainerSize().width
		--设置滚动条内容区域大小
		self.paylist:setInnerContainerSize(cc.size(innerWidth,math.ceil(tlen/colNum) * (h+colPadding)))
		self.paylist:removeAllChildren()
		--内容高度
		local innerHeight = self.paylist:getInnerContainerSize().height
		--y起始坐标
		local ystart = innerHeight - h - 8
		--render
		local addItem = nil
		--序号
		local index = 0
		--数据表的key 用来排序
		--local keys = table.keys(shopdata)
		--table.sort(keys)
		--组织数据
		-- for k,v in pairs(chargeData) do
		-- 	addItem = PayItem.new()
		-- 	addItem.showname = true
		-- 	local it = addItem
		-- 	--异步 塞数据
		-- 	local handle = scheduler.performWithDelayGlobal(function() it:setData(v) end, 0.01 * index)
		-- 	addItem:setPosition((index % colNum) * (w + colPadding)+ leftPadding , ystart - math.modf(index/colNum) * (h + rowPadding))
		-- 	index = index + 1
		-- 	addItem:addEventListener(PayItem.BUY_CLICK, handler(self,self.onItemClick))
		-- 	self.paylist:addChild(addItem)
		-- end
		for i=1,tlen do
			addItem = PayItem.new()
			addItem.showname = true
			v = chargeData[keys[i]]
			addItem:setData({v,payfirst})
			addItem:setPosition((index % colNum) * (w + colPadding)+ leftPadding , ystart - math.modf(index/colNum) * (h + rowPadding))
			index = index + 1
			addItem:addEventListener(PayItem.BUY_CLICK, handler(self,self.onItemClick))
			self.paylist:addChild(addItem)
		end
	end

end
--按钮事件的处理
function ChargeProcessor:onBtnClick(sender,eventType)
	if  eventType ~= TouchEventType.ended then
		return
	end
	local btn = tolua.cast(sender,"ccui.Button")
	local btnName = btn:getName()
	if btnName == "btnVipVilege" then
		Observer.sendNotification(GamesysModule.SHOW_VIP_VIEW,nil)
	end
end
function ChargeProcessor:onItemClick(event)
	--购买
	--dump(event.data)
	local data =event.data[1]
	local dex = data[3]

	local net = {}
	net.method = ChargeModule.USER_LOCAL_PAY_TEST
	net.params = {}
	net.params.pid = self.keys[dex]
	Net.sendhttp(net)
	
end
--充值返回数据
function ChargeProcessor:handlePayData(data)
	--dump(data)
	local net = {}
	net.method = ChargeModule.USER_GET_COIN
	net.params = {}
	Net.sendhttp(net)
	
end
--充值最终数据返回
function ChargeProcessor:handleCoinData(data)
	--dump(data)
	local coin = data.data.user.coin
	local vipLv = data.data.user.vip_lv
	local pay_first = data.data.user.pay_first
	local totalPayMoney = data.data.user.total_pay_money
	local payFirstGift = data.data.user.pay_first_gift
	local curCoin = PlayerData:getCoin()
	local getCoin = coin - curCoin
	PlayerData:setVipLv(vipLv)
	PlayerData:setCoin(coin)
	PlayerData:setFirstCharge(pay_first)
	PlayerData:setFirstPay(payFirstGift)
	PlayerData:setTotalPayMoney(totalPayMoney)
	popNotices({{"充值成功",COLOR_GREEN},{"获得元宝"..getCoin,COLOR_GREEN},
		{"当前元宝"..coin,COLOR_GREEN},})
	self:setData()
	
end
return ChargeProcessor

