os.setlocale("C", "all") -- fixes numeric locale issue on Mac
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
				t=vlc.var.get(vlc.object.input(), "time")
				if t > config.TIME.finish_time then
					if vlc.playlist.status()~="paused" then
						vlc.playlist.pause()
					end
				else
					vlc.misc.mwait(vlc.misc.mdate() + 100000)
				end
			end
		end				

--		config.TIME={time_format="[E1]",osd_position="bottom-left"}

		--[[if vlc.playlist.status()=="stopped" then -- no input or stopped input
			if curi then -- input stopped
				Log("stopped")
				curi=nil
			end
			--loops=loops+1
			--Log(loops)
			Sleep(1)
		else -- playing, paused
			local uri=nil
			if vlc.input.item() then 
				uri=vlc.input.item():uri() 
			end
			if not uri then --- WTF (VLC 2.1+): status playing with nil input? Stopping? O.K. in VLC 2.0.x
				Log("WTF??? " .. vlc.playlist.status())
				Sleep(0.1)
			elseif not curi or curi~=uri then -- new input (first input or changed input)
				curi=uri
				Log(curi)
			else -- current input
				if not config.TIME or config.TIME.stop~=true then TIME_Loop() end
				if vlc.playlist.status()=="playing" then
					--Log("playing")
				elseif vlc.playlist.status()=="paused" then
					--Log("paused")
					Sleep(0.3)
				else -- ?
					Log("unknown")
					Sleep(1)
				end
				Sleep(0.1)
			end
		end]]
	end
end

function Get_config()
	local s = vlc.config.get("bookmark10")
	if not s or not string.match(s, "^config={.*}$") then s = "config={}" end
	assert(loadstring(s))() -- global var
end

Looper() --starter
