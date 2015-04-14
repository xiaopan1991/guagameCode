local ObjectPoolManager = require("app.utils.ObjectPoolManager")
--装备道具的小格子
local ItemFace = class("ItemFace", function()
		local layout = ccui.Layout:create()
		layout:setContentSize(cc.size(105,106))
		return layout
	end)

ItemFace.view = nil
ItemFace.pool = nil --对象池

function ItemFace:ctor()
	self.inited = false
	--边框 Sprite
	self.sp_border = nil
	--图片 Sprite
	self.sp_img = nil
	--等级 文本
	self.lb_lv = nil
	--名称 文本
	self.lb_name = nil
	--数量 文本
	self.lb_number = nil
	--神器特效
	self.effect = nil
	--点击的时候 是否触发详情界面
	self.showInfo = true
	--默认图片
	self.defaultimg = "ui/comblack84.png"

	--宝石背景和图片
	self.dimbgs = {}
	self.dims = {}

	--是否显示等级
	self.showlv = true
	self.showname = false

	if ItemFace.uiview == nil then
		ItemFace.uiview = ResourceManager:widgetFromJsonFile("ui/itemface.json")
		ItemFace.uiview:retain()
	end
	self.view = ItemFace.uiview:clone()
	self.border = self.view:getChildByName("border")
	self.bg = self.view:getChildByName("bg")
	self:addChild(self.view)
end

--获取一个实例
function ItemFace.getInstance()
	local pool = ItemFace:getPool()
	return pool:pop()
end

--获取ItemFace类的对象池
function ItemFace:getPool()
	if ItemFace.pool == nil then
		ItemFace.pool = ObjectPoolManager.new()
	end
	return ItemFace.pool
end

function ItemFace.initPool(num)
	if(not ItemFace.pool) then
		ItemFace.pool = ObjectPoolManager.new()
		ItemFace.pool:init(ItemFace,num)
	end
end
function ItemFace.addToPool(num)
	if(not ItemFace.pool) then
		ItemFace.initPool(num)
		return
	end
	ItemFace.pool:init(ItemFace,num)
end

--设置数据
--goodsdata 道具数据
function ItemFace:setData(goodsdata)
	self.data = goodsdata
	if self.ani ~= nil then
		self:removeChild(self.ani, true)
		self.ani = nil
	end
	--移除各种宝石
	for k,v in pairs(self.dimbgs) do
		v:removeFromParent()
	end
	self.dimbgs = {}
	for kk,vv in pairs(self.dims) do
		vv:removeFromParent()
	end
	self.dims = {}

	if self.ani ~= nil then
		self:removeChild(self.ani, true)
		self.ani = nil
	end
	if self.bk ~= nil then
		self:removeChild(self.bk, true)
		self.bk = nil
	end

	if self.data == nil then
		local bg = self.view:getChildByName("bg")
		local border = self.view:getChildByName("border")
		--图片
		local img = self.view:getChildByName("img")
		--文本
		local lb = self.view:getChildByName("lb")
		--强化等级 也就是星级
		--bg:loadTexture("ui/com84.png")
		local lbstar = self.view:getChildByName("lbstar")
		lbstar:setTouchEnabled(false)
		img:setTouchEnabled(false)
		border:setTouchEnabled(false)
		lb:setTouchEnabled(false)
		border:loadTexture("ui/90001.png")
		img:loadTexture(self.defaultimg)
		lb:setEnabled(false)
		lbstar:setString("")
		lb:setString("")
		self.view:setTouchEnabled(false)
		return
	end
	--区分是道具还是装备
	if string.sub(self.data.eid,1,1)=="E" then
		self:setEquipData(self.data)
	else
		self:setGoodsData(self.data)
	end
end


function ItemFace:setDataWhenVisible(goodsdata)
	self.vdata = goodsdata
	self.data = nil
end

--设置装备数据
function ItemFace:setEquipData(data)
	--
	-- 	"e1" = {
	-- 	"color" = {
	-- 		1 = 4
	-- 		2 = 92
	-- 		3 = 93
	-- 		4 = 8
	-- 		5 = 211
	-- 	}
	-- 	"eid"   = "E000250"
	-- 	"hole" = {
	-- 		1 = 1
	-- 		2 = ""
	-- 	}
	-- 	"god"   = 0
	-- 	"star"  = 0
	-- }

	local border = self.view:getChildByName("border")
	--图片
	local img = self.view:getChildByName("img")
	--文本
	local lb = self.view:getChildByName("lb")
	lb:setFontSize(20)
	--强化等级 也就是星级
	local lbstar = self.view:getChildByName("lbstar")
	--星级
	lbstar:enableOutline(cc.c4b(0, 0, 0, 255),2)
	lbstar:setTouchEnabled(false)
	img:setTouchEnabled(false)	
	border:setTouchEnabled(false)
	lb:setTouchEnabled(false)
	lb:enableOutline(cc.c4b(0, 0, 0, 255),2)

	if self.data == nil then
		border:loadTexture("ui/90001.png")
		img:loadTexture("ui/comblack84.png")
		lb:setEnabled(false)
		if self.ani ~= nil then
			self:removeChild(self.ani, true)
		end
		lbstar:setString("")
		lb:setString("")
		self.view:setTouchEnabled(false)
		return
	else
		img:loadTexture("equip/"..data.eid..".png")
		img:ignoreContentAdaptWithSize(false)
		--img:setContentSize(cc.size(88,88))
		if tonumber(string.sub(self.data.eid,7,7)) == 0 then
			if self.data.color[1] == 0 then
				border:loadTexture("ui/90001.png")
			elseif self.data.color[1] == 1 then
				border:loadTexture("ui/90004.png")
			elseif self.data.color[1] == 2 then
				border:loadTexture("ui/90005.png")
			elseif self.data.color[1] == 3 then
				border:loadTexture("ui/90003.png")
			elseif self.data.color[1] == 4 then
				border:loadTexture("ui/90002.png")
			end
		else
			if self.data.color[1] == 0 then
				border:loadTexture("ui/91001.png")
			elseif self.data.color[1] == 1 then
				border:loadTexture("ui/91004.png")
			elseif self.data.color[1] == 2 then
				border:loadTexture("ui/91005.png")
			elseif self.data.color[1] == 3 then
				border:loadTexture("ui/91003.png")
			elseif self.data.color[1] == 4 then
				border:loadTexture("ui/91002.png")
			end
		end
	end

	if self.data.star ~=nil and self.data.star ~= 0 then
		lbstar:setEnabled(true)
		lbstar:setVisible(true)
		lbstar:setAnchorPoint(0, 0.5)
		lbstar:setPosition(15, 82)
		lbstar:setTextHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT)
		lbstar:enableOutline(cc.c4b(0, 0, 0, 255),2)
		lbstar:setString("+"..tostring(self.data.star))
	else
		lbstar:setEnabled(false)
		lbstar:setVisible(false)
	end

	if self.showlv == true then
		if self.data ~= nil and self.data.edata ~= nil then
			lb:setString("Lv"..tonumber(string.sub(self.data.eid,4,6)))
			--[[if device.platform == "android" or device.platform == "ios" then--lb不是labelttf,没有enableStroke方法
				lb:enableStroke(cc.c3b(0, 0, 0), 2, true)
			end]]
			lb:setPosition(52,0)
			lb:setEnabled(true)
		else
			lb:setEnabled(false)
		end
	else
		if self.showname == true then
			if self.data ~= nil and self.data.edata ~= nil then 
				lb:setFontSize(20)
				lb:setString(self.data.edata.name)
				-- lb:setPosition(42,10)
			end
		else 
			lb:setEnabled(false)
		end	
	end
	
	--如果装备是神器  显示神器特效
	-- dump(self.data)
	if self.data.god ~= nil and self.data.god ~= 0 and #self.data.god > 0 then
		-- self.data.god[4] = 'anti_dam'
		if #self.data.god >= 3 and self.ani == nil then
			local spr
			local frames
			local animation
			display.addSpriteFrames("ui/light.plist","ui/light.png")
			frames = display.newFrames("light%04d.png", 1,12)
			animation = display.newAnimation(frames, 1 / 10) -- 0.5 秒播放 10桢
			spr = display.newSprite()
			spr:playAnimationForever(animation)
			spr:setPosition(52,53)
			self.ani = spr
			self:addChild(spr)
		end
		if #self.data.god >= 4 and self.bk == nil then
			local bk
			local frames
			local animation
			display.addSpriteFrames("ui/bk.plist","ui/bk.png")
			frames = display.newFrames("bk%04d.png", 1,16)
			animation = display.newAnimation(frames, 1 / 10) -- 0.5 秒播放 10桢
			bk = display.newSprite()
			bk:playAnimationForever(animation)
			bk:setPosition(52,53)
			self.bk = bk
			self:addChild(bk)
		end
	end

	--宝石图标放上去
	--先放宝石孔
	-- dimhole.png
	--再放宝石
	if self.data.hole ~= nil then
		local bgitem = nil
		local dimg = nil
		local num = #self.data.hole
		local startx = 106/2 - num*20/2 + 10
		for k,v in pairs(self.data.hole) do
			bgitem = display.newSprite("ui/dimhole.png")
			bgitem:setPosition(startx,23)
			self:addChild(bgitem)
			self.dimbgs[#self.dimbgs + 1] = bgitem

			if v ~= "" then
				local t = string.sub(v,3,3)
				dimg = display.newSprite("ui/dim"..t..".png")
				dimg:setPosition(startx,23)
				self:addChild(dimg)
				self.dims[#self.dims + 1] = dimg
			end
			startx = startx + 20
		end
	end
	--是否点击显示信息
	if self.showInfo == true then
		self.view:setTouchEnabled(true)
		self.view:addTouchEventListener(handler(self,self.onClick))
	else
		self.view:setTouchEnabled(false)
	end
end

--设置道具数据
function ItemFace:setGoodsData(data)
	local border = self.view:getChildByName("border")
	--图片
	local img = self.view:getChildByName("img")
	--文本
	local lb = self.view:getChildByName("lb")
	lb:enableOutline(cc.c4b(0, 0, 0, 255),2)
	--强化等级 也就是星级
	local lbstar = self.view:getChildByName("lbstar")
	--星级
	lbstar:setTouchEnabled(false)
	img:setTouchEnabled(false)	
	border:setTouchEnabled(false)
	lb:setTouchEnabled(false)
	border:loadTexture("ui/90001.png")
	if self.data == nil then
		-- border:loadTexture("ui/img_36.png")
		border:loadTexture("ui/90001.png")
		-- img:loadTexture("ui/board0.png")
		img:loadTexture("ui/comblack84.png")
		lb:setEnabled(false)
		lbstar:setString("")
		lb:setString("")
		self.view:setTouchEnabled(false)
		return
	else
		img:loadTexture("goods/"..data.eid..".png")
	end

	if self.showlv == true then
		if self.data ~= nil and self.data.edata ~= nil and self.data.num~=nil then
			lbstar:setEnabled(true)
			lbstar:setVisible(true)
			lbstar:setFontSize(17)
			lbstar:setAnchorPoint(1, 0.5)
			lbstar:setPosition(90, 25)
			lbstar:setTextHorizontalAlignment(cc.TEXT_ALIGNMENT_RIGHT)
			lbstar:enableOutline(cc.c4b(0, 0, 0, 255),2)
			lbstar:setString("x"..self.data.num)
		else
			lbstar:setEnabled(false)
			lbstar:setVisible(false)
		end
	end

	if self.showname == true then
		if self.data ~= nil and self.data.edata ~= nil then 
			lb:setFontSize(18)
			lb:setString(self.data.edata.name)
			lb:setPosition(52,0)
		end
	else 
		lb:setEnabled(false)
	end	

	--是否点击显示信息
	if self.showInfo == true then
		self.view:setTouchEnabled(true)
		self.view:addTouchEventListener(handler(self,self.onClick))
	else
		self.view:setTouchEnabled(false)
	end
end
--设置充值数据
function ItemFace:setPayData(data)
	local border = self.view:getChildByName("border")
	--图片
	local img = self.view:getChildByName("img")
	img:loadTexture("ui/chargediamond.png")
	--边框颜色
	local color = data
	local border = self.view:getChildByName("border")
	if color == 0 then
		border:loadTexture("ui/90001.png")
	elseif color == 1 then
		border:loadTexture("ui/90004.png")
	elseif color == 2 then
		border:loadTexture("ui/90005.png")
	elseif color == 3 then
		border:loadTexture("ui/90003.png")
	elseif color == 4 then
		border:loadTexture("ui/90002.png")
	end
end
--点击事件
function ItemFace:onClick(sender,eventType)
	if  eventType ~= TouchEventType.ended then 
		return
	end
	local node = display.newNode()
	node.data = self.data
	--区分类型 是装备还是道具 发送不同的消息
	if string.sub(self.data.eid,1,1) == "E" then
		Observer.sendNotification(BagModule.SHOW_EQUIP_INFO, node)	--显示装备信息弹出框
	else
		Observer.sendNotification(BagModule.SHOW_GOODS_INFO, node) --显示道具信息弹出框
	end
end

function ItemFace:reset()
	if self:isTouchEnabled() then
		self.view:addTouchEventListener(nil)
		self:addTouchEventListener(nil)
	end

	self.data = nil
	self.vdata = nil
	if self.ani ~= nil then
		self:removeChild(self.ani, true)
		self.ani = nil
	end

	--点击的时候 是否触发详情界面
	self.showInfo = true
	--默认图片
	self.defaultimg = "ui/comblack84.png"

	--是否显示等级
	self.showlv = true
	self.showname = false

	self:setData()
	self.inited = false
end

--[[
function ItemFace:setVisible(visible)
	getmetatable(self).setVisible(self,visible)
	if visible == true then
		if self.vdata ~= nil and self.data == nil then
			self:setData(self.vdata)
		end
	end
end
]]

function ItemFace:dispose()
	self:reset()
	self:getPool():push(self)
end

function ItemFace:visibled(visible)
--    print("visible:"..tostring(visible).." self.inited:"..tostring(self.inited ))
	if visible and self.inited == false then
		self.inited = true
		self:setData(self.data)
		self:setVisibleEventEnabled(false)
	end
end
return ItemFace