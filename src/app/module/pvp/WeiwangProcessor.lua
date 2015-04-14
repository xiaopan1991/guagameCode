-- 威望商店处理器
-- Author: whe
-- Date: 2014-12-15 20:07:50
--
--威望商店
local weiwangitem = import(".ui.weiwangitem")
local WeiwangProcessor = class("WeiwangProcessor", BaseProcessor)

function WeiwangProcessor:ctor()
	-- body
	self.price = 0
end

function WeiwangProcessor:ListNotification()
	return {
		--请求威望商店数据
		PVPModule.USER_MANA_SHOP_INFO,
		--威望商店购买接口
		PVPModule.USER_BUY_MANA_SHOP,
		--威望商店刷新接口
		PVPModule.USER_MANA_SHOP_REFRESH,
		IndexModule.MONEY_UPDATE,
	}
end

function WeiwangProcessor:handleNotification(notify, data)
	if notify == PVPModule.USER_MANA_SHOP_INFO then
		self:handleShopInfo(data.data)
	elseif notify == PVPModule.USER_BUY_MANA_SHOP then
		self:handleBuyData(data.data)		
	elseif notify == PVPModule.USER_MANA_SHOP_REFRESH then
		self:handleRefresh(data.data)	
	elseif notify == IndexModule.MONEY_UPDATE then
		if(self.txtweiwang and (not tolua.isnull(self.txtweiwang))) then
			self.txtweiwang:setString(tostring(PlayerData:getMana()))	
		end
	end
end

--初始化UI显示
-- arg  预留 没用
function WeiwangProcessor:initUI(view)
	self:setView(view)
	--
	local goodslist = view:getChildByName("goodslist")
	local btnRefresh = view:getChildByName("btnRefresh")
	local txtweiwang = view:getChildByName("txtweiwang")
	self.goodslist = goodslist
	self.txtweiwang = txtweiwang
	btnRefresh:addTouchEventListener(handler(self,self.onBtnClick))
		
	--TODO判断下缓存
	local net = {}
	net.method = PVPModule.USER_MANA_SHOP_INFO
	net.params = {}
	Net.sendhttp(net)
end

--按钮点击
function WeiwangProcessor:onBtnClick(sender, eventType) 
	if eventType ~= TouchEventType.ended then
		return
	end 

	local price = DataConfig:getManaRefreshPrice()
	if price > PlayerData:getMana() then
		toastNotice("威望值不足!需要消耗"..price.."点威望")
		return
	end

	local btns = {
		{text = "取消",skin = 2,},
		{text = "确定",skin = 1, callback = handler(self,self.onBtnRefreshOK),args = true},
	}
	local alert = GameAlert.new()
	alert:pop({{text = "刷新将消耗50威望!"}},"ui/titlenotice.png", btns)
end

-- 点击刷新按钮提示
function WeiwangProcessor:onBtnRefreshOK()
	--刷新
	local net = {}
	net.method = PVPModule.USER_MANA_SHOP_REFRESH
	net.params = {}
	Net.sendhttp(net)
end

--设置数据
function WeiwangProcessor:setData(shopdata)

	self.txtweiwang:setString(tostring(PlayerData:getMana()))

	local tlen = table.nums(shopdata)
	--滚动条宽度
	local leftPadding = 3
	local rowPadding = 20
	local colPadding = 12
	local colNum = 3

	local w = 173
	local h = 202
	local innerWidth = self.goodslist:getInnerContainerSize().width
	--设置滚动条内容区域大小
	self.goodslist:setInnerContainerSize(cc.size(innerWidth,math.ceil(tlen/colNum) * (h+colPadding)))
	self.goodslist:removeAllChildren()
	--内容高度
	local innerHeight = self.goodslist:getInnerContainerSize().height
	--y起始坐标
	local ystart = innerHeight - h - rowPadding - 3
	--render
	local addItem = nil
	--序号
	local index = 0
	-- 	--数据表的key 用来排序
	-- local keys = table.keys(shopdata)
	-- table.sort(keys)
	-- 	--组织数据
	for k,v in pairs(shopdata) do
		addItem = weiwangitem.new()
		addItem.showname = true
		local it = addItem
		v.index = k - 1
		--异步 塞数据
		local handle = scheduler.performWithDelayGlobal(function() it:setData(v) end, 0.01 * index)

		addItem:setPosition((index % colNum) * (w + colPadding)+ leftPadding , ystart - math.modf(index/colNum) * (h + rowPadding))
		index = index + 1
		addItem:addEventListener(weiwangitem.BUY_CLICK, handler(self,self.onItemClick))
		self.goodslist:addChild(addItem)
	end
end

function WeiwangProcessor:onItemClick(event)
	--dump(event,"ITEM点击",99)
	local data 		= event.data
	local id 		= data.id_type
	local price 	= data.price
	local issell 	= data.is_sell
	local index 	= data.index

	if issell then
		toastNotice("该物品已经被兑换了！")
		return
	end

	local mana = PlayerData:getMana()
	if mana < price then
		toastNotice("威望值不足！")
		return
	end

	self.price = price
	self.index = index

	local gdata = {}	
	gdata.eid = id
	gdata.edata = DataConfig:getGoodByID(id)

	local buy_alert = GameAlert.new()
	local text = "兑换"..gdata.edata.name.."需要"..price.."威望"
	local btns = {{text = "取消",  skin = 2},{text = "确定",  skin = 1 ,callback = handler(self,self.handleBuyConfirm)}}
	buy_alert:pop(text, "ui/titlenotice.png", btns)
end

function WeiwangProcessor:handleBuyConfirm()
	local net = {}
	net.method = PVPModule.USER_BUY_MANA_SHOP
	net.params = {}
	net.params.index = self.index
	Net.sendhttp(net)
end

--获取威望商店数据
function WeiwangProcessor:handleShopInfo(data)
	--dump(data,"威望商店数据",99)
	local shopdata = data.data.mana_shop
	self:setData(shopdata)
end

--购买数据返回
function WeiwangProcessor:handleBuyData(data)
	--dump(data,"购买道具返回",99)
	local mana = data.data.mana
	local shopdata = data.data.mana_shop
	local goods = data.data.new_bag_dict

	PlayerData:setMana(mana)
	local notices = {{"消耗威望："..self.price}}

	local edata = nil
	for k,v in pairs(goods) do
		print(v)
		edata = DataConfig:getGoodByID(k)
		table.insert(notices, {"获得："..edata.name,COLOR_GREEN})
		-- Bag:updateGoodsNum(k, v)
		Bag:plusGoods(k,v)
	end
	popNotices(notices)
	self:setData(shopdata)
end

--数据刷新返回
function WeiwangProcessor:handleRefresh(data)
	--dump(data,"刷新数据返回",99)
	local refreshprice = DataConfig:getManaRefreshPrice()
	local mana = data.data.mana
	PlayerData:setMana(mana)
	popNotices({{"刷新成功！",COLOR_GREEN},{"威望值：-"..refreshprice}})
	local shopdata = data.data.mana_shop
	self:setData(shopdata)
end

return WeiwangProcessor