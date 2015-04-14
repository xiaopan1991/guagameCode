--
-- Author: Your Name
-- Date: 2015-01-23 10:13:54
--
local MultiBattleResultCell = class("MultiBattleResultCell", function()
		local layout = ccui.Layout:create()
		layout:setContentSize(cc.size(594,125))
		return layout
	end)
function MultiBattleResultCell:ctor()
	if MultiBattleResultCell.skin == nil then
		MultiBattleResultCell.skin = ResourceManager:widgetFromJsonFile("ui/MultiBattleResultCell.json")
		MultiBattleResultCell.skin:retain()
	end
	self.view = MultiBattleResultCell.skin:clone()
	self.teamname1 = self.view:getChildByName("teamname1")
	self.teamname2 = self.view:getChildByName("teamname2")
	self.numtxt = self.view:getChildByName("numtxt")
	self.resultsign = self.view:getChildByName("resultsign")
	self.lookbtn = self.view:getChildByName("lookbtn")
	self.lookbtn:addTouchEventListener(handler(self,self.onClick))
	self:addChild(self.view)
end
function MultiBattleResultCell:setData(index,data)
	self.index = index
	self.data = data
	--dump(self.data, nil, 999)
	local teamleader1 = self.data.team_leader_uid[1]
	if(teamleader1 ~= "") then
		for i,v in ipairs(self.data.my_team) do
			if(v[1] == teamleader1) then
				teamleader1 = (v[2]).."的小队"
				break
			end
		end
	else
		teamleader1 = "自由的小队"
	end
	local teamleader2 = self.data.team_leader_uid[2]
	if(teamleader2 ~= "") then
		for i,v in ipairs(self.data.rival_team) do
			if(v[1] == teamleader2) then
				teamleader2 = (v[2]).."的小队"
				break
			end
		end
	else
		teamleader2 = "自由的小队"
	end
	if(self.data.case == "lose_team") then
		self.resultsign:loadTexture("ui/multibattlefailure.png")
		self.teamname1:setString(teamleader1)
		self.teamname2:setString(teamleader2)
	elseif(self.data.case == "win_team") then
		self.resultsign:loadTexture("ui/multibattlevictory.png")
		self.teamname1:setString(teamleader1)
		self.teamname2:setString(teamleader2)
	elseif(self.data.case == "miss_team") then
		self.resultsign:loadTexture("ui/multibattlevictory.png")
		self.lookbtn:setVisible(false)
		self.lookbtn:setEnabled(false)
		self.teamname1:setString(teamleader1)
		self.teamname2:setString("轮空")
		self.teamname2:setColor(COLOR_WHITE)
	end
	self.numtxt:setString("第"..self.index.."轮")
end
function MultiBattleResultCell:onClick(sender,eventType)
	if  eventType ~= TouchEventType.ended then 
		return
	end
	local tempNode = display.newNode()
	local data = {}
	tempNode.data = self.data
	tempNode.index = self.index
	Observer.sendNotification(MultiBattleModule.SHOW_MULTI_BATTLE_ONE_RESULT,tempNode)
end
return MultiBattleResultCell