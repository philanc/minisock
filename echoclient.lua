
local he = require "he"
local ms = require "minisock"

local function repr(x) return string.format("%q", x) end


-- af_unix = true  	-- test AF_UNIX socket
-- af_unix = false	-- test AF_INET socket (on localhost)
--
function test(af_unix)
	if af_unix then 
		-- unix socket
		sockpath = "/tmp/minisock_test.sock"
		addr = "\1\0" .. sockpath .. "\0\0\0\0\0"
		print("---")
		print("spawning echoserver.lua listening on " .. sockpath)
		os.execute("lua echoserver.lua " .. sockpath .. " & ")
	else
		-- net socket: 127.0.0.1:4096 (0x1000)
		addr = "\2\0\x10\x00\x7f\0\0\1\0\0\0\0\0\0\0\0"
		s = "127.0.0.1 port 4096"
		print("---")
		print("spawning echoserver.lua listening on " .. s)
		os.execute("lua echoserver.lua  & ")
	end

	-- ensure server has enough time to start listening
	ms.msleep(500)

	sfd, msg = ms.connect(addr)
	if not sfd then print("echoclient:", msg); goto exit end

	req = "Hello!"
	r, msg = ms.write(sfd, req)
	print("echoclient sends on fd ".. sfd .. ":", req)

	resp, msg = ms.read(sfd)
	if not resp then print("echoclient:", msg); goto exit end

	print("echoclient receives on fd ".. sfd .. ":", resp)
	assert(resp == "echo:" .. req)

	r, msg = ms.close(sfd)
	if not r then print("echoclient:", msg); goto exit end

	::exit::
	if af_unix then
		print("echoclient: removing socket", os.remove(sockpath))
	end
end--test()

function testudp()
	addr = "\2\0\x10\x00\x7f\0\0\1\0\0\0\0\0\0\0\0"
	s = "127.0.0.1 port 4096"
	print("---")
	-- launch server, ensure it has enough time to start listening
	print("spawning echoserver.lua udp receiving on " .. s)
	os.execute("lua echoserver.lua udp & ")
	ms.msleep(500)

	sfd, msg = ms.udpsocket()
	if not sfd then print("echoclient:", msg); goto exit end

	req = "Hello udp!"
	r, msg = ms.sendto(sfd, addr, req)
	print("echoclient sendto on fd ".. sfd .. ":", req)

	resp, msg = ms.recvfrom(sfd)
	if not resp then print("echoclient:", msg); goto exit end

	print("echoclient recvfrom on fd ".. sfd .. ":", resp)
	assert(resp == "echo:" .. req)

	r, msg = ms.close(sfd)
	if not r then print("echoclient:", msg); goto exit end
	
	::exit::
	
end --testudp()


test(true)  -- AF_UNIX (/tmp/minisock.sock)
test(false) -- AF_INET (localhost)
testudp()


------------------------------------------------------------------------
--[[

unix socket
	sockaddr:    family (uint16, =1) | socket path | 0
	family = 1    (0x01, 0x00)
	max len of a unix socket path: 108 incl null at end
		"SIZEOF_SOCKADDR_UN_SUN_PATH 108"

AF_INET (IPv4)
	sockaddr:  (cf return values of getaddrinfo)  len=16
	family=2  (u16) | port (u16) | IPv4 addr (u8 * 4) | u8=0 * 8
	note: family is little endian, port is big endian
	ie: family=2, port=80 =>  0x02, 0x00, 0x00, 0x50 

AF_INET6 (IPv6)
	sockaddr:  (cf return values of getaddrinfo)  len=28
	family=10  (u16) | port (u16) | flow_id=0 (u32) |  \
	IPv6 addr (u8 * 16) | u8=0 * 4
	note: family is little endian, port is big endian



]]


