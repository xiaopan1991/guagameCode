--背包管理器
--装备数据 物品数据
--equips里存储背包里的装备的数据
--edata 指向配置表
--sid 服务器ID
--pos 是在背包 还是在身上 bag body
local BagManager = class("BagManager")

function BagManager:ctor()
	-- 保存数据
	self.data = nil
	-- 背包装备
	-- self.equips = {}
	-- 背包道具
	-- self.goods = {}
	---身上穿的道具
	-- self.body = {}
end
--处理数据
function BagManager:setData(data)
	self.data = data.data
	--初始化玩家背包数据  玩家道具和静态配置关联
	local edata = nil
	local bodyequip = self.data.as_equips  --身上的装备
	self.data.equips = self.data.equips or {}
	local equipPosScore = {{0,0,0,0,0,0,0,0,0,0,},{0,0,0,0,0,0,0,0,0,0,},{0,0,0,0,0,0,0,0,0,0,},}
	local equipPos
	local equipJob
	for k,v in pairs(self.data.equips) do
		edata = DataConfig:getEquipById(v.eid)
		if edata == nil then
			print("ID:"..v.eid.."装备不存在！！！")
		end
		v.edata = edata --取装备的静态属性 直接用edata 为了加快效率 以后不再循环
		v.sid = k 		--保存服务器的ID
		v.pos = "bag"
		self:getEquipAttribute(v.sid)
	end
	
	--处理身上的装备
	local curScores = {0,0,0,0,0,0,0,0,0,0,}
	local titem = nil
	for ii,b in pairs(bodyequip) do
		if(b ~= "") then
			titem = self.data.equips[b]
			if titem~= nil then
				titem.pos = "body"
				equipPos = tonumber(string.sub(titem.eid,3,3))
				curScores[equipPos+1] = titem.score
			else
				print("身上装备不存在!! ID:"..b)
			end
		end
	end
	--处理佣兵身上的道具
	---self.data.follower
	local fScores = {}
	local fitem = nil
	local follower = PlayerData:getAllSoliders()
	for l,m in pairs(follower) do
		fScores[l] = {0,0,0,0,0,0,0,0,0,0,}
		for ll,mm in pairs(m.as_equips) do
			if mm ~= "" then
				fitem = self.data.equips[mm]
				if fitem ~= nil then
					fitem.pos = "follower"
					equipPos = tonumber(string.sub(fitem.eid,3,3))
					fScores[l][equipPos+1] = fitem.score
				end				
			end
		end
	end
	self.playerEquipNotice = {false,false,false,false,false,false,false,false,false,false,}
	self.followerEquipNotice = {
		{false,false,false,false,false,false,false,false,false,false,},
		{false,false,false,false,false,false,false,false,false,false,},
		{false,false,false,false,false,false,false,false,false,false,},
	}
	local pType = tonumber(PlayerData:getHeroType())
	self.mainEquipNotice = false
	self.fEquipNotice  = false
	for k,v in pairs(self.data.equips) do	
		equipPos = tonumber(string.sub(v.eid,3,3))
		equipJob = tonumber(string.sub(v.eid,2,2))
		if(v.pos == "bag") then
			if(equipJob == 3) then
				for i=1,3 do
					if(v.score > equipPosScore[i][equipPos+1]) then
						equipPosScore[i][equipPos+1] = v.score
					end
				end
			else
				if(v.score > equipPosScore[equipJob+1][equipPos+1]) then
					equipPosScore[equipJob+1][equipPos+1] = v.score
				end
			end
		end
	end
	if(pType) then
		for i=1,10 do
			if(curScores[i] < equipPosScore[pType][i]) then
				self.playerEquipNotice[i] = true
				self.mainEquipNotice = true
			end
		end
		for k,v in pairs(fScores) do
			pType = tonumber(follower[k].hero_type)
			for i=1,10 do
				if(v[i] < equipPosScore[pType][i]) then
					self.followerEquipNotice[pType][i] = true
					self.fEquipNotice  = true
				end
			end
		end
	end
	--处理道具数据
	edata = nil
	local tnum = 0
	self.data.bag = self.data.bag or {}
	for kk,vv in pairs(self.data.bag) do
		edata = DataConfig:getGoodByID(kk)
		if edata == nil then
			print("ID:"..kk.."道具不存在！！！")
		end
		tnum = vv -- 临时保存数量
		if tnum~= 0 then
			self.data.bag[kk] = {eid = kk,edata = edata,num = tnum} -- 更新数据
		else 
			self.data.bag[kk] = nil
		end
	end
end

--添加一个道具 如果有 就覆盖
function BagManager:addEquip(id,data)
	--dump(id,data)
	local edata = nil
	edata = DataConfig:getEquipById(data.eid)
	if edata == nil then
		print("ID:"..v.eid.."装备不存在！！！")
	end
	data.edata = edata
	data.sid = id
	local tdata = self.data.equips[id]
	if tdata ~= nil then
		data.pos = tdata.pos
	else 
		data.pos = "bag"
	end
	self.data.equips[id] = data
	self:getEquipAttribute(data.sid)
	
	local equipPos = tonumber(string.sub(data.eid,3,3))
	local equipJob = tonumber(string.sub(data.eid,2,2))
	if(data.pos == "bag") then
		local equipData = self:getCurEquipByPosindex(equipPos)		
		local curScore = 0
		if(equipData) then
			curScore = equipData.score
		end
		if(curScore < data.score and (equipJob == 3 or (equipJob+1 == tonumber(PlayerData:getHeroType())))) then
			self.playerEquipNotice[equipPos+1] = true	
			self.mainEquipNotice = true			
			local tempNode = display.newNode()
			local data = {}
			tempNode.data = data
			data.pos = equipPos
			Observer.sendNotification(BagModule.NOTICE_BETTER_EQUIP,tempNode)
		end
		if(equipPos>EquipPosType.LEG) then
			return
		end
		local followers = PlayerData:getAllSoliders()
		local pType
		for k,v in pairs(followers) do
			equipData = self:getCurEquipByPosindex(equipPos,k)
			local curScore = 0
			if(equipData) then
				curScore = equipData.score
			end
			pType = tonumber(v.hero_type)
			if(curScore < data.score and (equipJob == 3 or (equipJob+1 == pType))) then
				self.followerEquipNotice[pType][equipPos+1] = true
				self.fEquipNotice = true
				Observer.sendNotification(BagModule.NOTICE_BETTER_EQUIP)
			end
		end
	end
end

--移除一个道具
function BagManager:removeEquip(id)
	self.data.equips[id] = nil
end
--更改一个道具的位置
function BagManager:changeEquipPos(id,pos)
	self.data.equips[id].pos = pos
end
--移除多个道具
function BagManager:removeEquips(ids)
	for k,v in pairs(ids) do
		self.data.equips[v] = nil
	end
end

--获取一个道具
function BagManager:getEquipById(id)
	return self.data.equips[id]
end

--根据装备品质排序 返回一个table
--品质 等级 位置
--order
--desc 降序
--asc 升序
--typefirst 本职业优先
--body 穿上的装备优先
function BagManager:sortEquipByQuality(equips,order,typefirst)
	order = order or "desc"
	typefirst = typefirst or -1
	local re = {}

	for k,v in pairs(equips) do
		re[#re + 1] = v
	end
	table.sort(re,function(a,b)
		if order == "desc" then
			--是否职业优先
			if typefirst ~= -1 then
				local ty1 = tonumber(string.sub(a.eid,2,2))
				local ty2 = tonumber(string.sub(b.eid,2,2))
				if ty1 == typefirst and ty2 ~= typefirst then
					return true
				elseif ty1 ~= typefirst and ty2 == typefirst then
					return false
				end
			end

			--神属性
			if #a.god ~= #b.god then
				return #a.god > #b.god
			end

			--颜色
			if a.color[1] ~= b.color[1] then
				return a.color[1] > b.color[1]	
			end

			--强化等级
			if a.star ~= b.star then
				return a.star > b.star
			end

			--宝石个数
			if a.dimnum ~= b.dimnum then
				return a.dimnum > b.dimnum
			end

			--部位
			local p1 = tonumber(string.sub(a.eid,3,3))
			local p2 = tonumber(string.sub(b.eid,3,3))
			if p1 ~= p2 then
				return p1 < p2
			end

			--职业
			local t1 = tonumber(string.sub(a.eid,2,2))
			local t2 = tonumber(string.sub(b.eid,2,2))
			if t1 ~= t2 then
				return t1 > t2
			end

			--等级
			local l1 = tonumber(string.sub(a.eid,4,6))
			local l2 = tonumber(string.sub(b.eid,4,6))
			if l1 ~= l2 then
				return l1 > l2
			end

			--EID
			local eid1 = tonumber(string.sub(a.eid,2,7))
			local eid2 = tonumber(string.sub(a.eid,2,7))

			if eid1 ~= eid2 then
				return eid1 > eid2
			end

		else
			--是否职业优先
			if typefirst ~= -1 then
				local ty1 = tonumber(string.sub(a.eid,2,2))
				local ty2 = tonumber(string.sub(b.eid,2,2))
				if ty1 == typefirst and ty2 ~= typefirst then
					return false
				elseif ty1 ~= typefirst and ty2 == typefirst then
					return true
				end
			end

			--神属性
			if #a.god ~= #b.god then
				return #a.god < #b.god
			end
			--颜色
			if a.color[1] ~= b.color[1] then
				return a.color[1] < b.color[1]
			end

			--强化等级
			if a.star ~= b.star then
				return a.star < b.star
			end

			--宝石个数
			if a.dimnum ~= b.dimnum then
				return a.dimnum < b.dimnum
			end

			--等级
			local l1 = tonumber(string.sub(a.eid,4,6))
			local l2 = tonumber(string.sub(b.eid,4,6))
			if l1 ~= l2 then
				return l1 < l2
			end

			--职业
			local t1 = tonumber(string.sub(a.eid,2,2))
			local t2 = tonumber(string.sub(b.eid,2,2))
			if t1 ~= t2 then
				return t1 < t2
			end

			--EID
			local eid1 = tonumber(string.sub(a.eid,2,7))
			local eid2 = tonumber(string.sub(a.eid,2,7))

			if eid1 ~= eid2 then
				return eid1 < eid2
			end
		end
		end)
	return re
end

--根据装备评分排序
--equips 装备列表
--order  升序降序

function BagManager:sortEquipByScore(equips,order)
	order = order or "desc"
	typefirst = typefirst or -1
	local re = {}

	for k,v in pairs(equips) do
		re[#re + 1] = v
	end
	--排序
	table.sort(re,function(a,b)
		if order == "desc" then
			return a.score > b.score
		else
			return a.score < b.score
		end
		end)
    return re
end

--根据装备位置 获取装备
--pos 装备位置 主手武器/副手武器等等
--typeFirst 职业优先
--exceptgod 排除神器
--inbag "bag" or "body" or "all" 默认是 "all"
--sc 升序或者降序
--typeonly 仅显示当前职业的装备
--byscore  根据评分排序

function BagManager:getEquipsByPos(pos,typeFirst,exceptgod,inbag,sc,typeonly,byscore)
	inbag = inbag or "all"
	sc = sc or "desc"
	exceptgod = exceptgod or false
	pos = tonumber(pos)
	typeonly = typeonly or false
	byscore  = byscore or false

	local re = {}
	local tpos = 0
	local etype = -1 --装备职业
	for k,v in pairs(self.data.equips) do
		tpos = tonumber(string.sub(v.eid,3,3))
		etype = tonumber(string.sub(v.eid,2,2))
		if (typeonly == true and etype == typeFirst) or (typeonly == true and etype == 3) or not typeonly then
			if tpos == pos then
				if exceptgod == true then
					--排除神器
					if #v.god == 0 then
						if inbag == "all" then
							re[#re+1] = v
						elseif inbag == v.pos then
							re[#re+1] = v
						end
					end
				else
					if inbag == "all" then
						re[#re+1] = v
					elseif inbag == v.pos then
						re[#re+1] = v
					end
				end
			end
		end
	end
	if byscore then
		return self:sortEquipByScore(re,sc)
	else
		return self:sortEquipByQuality(re,sc,typeFirst)
	end
end



--获取某品质的装备
--quality 品质 白绿蓝紫橙红
--inbag 在背包还是在身上 bag body all
function BagManager:getEquipsByQuality(quality,inbag)
	inbag = inbag or "all"
	quality = tonumber(quality)
	local re = {}
	local q = 0
	for k,v in pairs(self.data.equips) do
		q = tonumber(v.color[1])
		if (q == quality and quality ~= 5 and #v.god~=2) or (quality == 5 and #v.god==2) then
			if inbag == "all" then
				re[#re + 1] = v
			elseif v.pos == inbag then
				re[#re + 1] = v
			end
		end
	end
	return re
end
--背包物品排序
function BagManager:sortBagGood()
	local re = table.values(self.data.bag)
	table.sort(re,function(a,b)
		return a.eid < b.eid
	end)
	return re
end
--背包装备排序
function BagManager:sortBagEquip()
	--品质/等级/部位/阶级/宝石（个数）/强化
	local tempEquips = {}
	for k,v in pairs(self.data.equips) do
		if(v.pos == "bag") then
			tempEquips[#tempEquips + 1] = v
		end
	end
	
	local aGod
	local bGod
	local aLv
	local bLv
	local aEquipPos
	local bEquipPos
	local aQua
	local bQua
	local aStoneNum
	local bStoneNum
	local aStrengthenLvl
	local bStrengthenLvl
	local function sortEquips(a,b)
		aGod = math.min(#a.god,1)
		bGod = math.min(#b.god,1)
		if(aGod ~= bGod) then
			return aGod > bGod
		end
		if a.color[1] ~= b.color[1] then
			return a.color[1] > b.color[1]
        end
        aLv = tonumber(string.sub(a.eid,4,6))
        bLv = tonumber(string.sub(b.eid,4,6))
        if(aLv ~= bLv) then
        	return aLv > bLv
        end
		aEquipPos = tonumber(string.sub(a.eid,3,3))
		bEquipPos = tonumber(string.sub(b.eid,3,3))
		if aEquipPos ~= bEquipPos then
			return aEquipPos < bEquipPos
        end
        aQua = tonumber(string.sub(a.eid,7,7))
        bQua = tonumber(string.sub(b.eid,7,7))
        if(aQua ~= bQua) then
        	return aQua > bQua
        end
        aStoneNum = table.nums(a.stoneAttrs)
        bStoneNum = table.nums(b.stoneAttrs)
        if(aStoneNum ~= bStoneNum) then
        	return aStoneNum>bStoneNum
        end
        aStrengthenLvl = a.star
        bStrengthenLvl = b.star
        return aStrengthenLvl > bStrengthenLvl
	end
	table.sort(tempEquips,sortEquips)
	return tempEquips
end
--获取可穿戴装备
function BagManager:getDressEquips(job,posindex)
	local tempEquips = {}
	local equipPosIndex
	local equipJob
	for k,v in pairs(self.data.equips) do
		if(v.pos == "bag") then
			equipPosIndex = tonumber(string.sub(v.eid,3,3))
			equipJob = tonumber(string.sub(v.eid,2,2))
			if((equipJob == 3 or (equipJob+1 == job)) and equipPosIndex == posindex) then
				tempEquips[#tempEquips + 1] = v
			end
		end
	end
	table.sort(tempEquips,function (a,b)
			return a.score > b.score
		end)
	return tempEquips
end
--获取传承装备
function BagManager:getChuanChengEquips(epos)
	local tempEquips = {}
	for k,v in pairs(self.data.equips) do
		if(#v.god == 0 and tonumber(string.sub(v.eid,3,3)) == epos) then
			tempEquips[#tempEquips + 1] = v
		end
	end
	table.sort(tempEquips,function (a,b)
			return a.score > b.score
		end)
	return tempEquips
end
--获取吞噬装备
function BagManager:getTunShiEquips(curEquipSid,num)
	local tempEquips = {}
	for k,v in pairs(self.data.equips) do
		if(v.pos == "bag" and #v.god ~= 0 and k~= curEquipSid) then
			local hasStone
			for i,vv in ipairs(v.hole) do
				if(vv ~= "") then
					hasStone = true
					break
				end
			end
			if(not hasStone) then
				tempEquips[#tempEquips + 1] = v
			end
		end
	end
	table.sort(tempEquips,function (a,b)
			return a.score < b.score
		end)
	local res
	if(num) then
		res = {}
		for i,v in ipairs(tempEquips) do
			if( i<= num) then
				res[i] = v
			else
				break
			end
		end
	else
		res = tempEquips
	end
	return res
end
--获取熔炼装备,num为0表示所有熔炼选择筛选排序后的列表
function BagManager:getRonglianEquips(num)
	local tempEquips = {}
	for k,v in pairs(self.data.equips) do
		if(v.pos == "bag" and #v.god == 0) then
			local hasStone
			for i,vv in ipairs(v.hole) do
				if(vv ~= "") then
					hasStone = true
					break
				end
			end
			if(not hasStone) then
				tempEquips[#tempEquips + 1] = v
			end
		end
	end
	table.sort(tempEquips,function (a,b)
		if a.color[1] ~= b.color[1] then
			return a.color[1] < b.color[1]
        end
        local alv = tonumber(string.sub(a.eid,4,6))
        local blv = tonumber(string.sub(b.eid,4,6))
        if(alv ~= blv) then
        	return alv < blv
        end
        local apos = tonumber(string.sub(a.eid,3,3))
        local bpos = tonumber(string.sub(b.eid,3,3))
        if(apos ~= bpos) then
        	return apos<bpos
        end
        local aqua = tonumber(string.sub(a.eid,7,7))
        local bqua = tonumber(string.sub(b.eid,7,7))
        return aqua<bqua
	end)
	local res
	if(num) then
		res = {}
		for i,v in ipairs(tempEquips) do
			if( i<= num) then
				res[i] = v
			else
				break
			end
		end
	else
		res = tempEquips
	end
	return res
end
--获取最差的装备
--num 个数  nil或者0  就是按品质升序排序 品质低的在前边
--getPoorEquips 是否包含神器 默认false 不包含
--pos 位置 body bag all
function BagManager:getPoorEquips(num,includegod,pos)
	includegod = includegod or false
	pos = pos or "bag"
	local tempEquips = {}
	for k,v in pairs(self.data.equips) do
		if pos == "all" or v.pos == pos then
			if includegod == false then --不包含神器
				if #v.god == 0 then     --不是神器
					tempEquips[#tempEquips + 1] = v
				end
			else
				tempEquips[#tempEquips + 1] = v
			end
		end
	end
	table.sort(tempEquips,function (a,b)
		if a.color[1] == b.color[1] then
            return tonumber(string.sub(a.eid,4,6)) < tonumber(string.sub(b.eid,4,6))
        else
            return a.color[1] < b.color[1]
        end
	end)

	if num == 0 then 
		return tempEquips
	else 
		local res = {}
		local step = 6
		if #tempEquips < 6 then
			step = #tempEquips
		end

		for i=1,step do
			res[i] = tempEquips[i]
		end
		return res
	end
end

--获取最好的装备
--num 个数  nil或者0  就是按品质降序排序 品质高的在前边
function BagManager:getBestEquips(num)
	local tempEquips = {}
	for k,v in pairs(self.data.equips) do
		tempEquips[#tempEquips + 1] = v
	end

	table.sort(tempEquips,function (a,b)
		if a.color[1] == b.color[1] then
            return tonumber(string.sub(a.eid,4,6)) > tonumber(string.sub(b.eid,4,6))
        else
            return a.color[1] > b.color[1]
        end
	end)

	if num == 0 then 
		return tempEquips
	else 
		local res = {}
		local step = 6
		if #tempEquips < 6 then
			step = #tempEquips
		end
		for i=1,step do
			res[i] = tempEquips[i]
		end
		return res
	end
end

--获取各个部位的装备的数量
function BagManager:getEquipNumByPos()
	return {}
end

--获取各个品质的装备的数量
function BagManager:getEquipNumByQuality()
    
end

--返回所有的道具
--includegod是否包含神器 默认包含
--pos 位置 背包bag 或者 身上body 或者所有all
--
function BagManager:getAllEquip(includegod,pos,sc)
	if includegod == nil then
		includegod = true
	end	
	sc = sc or "desc"
	pos = pos or "all"
	--返回所有的
	if includegod == true and pos == "all" then
		return self:sortEquipByQuality(self.data.equips,sc)
	end

	local re = {}
	for k,v in pairs(self.data.equips) do
		if includegod == true then
			if pos == "all" then
				re[k] = v
			else
				if v.pos == pos then
					re[k] = v
				end
			end
		else
			if #v.god == 0 then
				if pos == "all" then
					re[k] = v
				else
					if v.pos == pos then
						re[k] = v	
					end
				end
			end
		end
	end
	return self:sortEquipByQuality(re,sc)
end

function BagManager:getAllEquipNum()
	return table.nums(self.data.equips)
end

--根据ID更新data
--id 装备的服务器id
--data 装备的数据
function BagManager:updateEquip(id,data)
	local edata = DataConfig:getEquipById(data.eid)
	data.edata = edata
	data.sid = id
	data.pos = "bag"

	local tdata = self.data.equips[id]
	if tdata ~= nil then
		data.pos = tdata.pos
	end
	self.data.equips[id] = data
	self:getEquipAttribute(data.sid)	

	local equipPos = tonumber(string.sub(data.eid,3,3))
	local equipJob = tonumber(string.sub(data.eid,2,2))
	if(data.pos == "bag") then
		local equipData = self:getCurEquipByPosindex(equipPos)		
		local curScore = 0
		if(equipData) then
			curScore = equipData.score
		end
		if(curScore < data.score and (equipJob == 3 or (equipJob+1 == tonumber(PlayerData:getHeroType())))) then
			self.playerEquipNotice[equipPos+1] = true	
			self.mainEquipNotice = true			
			local tempNode = display.newNode()
			local data = {}
			tempNode.data = data
			data.pos = equipPos
			Observer.sendNotification(BagModule.NOTICE_BETTER_EQUIP,tempNode)
		end
		if(equipPos>EquipPosType.LEG) then
			return
		end
		local followers = PlayerData:getAllSoliders()
		local pType
		for k,v in pairs(followers) do
			equipData = self:getCurEquipByPosindex(equipPos,k)
			local curScore = 0
			if(equipData) then
				curScore = equipData.score
			end
			pType = tonumber(v.hero_type)
			if(curScore < data.score and (equipJob == 3 or (equipJob+1 == pType))) then
				self.followerEquipNotice[pType][equipPos+1] = true
				self.fEquipNotice  = true				
				Observer.sendNotification(BagModule.NOTICE_BETTER_EQUIP)
			end
		end
	end
end

--获取背包里的神装
--num 数量
--except 排除
--pos 位置 "all" "bag" "body"
function BagManager:getGodEquip(num,except,pos,sc)
	num = num or 0
	pos = pos or "all"
	except = except or ""
	local re = {}
	for k,v in pairs(self.data.equips) do
		if #v.god > 0 then
			if except ~= k then
				if pos ~= "all" then
					if v.pos == pos then
						re[#re+1] = v
					end
				else
					re[#re+1] = v
				end

				if num~= 0 and #re == num then
					return re
				end
			end
		end
	end
	return self:sortEquipByQuality(re,sc)
end


--获取所有的道具
function BagManager:getAllGoods()
	local re = table.values(self.data.bag)
	table.sort(re,function(a,b)
		local eid1 = tonumber(string.sub(a.eid,2,5))
		local eid2 = tonumber(string.sub(b.eid,2,5))
		if eid1>=2000 and eid1<3000 and eid2>=2000 and eid2<3000 then
			return eid1 < eid2
		end

		if eid1>=2000 and eid1<3000 then
			return false
		end

		if eid2>=2000 and eid2<3000 then
			return true
		end

		return eid1 < eid2
	end)
	return re
end

--添加道具  
--id   
--num  数量
function BagManager:addGoods(id,num)
	local edata = DataConfig:getGoodByID(id)	
	if(num == 0) then
		self.data.bag[id] = nil
	else
		self.data.bag[id] = {eid = id,edata = edata,num = num} -- 更新数据
	end

	Observer:sendNotification(BagModule.UPDATE_BAG_GOODS, nil)
end

-- 递增道具 从原有数量上增加道具数量
function BagManager:plusGoods(id, num)
	local goods = self.data.bag[id]
	if goods == nil then
		local edata = DataConfig:getGoodByID(id)	
		self.data.bag[id] = {eid = id,edata = edata,num = num}
	else
		self.data.bag[id].num = goods.num + num
	end

	if self.data.bag[id].num <= 0 then
		self.data.bag[id] = nil
	end

	Observer:sendNotification(BagModule.UPDATE_BAG_GOODS, nil)
end

--删除道具
function BagManager:removeGoodsById(id)
	-- local index = 1
	-- for k,v in pairs(self.data.bag) do
	-- 	if k == id then
	-- 		table.remove(self.data.bag,index)
	-- 		break
	-- 	end
	-- 	index = index + 1
	-- end
	self.data.bag[id] = nil
	Observer:sendNotification(BagModule.UPDATE_BAG_GOODS, nil)
end
--根据id获取道具
function BagManager:getGoodsById(id)
	return self.data.bag[id]
end

--根据道具类型获取道具
--gtype 道具类型
function BagManager:getGoodsByType(gtype)
	local re = {}
	local itype = ""
	for k,v in pairs(self.data.bag) do
		itype = string.sub(v.eid,2,2)
		if itype == gtype then
			re[#re + 1] = v
		end
	end
	return re
end

--更新道具数量
--id   道具ID
--num  道具数量
function BagManager:updateGoodsNum(id,num)
	local data = self.data.bag[id]
	--如果没有该道具 则重新生成一个
	if data == nil then
		local edata = DataConfig:getGoodByID(id)
		data = {eid = id,edata = edata,num = num}
		self.data.bag[id] = data
	end
	
	if num > 0 then
		data.num = num
	else
		self.data.bag[id] = nil
	end

	Observer:sendNotification(BagModule.UPDATE_BAG_GOODS, nil)
end


--根据品质获取颜色
--color 品质 0-4
function BagManager:getEquipColor(color)
	if color == 0 then
		return EQUIP_WHITE
	elseif color == 1 then
		return EQUIP_GREEN
	elseif color == 2 then
		return EQUIP_BLUE
	elseif color == 3 then
		return EQUIP_PURPLE
	elseif color == 4 then
		return EQUIP_ORANGE
	end
end

function BagManager:getAttrName(attr)
	if attr == "strr" then
		return "力道"
	elseif attr == "agi" then
		return "身法"
	elseif attr == "intt" then
		return "内劲"
	elseif attr == "sta" then
		return "体质"
	elseif attr == "hp" then
		return "气血"
	elseif attr == "mp" then
		return "内力"
	elseif attr == "dam" then
		return "伤害"
	elseif attr == "arm" then
		return "筋骨"
	elseif attr == "deff" then
		return "外防"
	elseif attr == "adf" then
		return "内防"
	elseif attr == "cri" then
		return "会心"
	elseif attr == "crd" then
		return "会心一击伤害"
	elseif attr == "hit" then
		return "命中"
	elseif attr == "dod" then
		return "闪避"
	elseif attr == "res" then
		return "招架"
	elseif attr == "mps" then
		return "回复内力"
	end
end

--获取装备的主属性的文本
--edata
function BagManager:getEquipAttrName(edata)
	for attr,v in pairs(edata) do
		if attr == "strr" then
			return "strr","力道"
		elseif attr == "agi" then
			return "agi","身法"
		elseif attr == "intt" then
			return "intt","内劲"
		elseif attr == "sta" then
			return "sta","体质"
		elseif attr == "hp" then
			return "hp","气血"
		elseif attr == "mp" then
			return "mp","内力"
		elseif attr == "dam" then
			return "dam","伤害"
		elseif attr == "arm" then
			return "arm","筋骨"
		elseif attr == "deff" then
			return "deff","外防"
		elseif attr == "adf" then
			return "adf","内防"
		elseif attr == "cri" then
			return "cri","会心"
		elseif attr == "crd" then
			return "crd","会心一击伤害"
		elseif attr == "hit" then
			return "hit","命中"
		elseif attr == "dod" then
			return "dod","闪避"
		elseif attr == "res" then
			return "res","招架"
		elseif attr == "mps" then
			return "mps","回复内力"
		end
	end
	return nil
end

--计算装备评分
-- "<var>" = {
--     "color" = {
--         1 = 3
--         2 = 0
--         3 = 481
--         4 = 465
--         5 = 428
--     }
--     "edata" = {
--         "dam" = {
--             1 = 136
--             2 = 186
--         }
--         "name" = "武当20级0阶武器"
--     }
--     "eid"   = "E000200"
--     "god" = {
--     }
--     "hole" = {
--     }
--     "pos"   = "bag"
--     "sid"   = "e341"
--     "star"  = 0
-- }
function BagManager:getEquipScore(equip)
	local cf = DataConfig:getEquipScoreCfg()
	local attrs = {hp = 0,mp = 0,minDmg = 0,maxDmg = 0,arm = 0,deff = 0,adf = 0,cri = 0,hit = 0,dod = 0,res = 0,}
	local strr = equip.color[2]       --力道
	local agi  = equip.color[3]       --身法
	local intt = equip.color[4]       --内劲
	local sta  = equip.color[5]       --体质
	if equip.attrs == nil then
		self:updateEquipAttr(equip)
	end
	for k,v in pairs(equip.attrs) do
		attrs[k] = v
	end
	local score = (attrs.minDmg+attrs.maxDmg)*cf[1]+strr*cf[2]+agi*cf[3]+intt*cf[4]+sta*cf[5]+attrs.hp*cf[6]+attrs.mp*cf[7]+attrs.arm*cf[8]+attrs.dod*cf[9]+attrs.cri*cf[10]+attrs.deff*cf[11]+attrs.adf*cf[12]+attrs.res*cf[13]
	return math.round(score)
end

--获取装备增加的属性
function BagManager:getEquipAttribute(sid)
	--计算强化属性
	local equipData = self.data.equips[sid]
	self:updateEquipAttr(equipData)
	equipData.score = self:getEquipScore(equipData)
	equipData.dimnum = 0
	for k,v in pairs(equipData.hole) do
		if v ~= "" then
			equipData.dimnum = equipData.dimnum + 1
		end
	end
end

function BagManager:updateEquipAttr(equipData)
	-- local equipData = self.data.equips[sid]
	local attrs = {}
		--得到静态配置的属性（目前只与强化有关）
	if equipData.edata == nil then
		dump(equipData,"没有静态配置数据",999)
	end
	for k,v in pairs(equipData.edata) do
		if(k ~= "name") then
			if(k == "dam") then
				attrs["minDmg"] = v[1]
				attrs["maxDmg"] = v[2]
			else
				attrs[k] = v
			end
		end
	end
	--根据强化公式和强化等级和品质计算以上属性
	if(equipData.star > 0) then
		for k,v in pairs(attrs) do
			attrs[k] = DataConfig:getEquipStrengthenAttrs(v,equipData.color[1],equipData.star)
			attrs[k] = formatAttributeNum(k,attrs[k])
		end
	end
	equipData.attrs = attrs
	--得到力敏智耐基础属性属性
    
	--计算镶嵌宝石增加的属性
	equipData.stoneAttrs = {}
	local tempAttrs = {"strr","agi","intt","sta"}
	local itemData
	for k,v in pairs(equipData.hole) do
		if(v ~= "") then
			itemData = DataConfig:getGoodByID(v)
			for i,v in ipairs(tempAttrs) do
				if(itemData.value[v]) then
					if(not equipData.stoneAttrs[v]) then
						equipData.stoneAttrs[v] = 0
					end
					equipData.stoneAttrs[v] = equipData.stoneAttrs[v] + itemData.value[v]
					equipData.color[i+1] = equipData.color[i+1] + itemData.value[v]
				end
			end
		end
	end
	--计算神属性
	local godCfg = DataConfig.data.cfg.god
	local godName
	equipData.godInfo = {}
	if(#equipData.god > 0) then
		for i=3,#equipData.god do
			godName = equipData.god[i]
			equipData.godInfo[godName] = godCfg[godName].lv_base[1]*equipData.god[1] + godCfg[godName].lv_base[2]
			equipData.godInfo[godName] = formatGodinfoNum(godName,equipData.godInfo[godName])
		end
	end	
end
function BagManager:updateDress(data)
	self.data.as_equips = data
	local bodyEquips = self:getAllEquip(true,"body")
	for k,v in pairs(bodyEquips) do
		self:changeEquipPos(v.sid,"bag")		
	end
	for k,v in pairs(data) do
		if(v~="") then
			self:changeEquipPos(v,"body")
		end
	end
end
--posIndex装备位置，fid弟子位置
function BagManager:getCurEquipByPosindex(posIndex,fid)
	local bodyequip
	local equipData
	local equipPos
	if(not fid) then
		bodyequip = self.data.as_equips
	else
		bodyequip = PlayerData:getSoliderByID(fid).as_equips
	end
	for k,v in pairs(bodyequip) do
		if(v~="") then
			equipData = self.data.equips[v]
			equipPos = tonumber(string.sub(equipData.eid,3,3))
			if(equipPos == posIndex) then
				return equipData
			end
		end
	end
	return nil
end
function BagManager:clear()
	self.playerEquipNotice = nil
	self.followerEquipNotice = nil
	self.mainEquipNotice  = nil
	self.fEquipNotice  = nil
end
return BagManager