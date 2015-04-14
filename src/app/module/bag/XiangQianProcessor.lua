--宝石镶嵌处理器
local ItemFace = require("app.components.ItemFace")
local XiangQianProcessor = class("XiangQianProcessor", BaseProcessor)

local gemColors = {COLOR_RED, COLOR_GREEN, display.COLOR_YELLOW, display.COLOR_BLUE}

function XiangQianProcessor:ctor()
	
end

function XiangQianProcessor:ListNotification()
	return {
		BagModule.SHOW_EQUIP_XIANGQIAN,
		--请求打孔
		BagModule.USER_EQUIP_PUNCH,
		--请求镶嵌宝石
		BagModule.USER_EQUIP_INSET_GEM,
		--请求一键卸下
		BagModule.USER_EQUIP_UNSET_GEM
	}
end

function XiangQianProcessor:handleNotification(notify, data)
	if notify == BagModule.SHOW_EQUIP_XIANGQIAN then 
		local data = data.data
		self:initUI()
		self:setData(data)
	elseif notify == BagModule.USER_EQUIP_PUNCH then
		--打孔
		self:onMakeHoldData(data.data)
	elseif notify == BagModule.USER_EQUIP_INSET_GEM then
		--镶嵌
		self:onXiangQianData(data.data)
	elseif notify == BagModule.USER_EQUIP_UNSET_GEM then
	 	--卸下
	 	self:onXieXiaData(data.data)
	end
end

--初始化UI
function XiangQianProcessor:initUI()
	if view ~= nil then
		return
	end
	local view = ResourceManager:widgetFromJsonFile("ui/equipxiangqian.json")
	self:setView(view)
	
	self.txtInfo = view:getChildByName("txtInfo")
	self.btnTake = view:getChildByName("btnTake")
	self.lbName = view:getChildByName("lbName")
	self.btnClose = view:getChildByName("btnClose")
	local helpBtn = view:getChildByName("helpBtn")
	self.btnTake:addTouchEventListener(handler(self,self.onBtnClick))
	self.btnClose:addTouchEventListener(handler(self,self.onBtnClick))
	helpBtn:addTouchEventListener(handler(self,self.onBtnClick))
	--宝石名字
	self.lbdim1 = view:getChildByName("lbdim1")
	self.lbdim2 = view:getChildByName("lbdim2")
	self.lbdim3 = view:getChildByName("lbdim3")
	self.lbdim4 = view:getChildByName("lbdim4")
	self.lbdim1:setString("点击钻孔")
	self.lbdim2:setString("点击钻孔")
	self.lbdim3:setString("点击钻孔")
	self.lbdim4:setString("点击钻孔")
	--属性加成
	self.lbatt1 = view:getChildByName("lbatt1")
	self.lbatt2 = view:getChildByName("lbatt2")
	self.lbatt3 = view:getChildByName("lbatt3")
	self.lbatt4 = view:getChildByName("lbatt4")
	self.lbatt1:setString("")
	self.lbatt2:setString("")
	self.lbatt3:setString("")
	self.lbatt4:setString("")
	--
	self.itemface = ItemFace.new()
	self.itemface:setData()
	self.itemface.showInfo = false
	view:addChild(self.itemface,3)
	self.itemface:setPosition(266,370)

	self.dimface1 = ItemFace.new()
	self.dimface2 = ItemFace.new()
	self.dimface3 = ItemFace.new()
	self.dimface4 = ItemFace.new()
	self.dimface1.showInfo = false
	self.dimface2.showInfo = false
	self.dimface3.showInfo = false
	self.dimface4.showInfo = false
	self.dimface1:setName("dimface1")
	self.dimface2:setName("dimface2")
	self.dimface3:setName("dimface3")
	self.dimface4:setName("dimface4")

	self.dimface1:setScale(0.6)
	self.dimface2:setScale(0.6)
	self.dimface3:setScale(0.6)
	self.dimface4:setScale(0.6)

	view:addChild(self.dimface1,3)
	view:addChild(self.dimface2,3)
	view:addChild(self.dimface3,3)
	view:addChild(self.dimface4,3)

	self.dimface1:setData()
	self.dimface2:setData()
	self.dimface3:setData()
	self.dimface4:setData()

	self.dimface1:setPosition(93,231)
	self.dimface2:setPosition(222,231)
	self.dimface3:setPosition(353,231)
	self.dimface4:setPosition(483,231)

	self.dimface1:addTouchEventListener(handler(self,self.onItemClick))
	self.dimface2:addTouchEventListener(handler(self,self.onItemClick))
	self.dimface3:addTouchEventListener(handler(self,self.onItemClick))
	self.dimface4:addTouchEventListener(handler(self,self.onItemClick))

	self.dimface1:setTouchEnabled(true)
	self.dimface2:setTouchEnabled(true)
	self.dimface3:setTouchEnabled(true)
	self.dimface4:setTouchEnabled(true)

	self:addPopView(self.view)
end

--初始化数据
function XiangQianProcessor:setData(data)
	self.data = data
	self.itemface:setData(data)
	-- dump(data)

	local name = string.format("Lv%d %s", string.sub(data.eid, 5,6), data.edata.name)
	if data.star > 0 then
		name = name .. string.format("(+%d)", data.star)
	end
	self.lbName:setString(name)
	self.lbName:setColor(Bag:getEquipColor(data.color[1]))
	
	--405.png
	--dump(data,"待镶嵌的装备",999)

	for i=1,4 do
		local dim = data.hole[i]
		if dim == nil then
			--没孔
			self["dimface"..i].defaultimg = 'ui/hammer.png';
			self["dimface"..i]:setData()
			self["lbdim"..i]:setString("点击钻孔")
			self["lbdim"..i]:setColor(display.COLOR_WHITE)
			self["lbatt"..i]:setString("")
			self["lbatt"..i]:setColor(display.COLOR_WHITE)
		elseif dim == "" then
			--有孔没宝石
			self["dimface"..i].defaultimg = 'ui/kuangbig.png';
			self["dimface"..i]:setData()
			self["lbdim"..i]:setString("点击镶嵌")
			self["lbdim"..i]:setColor(display.COLOR_WHITE)
			self["lbatt"..i]:setString("")
			self["lbatt"..i]:setColor(display.COLOR_WHITE)
		else
			--有孔有宝石
			local edata = DataConfig:getGoodByID(dim)
			local da = {}
			da.edata = edata
			da.eid = dim
			local color = gemColors[tonumber(string.sub(dim, 3, 3))+1]
			self["dimface"..i].defaultimg = 'ui/kuangbig.png';
			self["dimface"..i]:setData(da)
			self["lbdim"..i]:setString(da.edata.name)
			self["lbdim"..i]:setColor(color)
			local n1,n2 = Bag:getEquipAttrName(da.edata.value)
			self["lbatt"..i]:setString(n2.."+"..da.edata.value[n1])
			self["lbatt"..i]:setColor(color)
		end
	end

	local msgs = DataConfig:getAllConfigMsg()
	local user_lv_limit = DataConfig:getEquipHoldLimitUserLv()
	local msg = string.gsub(msgs["30015"], "@0", user_lv_limit)
	self.txtInfo:setString(msg)
end

--按钮点击
function XiangQianProcessor:onBtnClick(sender, eventType)
	if eventType ~= TouchEventType.ended then
		return
	end
	local btnName = sender:getName()
	if btnName == "btnTake" then
		print("take click")
		self:sendTake()
	elseif btnName == "btnClose" then
		self:removePopView(self.view)
	elseif btnName == "helpBtn" then
		local alert = GameAlert.new()
		alert:popHelp("gem_inlay")
	end
end

--Item点击
function XiangQianProcessor:onItemClick(sender, eventType)
	if eventType ~= TouchEventType.ended then
		return
	end
	
	--判断操作类型 开孔还是镶嵌
	local itemName = sender:getName()
	print("itemName"..itemName)
	local index = tonumber(string.sub(itemName,8,8))
	local hole = self.data.hole[index]

	if hole == "" then
		--镶嵌
		local node = display.newNode()
		node.data = {}
		node.data.type = "2"
		node.data.callback = handler(self,self.onSelectGem)
		Observer.sendNotification(BagModule.SHOW_GOODS_SELECT, node)
		return
	end
	if hole ~= nil then
		--有宝石了
		return
	end

	local equip_hole = DataConfig:getEquipHoldNum(self.data.color[1])
	if equip_hole == 0 then
		toastNotice("此装备不能开孔！")
		return
	end

	if #self.data.hole >= equip_hole then
		toastNotice("已达到最大开孔数！")
		return
	end

	local quiplv = tonumber(string.sub(self.data.eid,4,6))
	if quiplv < DataConfig:getEquipHoldLimitLv() then
		local content = DataConfig:getEquipHoldLimitLv() .. "级以上装备才能开孔！"
		local btns = {{text = "确定",skin = 3,}}
		local alert = GameAlert.new()
		alert:pop(content, "ui/titlenotice.png", btns)
		return
	end

	local userlv = PlayerData:getLv()
	if userlv < DataConfig:getEquipHoldLimitUserLv() then
		local btns = {{text = "确定",skin = 3,}}
		local alert = GameAlert.new()
		local richStr = {{text = "开孔功能",color = COLOR_RED},
						{text = "角色等级"..DataConfig:getEquipHoldLimitUserLv().."级开启",color = COLOR_GREEN},}
		alert:pop(richStr,"ui/titlenotice.png",btns)
		return
	end

	-- 检查开孔顺序 第二个位置没有打孔 不能打孔第三个位置
	local hole_count = #self.data.hole
	if index > hole_count+1 then
		local hole_index_alert = GameAlert.new()
		local text = "请先将第"..(hole_count+1).."个位置打孔"
		local btns = {{text = "确定",  skin = 3}}
		hole_index_alert:pop(text, "ui/titlenotice.png", btns)
		return
	end

	--计算消耗
	--  'equip_punch':{   #装备打孔
	--          'color' : [1,1.2,1.3,1.4,1.5],                  #各颜色装备所对应的参数
	--          'coefficient' : [0, 50000],      #第一个空开孔所需的花费值
	--          'location' : [1.2,1.2,1,1,1,1,1,1,1,1],    #装备所对应的位置(分别为:)武器，衣服，马，护腿，腰带，鞋，戒指，护手，头，饰品
	--          'expend' : [0,('I0001',1),('I0002',1),('I0003',1)],      #打孔位置对应的消耗品和数量（分别为：）银两，铁锤子，银锤子，金锤子
	-- },
	local punch = DataConfig:getEquipPunch()
	local location = punch.location
	local coefficient = punch.coefficient
	local color = punch.color

	--下一个孔的索引
	local holdindex = #self.data.hole + 1
	local costObject = punch.expend[holdindex]
	self.costType = ""
	self.costValue = 0
	local loc = tonumber(string.sub(self.data.eid,3,3))

	if type(costObject) == "number" then
		--消耗银两
		self.costType = "gold"
		self.costValue = (coefficient[1]*quiplv+coefficient[2])*location[loc+1]*punch.color[self.data.color[1]+1]
	elseif type(costObject)=="table" then
		--消耗锤子
		self.costType = costObject[1]
		self.costValue = costObject[2]
	end

	local str = ""
	local cfg = DataConfig:getAllConfigMsg()
	if self.costType == "gold" then
		str = addArgsToMsg(cfg["30037"],self.costValue)
	else
		local goods = DataConfig:getGoodByID(self.costType)
		str = addArgsToMsg(cfg["30036"],goods.name,self.costValue)
	end

	local btns = {{text = "取消",skin = 2},{text = "确定",skin = 1,callback = handler(self,self.sendMakeHole)},}
	local alert = GameAlert.new()
	alert:pop({{text = str}},"ui/titlenotice.png",btns)
end

--发送开孔请求
function XiangQianProcessor:sendMakeHole()
	if self.costType == "gold" then
		if self.costValue > PlayerData:getGold() then
			toastNotice("银两不足！")
			return
		end
	else
		local goods = Bag:getGoodsById(self.costType)
		if goods==nil or goods.num < self.costValue then
			local edata = DataConfig:getGoodByID(self.costType)
			toastNotice(edata.name.."不足！")
			return
		end
	end
	print("发送开孔请求")--所有条件满足 开始发送请求
	local net = {}
	net.method = BagModule.USER_EQUIP_PUNCH
	net.params = {}
	net.params.eqid = self.data.sid
	Net.sendhttp(net)
end

--打孔数据返回
function XiangQianProcessor:onMakeHoldData(data)
	--dump(data,"打孔数据返回",99)
	local bag = data.data.bag
	if self.costType == "gold" and self.costValue ~= 0 then
		popNotices({{"开孔成功！",COLOR_GREEN},{"消耗银两:-"..self.costValue,COLOR_RED}})
	end
	PlayerData:setGold(data.data.gold)

	local id = data.data.eqid
	local eqdata = data.data.equips[id]
	Bag:updateEquip(id, eqdata)
	--
	local newItem = Bag:getEquipById(id)
	self:setData(newItem)

	--更新道具数据
	if bag ~= nil then
		for k,v in pairs(bag) do
			Bag:updateGoodsNum(k, v)
		end
	end

	local node = display.newNode()
	node.eid = {id}
	Observer.sendNotification(BagModule.UPDATE_EQUIP_ATTR,node)
	
end
--属性漂浮字
function XiangQianProcessor:updateNotice(oldData,newData)
	local changeAttrs = {"strr","agi","intt","sta"}
	local stone
	local enname
	local chname
	local color
	local notices = {}
	for i,v in ipairs(newData) do
		if(newData[i] ~= "" and oldData[i] == "") then
			color = COLOR_GREEN
			stone = DataConfig:getGoodByID(newData[i])
			for k=1,#changeAttrs do
				if(stone.value[changeAttrs[k]]) then
					enname,chname = getAttrName(changeAttrs[k])
					table.insert(notices,{chname..": +"..stone.value[changeAttrs[k]],color})
				end
			end
		elseif(newData[i] == "" and oldData[i] ~= "") then
			color = COLOR_RED
			stone = DataConfig:getGoodByID(oldData[i])
			for k=1,#changeAttrs do
				if(stone.value[changeAttrs[k]]) then
					enname,chname = getAttrName(changeAttrs[k])
					table.insert(notices,{chname..": -"..stone.value[changeAttrs[k]],color})
				end
			end
		end
	end
	popNotices(notices)
end
--镶嵌宝石返回
function XiangQianProcessor:onXiangQianData(data)
	local bagdata = data.data.bag 	--背包
	--dump(bagdata)
	local eqid = data.data.eqid 	--装备id
	local equips = data.data.equips --装备数组
	local eq = equips[eqid]
	local oldData = clone(Bag:getEquipById(eqid).hole)
	--更新装备
	Bag:updateEquip(eqid,eq)
	local newData = clone(Bag:getEquipById(eqid).hole)
	self:updateNotice(oldData,newData)
	--更新道具
	for k,v in pairs(bagdata) do
		Bag:updateGoodsNum(k, v)
	end

	local data = Bag:getEquipById(eqid)
	self:setData(data)

	local node = display.newNode()
	node.eid = {eqid}
	Observer.sendNotification(BagModule.UPDATE_EQUIP_ATTR,node)
	-- Observer.sendNotification(BagModule.UPDATE_EQUIP_ATTR)
end
--卸下宝石
function XiangQianProcessor:onXieXiaData(data)
	-- dump(data,"卸下宝石消息返回",999)
	--道具
	local bag = data.data.bag
	for k,v in pairs(bag) do
		Bag:updateGoodsNum(k, v) --更新道具
	end
	--装备
	local eqid = data.data.eqid
	local oldData = clone(Bag:getEquipById(eqid).hole)
	local eqitem = data.data.equips[eqid]
	Bag:updateEquip(eqid, eqitem)
	local newData = clone(Bag:getEquipById(eqid).hole)
	local data = Bag:getEquipById(eqid)
	self:setData(data)
	notice("卸下成功！",COLOR_GREEN)
	self:updateNotice(oldData,newData)
	local node = display.newNode()
	node.eid = {eqid}
	Observer.sendNotification(BagModule.UPDATE_EQUIP_ATTR,node)
end

--选择宝石回调
function XiangQianProcessor:onSelectGem(data)
	--BagModule.USER_EQUIP_INSET_GEM
	--先判断能不能镶嵌 同一件装备上不允许镶嵌两块同样颜色的宝石
	local hole = self.data.hole
	local gemItem = nil

	local ccolor = string.sub(data.eid,3,3)
	local tcolor = ""
	for k,v in pairs(hole) do
		if v ~= "" then
			tcolor = string.sub(v,3,3)
			if tcolor == ccolor then
				toastNotice("该装备已经镶嵌过同样颜色的宝石！")
				return
			end
		end
	end

	local net = {}
	net.method = BagModule.USER_EQUIP_INSET_GEM
	net.params = {}
	net.params.eqid = self.data.sid
	net.params.item_id = data.eid
	Net.sendhttp(net)
end
  
--发送一键卸下
function XiangQianProcessor:sendTake()
	--判断现在装备上是否有宝石
	local hole = self.data.hole
	local hasgem = false
	for k,v in pairs(hole) do
		if v ~= "" then
			hasgem = true
			break
		end
	end

	if hasgem == false then
		toastNotice("装备上没有宝石！")
		return
	end

	local net = {}
	net.method = BagModule.USER_EQUIP_UNSET_GEM 
	net.params = {}
	net.params.eqid = self.data.sid
	Net.sendhttp(net)
end
return XiangQianProcessor