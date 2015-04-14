--
-- Author: Your Name
-- Date: 2014-12-08 10:35:49
--
local PopLayer = class("PopLayer",function()
		local layout =  ccui.Layout:create()
        layout:setContentSize(cc.size(display.width,display.height))
        layout:setTouchEnabled(true)
		layout:retain()
		return layout
	end)
function PopLayer:ctor()
	self.popview = {}
    self.popviewbg = {}
    self.curScene = nil
end
function PopLayer:setCurScene(scene)
    self.curScene = scene
end
function PopLayer:popView(view)
    --将自己添加到当前scene，并pop出view
    -- 一定要用addWidget 用addChild会导致不响应触摸事件
    -- 不管哪种类的popview，只要不是一个个体，都可以添加多个
    -- 只想显示单个个体的popview，类使用单例来实现
    if(table.indexof(self.popview,view)) then
    	print("view已经添加")
    	return
    end
    if self:getParent() == nil then
		self.curScene:addChild(self)
    end

    local popbg = display.newScale9Sprite("ui/popbg.png", 0, 0, cc.size(display.width, display.height))
    popbg:setPosition((display.width)/2,(display.height)/2)

    self:addChild(popbg)

    self.popviewbg[#self.popviewbg+1] = popbg

    local size = view:getContentSize()
    self:addChild(view)
    view:setPosition((display.width-size.width)/2,(display.height-size.height)/2)
    self.popview[#self.popview+1] = view
end
function PopLayer:removePopView(view)--remove掉view，如果self.popview长度为0，移除自己
	if(view == nil or tolua.isnull(view)) then
		return
	end
	local popindex = table.indexof(self.popview, view)
    if(popindex) then
        table.remove(self.popview,popindex)
    end
    --self.popview[#self.popview] = nil 
	if view.processor ~= nil then
        view.processor:onHideView()
    else
        view:removeFromParent(true)
    end
    --[[self.popviewbg[#self.popviewbg]:removeFromParent(true)
    self.popviewbg[#self.popviewbg] = nil ]]
    if(popindex) then
        self.popviewbg[popindex]:removeFromParent(true)
        table.remove(self.popviewbg,popindex)
    end

    if table.nums(self.popview) == 0 then
        self.curScene:removeChild(self)
    end	
end
function PopLayer:clearPopLayer()
    for k,v in pairs(self.popview) do
        if v.processor ~= nil then
            v.processor:onHideView(v)
        else
            v:removeFromParent(true)
        end
    end
    for k,v in pairs(self.popviewbg) do
        v:removeFromParent(true)
    end
    self.popview = {}
    self.popviewbg = {}
--    self:clear()
    if(self.curScene) then
        self.curScene:removeChild(self)
    end
end
return PopLayer