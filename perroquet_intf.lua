os.setlocale("C", "all")

config={}
config.TIME={} -- subtable reserved for TIME extension

function Looper()
	local curi=nil
	local loops=0 -- counter of loops
	local t
	while true do
		if vlc.volume.get() == -256 then 
			break 
		end  -- inspired by syncplay.lua; kills vlc.exe process in Task Manager
		Get_config()
		if vlc.playlist.status()=="stopped" then -- no input or stopped input
		else 
			if config.TIME.start == true then
				vlc.msg.err("STOP1")
				while true do
					Get_config()
					t=vlc.var.get(vlc.object.input(), "time")
					if t > config.TIME.finish_time then
						vlc.playlist.pause()
						vlc.msg.err("STOP2")
						vlc.misc.mwait(vlc.misc.mdate() + 100000)
						break
					end
				end
			else
--				vlc.misc.mwait(vlc.misc.mdate() + 100000)
--				vlc.msg.err("STOP3")
			end
		end
	end				
end

function Get_config()
	local s = vlc.config.get("bookmark10")
	if not s or not string.match(s, "^config={.*}$") then 
		s = "config={}" 
	end
	assert(loadstring(s))() -- global var
end

Looper() --starter
