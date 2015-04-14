--随机整数,四舍五入
function math.randint(a, b, rand)
    --rand : 0-999
    return math.round(a+(b-a)*rand*1.0/999)
end
--随机浮点数,num小數點后幾位
function math.randfloat(a, b, rand,num)
    --rand: 0-999
    local pointNum = num or 5
    local mul = 1
    for i=1,pointNum do
    	mul = mul * 10
    end
    local temp = math.randint(mul*a,mul*b,rand)
    return temp/mul
end
--随机0-1000,檢驗probability概率是否發生
function math.random_occur2(probability, rand)
    if (rand<math.floor(probability*1000)) then
        return true
    else
        return false
    end
end
--权重随机
function math.random_choice2(config,rand)
    --config = [(0.1, 20), (0.2, 30), (0.7, 40)],[1]為種類，[2]為種類對應的概率權重
    local temp = 0
    local proConfig = config
    for i,v in ipairs(proConfig) do
    	temp = temp + v[2]
    end
    local tempResult = math.randint(1,temp,rand)
    temp = 0
    for i,v in ipairs(proConfig) do
    	temp = temp + v[2]
    	if(tempResult <= temp) then
    		return v[1]
    	end
    end
end
--把一个数限定到一个闭区间
function math.limitTo(num, minNum, maxNum)
    return math.min(math.max(num,minNum),maxNum)
end
--转成int
function math.toint(num)
    if(num >= 0) then
        return  math.floor(num)
    else
        return  math.ceil(num)
    end
end
--2014-08-26 11:48:29.0000格式-转换为秒数
function changeTimeStrToSec(timeStr)
    if(timeStr == "") then
        return 0
    end
    local temp1 = string.split(timeStr,".")
    local temp2 = string.split(temp1[1]," ")
    local dateArr = string.split(temp2[1],"-")
    local timeArr = string.split(temp2[2],":")
    local y = tonumber(dateArr[1])
    local m = tonumber(dateArr[2])
    local d = tonumber(dateArr[3])
    local h = tonumber(timeArr[1])
    local minute = tonumber(timeArr[2])
    local s = tonumber(timeArr[3])
    
    --android error year > 2037
    if y > 2037 then
        y = 2037
    end

    local tempsec = os.time({year = y,
        month = m,
        day = d,
        hour = h,
        min = minute,
        sec = s,})

    if( temp1[2] and temp1[2] ~= "") then
        tempsec = tempsec + tonumber("0."..temp1[2])
    end
    return tempsec
end
--秒数-转换为2014-08-26 11:48:29.
function changeSecToTimeStr(timeSec)
    local timeStr = tostring(timeSec)
    local temp = string.split(timeStr,".")
    local intnum = tonumber(temp[1])
    local ymdhms = os.date("%Y-%m-%d %H:%M:%S", intnum)
    if(temp[2]) then
        ymdhms = ymdhms.."."..temp[2]
    else
        ymdhms = ymdhms..".0"
    end
    return ymdhms
end
--秒数转换为1天2小时3分4秒格式
function changeSecToDHMSStr(sec)
	if(sec == 0) then
		return "0秒"
	end
    local days = math.floor(sec/24/3600)
    local hours = math.floor((sec - days*24*3600)/3600)
    local minutes = math.floor((sec%3600)/60)
    local seconds = sec%60
    local secStr = ""
    if(days>0) then
        secStr = secStr..days.."天"
    end
    if(hours>0) then
        secStr = secStr..hours.."小时"
    end
    if(minutes>0) then
        secStr = secStr..minutes.."分"
    end
    if(seconds>0) then
        secStr = secStr..seconds.."秒"
    end
    return secStr
end

--截取UTF8字符串
--开始位置
--结束位置
function string.utf8sub(input,b,e)
    local len  = string.len(input)
    print("len:"..len)
    local left = len
    local cnt  = 0
    local arr  = {0, 0xc0, 0xe0, 0xf0, 0xf8, 0xfc }
    local tb = {}
    while left ~= 0 do
        local tmp = string.byte(input, -left)
        local i  = #arr
        while arr[i] do
            if tmp >= arr[i] then
                left = left - i
                break
            end
            i = i - 1
        end
        if i == 1 then
            tb[#tb+1] = string.char(tmp)
        else
            tb[#tb+1] = string.sub(input,len-left-i +1,len-left)
        end
        cnt = cnt + 1
    end

    local re = {}
    local count = e - b + 1
    local index = 1
    for k, v in pairs(tb) do
        re[#re + 1] = v
        if index == count then
            break
        end
        index = index + 1
    end
    return table.concat(re)

end



function string.utf8find(input,patter)
    local len  = string.len(input)
    local left = len

    local arr  = {0, 0xc0, 0xe0, 0xf0, 0xf8, 0xfc }
    local tb = {}
    local tb2 = {}

    --拆源
    while left ~= 0 do
        local tmp = string.byte(input, -left)
        local i  = #arr
        while arr[i] do
            if tmp >= arr[i] then
                left = left - i
                break
            end
            i = i - 1
        end
        if i == 1 then
            tb[#tb+1] = string.char(tmp)
        else
            tb[#tb+1] = string.sub(input,len-left-i +1,len-left)
        end
    end

    len  = string.len(patter)
    left = len
    --拆子
    while left ~= 0 do
        local tmp = string.byte(patter, -left)
        local i  = #arr
        while arr[i] do
            if tmp >= arr[i] then
                left = left - i
                break
            end
            i = i - 1
        end
        if i == 1 then
            tb2[#tb2+1] = string.char(tmp)
        else
            tb2[#tb2+1] = string.sub(patter,len-left-i +1,len-left)
        end
    end

    local tlen1 = #tb
    local tlen2 = #tb2

    local index1 = 1
    local index2 = 1

    local matchnum = 0

    for i = 1, tlen1 do
        --源字符串的首字符
        local c1 = tb[i]
        if c1 == tb2[1] then
            index1 = i
            matchnum = 1
            for j = 2,tlen2  do
                if tb[index1+j-1] == tb2[j] then
                    matchnum = matchnum + 1
                    index1 = index1 + 1
                else
                    break
                end
            end

            if matchnum == tlen2 then
                return true
            end
        end
    end

    return false
end


--将“每日挑战其他玩家@0次”中的@0替换为第一个参数
function addArgsToMsg(...)
    local arg = {...}
    local scrstr = arg[1]
    for i=2,#arg do
        scrstr = string.gsub(scrstr,"[@][0-9]",arg[i],1)
    end
    return scrstr
end
function formatAttributeNum(key,num)
    if(key == "crd") then
        return math.round(num*100)/100
    else
        return math.round(num)
    end
end
function formatGodinfoNum(key,num)
    if(key == "ignore_armor") then
        return math.round(num)
    else
        return math.round(num*100)/100
    end
end
COMMON_BUTTONS = {}
COMMON_BUTTONS.TAB_BUTTON = "TAB_BUTTON"
COMMON_BUTTONS.BLUE_BUTTON = "BLUE_BUTTON"
COMMON_BUTTONS.ORANGE_BUTTON = "ORANGE_BUTTON"
COMMON_BUTTONS.GREEN_BUTTON = "GREEN_BUTTON"
function enableBtnOutLine(btn,btnStyle)
    if(btnStyle == COMMON_BUTTONS.BLUE_BUTTON) then
        btn:getTitleRenderer():enableOutline(cc.c4b(60,92,156,255),2)
    elseif(btnStyle == COMMON_BUTTONS.ORANGE_BUTTON) then
        btn:getTitleRenderer():enableOutline(cc.c4b(156,60,60,255),2)
    elseif(btnStyle == COMMON_BUTTONS.GREEN_BUTTON) then
        btn:getTitleRenderer():enableOutline(cc.c4b(50,101,50,255),2)
    elseif(btnStyle == COMMON_BUTTONS.TAB_BUTTON) then
        btn:getTitleRenderer():enableOutline(cc.c4b(28,44,63,255),2)
    end
end