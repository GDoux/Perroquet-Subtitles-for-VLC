--[[
Program: Perroquet Subtitles for VLC
Purpose: Train your listening comprehension by rewriting your favorite movies' subs (with correction)
Version: 1.1
Author: Gaspard DOUXCHAMPS
License: GNU GENERAL PUBLIC LICENSE
Release-Date: 25/06/2021
Credits: to Fred Bertolus and the Perroquet Team for the original software (https://launchpad.net/perroquet) and to Tomás Crespo for the "Subtitle Word Search" add-on (https://addons.videolan.org/p/1154033/). To Mederi for the Time v3.2 extension (https://addons.videolan.org/p/1154032/)
]]

--[[
INSTRUCTIONS:
This script file shoud be used with the perroquet.lua file.

The files should be placed in the following directories:

* Windows
	All Users:
	        perroquet.lua in	Program Files\VideoLAN\VLC\lua\extensions\
		perroquet_intf.lua in	Program Files\VideoLAN\VLC\lua\intf\
        Current user: [not tested]
		perroquet.lua in 	%APPDATA%\vlc\lua\extensions\
		perroquet_intf.lua in	%APPDATA%\vlc\lua\extensions\

* Mac OS X [not tested]
	All Users:
	        perroquet.lua in	/Applications/VLC.app/Contents/MacOS/share/lua/extensions/
		perroquet_intf.lua in	/Applications/VLC.app/Contents/MacOS/share/lua/intf/
        Current user:
		perroquet.lua in 	/Users/%your_name%/Library/ApplicationSupport/org.videolan.vlc/lua/extensions/
		perroquet_intf.lua in	/Users/%your_name%/Library/ApplicationSupport/org.videolan.vlc/lua/intf/

* Linux
	All Users:
	        perroquet.lua in	/usr/lib/vlc/lua/playlist/ or /usr/share/vlc/lua/extensions/
		perroquet_intf.lua in	/usr/lib/vlc/lua/playlist/ or /usr/share/vlc/lua/intf/
        Current user: [not tested]
		perroquet.lua in 	~/.local/share/vlc/lua/extensions/
		perroquet_intf.lua in	~/.local/share/vlc/lua/intf/
	Snap: (the number 2288 maybe different on your system)
		perroquet.lua in 	~/snap/vlc/2288/.local/share/vlc/lua/extensions/
		perroquet_intf.lua in	~/snap/vlc/2288/.local/share/vlc/lua/intf/
]]

-- not sure of the purpose of this...
os.setlocale("C", "all")

-- Initializes the runseq value and string in bookmark10
vlc.config.set("bookmark10", "runseq={[\"para\"]={[\"start\"]=false,[\"count\"]=0,[\"begin_time\"]=0,[\"finish_time\"]=0,},}")

-- Updates the runseq value and, in case of any change, wait for finish_time and pause
function Looper()
	local count_start=0 -- counter of loops
	local t
	while true do
		get_runseq()
		if (runseq.para.count ~= count_start) and (runseq.para.start) and (vlc.playlist.status()~="stopped") then
			count_start=runseq.para.count
			loop_until_pause()
		end
	end				
end

-- Pauses when finish_time has been reached
function loop_until_pause()
	repeat
		t=vlc.var.get(vlc.object.input(), "time")
	until t > runseq.para.finish_time
	vlc.playlist.pause()
end

-- Reads in runseq string in bookmark10 and update runseq parameters value
function get_runseq()
	local s = vlc.config.get("bookmark10")
	if not s or not string.match(s, "^runseq={.*}$") then 
		s = "runseq={}" 
	end
	assert(loadstring(s))()
end

Looper()
