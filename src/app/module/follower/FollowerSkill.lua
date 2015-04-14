-- 佣兵技能处理器
-- Author: wanghe
-- Date: 2014-11-14 10:42:36
--

local FollowerSkillItem = import(".ui.FollowerSkillItem")

local FollowerSkill = class("FollowerSkill",BaseProcessor)

function FollowerSkill:ctor()
	-- body
	self.lockArr = {}
end

function FollowerSkill:ListNotification()
	return {
		FollowerModule.SHOW_FOLLOWER_SKILL,
		FollowerModule.USER_FOLLOWER_SKILL_FLUSH
	}
end

function FollowerSkill:handleNotification(notify, data)
	if notify == FollowerModule.SHOW_FOLLOWER_SKILL then
		self:initUI()
		self:setData(data.id)
	elseif notify == FollowerModule.USER_FOLLOWER_SKILL_FLUSH then
		self:handleSkillRefresh(data.data)
	end
end

--初始化UI显示
-- arg  预留 没用
function FollowerSkill:initUI(arg)
	if self.view ~= nil then
		return
	end
	local view = ResourceManager:widgetFromJsonFile("ui/followerskill.json")
	local btnClose = view:getChildByName("btnClose")
	local btnRefresh = view:getChildByName("btnRefresh")
	local helpBtn = view:getChildByName("helpBtn")
	local txtCost = view:getChildByName("txtCost")
	self.txtCost = txtCost ---花费
	self.list = view:getChildByName("skillscrollview")

	btnClose:addTouchEventListener(handler(self,self.onBtnClick))
	btnRefresh:addTouchEventListener(handler(self,self.onBtnClick))
	helpBtn:addTouchEventListener(handler(self,self.onBtnClick))
	self:addPopView(view)
	self:setView(view)

	self.lockArr = {}
end

--设置数据
function FollowerSkill:setData(id)
	-- print("技能 弟子 id:"..id)
	self.list:removeAllChildren()
	self.fid = id
	local followerData = PlayerData:getSoliderByID(id)
	-- lv sid
	local size = self.list:getInnerContainerSize()

	local w = 550
	local h = 116

	local innerWidth = size.width
	local innerHeight = size.height
	local ystart = innerHeight
	local item = nil 

	self.data = followerData.skills

	for k,v in pairs(followerData.skills) do
		item = FollowerSkillItem.new()
		if self:getLockState(v.sid) then
			v.select = true
		else
			v.select = false
		end
		item:setData(v)
		item:setPosition(5,ystart - h)
		item:addEventListener(FollowerSkillItem.ITEM_SELECT, handler(self,self.handleItemClick))
		self.list:addChild(item)
		ystart = ystart - h
	end

	self:updateCost()
end

--获取技能锁定状态
function FollowerSkill:getLockState(sid)
	for k,v in pairs(self.lockArr) do
		if v == sid then
			return true
		end
	end
	return false
end

--按钮点击处理
function FollowerSkill:onBtnClick(sender,eventType)
	if eventType ~= TouchEventType.ended then
		return
	end

	local btnName = sender:getName()
	if btnName == "btnClose" then
		self:removePopView(self.view)
	elseif btnName == "btnRefresh" then
		local btns = {
			{text = "取消",skin = 2,},
			{text = "确定",skin = 1, callback = handler(self,self.btnRefresh),args = true},
		}
		local alert = GameAlert.new()
		local cfg = DataConfig:getAllConfigMsg()
		local textStr = addArgsToMsg(cfg["30033"],self.cost)
		alert:pop(textStr,"ui/titlenotice.png", btns)
	elseif btnName == "helpBtn" then
		local alert = GameAlert.new()
		alert:popHelp("skill_follower_refresh")
	end
end
function FollowerSkill:btnRefresh()
	self:sendRefresh()
end
--处理Item点击
function FollowerSkill:handleItemClick(event)
	--dump(event)
	self:updateCost()
end

--发送刷新技能
function FollowerSkill:sendRefresh()
	local tskill = {}
	self.lockArr = {}
	for k,v in pairs(self.data) do
		if v.select == true then
			tskill[#tskill+1] = v.sid
			--锁定数组
			self.lockArr[#self.lockArr + 1] = v.sid
		else
			tskill[#tskill+1] = ""
		end
	end
	if #self.lockArr == #self.data then
		print("进来了！！")
		toastNotice("技能全部锁定，无法刷新")
		return
	end

	if self.cost > PlayerData:getCoin() then
		--notice("元宝不足！")
		btns = {{text = "取消",skin = 2},{text = "充值",skin = 3,callback = handler(self,self.sendChargeView)}}
		alert = GameAlert.new()
		richStr = {{text = "您的元宝不足，请您及时充值！",color = display.COLOR_WHITE}}
		alert:pop(richStr,"ui/titlenotice.png",btns)
		return
	end

	local net = {}
	net.method = FollowerModule.USER_FOLLOWER_SKILL_FLUSH
	net.params = {}
	net.params.fid = self.fid
	net.params.skills = tskill
	Net.sendhttp(net)
end
--前去充值
function FollowerSkill:sendChargeView()
	self:removePopView(self.view)
	Observer.sendNotification(ChargeModule.SHOW_CHARGE_VIEW)
end
--处理技能刷新的数据
function FollowerSkill:handleSkillRefresh(data)
	--dump(data)
	local follower = PlayerData:getSoliderByID(data.params.fid)
	follower.skills = data.data.follower.skills
	local notices = {{"刷新成功！",COLOR_GREEN}}
	if self.cost ~= 0 then
		table.insert(notices,{"元宝：-"..self.cost})
	end
	popNotices(notices)
	PlayerData:setCoin(data.data.coin)
	self:setData(data.params.fid)

	local nowCount = PlayerData:getFoSkillReCount()
	PlayerData:setFoSkillReCount(nowCount + 1)
	self:updateCost()

	Observer.sendNotification(FollowerModule.FOLLOWER_SKILL_CHANGE)
end

--更新花费文本
function FollowerSkill:updateCost()
	local cfg = DataConfig:getAllConfigMsg()
	local text = ""

	local nowCount = PlayerData:getFoSkillReCount()
	local freeCount = DataConfig:getFoSkillFreeCount()
	--锁定价格
	local price = DataConfig:getFoSkillPrice()
	--锁定技能个数
	self.lockArr = {}
	for k,v in pairs(self.data) do
		if v.select == true then
			--锁定数组
			self.lockArr[#self.lockArr + 1] = v.sid
		end
	end	
	local lockNum = #self.lockArr

	self.cost = 0
	if nowCount < freeCount then
		if lockNum ~= 0 then
			local cost = lockNum * price
			self.cost = cost
			text = addArgsToMsg(cfg["30024"],cost)
		else
			text = addArgsToMsg(cfg["30034"])
		end
		
		
	else
		local cost = (lockNum + 1) * price
		text = addArgsToMsg(cfg["30024"],cost)
		self.cost = cost
	end

	self.txtCost:setString(text)
	self.text = text

end

return FollowerSkill