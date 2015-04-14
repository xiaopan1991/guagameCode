--佣兵培养处理器
--包含普通培养和专精培养
local FollowerFosterProcessor = class("FollowerFosterProcessor",BaseProcessor)
local Followerhead = import(".ui.Followerhead")

function FollowerFosterProcessor:ctor()
	
end

function FollowerFosterProcessor:ListNotification()
	return {
		FollowerModule.SHOW_FOLLOWER_FOSTER
	}
end

function FollowerFosterProcessor:handleNotification(notify, data)
	if notify == FollowerModule.SHOW_FOLLOWER_FOSTER then
		self:initUI()
		self:setData(data)
	end
end

--初始化UI显示
-- arg  预留 没用
function FollowerFosterProcessor:initUI(arg)
	
	if self.view ~= nil and tolua.isnull(self.view) then
		return
	end

	local viewf = ResourceManager:widgetFromJsonFile("ui/followerfoster.json")
	self.viewf = viewf
	self.txtrolelv = viewf:getChildByName("txtrolelv")
	self.txtrole = viewf:getChildByName("txtrole")
	self.txtroleproper = viewf:getChildByName("txtroleproper")
	self.txtrolelv:setString("")
	self.txtrole:setString("")
	self.txtroleproper:setString("")

	local btnCommon = viewf:getChildByName("btnCommon")                 --普通培养
	local btnSpecialization = viewf:getChildByName("btnSpecialization") --专精培养
	local btnClose = viewf:getChildByName("btnClose")
	local helpBtn = viewf:getChildByName("helpBtn")



	btnCommon:addTouchEventListener(handler(self,self.onFollowerBtnClick))
	btnSpecialization:addTouchEventListener(handler(self,self.onFollowerBtnClick))
	btnClose:addTouchEventListener(handler(self,self.onFollowerBtnClick))
	helpBtn:addTouchEventListener(handler(self,self.onFollowerBtnClick))

	self:addPopView(viewf)
	self:setView(viewf)
end
--按钮点击
function FollowerFosterProcessor:onFollowerBtnClick(sender,eventType)
	if  eventType ~= TouchEventType.ended then
		return
	end
	local btn = tolua.cast(sender,"ccui.Button")
	local btnName = btn:getName()
	if btnName == "btnCommon" then
	   local node = display.newNode()
	   node.curFollowerId = self.fid
	   Observer.sendNotification(FollowerModule.SHOW_COMMON_FOSTER,node)
	elseif btnName == "btnSpecialization" then
		local limit = DataConfig:getFollowerSpecialFosterLimitLv()
		if PlayerData:getLv() < limit then
			local btns = {{text = "确定",skin = 3,}}
			local alert = GameAlert.new()
			local richStr = {{text = "弟子专精培养",color = COLOR_RED},
							{text = " 角色等级"..limit.."级开启",color = COLOR_GREEN},}
			alert:pop(richStr,"ui/titlenotice.png",btns)
			return
		end
		local node = display.newNode()
	   	node.curFollowerId = self.fid
	   	Observer.sendNotification(FollowerModule.SHOW_SPECIAL_FOSTER,node)
	elseif btnName == "btnClose" then
		self:removePopView(self.view)
		self.view = nil
	elseif btnName == "helpBtn" then
		local alert = GameAlert.new()
		alert:popHelp("follower_help")
	end
end

--设置数据
--lv、职业、主属性  
function FollowerFosterProcessor:setData(data)
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
	followerHead = Followerhead.new()
	followerHead:setData(fdata)
	followerHead:setPosition(85,554)
	followerHead:setTouchEnabled(false)
	followerHead:setSelected(3)
	self.viewf:addChild(followerHead)
end
return FollowerFosterProcessor