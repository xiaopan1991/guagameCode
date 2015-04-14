local UIEditBox = class("UIEditBox", function(width,height,bg)
    local editbox = ccui.EditBox:create(cc.size(width, height), bg or "ui/blank.png")
    editbox.setString = editbox.setText
    editbox.getString = editbox.getText
	return editbox
end)


--构造
function UIEditBox:ctor()
	self.minLength = 2
	self.maxLength = 20
    self:registerScriptEditBoxHandler(handler(self,self.onEdit))

end
--maxlength
function UIEditBox:setMaxLength(length)
	self.maxLength = length
end

function UIEditBox:getMaxLength(length)
	return self.maxLength
end
--minlength
function UIEditBox:setMinLength(length)
	self.minLength = length
end

function UIEditBox:getMinLength(length)
	return self.minLength
end
--限定长度
function UIEditBox:onEdit(event, editbox)
    if event == "began" then
        -- 开始输入
    elseif event == "changed" then
        -- 输入框内容发生变化
        local _text = editbox:getText()
        local tn = string.split(_text," ")
    	local str = table.concat(tn)
    	_text = str
    	editbox:setText(_text)
    	dump(_text)
		if string.utf8len(_text) >= self.maxLength then
			local _trimed = string.utf8sub(_text,1,self.maxLength)
    		editbox:setText(_trimed)
    		--notice("最大长度为"..self.maxLength,COLOR_GREEN)
    	end
    	if string.utf8len(_text) < self.minLength then
    		notice("最小长度为"..self.minLength)
    		return
    	end
    elseif event == "ended" then
        -- 输入结束
    elseif event == "return" then
        -- 从输入框返回
    end
end

return UIEditBox