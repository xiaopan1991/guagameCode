--专精培养item
local SpecialItem = class("SpecialItem", function ()
	local node = ccui.Layout:create()
	node:setContentSize(cc.size(550,128))
	cc(node):addComponent("components.behavior.EventProtocol"):exportMethods()
	return node
end)

SpecialItem.skin = nil

SpecialItem.ITEM_SELECT = "ITEM_CLICK"

--弟子技能条
function SpecialItem:ctor()
	self:init()
end

--初始化UI
function SpecialItem:init()
	if SpecialItem.skin == nil then
		SpecialItem.skin = ResourceManager:widgetFromJsonFile("ui/specialitem.json")
		SpecialItem.skin:retain()
	end

	local view = SpecialItem.skin:clone()
	self:addChild(view)
	self.view = view
	 
	self.txtIntro = view:getChildByName("txtIntro")
	self.txtPropre = view:getChildByName("txtPropre")
	self.spicon = view:getChildByName("spicon")
	self.selectBtn = view:getChildByName("selectBtn")
	--进度条
	self.redBar = view:getChildByName("redBar")
	self.blueBar = view:getChildByName("blueBar")
	self.greenBar = view:getChildByName("greenBar")
	self.purpleBar = view:getChildByName("purpleBar")
	self.redBar:setPercent(0)
	self.blueBar:setPercent(0)
	self.greenBar:setPercent(0)
	self.purpleBar:setPercent(0)
	--check box
	self.selectBtn:addEventListener(handler(self,self.handleCheckItem))
end

--checkBOX点击
function SpecialItem:handleCheckItem(sender,eventType)
	if  eventType == CheckBoxEventType.selected then 
		--self.selectInfo = true
		self:dispatchEvent({name =  SpecialItem.ITEM_SELECT, data = true,info = self.selectInfo})
	elseif eventType == CheckBoxEventType.unselected then
		--self.selectInfo = false
		self:dispatchEvent({name =  SpecialItem.ITEM_SELECT, data = false,info = self.selectInfo})
	end
end

--设置数据
--参数的设定
--1.信息"strr"，"agi"，"intt"，"sta"  2.系数（变化量）
--3.最大值   4.notice标志，1表示培养界面，2表示保村或取消的界面
--5.fid      6.self.lock 用来判断是否锁住
function SpecialItem:setData(data)
	self.data = data
	--dump(self.data)
	self.selectInfo = self.data[1]
	--文字显示
	local tro = 0

	local attr = self.data[1]
	local attrValue = self.data[2]
	local maxValue = self.data[3]
	local notice = self.data[4]
	local fid = self.data[5]
	local isLock = self.data[6]

	self.spicon:loadTexture("ui/"..attr..".png")
	
	--上一次的
	local follower = PlayerData:getSoliderByID(fid)
	local CoeData = follower.special_train
	local halfnum = maxValue/2
	local bi = attrValue/maxValue*100
	if notice == 1 then
		if attrValue > halfnum then

			self.purpleBar:setPercent(bi)
			self.blueBar:setPercent(0)
		else
			self.blueBar:setPercent(bi)
			self.purpleBar:setPercent(0)
		end
		self.redBar:setPercent(0)
		self.greenBar:setPercent(0)
		self.txtPropre:setString(attrValue.."/"..maxValue)

		self.selectBtn:setTouchEnabled(true)
		--选中状态
		if isLock == true then
			self.selectBtn:setSelected(true)
		else
			self.selectBtn:setSelected(false)
		end	
		if attr == "sta" then
			tro = attrValue*1000
		else
			tro = attrValue*100
		end
	else
		self.selectBtn:setTouchEnabled(false)
		local preNum = CoeData[attr]
		local currNum = preNum + attrValue
		if attr == "sta" then
			tro = currNum*1000
		else
			tro = currNum*100
		end
		local isfirst = true
		for k,v in pairs(CoeData) do
			if v ~= 0 then
				isfirst = false
				break
			end
		end
		if isfirst then
			if isLock == true then
				self.txtPropre:setString(attrValue.."/"..maxValue)
			else
				self.txtPropre:setString(preNum.."--"..attrValue)
			end
			self.blueBar:setPercent(bi)
		else
			--第二次以上的培养
			-- local preNum = CoeData[attr]
			-- local currNum = preNum + attrValue
			local bizhic = currNum/maxValue*100
			local bizhip = preNum/maxValue*100
			if isLock == true then
				self.txtPropre:setString(currNum.."/"..maxValue)
			else
				self.txtPropre:setString(preNum.."--"..currNum)
				if currNum >= preNum then
					self.greenBar:setPercent(bizhic)
				else
					if currNum > halfnum then
						self.redBar:setPercent(bizhip)
						self.purpleBar:setPercent(bizhic)
						self.blueBar:setPercent(0)
					else
						self.blueBar:setPercent(bizhic)
						self.redBar:setPercent(bizhip)
						self.purpleBar:setPercent(0)
					end
					
				end	



			end
		end
	end
	local cfg = DataConfig:getAllConfigMsg()
	if self.data[1] == "strr" then
		str = addArgsToMsg(cfg["30019"],tro)
		self.txtIntro:setString(str)
	end
	if self.data[1] == "agi" then
		str = addArgsToMsg(cfg["30020"],tro)
		self.txtIntro:setString(str)
	end
	if self.data[1] == "intt" then
		str = addArgsToMsg(cfg["30021"],tro)
		self.txtIntro:setString(str)
	end
	if self.data[1] == "sta" then
		str = addArgsToMsg(cfg["30022"],tro)
		self.txtIntro:setString(str)
	end
end

return SpecialItem