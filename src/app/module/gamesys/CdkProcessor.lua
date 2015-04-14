local CdkProcessor = class("CdkProcessor", BaseProcessor)

function CdkProcessor:ctor()
end

function CdkProcessor:ListNotification()
	return {
		GamesysModule.SHOW_CDK_VIEW,
		GamesysModule.USER_GET_REWARD_BY_CODE
	
	}
end

function CdkProcessor:handleNotification(notify, data)
	if notify == GamesysModule.SHOW_CDK_VIEW then
		self:onSetView()
		self:onSetData()
	elseif notify == GamesysModule.USER_GET_REWARD_BY_CODE then
		self:onCDKData(data.data)
	end
end

function CdkProcessor:onSetView()
	if self.view ~= nil then
		return
	end
 	local cdkpanel = ResourceManager:widgetFromJsonFile("ui/cdkpanel.json")

 
 	local btnClose = cdkpanel:getChildByName("btnClose")
	local btnExchange = cdkpanel:getChildByName("btnExchange")
	btnClose:addTouchEventListener(handler(self,self.onbtnClick))
	btnExchange:addTouchEventListener(handler(self,self.onbtnClick))

	enableBtnOutLine(btnClose,COMMON_BUTTONS.BLUE_BUTTON)
	enableBtnOutLine(btnExchange,COMMON_BUTTONS.ORANGE_BUTTON)

	local txtCdk = ccui.EditBox:create(cc.size(260,40), "ui/blank.png")
    txtCdk:setContentSize(cc.size(260,40))
    txtCdk:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)
    txtCdk:setFontSize(18)
    txtCdk:setFontColor(cc.c3b(255,240,1))
    txtCdk:setFontName(DEFAULT_FONT)
    txtCdk:setPosition(325,149)
    txtCdk:setPlaceHolder("请输入CDkey兑换码")
    txtCdk:setPlaceholderFont(DEFAULT_FONT,18)
    txtCdk:setMaxLength(13)
    cdkpanel:addChild(txtCdk,5)
    self.txtCdk = txtCdk

	self:addPopView(cdkpanel,true)
	self:setView(cdkpanel)
end
--数据
function CdkProcessor:onSetData()

  
end
--按钮事件的处理
function CdkProcessor:onbtnClick(sender,eventType)
	if  eventType ~= TouchEventType.ended then
		return
	end
	local btn = tolua.cast(sender,"ccui.Button")
	local btnName = btn:getName()
	if btnName == "btnExchange" then
		local cdkstr = self.txtCdk:getText()
		if cdkstr == "" then
			toastNotice("兑换码不能为空")
			return
		end
		
		local data = {}
		data.method = GamesysModule.USER_GET_REWARD_BY_CODE
		data.params = {}
		data.params.code = cdkstr
		Net.sendhttp(data)
	elseif btnName == "btnClose" then
		self:removePopView(self.view)
	end
end
--兑换数据回来
function CdkProcessor:onCDKData(data)
	--dump(data)
	self:removePopView(self.view)
	local rewarddata = data.data.rewards
	local equip = rewarddata.equip
	local coin = rewarddata.coin
	local exp = rewarddata.exp
	local gold = rewarddata.gold
	local melte = rewarddata.melte
	local pith = rewarddata.pith
	local richStr = {}
	if equip ~= nil then
		local equipEid 
		local equipColor
		for k,v in pairs(equip) do
			Bag:addEquip(k,v)
			equipEid = v.eid
			equipColor = v.color
			local getEquipName = DataConfig:getEquipById(equipEid).name
			local lv = tonumber(string.sub(equipEid,4,6))
			local c3 = Bag:getEquipColor(equipColor[1])
			local namestr = "Lv"..lv.." "..getEquipName
			--table.insert(notices,{"获得装备："..namestr,COLOR_GREEN})
			table.insert(richStr, {text = "获得装备：",color = COLOR_GREEN})
			table.insert(richStr,{text = namestr.."\n",color = c3})
		end
		
	end
	if coin ~= nil then
		local curCoin = PlayerData:getCoin()
		local changeCoin = curCoin + coin
		PlayerData:setCoin(changeCoin)
		--table.insert(notices,{"获得元宝："..coin,COLOR_GREEN})
		table.insert(richStr, {text = "获得元宝："..coin.."\n",color = COLOR_GREEN})
	end
	if exp ~= nil then
		local curExp = PlayerData:getExp()
		local changeExp = curExp + exp
		PlayerData:setExp(changeExp)
		--table.insert(notices,{"获得经验："..exp,COLOR_GREEN})
		print("显示经验"..exp)
		table.insert(richStr, {text = "获得经验："..exp.."\n",color = COLOR_GREEN})
	end
	if gold ~= nil then
		local curGold = PlayerData:getGold()
		local changeGold = curGold + gold
		PlayerData:setGold(changeGold)
		--table.insert(notices,{"获得银两："..gold,COLOR_GREEN})
		table.insert(richStr, {text = "获得银两："..gold.."\n",color = COLOR_GREEN})
	end
	if melte ~= nil then
		local curMelte = PlayerData:getMelte()
		local changeMelte = curMelte + melte
		PlayerData:setMelte(changeMelte)
		--table.insert(notices,{"获得熔炼值："..melte,COLOR_GREEN})
		table.insert(richStr, {text = "获得熔炼值："..melte.."\n",color = COLOR_GREEN})
	end
	if pith ~= nil then
		local pithData = Bag:getGoodsById("I0001")
		if(pithData) then
			Bag:addGoods("I0001",pithData.num + pith)
		else
			Bag:addGoods("I0001",pith)
		end
		--table.insert(notices,{"获得强化精华数量："..pith,COLOR_GREEN})
		table.insert(richStr, {text = "获得强化精华数量："..pith.."\n",color = COLOR_GREEN})
	end
	--popNotices(notices)
	local btns = {{text = "确定",skin = 3}}
	local alert = GameAlert.new()
	alert:pop(richStr,"ui/titlenotice.png",btns)

end 
return CdkProcessor

