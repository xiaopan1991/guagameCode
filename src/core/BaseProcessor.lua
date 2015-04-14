--处理器基类
local Observer = import(".Observer")
local BaseProcessor = class("BaseProcessor", Observer)

--构造
function BaseProcessor:ctor()
	self.module = nil
end

--Processor关心的消息列表
function BaseProcessor:ListNotification()
	-- body
	return {}
end

--处理notify 由子类去处理
-- function BaseProcessor:handleNotification(notify,data)
	-- body
-- end

--注册
function BaseProcessor:register()
	-- body
	local listNotify = self:ListNotification()
	if #listNotify == 0 then 
		return 
	end
	--v 是字符串消息
	for k,v in pairs(listNotify) do
		self:registerNotification(v)
	end
end

--反注册
function BaseProcessor:unregister()
	-- body
	local listNotify = self:ListNotification()
	if #listNotify == 0 then 
		return 
	end
	--v 是字符串消息
	for k,v in pairs(listNotify) do
		self:unregisterNotification(v)
	end
end

--将显示对象和Processor 绑定，单个Processor对应多个view的情况  需要手动绑定
function BaseProcessor:setView(view)
	self.view = view
	view.processor = self
end

--子类重写 显示窗口
function BaseProcessor:onSetView(view)

end

--初始化UI显示
-- arg  预留 没用
function BaseProcessor:initUI(arg)
	
end

--设置数据
function BaseProcessor:setData(data)
	
end

--关闭
function BaseProcessor:onClose(view)
	if self.view ~= nil then 
		self.view:removeAllChildren()
		self.view = nil
	end
end

--移除绑定的窗口view
function BaseProcessor:onHideView(view)
	if self.view ~= nil then
        self.view:removeFromParent()        
		self.view = nil
	end
	self.isshow = false;
end

--如果scene里没有下列方法 会报错

--添加顶部UI
function BaseProcessor:addTopView(view)
	self.isshow = true
	GameInstance.mainScene:addTopView(view)
end

--添加中部UI
function BaseProcessor:addMidView(view,isremoveTop)
	self.isshow = true;
	GameInstance.mainScene:addMidView(view,isremoveTop)
end

--添加底部UI
function BaseProcessor:addBottomView(view)
	self.isshow = true;
	GameInstance.mainScene:addBottomView(view)
end
--添加弹出UI
function BaseProcessor:addPopView(view)
	self.isshow = true;
	PopLayer:popView(view)
end
--删除弹出UI 
function BaseProcessor:removePopView(view)
	self.isshow = false;
	PopLayer:removePopView(view)
end
return BaseProcessor