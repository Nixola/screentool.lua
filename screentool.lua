#!/usr/bin/env lua

local args = {...}

local home = os.getenv("HOME")
local display = os.getenv("DISPLAY")
local settings = {
	host = {
		--internal = "web:CookieSite/static/%s/",
		internal = "web:/srv/www/static/%s/",
		--external = "https://static.nixo.la/%s/",
		external = "https://%s.nixo.la/",
	},
	tmp = "/tmp/",
	cache = home .. "/.cache/screentool.lua/",
	misc = home .. "/.local/share/screentool.lua/",
	path = {
		img = home .. "/Pictures/",
		vid = home .. "/Videos/",
	},
	formats = {
		img = "png",
		vid = "mp4",
		rawvid = "mkv",
	},
	audio = {
		channels = 2,
	},
	Xtargets = {
		img = "image/png",
		str = "UTF8_STRING",
	},
}

os.execute("mkdir -p \"" .. settings.cache .. "\"")
os.execute("mkdir -p \"" .. settings.misc .. "\"")

local system = {}
do
	local p = io.popen("xrandr --current")
	local r = p:read "*a"
	assert(p:close(), "xrandr errored abort abort aaaaaaaaaaa")
	local w, h, hz = r:match("(%d+)x(%d+)[^\n]+(%d+)%S*%+")
	system.width  = tonumber(w)
	system.height = tonumber(h)
	system.hertz  = tonumber(hz)
end


local notify = function(title, body)
	title = title or ""
	body = body or ""
	os.execute(("notify-send '%s' '%s'"):format(title, body))
end

local exists = function(filename)
	local e = false
	local f = io.open(filename, "r")
	e = not not f
	if f then f:close() end
	return e
end

local read = function(filename)
	local f, e = io.open(filename, "r")
	if not f then
		return f, e
	end
	local r = f:read "*a"
	f:close()
	return r
end

local write = function(filename, content)
	local f, e = io.open(filename, "w")
	if not f then
		return f, e
	end
	f:write(content)
	f:close()
	return true
end

local modes = {}
local addMode = function(name, func)
	modes[name] = func
	modes[#modes + 1] = name
end

addMode("measure", function(args)
	local p = io.popen("slop -k", "r")
	local geometry = p:read("*a")
	local success, _, code = p:close()
	if not success then
		return success, code
	end
	local g, w, h, x, y = geometry, geometry:match("(%d+)x(%d+)([+-]%d+)([+-]%d+)")
    if not (w and h and x and y) then
        return false
    end
	args.geometry = g
	args.width = tonumber(w)
	args.height = tonumber(h)
	args.x = tonumber(x)
	args.y = tonumber(y)
	return args
end)

addMode("automeasure", function(args)
	local p = io.popen("xdotool getwindowfocus")
	local id = p:read("*a")
	local success, _, code = p:close()
	if not success then
		p = io.popen("xprop -root 32x '\\t$0' _NET_ACTIVE_WINDOW")
		id = p:read("*a")
		local success, _, code = p:close()
		if not success then
			return success, code
		end
		id = tonumber(id:match("%s(.+)"))
	end
	args.id = id
	return args
end)

addMode("wait_2s", function(args)
	os.execute("sleep 2")
	return args
end)

addMode("screenshot", function(args)
	local g = args and args.geometry
	g = g and "-g "..g or (args.id and "-i " .. args.id or "")
	local cmd = "maim -f " .. settings.formats.img .. " " .. g
	print(cmd)
	local p = io.popen("maim -f " .. settings.formats.img .. " " .. g, "r")
	local r = p:read "*a"
	local success, _, code = p:close()
	if not success then
		notify("Maim borked(" .. code .. "). Screenshot aborted")
		os.exit(-1)
	end
	args.data = r
	args.type = "img"
	return args
end)

addMode("edit", function(args)

	local source = args.filename
	if not source then
		local data = args.data
		if not data then
			if not os.execute("xclip -sel c -o -t TARGETS | grep image/png") then
				notify("Couldn't find an image to edit. Aborting.")
				return false
			end
			local p = io.popen("xclip -sel c -o -t image/png", "r")
			data = p:read("*a")
			p:close()
		end
		source = os.tmpname()
		local f, e = io.open(source, "wb")
		assert(f, e)
		f:write(data)
		f:close()
		os.execute("chmod a+r " .. source)
	end
	if not exists(settings.misc .. "editor") then
		notify("Missing editor", "The editor is not installed. Please install it in " .. settings.misc .. "editor.")
		return args
	end

	local command = ("cat '%s' | '%s'"):format(source, settings.misc .. "editor")
	print(command)
	local p = io.popen(command)
	local r = p:read "*a"
	local res = p:close()
	if not res then
		notify("Error occurred", "The editor errored. The image was not edited.")
		print(res)
		return args
	end
	args.data = r
	args.filename = nil
	return args
	--[[ hint at a future approach
	package.preload.love = package.loadlib('/usr/lib/liblove.so', 'luaopen_love')
	local love = require "love"
	--]]

end)

addMode("screencap", function(args)
	local x, y, w, h = args.x, args.y, args.width, args.height
	if not (x and y and w and h) then
		x, y = 0, 0
		w, h = system.width, system.height
	end
	local tmppath = settings.cache .. os.time() .. "." .. settings.formats.rawvid
	local input = ("%s+%d,%d"):format(display, x, y)
	--local cmd = ("ffmpeg -video_size %dx%d -framerate %d -f x11grab -i %s -f jack -i ffmpeg_screentool -c:v libx264 -crf 0 -preset ultrafast -c:a flac %s  & echo -n $! > \"%s\"")
	--local cmd = ("ffmpeg -video_size %dx%d -framerate %d -f x11grab -i %s -f pulse -i alsa_output.pci-0000_10_00.3.analog-stereo.monitor -c:v libx264 -crf 0 -preset ultrafast -c:a flac %s  & echo -n $! > \"%s\"")
	local cmd = ("ffmpeg -video_size %dx%d -framerate %d -f x11grab -i %s -c:v libx264 -crf 0 -preset ultrafast -c:a flac \"%s\"  & echo -n $! > \"%s\"")
		:format(w, h, 60, input, tmppath, settings.tmp .. "screentool.lua.ffmpeg.pid")
	assert(write(settings.tmp .. "screentool.lua.ffmpeg.tmpname", tmppath))
	print(cmd)
	local ffmpeg = io.popen(cmd)
	os.execute("sleep 1")
	for i = 1, settings.audio.channels do
		--os.execute(("jack_connect system:monitor_%d ffmpeg_screentool:input_%d"):format(i, i))
	end
	--[[ This is in case you don't want to, or can't, enable JACK monitor. It'll just grab anything that goes to output.
	os.execute("sleep 1")
	local jack_lsp = io.popen("jack_lsp -c")
	local connections = {}
	for line in (jack_lsp:read "*a"):gmatch("([^\n]+)") do
		connections[#connections + 1] = line
	end
	print(#connections)
	jack_lsp:close()

	for i, v in ipairs(connections) do
		if not v:match("^   ") then
			local connection = v
			for ii = i+1, #connections do
				local vv = connections[ii]
				if not vv:match("^   ") then break end
				local channel = vv:match("^   system:playback_(%d)")
				if channel then
					print("jack_connect " .. connection .. " ffmpeg_screentool:input_" .. channel)
					os.execute("jack_connect " .. connection .. " ffmpeg_screentool:input_" .. channel)
				end
			end
		end
	end
	--]]

	ffmpeg:close()
end)

addMode("stream", function(args)
	local x, y, w, h = args.x, args.y, args.width, args.height
	if not (x and y and w and h) then
		x, y = 0, 0
		w, h = system.width, system.height
	end
	local tmppath = settings.cache .. os.time() .. "." .. settings.formats.rawvid
	local input = ("%s+%d,%d"):format(display, x, y)
	local cmd = ("ffmpeg -video_size %dx%d -framerate %d -f x11grab -i %s -f jack -i ffmpeg_screentool -c:v libx264 -b:v 2M -preset fast -tune zerolatency -c:a aac -b:a 160k -f flv rtmp:nixo.la/live/bbb & echo -n $! > \"%s\"")
		:format(w, h, 60, input, settings.tmp .. "screentool.lua.ffmpeg.pid")
	assert(write(settings.tmp .. "screentool.lua.ffmpeg.tmpname", tmppath))
	print(cmd)
	local ffmpeg = io.popen(cmd)
	os.execute("sleep 1")
	for i = 1, settings.audio.channels do
		--os.execute(("jack_connect system:monitor_%d ffmpeg_screentool:input_%d"):format(i, i))
	end
	ffmpeg:close()
end)

addMode("stop", function(args)
	local pid, filename = read(settings.tmp .. "screentool.lua.ffmpeg.pid"), read(settings.tmp .. "screentool.lua.ffmpeg.tmpname")
	os.execute("kill " .. pid)
	args.filename = filename
	args.type = "vid"
	notify "Recording stopped."
    return args
end)

addMode("compress", function(args)
	notify "Compressing..."
	local filename = args.filename:gsub(settings.formats.rawvid, settings.formats.vid)
	local cmd = ("ffmpeg -i \"%s\" -c:v libx264 -threads 4 -vf \"pad=ceil(iw/2)*2:ceil(ih/2)*2,format=yuv420p\" -movflags +faststart -crf 20 -preset fast \"%s\"")
		:format(args.filename, filename)
	os.execute(cmd)
	args.filename = filename
	notify "Compressed."
	return args
end)

addMode("save", function(args)
	local data = args.data
	local type = args.type
	fname = ("%s%d.%s"):format(settings.path[type], os.time(), settings.formats[type])
	local f, e = io.open(fname, "wb")
	assert(f, e)
	f:write(data)
	f:close()
	args.filename = fname
	return args
end)

addMode("upload", function(args)
	notify "Uploading..."
	local source = args.filename
	local target = args.filename and args.filename:match(".+/(.-)$")
	if not source then
		source = os.tmpname()
		local f, e = io.open(source, "wb")
		assert(f, e)
		f:write(args.data)
		f:close()
		os.execute("chmod a+r " .. source)
		target = ("%d.%s"):format(os.time(), settings.formats[args.type])
	end
	local fullTarget = settings.host.internal:format(args.type:sub(1,1)) .. target
	os.execute(("scp '%s' '%s'"):format(source, fullTarget))
	local url = settings.host.external:format(args.type:sub(1,1)) .. target
	args.url = url
	notify "Uploaded."
	return args
end)

addMode("copy", function(args)
	local data = args.data
	local str = args.url or args.filename
	if data and str then
		local cmd = ("ximgcopy '%s'"):format(str)
		local p = io.popen(cmd, "w")
		p:write(data)
		p:flush()
	elseif data or str then
		local cmd = ("xclip -sel c -t %s"):format(data and settings.Xtargets[args.type] or settings.Xtargets.str)
		local p = io.popen(cmd, "w")
		p:write(data or str)
		p:close()
	end
	return args
end)

addMode("rofi", function()
	local input = table.concat(modes, "\\n")
	local cmd = ("echo -ne \"%s\" | rofi -dmenu -multi-select"):format(input)
	local p, e = io.popen(cmd)
	if not p then
		error("Error opening rofi: " .. e)
	end
	local r = p:read '*a'
	p:close()
	r = r:gsub("\n", " ")
	os.execute("screentool.lua " .. r)
end)


local arg = {}
for i, v in pairs(args) do print(i, v) end
for i, v in ipairs(args) do
	print(v)
	if not modes[v](arg) then
        print "Aborted."
        break
    end
end
