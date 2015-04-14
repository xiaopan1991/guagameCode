--背包管理器  管理装备和物品 

local ItemFace = require("app.components.ItemFace")
local BagProcessor = class("BagProcessor", BaseProcessor)

function BagProcessor:ctor()
	-- body
	self.curIndex = 1
	self.topview = nil
	self.bagview = nil
	self.equipview = nil
	self.index = 1
	self.items = {}  --itemface 缓存
end

--消息列表
function BagProcessor:ListNotification()
	return {
		BagModule.SHOW_BAG,
		--道具数量更新
		BagModule.EQUIP_NUM_UPDATE,
		BagModule.UPDATE_EQUIP_ATTR,
		BagModule.EQUIP_ADD_LIMIT,
		BagModule.UPDATE_BAG_GOODS,
	}
end

--消息处理
function BagProcessor:handleNotification(notify, data)
	if notify == BagModule.SHOW_BAG then
		local showtype = 1
		if data~=nil then
			if data.data~=nil then 
				showtype = data.data.type or 1	
			end
		end

		if self.view == nil then 
			self:onSetView()
		else
			return
		end

		if showtype == 1 then
			--显示装备页签
			self.index = 1
			self:showEquip()
		elseif showtype == 2 then
			--显示道具页签
			self.index = 2
			self:showGoods()
		end
	elseif notify == BagModule.EQUIP_NUM_UPDATE or notify == BagModule.UPDATE_EQUIP_ATTR then
		if self.view == nil or self.index ~= 1 then
			return
		end
		self:showEquip()
	elseif notify == BagModule.EQUIP_ADD_LIMIT  then
		if self.view == nil or self.index ~= 1 then
			return
		end
		self:handlerDataKuoZhan(data.data)
	elseif notify == BagModule.UPDATE_BAG_GOODS then
		if self.view == nil or self.index == 1 then
			return
		end
		self.index = 2
		self:showGoods()
	end
end

--先把主界面搞出来
function BagProcessor:onSetView(view)
	--中部
	local bagview = ResourceManager:widgetFromJsonFile("ui/bagpanel.json")
	self.btnEquip = bagview:getChildByName("btnEquip")
	self.btnGoods = bagview:getChildByName("btnGoods")
	-- self.btnGoods:setButtonOffset(2,-8)
	-- self.btnEquip:setButtonOffset(2,-8)
	enableBtnOutLine(self.btnGoods,COMMON_BUTTONS.TAB_BUTTON)
	enableBtnOutLine(self.btnEquip,COMMON_BUTTONS.TAB_BUTTON)
	
	imgbg = bagview:getChildByName("imgbg")
	local theight = 766
	self.det = display.height - 960
	if display.height > 960 then
		theight = 766 + self.det
	end
	
	local size = bagview:getLayoutSize()
	bagview:setContentSize(cc.size(size.width,theight))

	local bgsize = imgbg:getContentSize()
	imgbg:setContentSize(cc.size(bgsize.width,bgsize.height+self.det))

	self.btnEquip:addTouchEventListener(handler(self,self.onTabClick))
	self.btnGoods:addTouchEventListener(handler(self,self.onTabClick))
	self.bagview = bagview
	
	Observer.sendNotification(IndexModule.SHOW_MAIN_TOP)

	self:addMidView(bagview,true)
	self:setView(self.bagview)
end

--显示装备页签
function BagProcessor:showEquip()
	print("显示装备页签")
	---装备和道具用一个界面 道具界面把扩展的按钮和道具熟练隐藏掉
	if self.equipview == nil then
		local equipview = ResourceManager:widgetFromJsonFile("ui/equippanel.json")
		self.list = equipview:getChildByName("equipList")
		self.list:setTouchEnabled(true)
		self.equipNum = equipview:getChildByName("equipNum")
		self.btnKuoZhan = equipview:getChildByName("btnKuoZhan")
		--enableBtnOutLine(self.btnKuoZhan,COMMON_BUTTONS.GREEN_BUTTON)
		
		self.btnChoose = equipview:getChildByName("btnChoose")
		self.btnSell = equipview:getChildByName("btnSell")
		self.imgnum = equipview:getChildByName("imgnum")
		self.bgin = equipview:getChildByName("bgin")
		self.bgout = equipview:getChildByName("bgout")
		self.btnKuoZhan:addTouchEventListener(handler(self,self.onEquipBtnClick))
		self.btnChoose:addTouchEventListener(handler(self,self.onEquipBtnClick))
		self.btnSell:addTouchEventListener(handler(self,self.onEquipBtnClick))
		self.equipview = equipview
		-- equipview
		local relarg = ccui.RelativeLayoutParameter:create()

		--relarg:setAlign(ccui.RelativeAlign.alignParentTopLeft)
        --dump(ccui.RelativeAlign)
        --print(ccui.RelativeAlign.alignParentTopLeft)
        relarg:setAlign(ccui.RelativeAlign.alignParentTopLeft)
		local margin = {}
		margin.top = 52
		margin.left = 0
		relarg:setMargin(margin)

		local size = self.list:getContentSize()
		self.list:setContentSize(cc.size(size.width,size.height + self.det))
		self.list_Height = size.height  + self.det
		local sizein = self.bgin:getContentSize()
		self.bgin:setContentSize(cc.size(sizein.width,sizein.height + self.det))		

		local sizeout = self.bgout:getContentSize()
		self.bgout:setContentSize(cc.size(sizeout.width,sizeout.height + self.det))	
		-- self.det 
		--不强转不行
		equipview:setLayoutParameter(tolua.cast(relarg,"ccui.LayoutParameter"))

		self.bagview:addChild(equipview)

		
	end
	--self.list:retain()
	--self.list:removeFromParent()
	--self.equipview:addChild(self.list)
	if self.equipview ~= nil then
		self.listHeight = self.list_Height
	end
	local sizeList = self.list:getContentSize()
	self.list:setContentSize(cc.size(sizeList.width,self.listHeight))

	self.btnEquip:setTitleColor(cc.c3b(255,255,255))
	self.btnGoods:setTitleColor(cc.c3b(255,245,135))
	print("刷新背包数据")
	self.btnChoose:setTitleText("装备筛选")
	--GameInstance.uiLayer:stopTouch()
	self:clearlist()
	self.list:jumpToTop()
	--把按钮们显示出来
	--把list 清空 然后把装备数据塞进去
	self:tabIndex(1)

	self.equipNum:setEnabled(true)
	self.btnKuoZhan:setEnabled(true)
	self.imgnum:setEnabled(true)
	self.btnChoose:setEnabled(true)
	self.btnSell:setEnabled(true)

	self.equipNum:setVisible(true)
	self.btnKuoZhan:setVisible(true)
	self.imgnum:setVisible(true)
	self.btnChoose:setVisible(true)
	self.btnSell:setVisible(true)

	--self.quips = Bag:getAllEquip(nil,"bag")
	self.quips = Bag:sortBagEquip()
	self.equipNum:setString(tostring(table.nums(self.quips)).."/"..PlayerData:getBagMax())
	self:setData(self.quips)
	enableBtnOutLine(self.btnChoose,COMMON_BUTTONS.BLUE_BUTTON)
	enableBtnOutLine(self.btnSell,COMMON_BUTTONS.BLUE_BUTTON)
end

--显示道具页签
function BagProcessor:showGoods()
	print("显示道具页签")
	--干掉所有的数据
	self.equipNum:setEnabled(false)
	self.btnKuoZhan:setEnabled(false)
	self.imgnum:setEnabled(false)
	self.btnChoose:setEnabled(false)
	self.btnSell:setEnabled(false)
	self.equipNum:setVisible(false)
	self.btnKuoZhan:setVisible(false)
	self.imgnum:setVisible(false)
	self.btnChoose:setVisible(false)
	self.btnSell:setVisible(false)
	self:clearlist()
	self:tabIndex(2)
	local goods = Bag:sortBagGood()
	self.btnGoods:setTitleColor(cc.c3b(255,255,255))
	self.btnEquip:setTitleColor(cc.c3b(255,245,135))

	
	-- self.list:setAlign(ccui.RelativeAlign.alignParentTopLeft)
	-- self.list_r = ccui.RelativeLayoutParameter:create()
	-- self.list_r:setAlign(ccui.RelativeAlign.alignParentTopCenterHorizontal)
	-- self.list_r:setMargin({top=300})
	-- self.list:setLayoutParameter(tolua.cast(list_r,"ccui.LayoutParameter"))
	

	--self.list:retain()
	--self.list:removeFromParent()
	local sizeList = self.list:getContentSize()
	self.list:setContentSize(cc.size(sizeList.width,self.listHeight+115))
	self:setData(goods)
	--self.equipview:addChild(self.list)
end

function BagProcessor:setData(data)
	local leftPadding = 8
	local rowPadding = 14
	local colPadding = 18
	local colNum = 5

	local w = 90
	local h = 98

	local item = nil
	local index = 0

	--数据长度
	local tlen = table.nums(data)
	print("背包数据长度"..tlen)
	--滚动条宽度
	local innerWidth = self.list:getInnerContainerSize().width
	--设置滚动条内容区域大小
	self.list:setInnerContainerSize(cc.size(innerWidth,math.ceil(tlen/colNum) * (h + rowPadding)))
	--内容高度
	local innerHeight = self.list:getInnerContainerSize().height
	--y起始坐标
	local ystart = innerHeight - h 
	self.items = {}
	for k,v in pairs(data) do
		item = ItemFace.getInstance()
		self.items[#self.items + 1] = item
		--区分是道具还是装备
		if string.sub(v.eid,1,1)~="E" then
			item.showname = true
		end
		-- if index < 20 then 
		if index <= 1 then
			item:setData(v)
		else
			item.data = v
            item:setVisible(false)
			item:setVisibleEventEnabled(true)
		end
		item:setPosition((index % colNum) * (w + colPadding)+ leftPadding , ystart - math.modf(index/colNum) * (h + rowPadding))
		--item:setScale(0.9)
		
		self.list:addChild(item)
		index = index + 1
	end
	if(self.index == 1) then--装备
		local relarg = ccui.RelativeLayoutParameter:create()
		relarg:setAlign(ccui.RelativeAlign.alignParentTopCenterHorizontal)
		local margin = {}
		margin.top = 207
		margin.left = 64
		relarg:setMargin(margin)
		self.list:setLayoutParameter(tolua.cast(relarg,"ccui.LayoutParameter"))
	else
		local relarg = ccui.RelativeLayoutParameter:create()
		relarg:setAlign(ccui.RelativeAlign.alignParentTopCenterHorizontal)
		local margin = {}
		margin.top = 85
		margin.left = 64
		relarg:setMargin(margin)
		self.list:setLayoutParameter(tolua.cast(relarg,"ccui.LayoutParameter"))
	end
	self.list:jumpToTop()
end

--Tab按钮点击
function BagProcessor:onTabClick(sender,eventType)
	if  eventType ~= TouchEventType.ended then 
		return
	end
	local btn = tolua.cast(sender,"ccui.Button")
	local btnName = btn:getName()
	if btnName == "btnEquip" then
		self:tabIndex(1)
		self.index = 1
		self:showEquip()
	elseif btnName == "btnGoods" then
		self:tabIndex(2)
		self.index = 2
		self:showGoods()
	end
end

--拓展点击
function BagProcessor:onEquipBtnClick(sender,eventType)
	if  eventType ~= TouchEventType.ended then 
		return
	end
	local btnName = sender:getName()
	if btnName == "btnKuoZhan" then
		--扩展
    	local num,cost,times = PlayerData:getKuoZhanBag()
	    if times == 0 then
	    	toastNotice("背包数量已达到上限！")
	    	return
	    end
		print("拓展按钮点击")
		local btns = {{text = "取消",skin = 2},{text = "确定",skin = 1,callback = handler(self,self.sendKuoZhan),args = true}}
		local alert = GameAlert.new()
		self.cost = cost
		local cfg = DataConfig:getAllConfigMsg()
		local textStr = addArgsToMsg(cfg["30028"],num,self.cost,times)
		alert:pop(textStr,"ui/titlenotice.png",btns)
	elseif btnName == "btnChoose" then
		--筛选
		local node = display.newNode()
		node.data = {}
		node.data.callback = handler(self,self.onEquipFilterCall) --选择回调
		Observer.sendNotification(BagModule.SHOW_EQUIP_FILTER,node)
	elseif btnName == "btnSell" then
		--批量售出
		Observer.sendNotification(BagModule.SHOW_LOT_SELL)
	end
end

--装备筛选点击
--etype  筛选类型  pos color all
--evalue  
function BagProcessor:onEquipFilterCall(etype,evalue,text)
	print("etype"..etype)
	print("evalue"..evalue)
	if etype == "all" then
		self.quips = Bag:getAllEquip(nil,"bag")
		self.btnChoose:setTitleFontSize(24)
	elseif etype == "pos" then
		self.quips = Bag:getEquipsByPos(tonumber(evalue),nil,nil,"bag")
		self.btnChoose:setTitleFontSize(16)
	elseif etype == "color" then
		self.btnChoose:setTitleFontSize(16)
		if tonumber(evalue) <= 4 then
			self.quips = Bag:getEquipsByQuality(evalue,"bag")
		else
			self.quips = Bag:getGodEquip(nil,nil,"bag")
		end
	end

	self.btnChoose:setTitleText(text)
	self:clearlist()
	self.list:jumpToTop()
	self:setData(self.quips)
end
--发送扩展请求
function BagProcessor:sendKuoZhan()
	local currentCoin = PlayerData:getCoin()
	if currentCoin < self.cost then
		--notice("元宝不足！")
		btns = {{text = "取消",skin = 2},{text = "充值",skin = 1,callback = handler(self,self.sendChargeView)}}
		alert = GameAlert.new()
		richStr = {{text = "您的元宝不足，请您及时充值！",color = display.COLOR_WHITE}}
		alert:pop(richStr,"ui/titlenotice.png",btns)
		return
	end

	local data = {}
	data.method = BagModule.EQUIP_ADD_LIMIT 
	data.params = {}
	Net.sendhttp(data)
end
--前去充值
function BagProcessor:sendChargeView()
	self:removePopView(self.view)
	Observer.sendNotification(ChargeModule.SHOW_CHARGE_VIEW)
end
--返回扩展背包
function BagProcessor:handlerDataKuoZhan(data)
	-- dump(data,"返回扩展背包",99)
	local buy_count = data.data.bag_buy_count
	local coin = data.data.coin
	PlayerData:setCoin(coin)
	PlayerData:setBuyCount(buy_count)
	self.equipNum:setString(tostring(table.nums(self.quips)).."/"..PlayerData:getBagMax())
	popNotices({{"扩展成功!",COLOR_GREEN},{"元宝:-"..self.cost,COLOR_RED}})
	Observer.sendNotification(BagModule.EQUIP_NUM_UPDATE)	
end

function BagProcessor:onHideView(view)
	if self.bagview == view then
		self.bagview:removeFromParent()
		self.bagview = nil
		self.equipview = nil
		self.view = nil
	end
end
--改变按钮的选中状态
function BagProcessor:tabIndex(index)
	if index == 1 then
		self.btnEquip:setBright(true)
		self.btnGoods:setBright(false)
	else
		self.btnEquip:setBright(false)
		self.btnGoods:setBright(true)
	end
end

--清空列表
function BagProcessor:clearlist()
	for k,v in pairs(self.items) do
		if not tolua.isnull(v) then
			v:removeFromParent()
			v:dispose()
		end
	end
	self.list:removeAllChildren()
end

return BagProcessor