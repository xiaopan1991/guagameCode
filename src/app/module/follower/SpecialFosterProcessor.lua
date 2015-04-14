--专精培养处理器
local SpecialFosterProcessor = class("SpecialFosterProcessor",BaseProcessor)
local SpecialItem = import(".ui.SpecialItem")

function SpecialFosterProcessor:ctor()
	self.lock = {
		["strr"]=false,
		["agi"]=false,
		["intt"]=false,
		["sta"]=false,
	}
	--存储item显示对象
	self.items = {}
end

function SpecialFosterProcessor:ListNotification()
	return {
		FollowerModule.SHOW_SPECIAL_FOSTER,
		FollowerModule.USER_FOLLOWER_SPECIAL_TRAIN,
		FollowerModule.USER_CHANGE_TRAIN_STATUS
	
	}
end

function SpecialFosterProcessor:handleNotification(notify, data)
	if notify == FollowerModule.SHOW_SPECIAL_FOSTER then
		self:initUI()
		self:setData(data)
	elseif notify == FollowerModule.USER_FOLLOWER_SPECIAL_TRAIN then
		--返回培养的数据
		self:handlerSpecialFosterData(data.data)
	elseif notify == FollowerModule.USER_CHANGE_TRAIN_STATUS then
		--返回保存或取消的数据
		self:handlerSpecialKeepOrCancleData(data.data)
	end
end

--初始化UI显示
-- arg  预留 没用
function SpecialFosterProcessor:initUI(arg)
	if self.view ~= nil then
		return
	end

	local view = ResourceManager:widgetFromJsonFile("ui/followerspecialfoster.json")
	self.txtSpeCost = view:getChildByName("txtSpeCost")--专精培养消耗
	self.txtSpeCoin = view:getChildByName("txtSpeCoin")--每锁定一个属性消耗
	self.txtSpeCost:setString("")
	self.txtSpeCoin:setString("")
	self.spbg = view:getChildByName("spbg")
	

	local btnCancle = view:getChildByName("btnCancle")                --取消
	local btnKeep = view:getChildByName("btnKeep")                    --保持
	local btnClose = view:getChildByName("btnClose")                  --关闭
	local btnSpFoster = view:getChildByName("btnSpFoster")            --培养
	local helpBtn = view:getChildByName("helpBtn")			--帮助

	enableBtnOutLine(btnKeep,COMMON_BUTTONS.ORANGE_BUTTON)

	local title = btnKeep:getTitleText()
	btnKeep:setTitleText('')
	btnKeep:setTitleText(title)

	btnCancle:addTouchEventListener(handler(self,self.onFollowerBtnClick))
	btnKeep:addTouchEventListener(handler(self,self.onFollowerBtnClick))
	btnClose:addTouchEventListener(handler(self,self.onFollowerBtnClick))
	btnSpFoster:addTouchEventListener(handler(self,self.onFollowerBtnClick))
	helpBtn:addTouchEventListener(handler(self,self.onFollowerBtnClick))


	self.btnSpFoster = btnSpFoster
	self.btnKeep = btnKeep
	self.btnCancle = btnCancle


	self.btnCancle = btnCancle
    self.btnKeep = btnKeep
    self:onBtnVisible(true)

	self:addPopView(view)
	self:setView(view)
end
--设置数据
function SpecialFosterProcessor:setData(data)
	local fid = data.curFollowerId
	self.fid = fid
	local follower = PlayerData:getSoliderByID(fid)
	--dump(follower)
	local specialTrain = follower.special_train

	
	local mrang = DataConfig:getSpecialLvRange()
	self.mrang = mrang

	local size = self.spbg:getContentSize()

	local w = 550
	local h = 115

	local innerWidth = size.width
	local innerHeight = size.height
	local xstart = 0
	local ystart = innerHeight - h - 4
	

	local rowPadding = 3
	local colNum = 1
	local index = 0 
	local item = nil 


	-- local testData = {
	-- 	["strr"] = {"力道：每100点力道额外提升0点外防"},
	-- 	["agi"] = {"身法：每100点身法额外提升0点会心"},
	-- 	["intt"] = {"内劲：每100点内劲额外提升0点内防"},
	-- 	["sta"] = {"体质：每100点体质额外提升0点生命值"},
	-- }
	--notice 提示标志1上一次的，2当前这次的
	self.notice = 1
	local keys = {"strr","agi","intt","sta"}
	local len = table.nums(specialTrain)
	local v = nil

	for i=1,len do
		item = self.items[keys[i]]
		if item == nil then
			item = SpecialItem.new()
			self.items[keys[i]] = item
		end
		v = specialTrain[keys[i]]
		flog = self.lock[keys[i]]
		item:setData({keys[i],v,mrang,self.notice,fid,flog})
		item:setPosition(xstart+12,ystart - math.modf(index/colNum)*(h + rowPadding))
		item:addEventListener(SpecialItem.ITEM_SELECT, handler(self,self.handleItemClick))
		self.spbg:addChild(item)
		index = index + 1
	end
	self.spgold = DataConfig:getSpecialNeedGold()
	self.lockcoin = DataConfig:getSpecialNeedCoin()
	local cfg = DataConfig:getAllConfigMsg()
	local str = addArgsToMsg(cfg["30025"],self.spgold)
	local instr = addArgsToMsg(cfg["30026"],self.lockcoin)
	self.txtSpeCost:setString(str)
	self.txtSpeCoin:setString(instr)
	
	 --判断上次的专精培养是否有未保存的
	local spkeepData = PlayerData:getSpecialKeepData(self.fid)
	if spkeepData == nil or table.nums(spkeepData) == 0 then
		self:onBtnVisible(true)
	else
		self:onBtnVisible(false)
		self.notice = 2
		self:onItemDataChange(self.notice,spkeepData,fid)
		return
	end

	
end
function SpecialFosterProcessor:onBtnVisible(flag)
	if flag == true then
		self.btnSpFoster:setEnabled(true)
		self.btnKeep:setEnabled(false)
		self.btnCancle:setEnabled(false)
		self.btnSpFoster:setVisible(true)
		self.btnKeep:setVisible(false)
		self.btnCancle:setVisible(false)
		
	elseif flag == false  then
		self.btnSpFoster:setEnabled(false)
		self.btnKeep:setEnabled(true)
		self.btnCancle:setEnabled(true)
		self.btnSpFoster:setVisible(false)
		self.btnKeep:setVisible(true)
		self.btnCancle:setVisible(true)
	end
end

--按钮点击
function SpecialFosterProcessor:onFollowerBtnClick(sender,eventType)
	if  eventType ~= TouchEventType.ended then
		return
	end
	local btn = tolua.cast(sender,"ccui.Button")
	local btnName = btn:getName()
	if btnName == "btnSpFoster" then
		--专精培养时，先判断银两和元宝是否够用
		local currGold = PlayerData:getGold()
		local currCoin = PlayerData:getCoin()
		local num = 0
		for k,v in pairs(self.lock) do
			if v == true then
				num = num + 1
			end
		end
		
		if num ~= 0 then
			local lockCoin = self.lockcoin * num
			if currCoin < lockCoin then
				--notice("元宝数量不足"..lockCoin,COLOR_GREEN)
				btns = {{text = "取消",skin = 2},{text = "充值",skin = 3,callback = handler(self,self.sendChargeView)}}
				alert = GameAlert.new()
				richStr = {{text = "您的元宝不足，请您及时充值！",color = display.COLOR_WHITE}}
				alert:pop(richStr,"ui/titlenotice.png",btns)
				return
			end
		end
		if currGold < self.spgold then
			toastNotice("银两不足,请充值！")
			return
		end
		--判断是否4个都锁住
		if num == 4 then
			toastNotice("属性已经全部锁定，无法进行培养")
			return
		end
		self:onBtnVisible(false)
		self:onSendFosterHandler(self.fid,self.lock)
	elseif btnName == "btnKeep" then
		self:onBtnVisible(true)
		self:onsendSpecialKeepOrCancleHandler(2,1)
	elseif btnName == "btnCancle" then
		self:onBtnVisible(true)
		self:onsendSpecialKeepOrCancleHandler(2,2)
		--self:removePopView(self.view)
	elseif btnName == "btnClose" then
		self.items = {}
		self:removePopView(self.view)
		self.view = nil
	elseif btnName == "helpBtn" then
		local alert = GameAlert.new()
		alert:popHelp("equip_help")
	end

end
--前去充值
function SpecialFosterProcessor:sendChargeView()
	PopLayer:clearPopLayer()
	Observer.sendNotification(ChargeModule.SHOW_CHARGE_VIEW)
end
--向服务器发送专精培养的消息
--fid 弟子的ID
--lock : 锁定状态,数据格式如下,True为锁定状态
	-- {
	-- 'intt' : False,
	-- 'strr' : True,
	-- 'agi' : False,
	-- 'sta' : False
	-- }
function SpecialFosterProcessor:onSendFosterHandler(_fid,_lock)
	local data = {}
	data.method = FollowerModule.USER_FOLLOWER_SPECIAL_TRAIN
	data.params = {}
	data.params.fid = _fid
	data.params.lock = _lock
	Net.sendhttp(data)
end
--专精培养返回数据
function SpecialFosterProcessor:handlerSpecialFosterData(data)
	--dump(data)
	print("已经回来数据")
	--元宝和银两的消耗
	local num = 0
	local mlocks = data.params.lock
	for k,v in pairs(mlocks) do
		if v == true then
			num = num + 1
		end
	end
	local notices = {}
	if num ~= 0 then
		local lockcoin = self.lockcoin * num 
		table.insert(notices,{"元宝:-"..lockcoin,COLOR_RED})
	end
	table.insert(notices,{"银两:-"..self.spgold,COLOR_RED})
	popNotices(notices)
	local _coin = data.data.coin
	local _gold = data.data.gold
	PlayerData:setCoin(_coin)
	PlayerData:setGold(_gold)

	--系数变更，进度条变化
	local spData = data.data.follower_special_train_value
	local specialData = spData[self.fid]
	
	local tempValue = data.data.follower_train_value
	PlayerData:setSpecialKeepData(spData)
	local keepData = PlayerData:getSpecialKeepData(self.fid)
	if keepData ~= nil then
		self.notice = 2
		self:onItemDataChange(self.notice,specialData,self.fid)
	end
	-- self.notice = 2
	-- self:onItemDataChange(self.notice,specialData,self.fid)
end
--item 数据的变化
function SpecialFosterProcessor:onItemDataChange(notice,data,id)
	local keys = {"strr","agi","intt","sta"}
	local len = table.nums(data)
	local v = nil
	local item = nil
	for i=1,len do
		item = self.items[keys[i]]
		v = data[keys[i]]
		flog = self.lock[keys[i]]
		item:setData({keys[i],v,self.mrang,self.notice,id,flog})
	end
	
end
--处理Item点击
function SpecialFosterProcessor:handleItemClick(event)
	--dump(event)
	local bool = event.data
	local _info = event.info
	self.lock[_info] = bool
	
end
--向服务器弟子专精培养保存或取消
--status:1为保存 2为取消
--ftype : 1为普通培养, 2为专精培养
function SpecialFosterProcessor:onsendSpecialKeepOrCancleHandler(ftype,status)
	local data = {}
	data.method = FollowerModule.USER_CHANGE_TRAIN_STATUS
	data.params = {}
	data.params.ftype = ftype
	data.params.status = status
	data.params.fid = self.fid
	Net.sendhttp(data)
end
--保存或取消后的数据
function SpecialFosterProcessor:handlerSpecialKeepOrCancleData(data)
	if data.params.ftype ~= 2 then
		return
	end
	 --dump(data,nil,999)
	 print("保存了！！！")
	local sptrain = data.data.follower.special_train
	local id = data.params.fid
	--item变化
	self.notice = 1
	self:onItemDataChange(self.notice,sptrain,id)

	PlayerData:setSoliderSpecialTrainByID(id,sptrain)
	
	local pa = data.params["status"]
	--1 保存 2 取消
	local sptrainValue = data.data.follower_special_train_value
	PlayerData:setSpecialKeepData(sptrainValue)

	if pa == 1 then
		PlayerData:updateSoliderAttrsByID(self.fid)
		Observer.sendNotification(FollowerModule.FOLLOWER_FOSTER_CHANGE)
	end
end
return SpecialFosterProcessor