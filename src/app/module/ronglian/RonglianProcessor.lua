local ItemFace = require("app.components.ItemFace")
local RonglianProcessor = class("RonglianProcessor", BaseProcessor)

function RonglianProcessor:ctor()
	-- body
end

function RonglianProcessor:ListNotification()
	return {
		RonglianModule.SHOW_RONG_LIAN,
		RonglianModule.SHOW_HAVE_EQUIP,
		RonglianModule.USER_EQUIP_FORGE,
		RonglianModule.MELTE_UPDATE
	}
end

function RonglianProcessor:handleNotification(notify, data)
	if notify == RonglianModule.SHOW_RONG_LIAN then
		--显示熔炼界面
		self:onSetView()
	elseif notify == RonglianModule.SHOW_HAVE_EQUIP then
		--显示已经选择的装备，放到格子里
	   	self:handlerHaveSelectEquipData(data.data)
	elseif notify == RonglianModule.USER_EQUIP_FORGE then
		--返回熔炼后的数据
		self:handleRonglianData(data.data)
	elseif notify == RonglianModule.MELTE_UPDATE then
		--熔炼值更新
		if self.view ~= nil and self.txtRonglianNum ~= nil then
			self.txtRonglianNum:setString(tostring(PlayerData:getMelte()))
		end
	end
end

function RonglianProcessor:onSetView()

 	local ronglian = ResourceManager:widgetFromJsonFile("ui/ronglian.json")
 	local theight = 766
	self.det = display.height - 960
	if display.height > 960 then
		theight = 766 + self.det
	end
	local size = ronglian:getLayoutSize()
	ronglian:setContentSize(cc.size(size.width,theight))

    --当前熔炼值
	self.txtRonglianNum = ronglian:getChildByName("txtRonglianNum")
    self.txtRonglianNum:setString(tostring(PlayerData:getMelte()))
  	local image = ronglian:getChildByName("image")

	local btnDazaoEquip = ronglian:getChildByName("btnDazaoEquip")
	

	local btnDazaoGod = ronglian:getChildByName("btnDazaoGod")


	local btnAutoSelect = ronglian:getChildByName("btnAutoSelect")
	local btnRonglian = ronglian:getChildByName("btnRonglian")
	local bigbg = ronglian:getChildByName("bigbg") 
	local bigTiao = ronglian:getChildByName("bigTiao") 
	local smallTiao = ronglian:getChildByName("smallTiao") 
	local helpBtn = ronglian:getChildByName("helpBtn")
	local btnClose = ronglian:getChildByName("btnClose")
	local bigbgsize = bigbg:getLayoutSize()
	bigbg:setContentSize(cc.size(bigbgsize.width,bigbgsize.height + self.det))
	local imagesize = image:getLayoutSize()
	image:setContentSize(cc.size(imagesize.width,imagesize.height + self.det))
	local topheight = 189 + (self.det/2)
	local bigTiao_L = ccui.RelativeLayoutParameter:create()
	bigTiao_L:setAlign(ccui.RelativeAlign.alignParentTopCenterHorizontal)
	bigTiao_L:setMargin({top = topheight})
	bigTiao:setLayoutParameter(tolua.cast(bigTiao_L,"ccui.LayoutParameter"))

	btnDazaoGod:addTouchEventListener(handler(self,self.onRonglianClick))
	btnDazaoEquip:addTouchEventListener(handler(self,self.onRonglianClick))
	btnAutoSelect:addTouchEventListener(handler(self,self.onRonglianClick))
	btnRonglian:addTouchEventListener(handler(self,self.onRonglianClick))
	helpBtn:addTouchEventListener(handler(self,self.onRonglianClick))
	btnClose:addTouchEventListener(handler(self,self.onRonglianClick))


	--enableBtnOutLine(btnDazaoEquip,COMMON_BUTTONS.GREEN_BUTTON)
	--enableBtnOutLine(btnDazaoGod,COMMON_BUTTONS.ORANGE_BUTTON)
	enableBtnOutLine(btnAutoSelect,COMMON_BUTTONS.BLUE_BUTTON)
	enableBtnOutLine(btnRonglian,COMMON_BUTTONS.BLUE_BUTTON)

	local leftPadding = 60
	local rowPadding = 40
	local colPadding = 322
	local colNum = 2

	local w = 84
	local h = 84
	self.items = {}

	local layoutP = {}
	--y起始坐标
	local yview = ronglian:getContentSize()
	local y0 = 240 + (self.det/2) 
	local ystart = yview.height - y0
	self.item = nil
	for i = 0, 5 do
   	 	self.item = ItemFace.new()
   	 	self.item.defaultimg = "ui/icon_18.png"
   		self.items[#self.items + 1] = self.item
   	 	self.item.showInfo = false
		self.item:setData()
		--self.item:setPosition((i % colNum) * (w + colPadding)+ leftPadding , ystart - math.modf(i/colNum) * (h + rowPadding))
		--self.item:setScale(0.8)
		self.item:setTouchEnabled(true)
		self.item:addTouchEventListener(handler(self,self.onItemClick))
		ronglian:addChild(self.item)
		

		local yy =yview.height -  (ystart - math.modf(i/colNum) * (h + rowPadding))
		layoutP = ccui.RelativeLayoutParameter:create()
		if(i % colNum == 0) then
			layoutP:setAlign(ccui.RelativeAlign.alignParentTopLeft)
			layoutP:setMargin({top = yy,left = leftPadding })
		else
			layoutP:setAlign(ccui.RelativeAlign.alignParentTopRight)
			layoutP:setMargin({top = yy,right = leftPadding })
		end
		
		self.item:setLayoutParameter(tolua.cast(layoutP,"ccui.LayoutParameter"))

		i = i + 1
	end
	--存放选择的装备 sid
	self.data={}
	self.equips = {}
	self:setView(ronglian)
	-- self:addPopView(ronglian)
	self:addMidView(ronglian,true)
end
--按钮事件的处理
function RonglianProcessor:onRonglianClick(sender,eventType)
	if  eventType ~= TouchEventType.ended then
		return
	end
	local btn = tolua.cast(sender,"ccui.Button")
	local btnName = btn:getName()
	if btnName == "btnDazaoGod" then
		Observer.sendNotification(RonglianModule.SHOW_DA_ZAO_GAO,nil)
	elseif btnName == "btnDazaoEquip" then
		Observer.sendNotification(RonglianModule.SHOW_DA_ZAO,nil)
	elseif btnName == "btnAutoSelect" then
		--自动筛选
		self:autoSelect()
	elseif btnName == "btnRonglian" then
		if #self.data == 0 then
			toastNotice("请选择熔炼装备！")
			return
		end

		local hasgod = false
		local hasstar = false
		local einfo = nil
		for k,v in pairs(self.data) do
			einfo = Bag:getEquipById(v)
			if einfo.color[1] == 4 then
				hasgod = true
				break
			elseif einfo.star > 0 then
				hasstar = true
			end
		end
		--判断熔炼的装备是否有橙色
		if hasgod then
			local btns = {{text = "取消",skin = 2},{text = "确定",skin = 1,callback = handler(self,self.sendRonglian)},}
			local alert = GameAlert.new()
			alert:pop({{text = "即将被熔炼的装备含有橙色装备是否继续？"}},"ui/titlenotice.png",btns)
			return
		end
		--判断熔炼的装备是否有强化的
		if hasstar then
			local btns = {{text = "取消",skin = 2},{text = "确定",skin = 1,callback = handler(self,self.sendRonglian)},}
			local alert = GameAlert.new()
			alert:pop({{text = "即将被熔炼的装备含有强化的装备是否继续？"}},"ui/titlenotice.png",btns)
			return
		end
		--发消息给服务器
		self:sendRonglian()
	elseif btnName == "helpBtn" then
		local alert = GameAlert.new()
		alert:popHelp("smelt_forge")
	elseif btnName == "btnClose" then
		Observer.sendNotification(IndexModule.SHOW_INDEX,nil)
	end
end
--点击选择的六个格子
function RonglianProcessor:onItemClick(sender,eventType)
	if  eventType ~= TouchEventType.ended then
		return
	end
	local node = display.newNode()
	self.selects = {}
	--dump(self.equips)
	if self.equips and table.nums(self.equips) ~= 0 then
	    for k,v in pairs(self.equips) do
		    self.selects[k] = v.sid
	    end
	    node.select = self.selects
	end
	node.data = nil
	node.type = "check"
 	node.callback = handler(self,self.handlerHaveSelectEquipData)
 	node.user = "RonglianProcessor"
	Observer.sendNotification(BagModule.SHOW_COMMON_EQUIP_SELECT,node)
end
--熔炼返回数据处理
function RonglianProcessor:handleRonglianData(data)
	--dump(data)
	--'add_pith', 'pith'
	local tdata = data.data
	local melte = tdata.melte
	local pithhave = tdata.pith  	--当前拥有的强化精华数量
	local pithget = tdata.add_pith  --本次获得的强化精华数量
	local notices = {}
	if pithget ~= 0 then
		table.insert(notices,{"获得强化精华数量："..pithget,COLOR_GREEN})
		Bag:updateGoodsNum("I0001",pithhave)
	end
	local getMelte = melte - PlayerData:getMelte()
	if(getMelte > 0) then
		table.insert(notices,{"成功！获得"..getMelte.."点熔炼值",COLOR_GREEN})
	end
	PlayerData:setMelte(melte)
	self.txtRonglianNum:setString(tostring(PlayerData:getMelte()))
	local newEqids = tdata.new_eqids_dict
	
	--移除熔炼掉的装备
	local delequi = data.params.eqids
	for k,v in pairs(delequi) do
		Bag:removeEquip(v)
	end
	--清空控件
	for k,v in pairs(self.items) do
		v:setData()
	end
	
	--清空当前的数据显示
    self.equips = {}
	self.data = {}
	self.select = {}
	if table.nums(newEqids) == 0 then
		popNotices(notices)
		return
	end
	--熔炼后获得的装备放进背包
	for k,v in pairs(newEqids) do
		Bag:addEquip(k,v)
		local item = Bag:getEquipById(k)
		local c3 = Bag:getEquipColor(v.color[1])
		if #v.god > 0 then
			c3 = COLOR_RED
		end
		local lv = tonumber(string.sub(item.eid,4,6))
		table.insert(notices,{"意外获得新装备：Lv"..lv..item.edata.name,c3})
	end
	popNotices(notices)
	Observer.sendNotification(BagModule.UPDATE_EQUIP_ATTR)
end

--选择装备后返回的数据
function RonglianProcessor:handlerHaveSelectEquipData(data)
	self.equips = {}
	for k,v in pairs(self.items) do
		v:setData()
	end
	print("选择返回")
	self.data = data
	local index = 1
	local tdata = nil 
	for k,v in pairs(self.data) do
		print(self.items[index])
		tdata = Bag:getEquipById(v)
		self.items[index]:setData(tdata)
		index = index + 1
		self.equips[#self.equips+1] = tdata
	end
end
--自动筛选
function RonglianProcessor:autoSelect()
	--先清除一下
	for k,v in pairs(self.items) do
		v:setData()
	end
	--清空data
	self.data = {}

	--显示筛选的数据
	self.equips = Bag:getRonglianEquips(6)
	if table.nums(self.equips) == 0 then
		toastNotice("没有可以熔炼的装备！")
		return
	end
	local index = 1
	for k,v in pairs(self.equips) do
		self.items[index]:setData(v)
		self.data[index] = v.sid
		index = index + 1
	end
end

--发送熔炼消息
function RonglianProcessor:sendRonglian()
	local data = {}
	data.method = RonglianModule.USER_EQUIP_FORGE
	data.params = {}
	data.params.eqids = self.data
	Net.sendhttp(data)
end
return RonglianProcessor

