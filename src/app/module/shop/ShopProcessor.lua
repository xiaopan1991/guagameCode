--商店处理器
require("framework.scheduler")
local ShopProcessor = class("ShopProcessor", BaseProcessor)
local GoodsItem = import(".ui.GoodsItem")
--构造
function ShopProcessor:ctor()
	-- body
	self.name = "ShopProcessor"
	self.curShopType = "shop"    --shop  gold_shop  vip_shop
	
end

--关心的消息列表
function ShopProcessor:ListNotification()
	return {
		ShopModule.SHOW_SHOP,				--显示商店界面
		ShopModule.SHOP_INFO,  				--获取商店信息
		ShopModule.USER_SHOP_BUY_EQUIPS,	--购买商品
		ShopModule.USER_SHOP_REFRESH, 		--刷新商品
		ShopModule.USER_SHOP_BUY_GOLD,
		IndexModule.MONEY_UPDATE,         --时时更新银两
		ShopModule.SHOW_BUY_GOODS
	}
end

--消息处理
--notify 	消息名
--data 		数据
function ShopProcessor:handleNotification(notify, data)
	if notify == ShopModule.SHOW_SHOP then 
		if data ~= nil and data.data ~= nil and data.data.type ~= nil then
			self.curShopType = data.data.type
		else
			self.curShopType = "shop"
		end

		self:initUI()
		self:setData()

	elseif notify == ShopModule.SHOP_INFO then
		self:handleShopData(data.data) --
	elseif notify == ShopModule.USER_SHOP_BUY_EQUIPS then
		self:handleBuyQuip(data.data)  --购买返回
	elseif notify == ShopModule.USER_SHOP_REFRESH then
		self:handleRefresh(data.data)
	elseif notify == ShopModule.USER_SHOP_BUY_GOLD then
		self:handleBuyGold(data.data)
	elseif notify == IndexModule.MONEY_UPDATE then
		self:onUpdataGold()
	elseif notify == ShopModule.SHOW_BUY_GOODS then
		self:handleExterBuy(data.data)
	end
end

--初始化UI
function ShopProcessor:initUI()
	if self.view ~= nil then
		return
	end
	--设置大小做适配
	local view = ResourceManager:widgetFromJsonFile("ui/shopmain.json")
	self:setView(view)

	local theight = 744
	self.det = display.height - 960
	if display.height > 960 then
		theight = 744 + self.det
	end
	local size = view:getLayoutSize()
	view:setContentSize(cc.size(size.width,theight))


	local btndijing = view:getChildByName("btndijing")
	local btngold = view:getChildByName("btngold")
	
	enableBtnOutLine(btngold,COMMON_BUTTONS.TAB_BUTTON)
	enableBtnOutLine(btndijing,COMMON_BUTTONS.TAB_BUTTON)

	self.btndijing = btndijing
	self.btngold = btngold
	-- local btnvip = view:getChildByName("btnvip")
	local imgbg = view:getChildByName("imgbg")

	-- if PlayerData:getVipLv() == 0 then
	-- 	btnvip:setEnabled(false)
	-- end

	self.tabs = {btndijing,btngold}
	btndijing:addTouchEventListener(handler(self,self.onTabClick))
	btngold:addTouchEventListener(handler(self,self.onTabClick))
	-- btnvip:addTouchEventListener(handler(self,self.onTabClick))

	--地精商店 界面控件
	local djview = ResourceManager:widgetFromJsonFile("ui/shopdijing.json")
	djview:retain()
	self.goodslist = djview:getChildByName("goodslist")--商品列表
	local btnBuyAll = djview:getChildByName("btnBuyAll")--全部购买
	local btnRefresh = djview:getChildByName("btnRefresh") --刷新
	local infoluck = djview:getChildByName("infoluck")
	local noticeDi = djview:getChildByName("noticeDi")
	local cfg = DataConfig:getAllConfigMsg()
	local str = addArgsToMsg(cfg["20051"])
	local strDi = addArgsToMsg(cfg["20052"])
	infoluck:setString(str)
	noticeDi:setString(strDi)
	self.txtluck = djview:getChildByName("txtluck")      --幸运值
	self.txtluck:setString("")
	self.bgin = djview:getChildByName("bgin") 
	btnRefresh:addTouchEventListener(handler(self,self.onBtnClick))
	btnBuyAll:addTouchEventListener(handler(self,self.onBtnClick))

	enableBtnOutLine(btnRefresh,COMMON_BUTTONS.BLUE_BUTTON)
	enableBtnOutLine(btnBuyAll,COMMON_BUTTONS.BLUE_BUTTON)


	local relarg = ccui.RelativeLayoutParameter:create()
	relarg:setAlign(ccui.RelativeAlign.alignParentTopLeft)
	local margin = {}
	margin.top = 126
	margin.left = 0
	relarg:setMargin(margin)
	--大背景
	local bgsize = imgbg:getContentSize()
	imgbg:setContentSize(cc.size(bgsize.width,bgsize.height + self.det))

	local size = djview:getContentSize()
	djview:setContentSize(cc.size(size.width,size.height + self.det))

	local sizel = self.goodslist:getContentSize()
	self.goodslist:setContentSize(cc.size(sizel.width,sizel.height + self.det))

	local sizein = self.bgin:getContentSize()
	self.bgin:setContentSize(cc.size(sizein.width,sizein.height + self.det))		

	djview:setLayoutParameter(tolua.cast(relarg,"ccui.LayoutParameter"))
	self.djview = djview
	view:addChild(djview)
	
	self:tabIndex(1)
	self:addMidView(view,true)
end

--刷新列表数据显示
function ShopProcessor:setData()
	--银两商店特殊处理
	if self.curShopType == "gold_shop" then
		self:setGoldShopData()
		return
	end

	if self.goldview ~= nil and self.goldview:getParent()~=nil then
		-- self.goldview:retain()
		self.view:removeChild(self.goldview)
	end

	if self.djview:getParent() == nil then
		self.view:addChild(self.djview)
	end

	local shopdata = PlayerData:getShopData()
	if shopdata == nil or #shopdata==0 or #shopdata ~= DataConfig:getGoodsNumInShopByVIPLv() then
		local net = {}	
		net.method = ShopModule.SHOP_INFO
		net.params = {}
		Net.sendhttp(net)
		return
	end
	self.times = PlayerData:getShopBuyCount()
	--to do  GameInstance.uiLayer:stopTouch()
	
	local leftPadding = 3
	local rowPadding = 12
	local colPadding = 12
	local colNum = 3

	local w = 173
	local h = 202
	--数据长度
	if shopdata ~= nil then
		local tlen = table.nums(shopdata)
		--滚动条宽度
		local innerWidth = self.goodslist:getInnerContainerSize().width
		--设置滚动条内容区域大小
		self.goodslist:setInnerContainerSize(cc.size(innerWidth,math.ceil(tlen/colNum) * (h+colPadding)))
		self.goodslist:removeAllChildren()
		--内容高度
		local innerHeight = self.goodslist:getInnerContainerSize().height
		--y起始坐标
		local ystart = innerHeight - h
		--render
		local addItem = nil
		--序号
		local index = 0
		--数据表的key 用来排序
		local keys = table.keys(shopdata)
		table.sort(keys)
		--组织数据
		for k,v in pairs(shopdata) do
			addItem = GoodsItem.new()
			addItem.showname = true
			local it = addItem
			--异步 塞数据
			local handle = scheduler.performWithDelayGlobal(function() it:setData(v) end, 0.01 * index)

			addItem:setPosition((index % colNum) * (w + colPadding)+ leftPadding , ystart - math.modf(index/colNum) * (h + rowPadding))
			index = index + 1
			addItem:addEventListener(GoodsItem.BUY_CLICK, handler(self,self.onItemClick))
			self.goodslist:addChild(addItem)
		end
	end
	
	local vip = DataConfig:getVIPCfg()
	local vipLv = PlayerData:getVipLv()
	--计算:幸运值=初始值+购买增加量+VIP等级增量
	--购买增加量=ROUNDUP(20*EXP(-0.065)*(1-(EXP(-0.065*(购买次数+玩家VIP等级)))/(1-EXP(-0.065))),0)
	local addPay = 0
	-- local timeValue = {}
	-- if self.times == 0 then
	-- 	timeValue = 0
	-- else
	-- 	timeValue = self.times + vipLv
	-- end
	-- local xi = (-0.065) * timeValue
	-- local exb = math.exp(xi)
	local eb = math.exp(-0.065)
	local ebv = math.pow(eb,vipLv)
	local ebt = math.pow(eb,self.times)
	local num = ebv *(1 - ebt)/(1 - eb)
	addPay = math.ceil(20 * num)
	
	--初始值，VIP等级增量
	local vipValue = DataConfig:getLuckValue()
	
	for i=0,vipLv do
		local dexstr = tostring(i)
		vipValue = vipValue + vip[dexstr].add_luck
	end
	--vipValue = vipValue*100 
	local luckValue =  addPay + vipValue
	self.txtluck:setString(luckValue.."%")
end

--购买按钮点击
function ShopProcessor:onItemClick(event)
	--购买商品
	print("购买商品")
	local data = event.data

	if data.sell_type == "coin" then
		--元宝
		self.costCoin = data.price
		self.costGold = 0
		if data.price > PlayerData:getCoin() then
			--notice("元宝不足！")
			self:onNoticeCoin()
			return
		end
	else
		--银两gold
		self.costGold = data.price
		self.costCoin = 0
		if data.price > PlayerData:getGold() then
			toastNotice("银两不足！")
			return
		end
	end

	if data.is_sell == false then

		local net = {}
		net.method = ShopModule.USER_SHOP_BUY_EQUIPS
		net.params = {}
		net.params.indexs = {data.index}
		net.params.shop_type = self.curShopType
		Net.sendhttp(net)
	else 
		toastNotice("此道具已售出！")
	end
end

--全部购买 刷新按钮点击 btnBuyAll btnRefresh
function ShopProcessor:onBtnClick(sender,eventType)
	if  eventType ~= TouchEventType.ended then 
		return
	end
	local btn = tolua.cast(sender,"ccui.Button")
	local btnName = btn:getName()

	print("touch toolbar btn:"..btnName)

	if btnName == "btnBuyAll" then
		btns = {{text = "取消",skin = 2},{text = "确定",skin = 1,callback = handler(self,self.buyAll)}}
		alert = GameAlert.new()
		richStr = {{text = "是否确认全部购买",color = display.COLOR_WHITE}}
		alert:pop(richStr,"ui/titlenotice.png",btns)
		--self:buyAll()
	elseif btnName == "btnRefresh" then
		self:refresh()
	end
end

--购买全部
function ShopProcessor:buyAll()
	local shopdata = PlayerData:getShopData(self.curShopType)
	if #shopdata == 0 then
		toastNotice("无可购买商品!")
		return
	end
	local costCoin = 0
	local costGold = 0
	local index = {}
	for k,v in pairs(shopdata) do
		if v.is_sell == false then
			index[#index+1] = k - 1  --服务器数组是以0开始 lua数组以1开始
			if v.sell_type == "coin" then
				costCoin = costCoin + v.price
			else
				costGold = costGold + v.price
			end
		end
	end

	if costCoin > PlayerData:getCoin() then
		--notice("元宝不足！")
		self:onNoticeCoin()
		return
	end

	if costGold > PlayerData:getGold() then
		toastNotice("银两不足！")
		return
	end

	self.costCoin = costCoin
	self.costGold = costGold

	if #index > 0 then
		local net = {}
		net.method = ShopModule.USER_SHOP_BUY_EQUIPS
		net.params = {}
		net.params.shop_type = self.curShopType
		net.params.indexs = index
		Net.sendhttp(net)
	end
end

--刷新按钮点击
function ShopProcessor:refresh()
	if self.curShopType ~= "shop" then 
		return
	end
	
	local price = 0
	if self.curShopType == "shop" then
		price = DataConfig:getRefreshShopCost()
	end
	
	if price > PlayerData:getCoin() then
		--notice("元宝不足！")
		self:onNoticeCoin()
		return
	end
	self.refreshprice = price
	if price > 0 then
		local btns = {{text = "取消",skin = 2},{text = "确定",skin = 1,callback = handler(self,self.sendRefresh)},}
		local alert = GameAlert.new()
		alert:pop({{text = "刷新商店需要"..price.."元宝，确定继续吗？"}},"ui/titlenotice.png",btns)
	elseif price == 0 then
		self:sendRefresh()
	end
end


function ShopProcessor:sendRefresh()
	local net = {}
	net.method = ShopModule.USER_SHOP_REFRESH
	net.params = {}
	Net.sendhttp(net)
end

--T处理可刷新次数 和刷新价格
--处理刷新商店数据
function ShopProcessor:handleRefresh(data)
	--dump(data)
	local cost = PlayerData:getCoin() - data.data.coin
	local notices = {{"刷新成功！",COLOR_GREEN}}
	if self.refreshprice~= nil and self.refreshprice ~= 0 then
		table.insert(notices,{"元宝-"..self.refreshprice})
	end
	popNotices(notices)
	PlayerData:setShopRefreshCount(data.data.shop_refresh_count)
	
	
	PlayerData:setCoin(data.data.coin)    --元宝
	PlayerData:setShopData(data.data.shop_info)
	self:setData()
end

--商店道具列表返回
function ShopProcessor:handleShopData(data)
	-- dump(data,nil,999)
	--数据存起来
	PlayerData:setShopData(data.data.shop_info)
	--普通商店
	self:setData()
end

--购买返回
function ShopProcessor:handleBuyQuip(data)
	-- body
	self.times = data.data.shop_buy_count
	PlayerData:setShopBuyCount(self.times)
	--重置商品数据
	PlayerData:setShopData(data.data.shop_info,data.params.shop_type)

	local costcoin = self.costCoin
	local costgold = self.costGold

	PlayerData:setCoin(data.data.coin)    --元宝
	PlayerData:setGold(data.data.gold)    --银两
	local notices = {}
	--这里要区分道具和装备
	if data.data.new_bag_dict ~= nil then
		for k,v in pairs(data.data.new_bag_dict) do
			if string.sub(k,1,1) == "e" then
				Bag:addEquip(k, v)
				local c3 = Bag:getEquipColor(v.color[1])
				table.insert(notices, {"获得装备："..v.edata.name,c3})
			else -- I 是物品
				--这里的v是数量
				Bag:addGoods(k, v)
				local gdata = DataConfig:getGoodByID(k)
				table.insert(notices, {"获得道具："..gdata.name,COLOR_GREEN})
			end
		end
		Observer.sendNotification(BagModule.UPDATE_EQUIP_ATTR)
	end

	if costcoin > 0 then
		table.insert(notices, {"花费元宝：-"..costcoin})
	end
	if costgold > 0 then
		table.insert(notices, {"花费银两：-"..costgold})
	end
	popNotices(notices)
	self:setData()
end

--TAB按钮点击
function ShopProcessor:onTabClick(sender, eventType)
	if  eventType ~= TouchEventType.ended then 
		return
	end
	local btn = tolua.cast(sender,"ccui.Button")
	local btnName = btn:getName()

	-- print("touch toolbar btn:"..btnName)
	if btnName == "btndijing" then
		if self.curShopType == "shop" then
			return
		end
		self.curShopType = "shop"
		self:tabIndex(1)
	elseif btnName == "btngold" then
		if self.curShopType == "gold_shop" then
			return
		end
		self.curShopType = "gold_shop"
		self:tabIndex(2)
	end
	--刷新数据
	self:setData()
end

--高亮某个按钮
function ShopProcessor:tabIndex(index)
	for k,v in pairs(self.tabs) do
		if k == index then
			v:setBright(true)
		else
			v:setBright(false)
		end
	end
	if index == 1 then
		self.btndijing:setTitleColor(cc.c3b(255,255,255))
		self.btngold:setTitleColor(cc.c3b(255,245,135))
	else
		self.btngold:setTitleColor(cc.c3b(255,255,255))
		self.btndijing:setTitleColor(cc.c3b(255,245,135))
	end
end

--设置银两商城数据
function ShopProcessor:setGoldShopData()
	if self.goldview == nil then
		self.goldview = ResourceManager:widgetFromJsonFile("ui/shopgold.json") 
		self.g_txtInfo = self.goldview:getChildByName("txtInfo")
		self.g_txtGold = self.goldview:getChildByName("txtGold")
		self.g_txtCoin = self.goldview:getChildByName("txtCoin")
		self.g_txtCount = self.goldview:getChildByName("txtCount")
		self.g_btnBuyAll = self.goldview:getChildByName("btnBuyAll")
		self.g_btnBuy = self.goldview:getChildByName("btnBuy")
		self.g_bgin = self.goldview:getChildByName("bgin")
		-- self.g_bgout = self.goldview:getChildByName("bgout")
		self.g_img = self.goldview:getChildByName("img")
		self.goldview:retain()
		self.g_btnBuyAll:addTouchEventListener(handler(self,self.onGoldShopBtnClick))
		self.g_btnBuy:addTouchEventListener(handler(self,self.onGoldShopBtnClick))

		local msg = self.goldview:getChildByName("msg")
		local cfg = DataConfig:getAllConfigMsg()
		local str = addArgsToMsg(cfg["20050"])
		msg:setString(str)

		self.txtcurrgold = self.goldview:getChildByName("txtcurrgold")
		self.txtcurrCoin = self.goldview:getChildByName("txtcurrCoin")
		self.txtcurrgold:setString("")
		self.txtcurrCoin:setString("")

		local relarg = ccui.RelativeLayoutParameter:create()
		relarg:setAlign(ccui.RelativeAlign.alignParentTopLeft)
		local margin = {}
		margin.top = 126
		margin.left = 0
		relarg:setMargin(margin)

		self.goldview:setLayoutParameter(tolua.cast(relarg,"ccui.LayoutParameter"))

		local size = self.goldview:getContentSize()
		self.goldview:setContentSize(cc.size(size.width,size.height + self.det))

		local sizein = self.g_bgin:getContentSize()
		self.g_bgin:setContentSize(cc.size(sizein.width,sizein.height + self.det))

		-- local sizeout = self.g_bgout:getContentSize()
		-- self.g_bgout:setContentSize(cc.size(sizeout.width,sizeout.height + self.det))

		-- local px,py = self.g_img:getMargin()
		-- self.g_img:setPosition(px,py+self.det/2)
		
		local relargimg = ccui.RelativeLayoutParameter:create()
		relargimg:setAlign(ccui.RelativeAlign.alignParentTopCenterHorizontal)
		local marginimg = {}
		marginimg.top = 171 + self.det/2
		marginimg.left = 0
		relargimg:setMargin(marginimg)
		self.g_img:setLayoutParameter(tolua.cast(relargimg,"ccui.LayoutParameter"))		
	end




	if self.djview ~= nil and self.djview:getParent()~=nil then
		-- self.djview:retain()
		self.view:removeChild(self.djview)
	end

	if self.goldview:getParent() == nil then
		self.view:addChild(self.goldview)

	end
	-- self.goldview

	--设置各种显示
	local cfg = DataConfig:getGoldShopCfg()
	local coin = cfg.coin --价格
	local coefficient = cfg.coefficient --公式参数
	local count_limit = DataConfig:getVIPCfg()
	local count = coefficient[1]*PlayerData:getLv() + coefficient[2] --每次购买的银两数量
	local cfg = DataConfig:getAllConfigMsg()
	local str = addArgsToMsg(cfg["30083"],PlayerData:getVipLv(),count_limit[tostring(PlayerData:getVipLv())].gold_count)
	self.g_txtInfo:setString(str)
	self.g_txtGold:setString("银两："..count)
	self.g_txtCoin:setString("元宝："..coin)
	self.yinliangnum = count
	self.yuanbaonum = coin
	self.g_txtCount:setString("剩余购买次数："..count_limit[tostring(PlayerData:getVipLv())].gold_count - PlayerData:getShopGoldCount())


	self:onUpdataGold()
	self.txtcurrCoin:setString("元宝："..PlayerData:getCoin())
end
function ShopProcessor:onUpdataGold()
	if self.goldview == nil then 
    	return
  	end
	self.txtcurrgold:setString("当前银两："..PlayerData:getGold())
end
--银两商店按钮点击
function ShopProcessor:onGoldShopBtnClick(sender,eventType)
	if eventType ~= TouchEventType.ended then
		return
	end

	local cfg = DataConfig:getGoldShopCfg() 

	local btnName = sender:getName()
	local count_limit = DataConfig:getVIPCfg() --VIP等级对应购买次数
	local price = cfg.coin -- 单次购买价格
	self.price = price
	local countbuy = count_limit[tostring(PlayerData:getVipLv())].gold_count --可以购买的次数
	self.countbuy = countbuy
	if PlayerData:getShopGoldCount() == countbuy then
		toastNotice("今天的购买次数已经用尽！")
		return
	end

	
	self.buynum = 0
	if btnName =="btnBuyAll" then
		btns = {{text = "取消",skin = 2},{text = "确定",skin = 1,callback = handler(self,self.GoldbuyAll)}}
		alert = GameAlert.new()
		richStr = {{text = "是否确认全部购买",color = display.COLOR_WHITE}}
		alert:pop(richStr,"ui/titlenotice.png",btns)
	elseif btnName == "btnBuy" then
		self.buynum = 1
		self:onSendGoldbuy()
	end

end
----购买银两 发送
function ShopProcessor:onSendGoldbuy()
	if self.price * self.buynum > PlayerData:getCoin() then
		--notice("元宝不足！")
		self:onNoticeCoin()
		return
	end
	
	local net = {}
	net.method = ShopModule.USER_SHOP_BUY_GOLD
	net.params = {}
	net.params.num = self.buynum
	Net.sendhttp(net)
end
--购买金币，全部购买
function ShopProcessor:GoldbuyAll()
	self.buynum = self.countbuy - PlayerData:getShopGoldCount()
	self:onSendGoldbuy()
end
--元宝不足提示框
function ShopProcessor:onNoticeCoin()
	btns = {{text = "取消",skin = 2},{text = "充值",skin = 1,callback = handler(self,self.sendChargeView)}}
	alert = GameAlert.new()
	richStr = {{text = "您的元宝不足，请您及时充值！",color = display.COLOR_WHITE}}
	alert:pop(richStr,"ui/titlenotice.png",btns)
end
--前去充值
function ShopProcessor:sendChargeView()
	Observer.sendNotification(ChargeModule.SHOW_CHARGE_VIEW)
end
--处理购买银两返回
function ShopProcessor:handleBuyGold(data)
	--dump(data,"购买银两返回",999)
	local coin = data.data.coin
	local gold = data.data.gold
	local shop_gold_count = data.data.shop_gold_count
	PlayerData:setShopGoldCount(shop_gold_count)
	PlayerData:setGold(gold)
	PlayerData:setCoin(coin)
	local notices = {}
	table.insert(notices, {"获得银两："..self.yinliangnum * self.buynum,COLOR_GREEN})
	table.insert(notices, {"花费元宝：-"..self.yuanbaonum * self.buynum})
	popNotices(notices)
-- 		"data": {
--         "coin": 660, 
--         "shop_gold_count": 4, 
--         "gold": 592000
--     }, 
	
	-- dump(data)

	-- local cfg = DataConfigManager:getGoldShopCfg()
	local cfg = DataConfig:getGoldShopCfg()
	local coin2 = cfg.coin --价格
	local coefficient = cfg.coefficient --公式参数
	local count_limit = DataConfig:getVIPCfg()
	local count = coefficient[1]*PlayerData:getLv() + coefficient[2] --每次购买的银两数量
	self.g_txtInfo:setString("您当前的等级是VIP"..PlayerData:getVipLv().."，每天可以购买"..count_limit[tostring(PlayerData:getVipLv())].gold_count.."次")
	self.g_txtGold:setString("银两："..count)
	self.g_txtCoin:setString("元宝："..coin2)
	self.yinliangnum = count
	self.yuanbaonum = coin2
	self.g_txtCount:setString("剩余购买次数："..count_limit[tostring(PlayerData:getVipLv())].gold_count - PlayerData:getShopGoldCount())

	self.txtcurrCoin:setString("元宝："..PlayerData:getCoin())
end

function ShopProcessor:handleExterBuy(data)
	local event = {}
	event.data = data
	self:onItemClick(event)
end


--移除绑定的窗口view
function ShopProcessor:onHideView(view)
	if self.djview ~= nil then
		self.djview:release()
		self.djview = nil
	end

	if self.goldview ~= nil then
		self.goldview:release()
		self.goldview = nil
	end

	if self.view ~= nil then
		self.view:removeFromParent(true)
		self.view = nil
	end
end


return ShopProcessor