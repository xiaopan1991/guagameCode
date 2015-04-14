--Module 模块基类
local BaseModule = class("BaseModule")

--构造
function BaseModule:ctor()
	self.processor = {}
end

--Processor列表  由子类去重写
function BaseModule:ProcessorList()
	-- body
	return {}
end

--注册Processor
function BaseModule:registerProcessor()
	local prolist = self:ProcessorList()
	if #prolist == 0 then
		return
	end
	--v 是BaseProcessor的子类
	for k,v in pairs(prolist) do
		--实例化
		local pro = v.new()
		--注册
		pro:register()
		pro.module = self
		--保存
		table.insert(self.processor,pro)
	end
end

--反注册Processor
function BaseModule:unregisterProcessor()
	-- body
	local prolist = self.processor
	if #prolist == 0 then
		return
	end
	--v 是BaseProcessor的子类
	for k,v in pairs(prolist) do
		v:unregister()
	end
	--清空表
	self.processor = {}
end

--获取同一个module下的Processor
function BaseModule:getProcessorByName(processorName)
	for k,v in pairs(self.processor) do
		if v.__cname == processorName then
			return v
		end
	end
end

return BaseModule