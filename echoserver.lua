
-- echoserver.lua  --  should be launched by echoclient.lua 

local ms = require "minisock"

local function repr(x) return string.format("%q", x) end

-- arg[1] == "udp" for a udp datagram socket
-- or is the socket pathname for a unix socket 
-- or nil for a localhost tcp socket
-- (see echoclient.lua)

if arg[1] == "udp" then 
	goto udp
elseif arg[1] then 
	-- unix socket
	af_unix = true
	addr = "\1\0" .. arg[1] .. "\0\0\0\0\0"
else
	-- net socket: 127.0.0.1:4096 (0x1000, big endian)
	af_unix = false
	-- addr = family | port | IP addr | 00 * 8	
	addr = "\2\0" .. "\x10\x00" .. "\127\0\0\1" .. "\0\0\0\0\0\0\0\0"
end

sfd, msg = ms.bind(addr)
if not sfd then print("echoserver:", msg); goto exit end

cfd, msg = ms.accept(sfd)
if not cfd then print("echoserver:", msg); goto exit end

if af_unix then 
	print("echoserver: accept connection from unix socket:", repr(msg))
else
	print("echoserver: accept connection from:", ms.getnameinfo(msg))
end

req, msg = ms.read(cfd)
if not req then print("echoserver:", msg); goto exit end

r, msg = ms.write(cfd, "echo:" .. req)
if not r then print("echoserver:", msg); goto exit end

r, msg = ms.close(sfd)
if not r then print("echoserver:", msg); goto exit end

goto exit

::udp::
addr = "\2\0" .. "\x10\x00" .. "\127\0\0\1" .. "\0\0\0\0\0\0\0\0"
sfd, msg = ms.udpsocket(addr)
if not sfd then print("echoserver:", msg); goto exit end

req, msg = ms.recvfrom(sfd)
if not req then 
	print("echoserver:", msg); goto exit end

senderaddr = msg
print("echoserver: received message from:", ms.getnameinfo(senderaddr))

r, msg = ms.sendto(sfd, senderaddr, "echo:" .. req)
if not r then print("echoserver:", msg); goto exit end

r, msg = ms.close(sfd)
if not r then print("echoserver:", msg); goto exit end






::exit::


