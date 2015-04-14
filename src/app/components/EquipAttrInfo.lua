--装备属性容器

--
-- "equips": {
--         "e4": {			--装备ID
--             "color": [
--                 4, 		--道具品级
--                 2, 		--力道
--                 2, 		--身法
--                 2, 		--内劲
--                 2 		--体质
--             ], 
--             "eid": "E000010",   --静态属性
--             "god": 0, 		--是否神器 >0 就是神器
--             "hole": [		--装备孔洞
--                 "", 			--宝石
--                 ""			--宝石
--             ], 
--             "star": 0 		--强化等级
--         }, 
--    }
local ItemFace = import(".ItemFace")
local XRichText = import(".XRichText")
local EquipAttrInfo = class("EquipAttrInfo",function ()
	local node = ccui.Layout:create()
	return node
end)

EquipAttrInfo.defaultTxtwidth = 220

function EquipAttrInfo:ctor()
	self.labels = {}
	self.txtwidth = 220
end

--设置数据
--data 数据
--max 是否显示 触发神属性和宝石 默认 false
function EquipAttrInfo:setData(data,max,maxStrengthenLv)
	local richtext = nil
	if self.richtext ~= nil then
		self.richtext:removeFromParent()
		self.richtext = nil
	end

	richtext = XRichText.new()
	self.richtext = richtext
	-- richtext:setVerticalSpace(2)

	self.richtext:setContentSize(cc.size(self.txtwidth,0))

	self.richtext:setPosition(-90-(EquipAttrInfo.defaultTxtwidth - self.txtwidth)/2,-20)
	self:addChild(self.richtext)

	max = max or false
	self.padding = 20
	self.fontsize = 20
	--先清空属条目
	if self.labels ~= nil and #self.labels ~= 0 then
		for k,v in pairs(self.labels) do
			v:removeFromParent()
		end
	end
	
	self.labels = {}
	if data == nil then
		self.curHeight = 0
		return
	end
	--y从0开始 向下是负的
	local curHeight = 0 --当前累计的长度
	if data.edata == nil then 
		data.edata = DataConfig:getEquipById(data.eid)
	end	
	local c3 = Bag:getEquipColor(data.color[1])

	--名字
	if data.edata ~= nil then 
		local lv = tonumber(string.sub(data.eid,4,6))
		-- self.richtext:appendStr()
		-- self:appendStr("Lv"..lv.." "..data.edata.name, 30,c3)
		dump(data)
		local st = ""
		if data.star and data.star > 0 then
			st = "(+"..data.star..")"
		end
		local lb = self:getLabel("Lv"..lv.." "..data.edata.name..st, 22,c3)
		self.labels[#self.labels+1] = lb
		self:addChild(lb)
	else
		printError("道具找不到"..data.eid)
		return
	end
	--职业限制
	local player_type = string.sub(data.eid,2,2)
	if player_type == "0" then
		self:appendStr("只有武当可以装备",18,cc.c3b(255,205,30))
	elseif player_type == "1" then
		self:appendStr("只有丐帮可以装备",18,cc.c3b(255,205,30))
	elseif player_type == "2" then
		self:appendStr("只有峨眉可以装备",18,cc.c3b(255,205,30))
	end
	--装备评分
	local eqscore = Bag:getEquipScore(data)
	self:appendStr("装备评分 "..eqscore,18,EQUIP_PURPLE)
	--装备主属性
	local str = ""
	for k,v in pairs(data.attrs) do
		if(k~="maxDmg") then
			if(k~="minDmg" and k~="maxDmg") then			
				str = Bag:getAttrName(k)..":"..math.round(v)
			elseif(k=="minDmg") then
				str = Bag:getAttrName("dam")..":"..math.round(v).."~"..math.round(data.attrs.maxDmg)
			end
			self:appendStr(str,18,cc.c3b(255,255,255))
		end
	end

	--装备四个基础属性
	if data.color[2] ~= 0 then
		if(self.user and self.user == "XiLianProcessor") then
			if(data.stoneAttrs["strr"] and data.stoneAttrs["strr"] > 0) then
				self:appendStr("力道："..math.round(data.color[2] - data.stoneAttrs["strr"]).."(宝石+"..data.stoneAttrs["strr"]..")",16,c3)
			else
				self:appendStr("力道："..math.round(data.color[2]),16,c3)
			end
		else
			self:appendStr("力道："..math.round(data.color[2]),16,c3)
		end
	end

	if data.color[3] ~= 0 then
		if(self.user and self.user == "XiLianProcessor") then
			if(data.stoneAttrs["agi"] and data.stoneAttrs["agi"] > 0) then
				self:appendStr("身法："..math.round(data.color[3] - data.stoneAttrs["agi"]).."(宝石+"..data.stoneAttrs["agi"]..")",16,c3)
			else
				self:appendStr("身法："..math.round(data.color[3]),16,c3)
			end
		else
			self:appendStr("身法："..math.round(data.color[3]),16,c3)
		end
	end

	if data.color[4] ~= 0 then
		if(self.user and self.user == "XiLianProcessor") then
			if(data.stoneAttrs["intt"] and data.stoneAttrs["intt"] > 0) then
				self:appendStr("内劲："..math.round(data.color[4] - data.stoneAttrs["intt"]).."(宝石+"..data.stoneAttrs["intt"]..")",16,c3)
			else
				self:appendStr("内劲："..math.round(data.color[4]),16,c3)
			end
		else
			self:appendStr("内劲："..math.round(data.color[4]),16,c3)
		end
	end

	if data.color[5] ~= 0 then
		if(self.user and self.user == "XiLianProcessor") then
			if(data.stoneAttrs["sta"] and data.stoneAttrs["sta"] > 0) then
				self:appendStr("体质："..math.round(data.color[5] - data.stoneAttrs["sta"]).."(宝石+"..data.stoneAttrs["sta"]..")",16,c3)
			else
				self:appendStr("体质："..math.round(data.color[5]),16,c3)
			end
		else
			self:appendStr("体质："..math.round(data.color[5]),16,c3)
		end
	end

	--神属性
	if #data.god > 0 then
		self:appendStr(tostring(data.god[1]).."星神器:",16,COLOR_RED)
		--获取神属性的配置
		local pos = string.sub(data.eid,3,3)
		local lv = tonumber(string.sub(data.eid,4,6))

		local godname
		local godcfg
		local godlabel
		for k,v in pairs(data.godInfo) do
			godcfg = DataConfig:getGodCfg(k)
			if("ignore_armor" == k or "ignore_deff" == k or "ignore_adf" == k) then
				godname = godcfg.name .. " +"..v
			else
				godname = godcfg.name .. " +"..v*100 .."%"

			end
			self:appendStr(godname,16,COLOR_RED)
		end
		--神属性激活逻辑
		if data.pos == "body" and max == true then
			local god_unlock = DataConfig:getGodUnlock() --神属性激活配置
			local star = data.god[1] --当前装备的星级
			local maxStar = maxStrengthenLv or PlayerData:getGodImproveLv()--全身强化等级
			local curLv = 0  --当前神属性能够激活的等级
			if star > maxStar then
				curLv = maxStar
			else
				curLv = star
			end
			local addNum
			--已激活的属性
			if curLv > 0 then
				for k,v in pairs(data.godInfo) do
					godcfg = DataConfig:getGodCfg(k)
					addNum = god_unlock[tostring(curLv)]*godcfg.unlock_base[1] + godcfg.unlock_base[2]
					if("ignore_armor" == k or "ignore_deff" == k or "ignore_adf" == k) then
						godname = godcfg.name.." +"..(addNum).." [全身强化+"..curLv.."激活 已激活]"
					else
						godname = godcfg.name.." +"..(addNum*100).."%".." [全身强化+"..curLv.."激活 已激活]"
					end					
					
					self:appendStr(godname,16,COLOR_GREEN)
				end
			end
			--未激活的属性
			local nextLv = curLv + 1
			if (star > maxStar) then
				if(god_unlock[tostring(nextLv)]) then				
					for k,v in pairs(data.godInfo) do
						godcfg = DataConfig:getGodCfg(k)
						addNum = god_unlock[tostring(nextLv)]*godcfg.unlock_base[1] + godcfg.unlock_base[2]
						if("ignore_armor" == k or "ignore_deff" == k or "ignore_adf" == k) then
							godname = godcfg.name.." +"..(addNum).." [全身强化+"..nextLv.."激活 未激活]"
						else
							godname = godcfg.name.." +"..(addNum*100).."%".." [全身强化+"..nextLv.."激活 未激活]"
						end
						
						self:appendStr(godname,16,EQUIP_GRAY)
					end
				end
			else
				godname = "当前星级最大值"
				self:appendStr(godname,16,EQUIP_GRAY)
			end
		end
	end
	--镶嵌的宝石
	richtext.text:visit()
	curHeight = -richtext.text:getTextSize().height - 40
	if #data.hole ~= 0 and max == true then
		local dimItems = {}
		for k,v in pairs(data.hole) do
			if v ~= "" then
				local dimdata = DataConfig:getGoodByID(v)
				dimdata.eid = v
				dimItems[#dimItems+1] = dimdata
				local attr,attrName = Bag:getEquipAttrName(dimdata.value)
				local dimstr = dimdata.name.." "..attrName.."+"..dimdata.value[attr]
				self:appendStr(dimstr,16,EQUIP_PURPLE)
			else
				dimItems[#dimItems+1] = 0
			end
		end
		local itemface = nil 
		local index = 0
		richtext.text:visit()
		curHeight = -richtext.text:getTextSize().height - 50
		for kk,vv in pairs(dimItems) do
			itemface = ItemFace.new()
			-- 宝石
			self.labels[#self.labels + 1] = itemface
			itemface.showInfo = false
			itemface.showname = false 
			if vv ~= 0 then
				itemface:setData({edata = vv,eid = vv.eid})
			else
				itemface:setData(nil)
			end
			self:addChild(itemface)
			itemface.border:loadTexture("ui/84000.png")
			itemface.bg:loadTexture("ui/comblack84.png")
			itemface:setScale(0.5)
			itemface:setPosition(index * 50 - 204,curHeight - 26)
			index = index + 1
		end
	end
	self.curHeight = math.abs(curHeight)
end

--获取一个属性label
function EquipAttrInfo:getLabel(text,fontsize,color)
	local label = ccui.Text:create()
	label:ignoreContentAdaptWithSize(false)
	label:setContentSize(cc.size(400, fontsize + 8))
	label:setFontSize(fontsize)
	label:setFontName(DEFAULT_FONT)
	label:setColor(color)
	-- label:setAnchorPoint(0,0)
	local left = 0x0
	--label:setStringHorizontalAlignment(left)
	label:setString(text)
	-- self.labels[#self.labels+1] = label
	return label
end

--追加文本
function EquipAttrInfo:appendStr(text,fontsize,color)
	self.richtext:appendStr(text.."\n",color,fontsize)
end

--获取高宽
function EquipAttrInfo:getContentSize()
	return 400,self.curHeight + 40
end

return EquipAttrInfo