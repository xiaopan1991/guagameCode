local StrLib = require("app.data.StrLib")
--富文本
local XRichText = class("XRichText",function ()
	return ccui.Layout:create()
end)

--构造
function XRichText:ctor()
	local rtext = ccui.RichText:create()
   	rtext:ignoreContentAdaptWithSize(false)
   	--默认大小
   	rtext:setContentSize(cc.size(400,200))
   	self.text = rtext
   	self:addChild(rtext)
end

--设置大小
function XRichText:setContentSize(size)
	self.text:setContentSize(size)
end

--得到大小
function XRichText:getContentSize()
	return self.text:getTextSize()
end
--追加字符串
--str    文本
--color  颜色
--size 	 字号
--font   字体
--tag 	 标记
function XRichText:appendStr(str,color,size,font,tag)
	local tcolor = color or display.COLOR_WHITE
	local ttag = tag or 1
	local tsize = size or 18
	local tfont = font or DEFAULT_FONT
	local ele = ccui.RichElementText:create(ttag,tcolor,255,str,tfont,tsize)
	-- local ele = RichElementText:create(1,cc.c3b(255,0,255),255,"quick-cocos2d-x是一个快速开发的框架quick-cocos2d-x是一个快速开发的框架quick-cocos2d-x是一个快速开发的框架quick-cocos2d-x是一个快速开发的框架quick-cocos2d-x是一个快速开发的框架","MSYH",24)
	self.text:pushBackElement(ele)
end

--追加多条字符串
--table里单条的内容  如下
--str    文本
--color  颜色
--size 	 字号
--font   字体
--tag 	 标记
function XRichText:appendStrs(table)
	for k,v in pairs(table) do
		self:appendStr(v.text,v.color,v.size,v.font,v.tag)
	end
end

--根据模板追加
--	通过sid 和 args生成模板  再渲染出来
-- 	arg 格式  【文本 颜色 字号 字体】   颜色 字号 字体可省略，省略之使用模板的颜色字号字体
-- 	local template = {
--                     {"This is a n test",{255,255,255},20,"微软雅黑"},
--                     {"hello world",{255,0,0},20,"微软雅黑" }
-- 			}
function XRichText:append(sid,args)
	local table = XRichText.getStrTable(sid,args)

	local txt = ""
	local color = display.COLOR_WHITE
	local size = 20
	local font = DEFAULT_FONT

	for k,v in pairs(table) do
		--重置
		txt = ""
		color = display.COLOR_WHITE
		size = 20
		font = DEFAULT_FONT


		txt = v[1]
		if v[2] ~= nil then
			color = cc.c3b(v[2][1], v[2][2], v[2][3])
		end
		size = v[3] or size
		font = v[4] or font
		self:appendStr(txt,color,size,font)
	end
end

--	通过sid 和 args生成模板
-- 	arg 格式  【文本 颜色 字号 字体】   颜色 字号 字体可省略，省略之使用模板的颜色字号字体
-- 	local template = {
--                     {"This is a n test",{255,255,255},20,"微软雅黑"},
--                     {"hello world",{255,0,0},20,"微软雅黑" }
-- 			}
--	
--	
--	

function XRichText.getStrTable(sid,arg)
	--获取模板
	local template = StrLib[sid]
	--结果
	local result = {}

	for k, v in pairs(template) do
    local str = v[1]
    local i = 0
    local j = 0
    local lastj = 0
	    while i~= nil do
	        i,j = string.find(str,'%%s',i+1)
	        if i == nil then
	            if lastj <= #str then
	                local t = string.sub(str,lastj,#str)
	                result[#result+1] = {t,v[2],v[3],v[4]}
	            end
	            break
	        end
	        if lastj <= (i - 1) then
	            local te = string.sub(str,lastj,i-1)
	            result[#result+1] = {te,v[2],v[3],v[4]}
	        end
	        lastj = j+1
	        local tempstr = string.sub(str,i,j)
	        result[#result+1] = {tempstr,v[2],v[3],v[4]}
	    end
	end
	--args 替换 %s
	local index = 1
	for l,m in pairs(result) do
		if m[1] == "%s" then
			if arg[index] == nil then
				m[1] = ""
				break
			end
			--dump(arg[index])
			m[1] = arg[index][1]  --字符串
			if arg[index][2] ~= nil then  --颜色
				m[2] = arg[index][2]
			end
			if arg[index][3] ~= nil then  --字号
				m[3] = arg[index][3]
			end
			if arg[index][4] ~= nil then   --字体
				m[4] = arg[index][4]
			end
			index = index + 1
		end
	end
	return result
end


function XRichText:setVerticalSpace(space)
	self.text:setVerticalSpace(space)
end
function XRichText:clear()
	self.text:clear()
end

--描边
function XRichText:enableOutline(outlineColor, outlineSize)
	self.text:enableOutline(outlineColor, outlineSize)
end


return XRichText