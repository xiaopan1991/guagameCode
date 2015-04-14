--对象池
--	
local ObjectPoolManager = class("ObjectPoolManager")

function ObjectPoolManager:ctor()
	self.objArr = {}
end

--初始化
function ObjectPoolManager:init(classType,num)
	self.classType = classType
	local obj = nil 
	for i=1,num do
		obj = classType.new()
        obj:retain()
		self.objArr[#self.objArr+1] = obj
	end
end
--从缓冲池里取
function ObjectPoolManager:pop()
	local len = #self.objArr
	if len == 0 then
		local obj = self.classType.new()
		obj:retain()
		return obj
	end
	local obj = self.objArr[#self.objArr]
    self.objArr[#self.objArr] = nil
	return obj
end
function ObjectPoolManager:getLen()
	return #self.objArr
end
--放回缓冲池
function ObjectPoolManager:push(obj)
    self.objArr[#self.objArr+1] = obj
end

return ObjectPoolManager