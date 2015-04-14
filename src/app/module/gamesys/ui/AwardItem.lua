local AwardItem = class(AwardItem, function()
	local node = ccui.Layout:create()
	cc(node):addComponent("components.behavior.EventProtocol"):exportMethods()
	node:setContentSize(cc.size(545,127))
    return node
end)
function AwardItem:ctor()
	if(not AwardItem.view) then
		AwardItem.view = ResourceManager:widgetFromJsonFile("ui/itemaward.json")
		AwardItem.view:retain()
	end	
	local itemAward = AwardItem.view:clone()
	self.rewardIcon = itemAward:getChildByName("rewardIcon")
	self.getImg = itemAward:getChildByName("getImg")
	self.getImg:loadTexture("ui/awardIma.png")
	self.txtInfo = itemAward:getChildByName("txtInfo")
	self.txtName = itemAward:getChildByName("txtName")
	self.conditionTxt = itemAward:getChildByName("conditionTxt")
	self.rewardTxt = itemAward:getChildByName("rewardTxt")
	self.rewardTxt:setColor(cc.c3b(0,255,0))
	self.rewardTxt:getVirtualRenderer():setMaxLineWidth(300)
	self.rewardTxt:getVirtualRenderer():setLineBreakWithoutSpace(true)

	self.bg002 = itemAward:getChildByName("bg002")
	self.imagebg = itemAward:getChildByName("imagebg")
	self.imagebg:setTouchEnabled(true)
	self.imagebg:addTouchEventListener(handler(self,self.onClick)) 
	self:addChild(itemAward)
	self.itemAward = itemAward
end
function AwardItem:onClick(sender,eventType)
	if  eventType ~= TouchEventType.ended then 
		return
	end
	if(self.data.canget) then
		self:setRequestAward()
	else
		toastNotice("未完成，无法领取奖励")
	end	
end
function AwardItem:setRequestAward()
	local net = {}
	net.method = GamesysModule.USER_TASK_DONE
	net.params = {}
	net.params.task_key = self.data.id
	Net.sendhttp(net)
end
function AwardItem:setData(data)
	self.data = data

	local adata = DataConfig:getAllTask()[data.id]
	local cfg = DataConfig:getAllConfigMsg()
	self.txtName:setString(cfg[tostring(adata.name)])
	if(adata.res) then
		self.rewardIcon:loadTexture("ui/gift/"..adata.res..".png")
	end

	local content = adata.content[data.content + 1]
	self.txtInfo:setString(self.data.txtInfo)
	self.conditionTxt:setString(self.data.conditionTxt)
	self.getImg:setVisible(self.data.canget)

	
	local awarddata = content.gift	
	local chDic = {coin = "元宝",exp = "经验",melte = "熔炼值",pith = "强化精华",silver = "银两",gold = "银两",}
	local info = "奖励:"
	for k,v in pairs(awarddata) do
		if(chDic[k]) then
			info = info..chDic[k].."*"..v.." "
		elseif(k == "goods") then
			for kk,vv in pairs(v) do
				info = info..DataConfig:getGoodByID(kk).name.."*"..vv.." "
			end
		elseif(k == "equip") then
			for kk,vv in pairs(v) do
				info = info..DataConfig:getEquipById(kk).name.."*"..vv.." "
			end
		end
	end
	self.rewardTxt:setString(info)
	local tempH = self.rewardTxt:getVirtualRendererSize().height
	if(tempH > 53) then
		local addH = tempH - 53
		self:setContentSize(cc.size(545,127+addH))
		self.itemAward:setContentSize(cc.size(545,127+addH))
		self.imagebg:setContentSize(cc.size(545,127+addH))
		self.bg002:setContentSize(cc.size(321,80+addH))
	end
end


return AwardItem
