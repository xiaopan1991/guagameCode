--网络流处理类
--table 转 json 封包
--粘包处理
--TODO 先不处理接收一包多协议的问题
local PacketBuffer = class("PacketBuffer")

--起始标记
PacketBuffer.MASK1 = 0x06
--结束标记
PacketBuffer.MASK2 = 0x04

PacketBuffer.MASK_LEN = 5

PacketBuffer.ENDIAN = cc.utils.ByteArrayVarint.ENDIAN_BIG

PacketBuffer.MASKBEGIN 	= nil
PacketBuffer.MASKEND 	= nil

function PacketBuffer:ctor()
	self:init()
end

function PacketBuffer:init()
	self._buf = PacketBuffer.getBaseBA()
	self._tempbuf = PacketBuffer.getBaseBA()
end
--
--转换数据到json 然后拼socket 信息头，再转回string
function PacketBuffer.parseData(data)
	local _buf = PacketBuffer.getBaseBA()

	if PacketBuffer.MASKBEGIN == nil then
		PacketBuffer.MASKBEGIN = PacketBuffer.getBaseBA()
		PacketBuffer.MASKBEGIN:writeByte(PacketBuffer.MASK1)
		PacketBuffer.MASKBEGIN:writeByte(PacketBuffer.MASK1)
		PacketBuffer.MASKBEGIN:writeByte(PacketBuffer.MASK1)
		PacketBuffer.MASKBEGIN:writeByte(PacketBuffer.MASK1)
		PacketBuffer.MASKBEGIN:writeByte(PacketBuffer.MASK1)

		PacketBuffer.MASKEND = PacketBuffer.getBaseBA()
		PacketBuffer.MASKEND:writeByte(PacketBuffer.MASK2)
		PacketBuffer.MASKEND:writeByte(PacketBuffer.MASK2)
		PacketBuffer.MASKEND:writeByte(PacketBuffer.MASK2)
		PacketBuffer.MASKEND:writeByte(PacketBuffer.MASK2)
		PacketBuffer.MASKEND:writeByte(PacketBuffer.MASK2)
	end

	--_buf:writeBytes(PacketBuffer.MASKBEGIN)
	_buf:writeString(json.encode(data))
	--_buf:writeBytes(PacketBuffer.MASKEND)
	return _buf
end

function PacketBuffer.getBaseBA()
	return cc.utils.ByteArray.new(PacketBuffer.ENDIAN)
end
--- Get a byte stream and analyze it, return a splited table
-- Generally, the table include a message, but if it receive 2 packets meanwhile, then it includs 2 messages.
function PacketBuffer:parsePackets(__byteString)
	local __msgs = {}
	local __pos = 0
	self._buf:setPos(self._buf:getLen()+1)
	self._buf:writeBuf(__byteString)
	self._buf:setPos(1)
	local __flag1 = nil
	local __flag2 = nil
	local __flag3 = nil
	local __flag4 = nil
	local __flag5 = nil
	local __preLen = PacketBuffer.MASK_LEN
	printf("start analyzing... buffer len: %u, available: %u", self._buf:getLen(), self._buf:getAvailable())
	while self._buf:getAvailable() >= __preLen do
		__flag1 = self._buf:readByte()
		--printf("__flag1:%2X", __flag1)
		--if bit.band(__flag1 ,PacketBuffer.MASK1) == __flag1 then
		if __flag1 == PacketBuffer.MASK1 then
			__flag2 = self._buf:readByte()
			--printf("__flag2:%2X", __flag2)
			--if bit.band(__flag2, PacketBuffer.MASK2) == __flag2 then
			if __flag2 ==  PacketBuffer.MASK1 then
				__flag3 = self._buf:readByte()
				if __flag2 ==  PacketBuffer.MASK1 then
					__flag3 = self._buf:readByte()
					if __flag3 ==  PacketBuffer.MASK1 then
						__flag4 = self._buf:readByte()
						if __flag4 == PacketBuffer.MASK1 then 
							__flag5 = self._buf:readByte()
							-- skip type value, client isn't needs it
							-- self._buf:setPos(self._buf:getPos()+1)
							-- local __bodyLen = self._buf:readInt()
							local __pos = self._buf:getPos()
							--printf("__bodyLen:%u", __bodyLen)
							-- buffer is not enougth, waiting...
							--包是否完整结束
							local ended = false
							while self._buf:getAvailable()>=__preLen do
								__flag1 = self._buf:readByte()
								if __flag1 == PacketBuffer.MASK2 then 
									__flag2 = self._buf:readByte()
									if __flag2 == PacketBuffer.MASK2 then 
										__flag3 = self._buf:readByte()
										if __flag3 == PacketBuffer.MASK2 then
											__flag4 = self._buf:readByte()
											if __flag4 == PacketBuffer.MASK2 then
												__flag5 = self._buf:readByte()
												if __flag5 == PacketBuffer.MASK2 then
													--这一个包结束了
													ended = true
													self._tempbuf:setPos(1)
													__msgs[#__msgs+1] = self._tempbuf:readStringBytes(self._tempbuf:getAvailable())
													--清空
													self._tempbuf = PacketBuffer.getBaseBA()
													break
												else
													self._tempbuf:writeByte(__flag5)
												end
											else
												self._tempbuf:writeByte(__flag4)
											end
										else
											self._tempbuf:writeByte(__flag3)
										end
									else
										self._tempbuf:writeByte(__flag2)
									end
								else
									self._tempbuf:writeByte(__flag1)
								end
							end

							if ended == false then
								--not enough
								self._buf:setPos(__pos - __preLen)
								break
							end
						end
					end
				end
			end
		end
	end
	-- clear buffer on exhausted
	if self._buf:getAvailable() <= 0 then
		self:init()
	else
		-- some datas in buffer yet, write them to a new blank buffer.
		-- printf("cache incomplete buff,len: %u, available: %u", self._buf:getLen(), self._buf:getAvailable())
		local __tmp = PacketBuffer.getBaseBA()
		self._buf:writeBytes(__tmp, 1, self._buf:getAvailable())
		self._buf = __tmp
		-- printf("tmp len: %u, availabl: %u", __tmp:getLen(), __tmp:getAvailable())
		-- print("buf:", __tmp:toString())
	end

	return __msgs
end

return PacketBuffer