--邮件 处理器
local GameMailProcessor = class("GameMailProcessor", BaseProcessor)
local MailItem = import(".ui.MailItem")

function GameMailProcessor:ctor()
	self.mailData = nil
end

function GameMailProcessor:ListNotification()
	return {
		GamesysModule.SHOW_GAME_MAIL,
		GamesysModule.UPDATE_GAME_MAIL,
		GamesysModule.USER_GET_MSG,
		GamesysModule.USER_GET_GIFT_MSG,
	}
end

function GameMailProcessor:handleNotification(notify, data)
	if notify == GamesysModule.SHOW_GAME_MAIL then
		self:initUI()
		self:sendMailsRequest()
	elseif notify == GamesysModule.UPDATE_GAME_MAIL then
		if(self.view) then
			self:updateMail()
		end
	elseif notify == GamesysModule.USER_GET_MSG then		
		if(self.view) then
			self:updateMail(data.data.data.gift_msg or {})
		end
		local num = table.nums(data.data.data.gift_msg)
		self:sendMailNotice(num)		
	elseif notify == GamesysModule.USER_GET_GIFT_MSG then
		local mdata = self.mailData[data.data.params.gk]
		local notices = {}
		if(data.data.data.coin) then
			if( mdata.gift_dict.coin ) then
				table.insert(notices,{"获得元宝 "..(mdata.gift_dict.coin or 0),COLOR_GREEN})
			end
			PlayerData:setCoin(data.data.data.coin)
		end
		if(data.data.data.lv) then
			PlayerData:setLv(data.data.data.lv)
		end
		if(data.data.data.exp) then
			if( mdata.gift_dict.exp ) then
				table.insert(notices,{"获得经验 "..(mdata.gift_dict.exp or 0),COLOR_GREEN})
			end
			PlayerData:setExp(data.data.data.exp)
		end
		if(data.data.data.gold) then
			if( mdata.gift_dict.gold ) then
				table.insert(notices,{"获得银两 "..(mdata.gift_dict.gold or 0),COLOR_GREEN})
			end
			PlayerData:setGold(data.data.data.gold)
		end
		if(data.data.data.melte) then
			if( mdata.gift_dict.melte ) then
				table.insert(notices,{"获得熔炼值 "..(mdata.gift_dict.melte or 0),COLOR_GREEN})
			end
			PlayerData:setMelte(data.data.data.melte)
		end
		if(data.data.data.mana) then
			if( mdata.gift_dict.mana ) then
				table.insert(notices,{"获得威望 "..(mdata.gift_dict.mana or 0),COLOR_GREEN})
			end
			PlayerData:setMana(data.data.data.mana)
		end
		if(data.data.data.pith) then
			if( mdata.gift_dict.pith ) then
				table.insert(notices,{"获得强化精华 "..(mdata.gift_dict.pith or 0),COLOR_GREEN})
			end
			Bag:addGoods("I0001",data.data.data.pith)
		end
		if(data.data.data.goods) then
			for k,v in pairs(data.data.data.goods) do
				table.insert(notices,{"获得物品 "..(DataConfig:getGoodByID(k).name.."*"..mdata.gift_dict.goods[k]),COLOR_GREEN})
				Bag:addGoods(k,v)
			end
		end
		if(data.data.data.neweids) then
			for k,v in pairs(data.data.data.neweids) do
				local c3 = Bag:getEquipColor(v.color[1])
				table.insert(notices,{"获得装备 "..(DataConfig:getEquipById(v.eid).name),c3})
				Bag:addEquip(k,v)
			end
		end
		popNotices(notices)
		Observer.sendNotification(BagModule.EQUIP_NUM_UPDATE) --数量更新	
		self.mailData[data.data.params.gk] = nil
		if(self.view) then
			self:updateMail()
		end
		local num = table.nums(self.mailData)
		self:sendMailNotice(num)
	end
end
function GameMailProcessor:noMailNotice()
	if(table.nums(self.mailData) == 0) then
	end
end
function GameMailProcessor:sendMailNotice(num)
	local tempNode = display.newNode()
	local data = {}
	tempNode.data = data
	data.mailNum = num
	Observer.sendNotification(IndexModule.MAIL_NOTICE,tempNode)
end
--初始化UI显示
-- arg  预留 没用
function GameMailProcessor:initUI(arg)
	if self.view ~= nil then
		return
	end
	local view = ResourceManager:widgetFromJsonFile("ui/awardpanel.json")
	local taskBtn = view:getChildByName("taskBtn")
	local activityBtn = view:getChildByName("activityBtn")
	local btnCDK = view:getChildByName("btnCDK")
	btnCDK:setVisible(false)
	btnCDK:setEnabled(false)
	taskBtn:removeFromParent(true)
	activityBtn:removeFromParent(true)
	self.title = view:getChildByName("title")
	self.title:loadTexture("ui/titlemail.png")
	self.mailTip = view:getChildByName("mailTip")
	
	local msgs = DataConfig:getAllConfigMsg()
  	self.mailTip:setString(msgs['20016'])
	--self.title:setString("邮 件")
	self.det = display.height - 960
	local theight = 766
	if display.height > 960 then
		theight = 766 + self.det
	end
	local size = view:getLayoutSize()
	view:setContentSize(cc.size(size.width,theight))
	local bg = view:getChildByName("imgbg")
	local bgsize = bg:getLayoutSize()
	bg:setContentSize(cc.size(bgsize.width,bgsize.height + self.det))

	if self.awardview == nil then
		self.awardview = ResourceManager:widgetFromJsonFile("ui/awardview.json")
		
		local relarg = ccui.RelativeLayoutParameter:create()
		relarg:setAlign(ccui.RelativeAlign.alignParentTopLeft)
		local margin = {}
		margin.top = 125
		margin.left = 0
		relarg:setMargin(margin)
		self.awardview:setLayoutParameter(tolua.cast(relarg,"ccui.LayoutParameter"))

		local size = self.awardview:getLayoutSize()
		self.awardview:setContentSize(cc.size(size.width,size.height + self.det))

		self.scrollview = self.awardview:getChildByName("awardScroll")
		self.imabg = self.awardview:getChildByName("imabg")
		
		local listsize = self.scrollview:getContentSize()
		bgsize = self.imabg:getContentSize()
		self.imabg:setContentSize(cc.size(bgsize.width,bgsize.height+self.det))
		self.scrollview:setContentSize(cc.size(listsize.width,listsize.height+self.det))	
		view:addChild(self.awardview)
	end	
	self:setView(view)
	self:addMidView(view,true)
end
function GameMailProcessor:sendMailsRequest()
	local net = {}
	net.method = GamesysModule.USER_GET_MSG
	net.params = {}
	Net.sendhttp(net)
end
function GameMailProcessor:updateMail(mailData)
	if(mailData) then
		self.mailData = mailData
	end
	local mailArr = {}
	for k,v in pairs(self.mailData) do
		v.id = k
		table.insert(mailArr,v)
	end
	local function sortMail(a,b)
		-- body
		return a.time["$datetime"] > b.time["$datetime"]
	end
	table.sort(mailArr,sortMail)
	if(self.limitTxt) then
		--self.limitTxt:removeFromParent(true)
		self.limitTxt = nil
	end
	self.scrollview:removeAllChildren()
	self.renders = {}	
    local rowPadding = 5
	local w = 545
	local leftPadding = (self.scrollview:getContentSize().width - w)/2

	--滚动条宽度
	local innerWidth = self.scrollview:getInnerContainerSize().width
	--设置滚动条内容区域大小
	
	local render = nil
	
	local i = 1
	local totalh = rowPadding
	for k,v in ipairs(mailArr) do
		render = MailItem.new()
		render:setData(v)
		table.insert(self.renders, render)
		self.scrollview:addChild(render)
		i = i + 1
		totalh = totalh + render:getContentSize().height + rowPadding
	end
	self.scrollview:setInnerContainerSize(cc.size(innerWidth,math.max(totalh,self.scrollview:getContentSize().height)))
	local innerHeight = self.scrollview:getInnerContainerSize().height
	--y起始坐标
	local ystart = innerHeight 
	for i,v in ipairs(self.renders) do
		v:setPosition(leftPadding,ystart - v:getContentSize().height - rowPadding)
		ystart = ystart - v:getContentSize().height - rowPadding
	end
	--重新刷一下显示数据
	self.scrollview:setInnerContainerSize(cc.size(innerWidth,math.max(totalh,self.scrollview:getContentSize().height)))

	local cfg = DataConfig:getAllConfigMsg()		
	if(#mailArr == 0) then
		-- self.limitTxt = CCLabelTTF:create(cfg["10159"],DEFAULT_FONT,30,cc.size(500,50),kCCTextAlignmentCenter)
		self.limitTxt = display.newTTFLabel({
			text = cfg["10159"],
			font = DEFAULT_FONT,
			size = 30,
		})
		self.limitTxt:setColor(COLOR_RED)
		self.limitTxt:setPosition(innerWidth/2,self.scrollview:getContentSize().height/2)
		self.scrollview:addChild(self.limitTxt)
		self.scrollview:setBounceEnabled(false)
		--toastNotice(cfg["10159"],COLOR_GREEN)
	else
		self.scrollview:setBounceEnabled(true)
	end
end
--移除界面
function GameMailProcessor:onHideView(view)
	if self.view ~= nil then
		self.awardview:removeAllChildren()
		self.awardview:removeFromParent(true)
		self.view:removeFromParent(true)
		self.view = nil
		self.awardview = nil
	end
	self.isshow = false;
end
return GameMailProcessor