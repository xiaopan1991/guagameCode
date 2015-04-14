-- 选择装备界面的小格子
-- 可自适应高度
-- Author: whe
-- Date: 2014-08-26 16:59:52
--对象池
local ObjectPoolManager = require("app.utils.ObjectPoolManager")

local ItemFace = require("app.components.ItemFace")
local EquipAttrInfo = require("app.components.EquipAttrInfo")
local CommonEquipItem = class("equipselectitem",function()
		local lay = ccui.Layout:create()
		lay:setContentSize(cc.size(545, 187)) --默认最小尺寸

		cc(lay):addComponent("components.behavior.EventProtocol"):exportMethods()
		return lay
	end)

--装备点击
CommonEquipItem.ITEM_CLICK = "ITEM_CLICK"
--装备选择
CommonEquipItem.ITEM_SELECT = "ITEM_SELECT"

function CommonEquipItem:ctor()
	self.nh = 187
	self.nw = 545
	self.inited = false
end


--设置数据
--data 数据
--pos = "top" 蓝色背景 ， "bottom" 黄色背景
--ttype "button" "check" 显示复选框 还是显示按钮
--needSelect 是否默认选中
function CommonEquipItem:setData(data,pos,ttype,index,bShowJobLimit,needSelect,showSelect,hero_type)
	self.data = data
	self.po = pos 
	self.ttype = ttype
	self.index = index
	self.bShowJobLimit = bShowJobLimit
	self.needSelect = needSelect or false
	self.showSelect = showSelect or false
	self.hero_type = hero_type

	self.bShowJobLimit = bShowJobLimit
	if CommonEquipItem.tview == nil then
		CommonEquipItem.tview = ResourceManager:widgetFromJsonFile("ui/equipselectitem.json")
		CommonEquipItem.tview:retain()
	end

	if self.view == nil then
		local view = CommonEquipItem.tview:clone()
		self.view = view
		self.bg1 = view:getChildByName("bg1")
		self.bg2 = view:getChildByName("bg2")
		self.imgpos = view:getChildByName("imgpos")
		self.btn = view:getChildByName("btnSelect")
		self.check = view:getChildByName("chkbox")
		self.currentEquip = view:getChildByName("currentEquip")
		self:addChild(view)
	end

	--初始化itemface
	if self.itemface == nil then
		self.itemface = ItemFace.new()
		self.itemface.showInfo = false
		self:addChild(self.itemface,2)
		self.itemface:setPosition(26,40)
	end
	--初始化装备属性列表
	if self.attr == nil then
		self.attr = EquipAttrInfo.new()
		self.attr.txtwidth = 180
		self:addChild(self.attr,2)
		self.attr:setPosition(370,170)
	end

	local po = string.sub(data.eid,3,3)
	self.imgpos:loadTexture("ui/e"..po..".png")

	if pos == "top" then
		-- self.view:setBackGroundImage("ui/borderpurper.png")
		-- self.bg1:loadTexture("ui/purperbg.png")
		-- self.bg2:loadTexture("ui/purperbg.png")
		self.view:setBackGroundImage("ui/equipColumn.png")
		self.itemface.bg:loadTexture("ui/comequip84.png")
		self.bg1:loadTexture("ui/equiptiaobg.png")
		self.bg2:loadTexture("ui/equipnamebg.png")
		self.bg2:setCapInsets(cc.rect(20,20,60,60))
		self.btn:setEnabled(false)
		self.check:setEnabled(false)
		self.btn:setVisible(false)
		self.check:setVisible(false)
		self.currentEquip:setVisible(true)
		self.itemface.bg:loadTexture("ui/com84.png")
	elseif pos == "bottom" then
		-- self.view:setBackGroundImage("ui/borderblue.png")
		-- self.bg1:loadTexture("ui/bluebg2.png")
		-- self.bg2:loadTexture("ui/bluebg2.png")
		self.view:setBackGroundImage("ui/comColumn.png")
		self.bg1:loadTexture("ui/comequipinfobg.png")
		self.bg2:loadTexture("ui/equipnamebg0.png")
		self.currentEquip:setVisible(false)
		if ttype == "button" then
			self.btn:addTouchEventListener(handler(self,self.btnClick))
			self.check:setEnabled(false)
			self.check:setVisible(false)
		elseif ttype == "check" then
			if self.needSelect then
				self.data.select = true
				self.check:setSelected(true)
			else
				if self.showSelect == false then
					self.check:setEnabled(false)
					self.check:setVisible(false)
                else
                    self.check:setEnabled(true)
                    self.check:setVisible(true)
				end
				self.data.select = false
			end
			self.check:addEventListener(handler(self,self.checkClick))
			self.btn:setEnabled(false)
			self.btn:setVisible(false)
		end
		local itemJob = tonumber(string.sub(self.data.eid,2,2))
		--职业限定
		local playerJob = self.hero_type
		if playerJob == nil then
			playerJob = tonumber(PlayerData:getHeroType())
		end
		local tw
		local th	
		if(self.bShowJobLimit and itemJob~=3 and (itemJob+1) ~= playerJob) then
			tw,th = self:getContentSize()
			local limitTxt = CCLabelTTF:create("职业不符",DEFAULT_FONT,30,cc.size(200,50),kCCTextAlignmentCenter)
			limitTxt:setColor(COLOR_RED)
			limitTxt:setPosition(tw/2,th/2)
			 local act1 = transition.sequence({CCFadeOut:create(1.0),CCFadeIn:create(1.0)})
			limitTxt:runAction(CCRepeatForever:create(act1))
			self:addChild(limitTxt,5)
		end		
	end
	--异步
	self.itemface:setData(data)
	self.attr:setData(data)

	self:resetPos()
end

--按钮点击
function CommonEquipItem:btnClick(sender, eventType)
	if eventType ~= TouchEventType.ended then
		return
	end
	self:dispatchEvent({name =  CommonEquipItem.ITEM_CLICK, data = self.data})
end

--点击选择
function CommonEquipItem:checkClick(sender,eventType)
	if  eventType == ccui.CheckBoxEventType.selected then 
		self.data.select = true
		self:dispatchEvent({name =  CommonEquipItem.ITEM_SELECT, data = self.data})
	elseif eventType == ccui.CheckBoxEventType.unselected then
		self.data.select = false
		self:dispatchEvent({name =  CommonEquipItem.ITEM_SELECT, data = self.data})
	end
end

--重置位置
function CommonEquipItem:resetPos()
	local w,h = self.attr:getContentSize()
	local nw = 545 	--新的宽度
	local nh = 187 	--新的高度
	--166 最小高度
	if h > 166 then
		nh = nh + (h - 166)
	end
	self.view:setContentSize(cc.size(nw,nh))
	self.bg2:setPosition(80,nh - 40)
	self.bg1:setPosition(336,nh/2)
	self.bg1:setContentSize(cc.size(347,nh-30))
	self.imgpos:setPosition(78,nh - 38)
	self.itemface:setPosition(26,nh - 160)
	self.attr:setPosition(370,nh - 34)
	self.currentEquip:setPosition(40,nh - 35)

	self.nh = nh
	self.nw = nw
	self:setContentSize(cc.size(nh,nw))
end

--获取新的高度和宽度
function CommonEquipItem:getContentSize()
	return self.nw,self.nh
end


--设置是否显示复选框
function CommonEquipItem:setCheckVisible(b)
	if self.check == nil then
		self.showSelect = b
	else 
		self.check:setEnabled(b)
		self.check:setVisible(b)
	end
end

function CommonEquipItem:visibled(visible)
	if visible == true and self.inited == false then
		self:setData(self.data,self.pos,self.ttype,self.index,self.bShowJobLimit,self.needSelect,self.showSelect)
		self.inited = true
		self:setVisibleEventEnabled(false)
		if self.initcall ~= nil then
			-- local f = self.initcall
			self.initcall()
			-- scheduler.performWithDelayGlobal(function () f() end,0.001)
		end
	end
end


return CommonEquipItem