--
-- Author: Your Name
-- Date: 2015-01-23 10:56:14
--
local MultiBattleOneResultCell = class("MultiBattleOneResultCell", function()
		local layout = ccui.Layout:create()
		layout:setContentSize(cc.size(299,103))
		return layout
	end)
function MultiBattleOneResultCell:ctor()
	if MultiBattleOneResultCell.skin == nil then
		MultiBattleOneResultCell.skin = ResourceManager:widgetFromJsonFile("ui/MultiBattleOneResultCell.json")
		MultiBattleOneResultCell.skin:retain()
	end
	self.view = MultiBattleOneResultCell.skin:clone()
	self.bg = self.view:getChildByName("bg")
	self.nametxt = self.view:getChildByName("nametxt")
	self.scoretxt = self.view:getChildByName("scoretxt")
	self.killtxt = self.view:getChildByName("killtxt")
	self.bg:setTouchEnabled(true)
	self.bg:addTouchEventListener(handler(self,self.onClick)) 
	self:addChild(self.view)
end
function MultiBattleOneResultCell:onClick(sender,eventType)
	if  eventType ~= TouchEventType.ended then 
		return
	end
	local net = {}
	net.method = BagModule.USER_GET_USER_INFO
	net.params = {}
	net.params.uid = self.data[1]
	Net.sendhttp(net)
end
function MultiBattleOneResultCell:setData(data,bgood,bself)
	self.data = data
	self.bgood = bgood
	self.bself = bself
	self.nametxt:setString(data[2])
	self.scoretxt:setString("得分："..data[3])
	if(data[4] == 0) then
		self.killtxt:setString("未击杀")
		self.killtxt:setColor(COLOR_BLUE)
	else
		self.killtxt:setString("击杀："..data[4])
		self.killtxt:setColor(COLOR_YELLOW)
	end
	if(bleader) then
		self.bg:loadTexture("ui/multibattlebg10.png")
	elseif(bgood) then
		self.bg:loadTexture("ui/multibattlebg8.png")
	else
		self.bg:loadTexture("ui/multibattlebg9.png")
	end
end
return MultiBattleOneResultCell