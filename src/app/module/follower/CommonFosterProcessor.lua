--佣兵普通培养处理器
local CommonFosterProcessor = class("CommonFosterProcessor",BaseProcessor)
local Followerhead = import(".ui.Followerhead")

function CommonFosterProcessor:ctor()
	
end

function CommonFosterProcessor:ListNotification()
	return {
		FollowerModule.SHOW_COMMON_FOSTER,
		FollowerModule.USER_FOLLOWER_TRAIN,
		FollowerModule.USER_CHANGE_TRAIN_STATUS
	}
end

function CommonFosterProcessor:handleNotification(notify, data)
	if notify == FollowerModule.SHOW_COMMON_FOSTER then
		self:initUI()
		self:setData(data)
	elseif notify ==  FollowerModule.USER_FOLLOWER_TRAIN then
		--返回培养的数据
		self:handlerFollowerFosterData(data.data)
	elseif notify == FollowerModule.USER_CHANGE_TRAIN_STATUS then
		--返回弟子培养保存或取消的数据
		self:handlerKeepOrCancleData(data.data)
	end
end

--初始化UI显示
-- arg  预留 没用
function CommonFosterProcessor:initUI(arg)
	if self.view ~= nil then
		return
	end

	local viewc = ResourceManager:widgetFromJsonFile("ui/followercommonfoster.json")
	self.viewc = viewc
	self.txtrolelv = viewc:getChildByName("txtrolelv")
	self.txtrole = viewc:getChildByName("txtrole")
	self.txtroleproper = viewc:getChildByName("txtroleproper")
	self.txtrolelv:setString("")
	self.txtrole:setString("")
	self.txtroleproper:setString("")
	--培养前
	self.txtBpower = viewc:getChildByName("txtBpower")                 --力道
	self.txtBspeed = viewc:getChildByName("txtBspeed")                 --身法
	self.txtBinner = viewc:getChildByName("txtBinner")                 --内劲
	self.txtBphysique = viewc:getChildByName("txtBphysique")           --体质 
	self.txtBpower:setString("")
	self.txtBspeed:setString("")
	self.txtBinner:setString("")
	self.txtBphysique:setString("")

	--需要消耗的元宝或者银两
	self.cominfo = viewc:getChildByName("cominfo")
	self.superinfo = viewc:getChildByName("superinfo")
	self.ptinfo = viewc:getChildByName("ptinfo")
	self.extreinfo = viewc:getChildByName("extreinfo")
	local com = DataConfig:onFosterNeedCoin(1)
	local super = DataConfig:onFosterNeedCoin(2)
	local pt = DataConfig:onFosterNeedCoin(3)
	local extre = DataConfig:onFosterNeedCoin(4)
	self.comNeed = com[2]
	self.superNeed = super[2]
	self.ptNeed = pt[2]
	self.extreNeed = extre[2]
	self.cominfo:setString(""..self.comNeed.."银两")
	self.superinfo:setString(""..self.superNeed.."元宝")
	self.ptinfo:setString(""..self.ptNeed.."元宝")
	self.extreinfo:setString(""..self.extreNeed.."元宝")
	--培养后
	self.laterpower = viewc:getChildByName("laterpower")
    self.laterspeed = viewc:getChildByName("laterspeed")
    self.laterinner = viewc:getChildByName("laterinner") 
    self.laterphysique = viewc:getChildByName("laterphysique")

	self.txtLpower = viewc:getChildByName("txtLpower")                 --力道
	self.txtLspeed = viewc:getChildByName("txtLspeed")                 --身法
	self.txtLinner = viewc:getChildByName("txtLinner")                 --内劲
	self.txtLphysique = viewc:getChildByName("txtLphysique")           --体质
	self.txtLpower:setString("")
	self.txtLspeed:setString("")
	self.txtLinner:setString("")
	self.txtLphysique:setString("")

	local btnComfoster = viewc:getChildByName("btnComfoster")          --普通培养
	local btnSuperfoster = viewc:getChildByName("btnSuperfoster")      --高级培养
	local btnptfoster = viewc:getChildByName("btnptfoster")            --白金培养
	local btnExtremefoster = viewc:getChildByName("btnExtremefoster")  --至尊培养

	local btnCancle = viewc:getChildByName("btnCancle")                --取消
	local btnKeep = viewc:getChildByName("btnKeep")                    --保持
	local btnClose = viewc:getChildByName("btnClose")                  --关闭

	enableBtnOutLine(btnKeep,COMMON_BUTTONS.ORANGE_BUTTON)

	local title = btnKeep:getTitleText()
	btnKeep:setTitleText('')
	btnKeep:setTitleText(title)

	btnComfoster:addTouchEventListener(handler(self,self.onFollowerBtnClick))
	btnSuperfoster:addTouchEventListener(handler(self,self.onFollowerBtnClick))
	btnptfoster:addTouchEventListener(handler(self,self.onFollowerBtnClick))
	btnExtremefoster:addTouchEventListener(handler(self,self.onFollowerBtnClick))
	btnCancle:addTouchEventListener(handler(self,self.onFollowerBtnClick))
	btnKeep:addTouchEventListener(handler(self,self.onFollowerBtnClick))
	btnClose:addTouchEventListener(handler(self,self.onFollowerBtnClick))

	self.btnComfoster = btnComfoster
	self.btnSuperfoster = btnSuperfoster
	self.btnptfoster = btnptfoster
	self.btnExtremefoster = btnExtremefoster

	self.btnCancle = btnCancle
    self.btnKeep = btnKeep


	self:addPopView(viewc)
	self:setView(viewc)
end
--设置数据
function CommonFosterProcessor:setData(data)
	local fid = data.curFollowerId
	self.fid = fid
	local follower = PlayerData:getSoliderByID(fid)
	--dump(follower)
	local flv = PlayerData:getLv()
	local name = follower.name
	self.txtrolelv:setString("lv."..flv.."  "..name)
	
	local tp = tonumber(follower.hero_type)
	local playertp = PlayerType[tp]
	self.txtrole:setString("职业："..playertp)

	local properInfo = DataConfig:getJobById(follower.hero_type)
	if(properInfo.ma == "int") then
		properInfo.ma = "intt"
	end
	if(properInfo.ma == "str") then
		properInfo.ma = "strr"
	end
	local str,proper = getAttrName(properInfo.ma)
	self.txtroleproper:setString("主属性："..proper)

	--头像
	local fdata ={}
	local followerHead = {}
	fdata.lock = false
	fdata.job = follower.hero_type
	fdata.choose = false
	followerHead = Followerhead.new()
	followerHead:setData(fdata)
	followerHead:setPosition(85,563)
	followerHead:setTouchEnabled(false)
	followerHead:setSelected(true)
	self.viewc:addChild(followerHead)

	--培养前
	self.mstrr = follower.jobAttrs["strr"]
	self.magi = follower.jobAttrs["agi"]
	self.mintt = follower.jobAttrs["intt"]
	self.msta = follower.jobAttrs["sta"]
	self.currstrr = self.mstrr +follower.train["strr"]
	self.curragi = self.magi+follower.train["agi"]
	self.currintt = self.mintt+follower.train["intt"]
	self.currsta = self.msta+follower.train["sta"]
	self:onBeforechangeData(self.currstrr,self.curragi,self.currintt,self.currsta)

	 --判断上次的培养是否有未保存的
	local keepData = PlayerData:getFosterKeepData(self.fid)
	-- dump(keepData)
	if keepData == nil or table.nums(keepData) == 0 then
		self:onBtnVisible(true)
	else
		self:onBtnVisible(false)
		self:onLaterchangeData(keepData)
	end

end
--按钮点击
function CommonFosterProcessor:onFollowerBtnClick(sender,eventType)
	if  eventType ~= TouchEventType.ended then
		return
	end
	local btn = tolua.cast(sender,"ccui.Button")
	local btnName = btn:getName()
	local coin = PlayerData:getCoin() --元宝
	local gold = PlayerData:getGold() --银两
	local curvipLv = PlayerData:getVipLv()

	--vip等级限制
	local vipLimO = DataConfig:onFosterVipLimite(1)
	local vipLimT = DataConfig:onFosterVipLimite(2)
	local vipLimTh = DataConfig:onFosterVipLimite(3)
	local vipLimF = DataConfig:onFosterVipLimite(4)

	local cfg = DataConfig:getAllConfigMsg()

	--先判断vip等级 再判断元宝或银两
	if btnName == "btnComfoster" then
		if curvipLv < vipLimO then
			return
		end
		if gold < self.comNeed then
			toastNotice("银两不足,请充值！")
			return
		end
		notice("银两-"..self.comNeed,COLOR_RED)
	    self:onSendFosterHandler(1)
	    self:onBtnVisible(false)
	elseif btnName == "btnSuperfoster" then
		if curvipLv < vipLimT then
			local vipInfo2 = DataConfig:onFosterVipInfo(2)
			local str = addArgsToMsg(cfg["30039"],vipLimT,vipInfo2)
			toastNotice(str)
			return
		end
		if coin < self.superNeed then
			--notice("元宝数量不足,请充值！",COLOR_GREEN)
			self:onNoticeCoin()
			return
		end
		self:onCoinCost(self.superNeed)
	    self:onSendFosterHandler(2)
	    self:onBtnVisible(false)
	elseif btnName == "btnptfoster" then
		if curvipLv < vipLimTh then
			local vipInfo3 = DataConfig:onFosterVipInfo(3)
			local str = addArgsToMsg(cfg["30039"],vipLimTh,vipInfo3)
			toastNotice(str)
			return
		end
		if coin < self.ptNeed then
			--notice("元宝数量不足,请充值！",COLOR_GREEN)
			self:onNoticeCoin()
			return
		end
		self:onCoinCost(self.ptNeed)
		self:onSendFosterHandler(3)
		self:onBtnVisible(false)
	elseif btnName == "btnExtremefoster" then
		if curvipLv < vipLimF then
			local vipInfo4 = DataConfig:onFosterVipInfo(4)
			local str = addArgsToMsg(cfg["30039"],vipLimF,vipInfo4)
			toastNotice(str)
			return
		end
		if coin < self.extreNeed then
			--notice("元宝数量不足,请充值！",COLOR_GREEN)
			self:onNoticeCoin()
			return
		end
		self:onCoinCost(self.extreNeed)
		self:onSendFosterHandler(4)
		self:onBtnVisible(false)
	elseif btnName == "btnKeep" then
		self:onBtnVisible(true)
		self:onsendKeepOrCancleHandler(1,1)
	elseif btnName == "btnCancle" then
		self:onBtnVisible(true)
		self:onsendKeepOrCancleHandler(1,2)
	elseif btnName == "btnClose" then
		self:removePopView(self.view)
		-- self.view = nil
	end

end
--元宝的消耗量
function CommonFosterProcessor:onCoinCost(needCost)
	notice("元宝:-"..needCost,COLOR_RED)
end
--元宝不足提示框
function CommonFosterProcessor:onNoticeCoin()
	btns = {{text = "取消",skin = 2},{text = "充值",skin = 3,callback = handler(self,self.sendChargeView)}}
	alert = GameAlert.new()
	richStr = {{text = "您的元宝不足，请您及时充值！",color = display.COLOR_WHITE}}
	alert:pop(richStr,"ui/titlenotice.png",btns)
end
--前去充值
function CommonFosterProcessor:sendChargeView()
	PopLayer:clearPopLayer()
	Observer.sendNotification(ChargeModule.SHOW_CHARGE_VIEW)
end
--向服务器发送培养的消息
--fid 弟子的ID
--t_type 培养的类型1,2,3,4 分别对应普通培养,高级培养,白金培养,至尊培养
function CommonFosterProcessor:onSendFosterHandler(type)
	local data = {}
	data.method = FollowerModule.USER_FOLLOWER_TRAIN
	data.params = {}
	data.params.t_type = type
	data.params.fid = self.fid
	Net.sendhttp(data)
end

--返回培养的数据(四个点击按钮的)
function CommonFosterProcessor:handlerFollowerFosterData(data)
	-- dump(data,"",99)
	local _coin = data.data.coin
	local _gold = data.data.gold
	PlayerData:setCoin(_coin)
	PlayerData:setGold(_gold)
	
	local tempValue = data.data.follower_train_value
	PlayerData:setFosterKeepData(tempValue)
	local keepData = PlayerData:getFosterKeepData(self.fid)
	if keepData ~= nil then
		-- keepData.temp_value = tempValue
		self:onLaterchangeData(keepData)
	end
end
--培养后文本的变化
function CommonFosterProcessor:onLaterchangeData(temp_value)
	local changestrr = temp_value["strr"]
	local changeagi = temp_value["agi"]
	local changeintt = temp_value["intt"]
	local changesta = temp_value["sta"]
	local chstrr = (changestrr > 0  and "+"..changestrr) or changestrr
	local chagi = (changeagi > 0  and "+"..changeagi) or changeagi
	local chintt = (changeintt > 0  and "+"..changeintt) or changeintt
	local chsta =  (changesta > 0  and "+"..changesta) or changesta
		
	local colstrr = self.currstrr + changestrr
	local colagi = self.curragi + changeagi
	local colintt = self.currintt + changeintt
	local colsta = self.currsta + changesta
	--根据变量，颜色的变化。变量增加显示绿色，减少显示红色，0显示白色
	local changes = {changestrr,changeagi,changeintt,changesta}
	local txtColor = {self.txtLpower,self.txtLspeed,self.txtLinner,self.txtLphysique}
	for k,v in pairs(changes) do
		if v > 0 then
			txtColor[k]:setColor(COLOR_GREEN)
		elseif v < 0 then
			txtColor[k]:setColor(COLOR_RED)
		elseif v == 0 then
			txtColor[k]:setColor(display.COLOR_WHITE)
		end
	end
	self.changes = changes
	self.txtColor = txtColor
	self.txtLpower:setString(""..colstrr.."("..""..chstrr..")")
	self.txtLspeed:setString(""..colagi.."("..""..chagi..")")
	self.txtLinner:setString(""..colintt.."("..""..chintt..")")
	self.txtLphysique:setString(""..colsta.."("..""..chsta..")") 
end
--培养前文本的变化
function CommonFosterProcessor:onBeforechangeData(currstrr,curragi,currintt,currsta)
	self.txtBpower:setString(""..currstrr)
	self.txtBspeed:setString(""..curragi)
	self.txtBinner:setString(""..currintt)
	self.txtBphysique:setString(""..currsta)
end

--按钮是否显示
--flag  true  四个培养按钮显示
--      false 保存取消按钮显示
function CommonFosterProcessor:onBtnVisible(flag)
	if flag == true then
		self.btnComfoster:setEnabled(true)
	    self.btnSuperfoster:setEnabled(true)
		self.btnptfoster:setEnabled(true)
		self.btnExtremefoster:setEnabled(true)

		self.btnComfoster:setVisible(true)
	    self.btnSuperfoster:setVisible(true)
		self.btnptfoster:setVisible(true)
		self.btnExtremefoster:setVisible(true)
		--花费多少的文本显示
		self.cominfo:setVisible(true)
		self.superinfo:setVisible(true)
		self.ptinfo:setVisible(true)
		self.extreinfo:setVisible(true)

		self.btnCancle:setEnabled(false)
		self.btnKeep:setEnabled(false)
		self.btnCancle:setVisible(false)
		self.btnKeep:setVisible(false)
    	

    	--培养后的文字及文本
    	self.laterpower:setVisible(false)
    	self.laterspeed:setVisible(false)
    	self.laterinner:setVisible(false)
    	self.laterphysique:setVisible(false)

    	self.txtLpower:setVisible(false)
		self.txtLspeed:setVisible(false)
		self.txtLinner:setVisible(false)
		self.txtLphysique:setVisible(false)

		self.txtLpower:setString("")
		self.txtLspeed:setString("")
		self.txtLinner:setString("")
		self.txtLphysique:setString("")
    elseif flag == false  then
    	self.btnComfoster:setEnabled(false)
	    self.btnSuperfoster:setEnabled(false)
		self.btnptfoster:setEnabled(false)
		self.btnExtremefoster:setEnabled(false)
		self.btnComfoster:setVisible(false)
	    self.btnSuperfoster:setVisible(false)
		self.btnptfoster:setVisible(false)
		self.btnExtremefoster:setVisible(false)

		self.cominfo:setVisible(false)
		self.superinfo:setVisible(false)
		self.ptinfo:setVisible(false)
		self.extreinfo:setVisible(false)

		self.btnCancle:setEnabled(true)
		self.btnKeep:setEnabled(true)
		self.btnCancle:setVisible(true)
		self.btnKeep:setVisible(true)
    	

    	self.laterpower:setVisible(true)
    	self.laterspeed:setVisible(true)
    	self.laterinner:setVisible(true)
    	self.laterphysique:setVisible(true)

    	self.txtLpower:setVisible(true)
		self.txtLspeed:setVisible(true)
		self.txtLinner:setVisible(true)
		self.txtLphysique:setVisible(true)
	end
	 
end
--向服务器弟子培养保存或取消
--status:1为保存 2为取消
--ftype : 1为普通培养, 2为专精培养
function CommonFosterProcessor:onsendKeepOrCancleHandler(ftype,status)
	local data = {}
	data.method = FollowerModule.USER_CHANGE_TRAIN_STATUS
	data.params = {}
	data.params.ftype = ftype
	data.params.status = status
	data.params.fid = self.fid
	Net.sendhttp(data)
end
--保存或取消后的数据
function CommonFosterProcessor:handlerKeepOrCancleData(data)
	if data.params.ftype ~= 1 then
		return
	end

	--dump(data,"",99)
	local train = data.data.follower.train

	local restrr = self.mstrr + train["strr"]
	local reagi = self.magi + train["agi"]
	local reintt = self.mintt + train["intt"]
	local resta = self.msta + train["sta"]
	self:onBeforechangeData(restrr,reagi,reintt,resta)
	PlayerData:addSoliderTrainAttrsByID(self.fid,train)
	self.currstrr = restrr
	self.curragi = reagi
	self.currintt = reintt
	self.currsta = resta

	local pa = data.params["status"]
	--1 保存 2 取消
	local trainValue = data.data.follower_train_value
	PlayerData:setFosterKeepData(trainValue)
	local followerInfo = {"力道：","身法：","内劲：","体质："}
	local str = ""
	local color = nil
	local notices = {}
	if pa == 1 then
		for k,v in pairs(self.changes) do
			if v > 0 then
				color = COLOR_GREEN
			elseif v < 0 then
				color = COLOR_RED
			elseif v == 0 then
				color = display.COLOR_WHITE
			end
			v = (v > 0  and "+"..v) or v
			str = followerInfo[k] ..v
			table.insert(notices,{str,color})
		end
		popNotices(notices)
		PlayerData:updateSoliderAttrsByID(self.fid)
		Observer.sendNotification(FollowerModule.FOLLOWER_FOSTER_CHANGE)
	end
end
return CommonFosterProcessor