local XWebView = class("XWebView",function()
		local n = display.newNode()
		n:retain()
		return n
	end)

function XWebView:ctor()
	webview.setActivityName("com/meng52/game/guagame/Guagame")
end

--打开URL  网页
function XWebView:open(url,xx,yy,ww,hh)
	webview.show(url,xx,yy,ww,hh)
end

--关闭浏览器
function XWebView:remove()
	webview.remove()
	self:release()
end

return XWebView