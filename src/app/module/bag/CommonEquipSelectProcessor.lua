-- 装备选择面板
-- 传承 吞噬 都使用这个
-- Author: whe
-- Date: 2014-08-26 15:28:23
local CommonEquipItem = import(".ui.CommonEquipItem")
local CommonEquipSelectProcessor = class("CommonEquipSelectProcessor", BaseProcessor)

function CommonEquipSelectProcessor:ctor()

end

function CommonEquipSelectProcessor:ListNotification()
	return {
		BagModule.SHOW_COMMON_EQUIP_SELECT
	}
end

--data.data 	道具数据
--data.callback 回调函数
--data.type     显示类型 单选还是多选 "button" "check"
--data.god 		只显示神器
--data.user 	用途，比如说“吞噬”
function CommonEquipSelectProcessor:handleNotification(notify, data)
	if notify == BagModule.SHOW_COMMON_EQUIP_SELECT then
		--dump(data.data)
		self.callback = data.callback
		self.type = data.type 	-- 显示类型
		self.user  = data.user  -- 用途
        self.select = (data.select and clone(data.select)) or {}
        self.params  = data.params
		self:initUI()
		self:setData(data.data)
	end
end

--初始化UI显示
-- arg  预留 没用
function CommonEquipSelectProcessor:initUI(arg)
	if self.view ~= nil then
		return
	end
	local view = ResourceManager:widgetFromJsonFile("ui/equipselect.json")
	local panel = view:getChildByName("panel")
	--EquipItem
	local equipItem = CommonEquipItem.new()
	self.equipItem = equipItem
	self.bg1 = panel:getChildByName("bg1")
	self.bg2 = panel:getChildByName("bg2")
	self.list = panel:getChildByName("list")

	local btnClose = panel:getChildByName("btnClose")
	local btnClose2 = panel:getChildByName("btnClose2")
	if self.type == "button" then
		btnClose2:setTitleText("关闭")
	elseif self.type == "check" then
		btnClose2:setTitleText("确定")
	end
	btnClose:addTouchEventListener(handler(self,self.btnClick))
	btnClose2:addTouchEventListener(handler(self,self.btnClick))

	view:addChild(equipItem)
	local w,h = self.equipItem:getContentSize()
	self.equipItem:setPosition(self.bg1:getPositionX() + 10, self.bg1:getPositionY() - h - 10)

	self:setView(view)
	self:addPopView(view)
end

--设置数据
function CommonEquipSelectProcessor:setData(data)
	self.data = data

	local w = 0 
	local h = 0
	local h2 = 422+205-(h + 20)
	if self.data == nil then
		self.equipItem:removeFromParent()
		self.bg1:setEnabled(false)
		self.bg1:setVisible(false)
	else
		self.equipItem:setData(self.data,"top",self.type)
		w,h = self.equipItem:getContentSize()
		-- self.equipItem:setPosition(66,600-(h - 204)-12)
		self.equipItem:setPosition(self.bg1:getPositionX() + 10, self.bg1:getPositionY() - h - 10)
		self.bg1:setContentSize(cc.size(565,h + 20))
	end
	 
	local h2 = 422+205-(h + 20)
	self.bg2:setContentSize(cc.size(565,h2))

	--设置list的大小 h2 - 20, w = 510
	-- self.list:set
	-- print("改变滚动条的大小"..h2)
	self.list:setContentSize(cc.size(545,h2-20)) --改变滚动条的大小
	self.listheight = h2
	--筛选出同部位的装备

	local items = {}
	if(self.user == "RonglianProcessor") then
		items = Bag:getRonglianEquips()
	elseif(self.user == "TunShiProcessor") then
		items = Bag:getTunShiEquips(self.data.sid)
	elseif(self.user == "ChuanChengProcessor") then
		items = Bag:getChuanChengEquips(tonumber(string.sub(self.data.eid,3,3)))
	elseif(self.user == "EquipProcessor" or self.user == "FollowerProcessor") then
		items = Bag:getDressEquips(self.params[1],self.params[2])
	--elseif(self.user == "") then
	end
  	self.equips = items
	--如果没有数据 则显示 没有符合条件的装备
	if #self.equips == 0 then
		local label = ccui.Text:create()
		label:ignoreContentAdaptWithSize(false)
		label:setContentSize(cc.size(400, 32))
		label:setFontSize(26)
		label:setFontName(DEFAULT_FONT)
		label:setColor(COLOR_RED)
		label:setString("没有符合条件的装备")
		label:setTextHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)
		self.view:addChild(label)
		local x,y = self.list:getPosition()
		label:setPosition(320 ,y + h2/2)
	end

	--处理这个 items
	--选中的优先
	if self.select ~= nil and #self.select > 0 then
		local tempItems = {}
		local des = {}
		local sl = false
		for k,v in pairs(items) do
			sl = false
			for kk,vv in pairs(self.select) do
				if v.sid == vv then
					sl = true
					break
				end
			end
			if not sl then
				tempItems[#tempItems + 1] = v
			else
				des[#des+1] = v
			end
		end
		
		table.insertto(des,tempItems)
        items = des
	end
	self.equips = items
	--刷新列表的数据
	local handle = scheduler.performWithDelayGlobal(function() self:setlistData(items) end, 0.1)
end

--刷新列表的数据
function CommonEquipSelectProcessor:setlistData(data)
	local leftPadding = 10
	local rowPadding = 10
	local colPadding = 10
	local colNum = 1
	--单个格子的高宽
	local w = 545
	local h = 187
	--临时变量
	local tw = 545
	local th = 187
	local totalh = 0  --所有格子的高度

	local item = nil  --单个的item
	local items = {}  --全部的item
	local items2 = {}  --全部的item
	local index = 0
	self.renderIndex = 0 --已经渲染到的下标 用于索引self.equips
	print("列表数据长度"..#data)
	-- dump(data)
	-- dump(self.data)
	print("···dasdasdas:"..#self.select)
	local showSelect = #self.select ~= 6 or false
	print("showSelect"..tostring(showSelect))
	for k,v in pairs(data) do
		if self.data == nil or v.sid ~= self.data.sid then
			item = CommonEquipItem.new()
			local needSelect = false
			if self:checkDataSelect(v.sid) then
				needSelect = true
			end
			item:setData(v,"bottom",self.type,index,self.bShowJobLimit,needSelect,showSelect,self.hero_type)
			tw,th = item:getContentSize()
			totalh = totalh + th + rowPadding
			self.list:addChild(item)
			if self.type == "button" then
				item:addEventListener(CommonEquipItem.ITEM_CLICK,handler(self,self.onItemClick))
			else 
				item:addEventListener(CommonEquipItem.ITEM_SELECT,handler(self,self.onItemSelect))
			end
			items[#items + 1] = item
			items2[v.sid] = item
			index = index + 1
			self.renderIndex = index
			if index == 5 then
				break
			end
		end
	end

	self.totalh = totalh

	self.items = items
	self.items2 = items2

	if self.listheight > totalh then
		totalh = self.listheight
	end
	
	self.list:setInnerContainerSize(cc.size(w,totalh))
	
	for kk,vv in pairs(items) do
		vv:setPosition(0,totalh - vv.nh)
		totalh = totalh - vv.nh - rowPadding
	end

	if self.renderIndex < #self.equips then
		local hand = scheduler.performWithDelayGlobal(handler(self,self.addRender),0.1)
	else
		self:resetItemPosition()
	end
end

--重缓存数据里取数据 分批渲染
function CommonEquipSelectProcessor:addRender()
	if self.view == nil then
		return
	end
	local rowPadding = 10
	local w = 510
	local showSelect = #self.select ~= 6 or false
	if self.renderIndex < #self.equips then
		self.renderIndex = self.renderIndex + 1
		local itemdate = self.equips[self.renderIndex]

		if  self.data == nil or itemdate.sid ~= self.data.sid then
			local needSelect = false
			if self:checkDataSelect(itemdate.sid) then
				needSelect = true
			end

			local render = CommonEquipItem.new()
			render:setVisibleEventEnabled(true)
			
			render.data = itemdate
			render.needSelect = needSelect
			render.showSelect = showSelect

			render.pos = "bottom" 
			render.ttype = self.type
			render.index = self.renderIndex
			render.bShowJobLimit = self.bShowJobLimit
			render.initcall = handler(self,self.resetItemPosition)
			render.hero_type = self.hero_type
			render.typeonly = self.typeonly

			local tw,th = render:getContentSize()
			self.totalh = self.totalh + th + rowPadding
			self.list:addChild(render)

			self.items2[itemdate.sid] = render
			self.items[#self.items + 1] = render

			if self.type == "button" then
				render:addEventListener(CommonEquipItem.ITEM_CLICK,handler(self,self.onItemClick))
			else 
				render:addEventListener(CommonEquipItem.ITEM_SELECT,handler(self,self.onItemSelect))
			end	

			self.list:setInnerContainerSize(cc.size(w,self.totalh))

			local totalhtemp = self.totalh
			for kk,vv in pairs(self.items) do
				vv:setPosition(0,totalhtemp - vv.nh)
				totalhtemp = totalhtemp - vv.nh - rowPadding
			end
		end
		self:addRender()
	end
end

function CommonEquipSelectProcessor:resetItemPosition()
	-- self.items
	self.totalh = 0
	local rowPadding = 10
	local w = 510
	for k,v in pairs(self.items) do
		local tw,th = v:getContentSize()
		self.totalh = self.totalh + th + rowPadding
	end

	if self.listheight > self.totalh then
		self.totalh = self.listheight
	end
	
	local totalhtemp = self.totalh
	for kk,vv in pairs(self.items) do
		vv:setPosition(0,totalhtemp - vv.nh)
		totalhtemp = totalhtemp - vv.nh - rowPadding
	end
	self.list:setInnerContainerSize(cc.size(w,self.totalh))
end

--按钮点击事件
function CommonEquipSelectProcessor:onItemClick(event)
	self:removePopView(self.view)
	if self.callback ~= nil then
		self.callback(event.data)
	end
end

function CommonEquipSelectProcessor:onItemSelect(event)

	if event.data.select == true then
		self.select[#self.select + 1] = event.data.sid
	else
		table.removebyvalue(self.select, event.data.sid)
	end

	local n = 6 
	if self.user == "ChuanChengProcessor" then
		n = 1
	end
	local visible = false
	if #self.select == n then
		visible = false
	elseif #self.select == (n-1) and event.data.select == false then
		visible = true
	else 
		return 
	end

	local check = false
    
    local num = table.nums(self.items2)
    local num2 = #self.equips

	for k,v in pairs(self.equips) do
		check = false
		for kn,vn in pairs(self.select) do
			if v.sid == vn then
				--已选中的
				check = true
		    end
		end
		if check == false then
			self.items2[v.sid]:setCheckVisible(visible)
		end
	end
end

--初始化 检查条子是否选中
function CommonEquipSelectProcessor:checkDataSelect(sid)
	for k,v in pairs(self.select) do
		if v == sid then
			return true
		end
	end
	return false
end


--关闭按钮点击
function CommonEquipSelectProcessor:btnClick(sender,eventType)
	if eventType ~= TouchEventType.ended then
		return
	end
	if self.type == "button" then
		self:removePopView(self.view)
		return	
	end

	local btnName = sender:getName()
	if btnName == "btnClose2" then
		if self.callback ~= nil then
			self.callback(self.select)
		end
	end
	self:removePopView(self.view)
end


return CommonEquipSelectProcessor
