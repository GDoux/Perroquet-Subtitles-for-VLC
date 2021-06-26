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
This script file shoud be used with the perroquet_intf.lua file.

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

function descriptor()
	return {
		title = "Perroquet Subtitles for VLC",
		version = "1.1",
		author = "Gaspard DOUXCHAMPS",
		url = "https://github.com/GDoux/Perroquet-Subtitles-for-VLC",
		shortdesc = "Perroquet Subtitles for VLC",
		description = "Train your listening comprehension by rewriting your favorite movies' subs (with correction)",
		capabilities ={},
	}
end

---------- VLC entrypoints ----------

function activate()
	os.setlocale("C", "all") -- just in case
	local VLC_extraintf, VLC_luaintf, intf_table, luaintf_index = VLC_intf_settings()
	if luaintf_index==-1 or VLC_luaintf~="perroquet_intf" then 
		trigger_menu(2) 
	else 
		trigger_menu(1) 
	end
end

function close()
	vlc.deactivate();
end

----------Menu---------------

-- Selects the menu depending on id and initialize it
function trigger_menu(id)
	if self then
		if self.dialog then
			self.dialog:delete() 
		end
	end
	if id==1 then -- Normal menu
		initialize_runseq()
		initialize_gui()
		initialize_encodings()
		initialize_subtitle_files()
		load_subtitle_file()
	elseif id==2 then -- Intf settings menu
		initialize_gui_intf()
	end
end

-----------INTF activation----------------

-- Initializes the intf activation settings gui
function initialize_gui_intf()
	self = Gui:new()
	self.dialog = vlc.dialog("Perroquet for VLC")	
	
	enable_extraintf = self.dialog:add_check_box("Enable interface: ", true,1,1,1,1)
	name_luaintf = self.dialog:add_text_input("perroquet_intf",2,1,2,1)
	self.dialog:add_button("SAVE!", click_SAVE_settings,1,2,1,1)
	self.dialog:add_button("CANCEL", click_CANCEL_settings,2,2,1,1)

	local VLC_extraintf, VLC_luaintf, intf_table, lua_intf_index = VLC_intf_settings()
	lb_message = self.dialog:add_label("Current status: " .. ((lua_tinf_index==-1) and "ENABLED" or "DISABLED") .. " " .. tostring(VLC_luaintf),1,3,3,1)	
end

-- Activates perroquet intf
function click_SAVE_settings()
	local VLC_extraintf, VLC_luaintf, intf_table, luaintf_index = VLC_intf_settings()

	if enable_extraintf:get_checked() then
		if not lua_intf_index then table.insert(intf_table, "luaintf") end
		vlc.config.set("lua-intf", name_luaintf:get_text())
	else
		if lua_intf_index then table.remove(intf_table, luaintf_index) end
	end
	vlc.config.set("extraintf", table.concat(intf_table, ":"))
	lb_message:set_text("Please restart VLC for changes to take effect!")
end

function click_CANCEL_settings()
	trigger_menu(1)
end

-- Reads intf settings
function VLC_intf_settings()
	local VLC_extraintf = vlc.config.get("extraintf") -- enabled VLC interfaces
	local VLC_luaintf = vlc.config.get("lua-intf") -- Lua Interface
	local intf_table={}
	local luaintf_index=false
	if VLC_extraintf then
		intf_table=split_string(VLC_extraintf, ":")
		for i,v in ipairs(intf_table) do
			if v=="luaintf" then
				luaintf_index=i
				break
			end
		end
	end
	return VLC_extraintf, VLC_luaintf, intf_table, luaintf_index
end

---------- Initialization functions ----------

-- gui {Gui} The Graphical User Interface.
gui = nil
-- subtitle_files {array<SubtitleFile>} Contains the candidate subtitle files.
subtitle_files = nil
-- current_subtitle_file {SubtitleFile} Contains the currently selected subtitle file.
current_subtitle_file = nil
--current_subtitle_line {SubtitleLine} Contains the currently studies subtitle line
current_subtitle_line=nil
-- encodings {} Contains all encoding/decoding capabilities
encodings={}
--characters that form words in subtitle_line
readable_char="([%wçÀ-ÿæœÆŒß]+)"
--characters that delimitates words in subtitle_line
word_recogn_char= "([^%w^ç^À-ÿ^æ^œ^Æ^Œ^ß]+)"

-- Initializes the runseq string in bookmark10, just to make sure
function initialize_runseq()
	runseq=Runseq.new()
	runseq:init_runseq()
end

-- Initializes the normal gui
function initialize_gui()
	gui = Gui.new()
	gui:render()
end

-- Generates the list of enconding/decoding capabilities
-- The list is the same for windows and unix in this version
function initialize_encodings() 
	if (is_unix_os()) then
		encodings = {"UTF-8", "UTF-8-SIG", "ISO_8859-1", "ISO_8859-1-SIG"}
	else
		encodings = {"UTF-8", "UTF-8-SIG", "ISO_8859-1", "ISO_8859-1-SIG"}
	end
	gui:inject_encodings(encodings)
end

-- Looks for the candidate perroquet files and adds them to the GUI dropdown.
function initialize_subtitle_files()
	local file_discoverer = SubtitleFileDiscoverer.new("perroquet")
	local is_movie_opened = get_video_file_location()
	if (is_movie_opened) then
		subtitle_files = file_discoverer:discover_files()
		if (subtitle_files) then
			gui:inject_subtitle_files(subtitle_files)
		end
	else 
		gui:print_error_message("No movie files opened in VLC. Close Perroquet, open a movie, and retry")
	end
end

---------- GUI callback functions ----------

-- Loads a perroquet file.
-- Then shows the subtitle hidden words corresponding to the current time, or to the closest next sequence, or displays an error message if something went wrong.
function load_subtitle_file()
	if (current_subtitle_file) then
		current_subtitle_file:clear()
--		gui:print_error_message("")
		gui:print_warning_message("Loading ...")
	end

	local subtitle_file_index = gui:get_selected_subtitle_file_index()
	if (subtitle_files) then
		current_subtitle_file = subtitle_files[subtitle_file_index]
		if (current_subtitle_file) then
			local subtitle_delay = vlc.var.get(vlc.object.input(), "spu-delay")
			local video_length = vlc.var.get(vlc.object.input(), "length")
			local encoding_index=gui:get_selected_encoding_index()
			local encoding=encodings[encoding_index]
			local srt_reader = SrtReader.new(current_subtitle_file:get_path(), subtitle_delay, video_length, encoding)
			local subtitle_lines, error_message = srt_reader:read()
	
			if (error_message) then
				gui:print_error_message(error_message)
			else
				current_subtitle_file:set_subtitle_lines(subtitle_lines)
				capture_words_at_now()
			end
		else
			local video_directory, video_filename = get_video_file_location()
			if (video_directory and video_filename) then
				gui:print_error_message("No file found for " .. string.sub(video_filename,1,string.len(video_filename)-3) .. "perroquet")
			end
		end
	end
end

-- Shows the hidden words appearing at the current timestamp, or at the closest next sequence.
-- Displays an error message if something goes wrong.
function capture_words_at_now()
	if (not current_subtitle_file) then
		return
	end

	local current_playing_timestamp = Timestamp.now()
	current_subtitle_line = current_subtitle_file:search_line_at(current_playing_timestamp)
	if (not current_subtitle_line) then
		current_subtitle_line = current_subtitle_file:pick_closest_line(current_playing_timestamp)
	end

	if (not current_subtitle_line) then 
		gui:print_error_message("Error, try to reload or changing position in movie")
	else
		gui:print_error_message("")
--		current_subtitle_line:get_start()
		show_subtitle_and_timestamp(current_subtitle_line, current_subtitle_line:get_start(), current_subtitle_line:get_finish() )
	end
end

-- Shows the words corresponding to the current subtitle.
function navigate_still()
	navigate(0)
end

-- Shows the words corresponding to the subtitle that goes before the current one.
function navigate_backward()
	navigate(-1)
end

-- Shows the words corresponding to the subtitle that goes after the current one.
function navigate_forward()
	navigate(1)
end

-- Shows the words corresponding to the subtitle shifted `n` lines.
function navigate(n)
	if (not current_subtitle_file) then
		return
	end
	if n~=0 then
		gui.input_subs:set_text("")
	end
	current_subtitle_line = current_subtitle_file:shift_lines(n)
	if (current_subtitle_line) then
		show_subtitle_and_timestamp(current_subtitle_line, current_subtitle_line:get_start(), current_subtitle_line:get_finish() )
	end
end

-- Shows the hidden words of a subtitle along with the associated timestamp in the corresponding list widget.
function show_subtitle_and_timestamp(subtitle_line, timestamp_start, timestamp_finish)
	if (subtitle_line) then
		gui:inject_subtitle_words(subtitle_line:get_hidden())
		gui:print_timestamp(timestamp_start,timestamp_finish)
	else
		gui:inject_subtitle_words("")
	end
end

-- Gets the subs written by user in input field, update hidden words accordingly. If all words were found, replay the sequence and go to the next
function user_input_subs()
	local input_string=gui.input_subs:get_text()
	if (current_subtitle_line) then
		gonext=current_subtitle_line:update_hidden_table(input_string)
		gui:update()
		if gonext==1 then
			navigate_forward_and_play()
		end
	end
end

-- Replays the current sequence and play the next sequence. Displays hidden words of next sequence
function navigate_forward_and_play()
	local old_start = current_subtitle_line:get_start():to_microseconds()
	navigate(1)
	run_seq(old_start - gui.delay_before:get_text()*1000, current_subtitle_line.finish.microseconds + gui.delay_after:get_text()*1000)
end

-- Replays the current sequence
function go_to_subtitle_timestamp()
	if (not current_subtitle_file) then
		return
	end
	navigate(0)
	run_seq(current_subtitle_line:get_start():to_microseconds() - gui.delay_before:get_text()*1000,current_subtitle_line.finish.microseconds + gui.delay_after:get_text()*1000)
end

-- Runs a video sequence between two times, then pause. Improved in v1.1 vs v1.0
function run_seq(begin_time, finish_time)
	local runseq=Runseq.new()
	runseq.para.begin_time = math.max(1,begin_time)
	runseq.para.finish_time = math.min(vlc.var.get(vlc.object.input(), "length"),finish_time)
	runseq.para.count = get_runseq_count() +1
	runseq.para.start=true
	runseq:set_runseq()
	vlc.var.set(vlc.object.input(), "time", begin_time)
	vlc.playlist.play()
--	dlg:set_title(descriptor().title)
end

function help()
	if (current_subtitle_line) then
		current_subtitle_line:reveal_all()
	end
end

---------- Classes ----------

-- Class: Runseq
-- Stores the sequence running parameters
Runseq = {}
Runseq.__index = Runseq

-- Creates and initialize a runseq
function Runseq.new()
	local self = setmetatable({}, Runseq)
	self.para = {}
	self.para.begin_time = 0
	self.para.finish_time = 0
	self.para.count = 0
	self.para.start=false
	return self
end

-- Writes the init runseq in bookmark10.
function Runseq:init_runseq()
	self:set_runseq()
end

-- Reads the current runseq_count (roughly the number of times run_seq function has been called)
function get_runseq_count()
	local s = vlc.config.get("bookmark10")
	count = string.match(s,"\"count\"]=(%d+)")
	return count
end

-- Writes the runseq parameters to bookmark10
function Runseq:set_runseq()	
	vlc.config.set("bookmark10", "runseq="..Serialize(self))
end

-- Class: Gui.
-- Renders the GUI (Graphical User Interface).
Gui = {}
Gui.__index = Gui

-- Constructor method. Creates the GUI instance.
function Gui.new()
	local self = setmetatable({}, Gui)
	-- dialog {vlc.dialog} The VLC dialog.
	self.dialog = nil
	-- files_dropdown {vlc.dropdown} The subtitle files dropdown.
	self.files_dropdown = nil
	-- timestamp_label {vlc.label} The current timestamp label.
	self.timestamp_label = nil
	-- correction {vlc.label} The correction field (hidden words).
	self.correction = nil
	-- search_engines_dropdown {vlc.dropdown} The search engines dropdown.
	self.search_engines_dropdown = nil
	-- last_row {number} The last row in the grid being constructed.
	self.last_row = 1
	return self
end

-- Renders the VLC extension grid dialog.
function Gui:render()
	self.dialog = vlc.dialog("Perroquet for VLC")
	self:draw_file_section()
	self:draw_input_section()
	self:draw_correction_section()
	self:draw_button_section()
	self.dialog:show()
end

-- Increments the index of the last row in the GUI and returns the value previous to the increment.
-- Equivalent to the typical construct `n++` of other programming languages.
-- @return {number} The last row number value previous to the increment.
function Gui:increment_row()
	local previous_last_row = self.last_row
	self.last_row = self.last_row + 1
	return previous_last_row
end

-- Draws the perroquet files selector section. The order matters to ease the use of tab, arrows and enter key
function Gui:draw_file_section()
	self.dialog:add_label("<h4>Subtitles file and settings</h4>", 1, self:increment_row(), 5, 1)
	self.files_dropdown = self.dialog:add_dropdown(1, self.last_row, 1)
	self.dialog:add_label("<h6>Delay before (ms)</h6>", 4, 1)
	self.dialog:add_label("<h6>Delay after (ms)</h6>", 5, 1)
	self.encodings_dropdown = self.dialog:add_dropdown(2, self.last_row, 1)
	self.delay_before = self.dialog:add_text_input("1000",4,self.last_row)
	self.delay_after = self.dialog:add_text_input("1000",5,self:increment_row())
--	self.error_message = self.dialog:add_label("",1,self:increment_row(),5)
end

-- Draws the input section
function Gui:draw_input_section()
	self.dialog:add_label("<h4>Input</h4>", 1, self:increment_row())
	self.input_subs = self.dialog:add_text_input("Write here what you understand here and click on Try!",1,self.last_row,4)
	self.dialog:add_button("Try!", user_input_subs, 5, self:increment_row())
end

-- Draws the correction field
function Gui:draw_correction_section()
	self.dialog:add_label("<h4>Correction</h4>", 1, self:increment_row())
	self.timestamp_label = self.dialog:add_label("<center> 00:00:00 to 00:00:00 </center>", 1, self.last_row)
	self.dialog:add_button("(Re)play", go_to_subtitle_timestamp, 4, self.last_row)
	self.dialog:add_button("Help!", help, 5, self.last_row)
	self.dialog:add_button("<<", navigate_backward, 2, self.last_row)
	self.dialog:add_button(">>", navigate_forward, 3, self:increment_row())
	self.correction = self.dialog:add_label("", 1, self:increment_row(), 5, 1)
end

-- Finishes to draw the perroquet files selector section. The order matters to ease the use of tab, arrows and enter key
function Gui:draw_button_section()
	self.dialog:add_button("Load", load_subtitle_file, 3, 2)
end

--Builds the encoding dropdown widget
function Gui:inject_encodings(encodings)
	for index, encoding in ipairs(encodings) do
		gui:inject_encoding(encoding, index)
	end
end

--Adds an encoding to the corresponding dropdown widget
function Gui:inject_encoding(encoding, index)
	self.encodings_dropdown:add_value(encoding,index)
end

--Builds the perroquet files dropdown widget
function Gui:inject_subtitle_files(subtitle_files)
	for index, subtitle_file in ipairs(subtitle_files) do
		gui:inject_subtitle_file(subtitle_file:get_name(), index)
	end
end

-- Adds a perroquet file name to the corresponding dropdown widget.
function Gui:inject_subtitle_file(name, index)
	self.files_dropdown:add_value(name, index)
end

-- Shows the content of the correction field (hidden words)
function Gui:inject_subtitle_words(text)
	self.correction:set_text("<h2><font color=DarkRed><center>" .. text .. "</center></font></h2>")
end


function Gui:get_selected_encoding_index()
	return self.encodings_dropdown:get_value()
end

-- Gets the index of the selected subtitle file in the corresponding dropdown widget.
function Gui:get_selected_subtitle_file_index()
	return self.files_dropdown:get_value()
end

-- Prints a timestamp in the specific label.
function Gui:print_timestamp(timestamp_start,timestamp_finish)
	self.timestamp_label:set_text(timestamp_start:to_string() .. " to " .. timestamp_finish:to_string())
end

function Gui:print_error_message(error_message)
	self.correction:set_text("<h3><font color=red><center>" .. error_message .. "</center></font></h3>")
end

function Gui:print_warning_message(warning_message)
	self.correction:set_text("<h4><font color=DarkRed><center>" .. warning_message .. "</center></font></h4>")
	gui:update()
end

-- Updates the GUI. Useful to render partial updates before a method returns.
function Gui:update()
	self.dialog:update()
end

-- Class: SubtitleFileDiscoverer.
-- Discovers the candidate subtitle files in the filesystem.
SubtitleFileDiscoverer = {}
SubtitleFileDiscoverer.__index = SubtitleFileDiscoverer

-- Constructor method. Creates a subtitle file discoverer.
function SubtitleFileDiscoverer.new(extension)
	local self = setmetatable({}, SubtitleFileDiscoverer)
	-- extension {string} The file extension to discover
	self.extension = extension
	return self
end

-- Gets the file system's paths to the found subtitles of the playing video
function SubtitleFileDiscoverer:discover_files()
	local subtitle_files = {}

	local video_dir_path, video_filename = get_video_file_location()
	local video_filename_no_ext = video_filename:match("^(.+)%..+$")
	if (is_unix_os()) then
		video_dir_path = "/" .. video_dir_path
	end
	local filenames_in_directory = list_directory(video_dir_path)
	local subtitle_filenames = self:find_matching_filenames(video_filename_no_ext, filenames_in_directory)
	if (subtitle_filenames) then
		for index, subtitle_filename in ipairs(subtitle_filenames) do
			local absolute_path = video_dir_path .. subtitle_filename
			subtitle_files[#subtitle_files + 1] = SubtitleFile.new(absolute_path, subtitle_filename)
		end
	else
		vlc.msg.warn("The list of filenames in the directory couldn't be retrieved: trying the default subtitle name")
		local filename = video_filename_no_ext .. "." .. self.extension
		local absolute_path = video_dir_path .. filename
		subtitle_files[1] = SubtitleFile.new(absolute_path, filename)
	end
	return subtitle_files
end

-- Gets an array of filenames that have the same name as the given filename but differ in extension.
function SubtitleFileDiscoverer:find_matching_filenames(target_filename, filename_listing)
	local matching_filenames = {}

	for index, candidate_filename in ipairs(filename_listing) do
		local has_name = candidate_filename:find(target_filename, 1, true)
		local has_extension = candidate_filename:find("%." .. self.extension)

		if (has_name and has_extension) then
			matching_filenames[#matching_filenames + 1] = candidate_filename
		end
	end

	return matching_filenames
end


-- Class: SubtitleFile.
-- Represents a subtitle file.
SubtitleFile = {}
SubtitleFile.__index = SubtitleFile

-- Constructor method. Creates a subtitle file.
function SubtitleFile.new(path, name)
	local self = setmetatable({}, SubtitleFile)
	self.path = path
	self.name = name
	self.subtitle_lines = nil
	self.current_line_index = nil
	return self
end

-- Sets the subtitle lines read from the file.
function SubtitleFile:set_subtitle_lines(subtitle_lines)
	self.subtitle_lines = subtitle_lines
end

-- Gets the name of the subtitle file.
function SubtitleFile:get_name()
	return self.name
end

-- Gets the path of the subtitle file.
function SubtitleFile:get_path()
	return self.path
end

-- Searches the subtitle line at the given timestamp.
-- Performs a binary search over the ordered subtitle lines.
-- Updates the value of the current line index, which would point to an index with fractional part if nothing was found.
function SubtitleFile:search_line_at(timestamp)
	local lower_bound, upper_bound = 1, #self.subtitle_lines

	local found_line, middle_index
	repeat
		local half_distance = math.floor((upper_bound - lower_bound) / 2)
		middle_index = lower_bound + half_distance
		local current_line = self.subtitle_lines[middle_index]
		local is_in_interval = current_line:is_in_interval(timestamp)
		if (is_in_interval) then
			found_line = current_line
			self.current_line_index = middle_index
			break
		else
			local comparison = timestamp:compare_to(current_line:get_start())
			if (comparison > 0) then
				lower_bound = middle_index
			else
				upper_bound = middle_index
			end
		end
	until (half_distance == 0)

	if (not found_line) then
		self:set_invalid_line_index(lower_bound, upper_bound, timestamp)
	end

	return found_line
end


-- Returns the closest subtitle_line after a given timestamp
function SubtitleFile:pick_closest_line(timestamp)
	local timestamp_microsec = timestamp:to_microseconds()
	local deltaT=1000000
	local timestamp_sup, timestamp_inf
	local max_timestamp = vlc.var.get(vlc.object.input(), "length")
	local min_timestamp =1
	local n_shift=0
	local shift_timestamp_inf
	local shift_timestamp_sup
	repeat 
		shift_timestamp_sup = math.min(max_timestamp,timestamp_microsec + n_shift*deltaT)
		shift_timestamp_inf = math.max(min_timestamp,timestamp_microsec - n_shift*deltaT)
		timestamp_sup = Timestamp.of_microseconds(shift_timestamp_sup)
		timestamp_inf = Timestamp.of_microseconds(shift_timestamp_inf)
		n_shift=n_shift+1
		found_line = self:search_line_at(timestamp_sup)
		if (not self:is_valid_line_index()) then
			found_line = self:search_line_at(timestamp_inf)
		end

	until self:is_valid_line_index()
	return found_line
end

-- Sets an index with fractional part, indicating the place near two consecutive indices where a value not found should be.
function SubtitleFile:set_invalid_line_index(lower_bound, upper_bound, timestamp)
	local lower_line_timestamp = self.subtitle_lines[lower_bound]:get_start()
	local upper_line_timestamp = self.subtitle_lines[upper_bound]:get_start()

	if (timestamp:compare_to(lower_line_timestamp) < 0) then
		self.current_line_index = lower_bound - 0.5
	elseif (timestamp:compare_to(upper_line_timestamp) > 0) then
		self.current_line_index = upper_bound + 0.5
	else
		self.current_line_index = lower_bound + 0.5
	end
end

-- Checks if the current index is pointing to an actual subtitle, or rather to a middle ground.
function SubtitleFile:is_valid_line_index()
	return (self.current_line_index == math.floor(self.current_line_index))
end

-- Gets the subtitle line shifting `n` lines from the current line.
-- The lines to shift must be between -1, 0 and +1. A value of 0 returns the current line, or `nil` if not pointing to a valid line.
function SubtitleFile:shift_lines(n)
	local is_valid_line_index = self:is_valid_line_index()
	if (not is_valid_line_index and (n == 0)) then
		return nil
	end

	local new_line_index
	if (is_valid_line_index) then
		new_line_index = self.current_line_index + n
	else
		new_line_index = self.current_line_index + 0.5 * n
	end

	if ((new_line_index < 1) or (new_line_index > #self.subtitle_lines)) then
		return nil
	end

	self.current_line_index = new_line_index
	return self.subtitle_lines[new_line_index]
end

-- Clears the subtitle lines of the file.
-- Note: the current line index is not cleared.
function SubtitleFile:clear()
	self.subtitle_lines = nil
end


-- Class: SrtReader.
-- Reads an SRT file.
SrtReader = {}
SrtReader.__index = SrtReader

-- Reader state machine values
SrtReader.READING_NUMBER = 0
SrtReader.READING_INTERVAL = 1
SrtReader.READING_CONTENT = 2

-- Constructor method. Creates a reader.
function SrtReader.new(filepath, subtitle_delay, video_length_microseconds,encoding)
	local self = setmetatable({}, SrtReader)
	self.filepath = filepath
	self.subtitle_delay = subtitle_delay -- microseconds
	self.video_length_microseconds = video_length_microseconds --microseconds
	self.encoding = encoding
	self.current_line_number = 1
	self.subtitle_lines = {}
	self.current_index = 1
	self.current_number = 1
	self.current_subtitle_line = nil
	self.current_state = SrtReader.READING_NUMBER
	return self
end

-- Reads the file according to encoding and extracts all subtitle lines. 
function SrtReader:read()
	local file, error_message = io.open(self.filepath, "r")
	if (not file) then
		return nil, error_message
	end
	self.current_subtitle_line = SubtitleLine.new()
	self.current_subtitle_line.encoding = self.encoding
	local index=0
	for line in file:lines() do
		index=index+1
		line = remove_charset_signature(line,self.encoding,index)
		line= line .. " "
		error_message = self:process_line(line)
		if (error_message) then
			file:close()
			return nil, error_message
		end
	end
	file:close()
	return self.subtitle_lines
end

-- Processes a file line depending on the state machine status.
function SrtReader:process_line(line)
	local error_message
	if (self.current_state == SrtReader.READING_NUMBER) then
		error_message = self:process_number(line)
	elseif (self.current_state == SrtReader.READING_INTERVAL) then
		error_message = self:process_interval(line)
	elseif (self.current_state == SrtReader.READING_CONTENT) then
		self:process_content(line)
	end

	self.current_line_number = self.current_line_number + 1
	return error_message
end

-- Processes a file line looking for a subtitle number.
function SrtReader:process_number(line)
	if (is_blank(line)) then return end

	local error_message = self:read_number(line)
	self.current_state = SrtReader.READING_INTERVAL

	return error_message
end

-- Processes a file line looking for a subtitle appearance interval.
function SrtReader:process_interval(line)
	if (is_blank(line)) then return end

	local error_message = self:read_interval(line)
	self.current_state = SrtReader.READING_CONTENT

	return error_message
end

-- Processes a file line looking for subtitle content.
function SrtReader:process_content(line)
	if (is_blank(line)) then
		if (self.current_subtitle_line.start:is_in_video_bounds(self.video_length_microseconds)) then
			-- Save the subtitle line only if the start timestamp is within the video bounds
			self.subtitle_lines[self.current_index] = self.current_subtitle_line
			self.current_index = self.current_index + 1
		end
		self.current_state = SrtReader.READING_NUMBER
		self.current_subtitle_line = SubtitleLine.new()
		self.current_subtitle_line.encoding = self.encoding
		return
	end
	self:read_content(line)
end

-- Reads the line containing the number of the current subtitle.
-- Checks if the number is expected.
function SrtReader:read_number(line)
	local number = line:match("^%s*(%d+)%s*$")
	if (not number) then
		return "Malformed subtitle number on line " .. self.current_line_number .. ". Please try another encoding in 'Subtitles file and settings'"
	end

	local number_as_number = tonumber(number)
	if (number_as_number ~= self.current_number) then
		return "Out of place subtitle found on line " .. self.current_line_number .. "."
	end

	self.current_number = self.current_number + 1
end

-- Reads the line containing the interval appearance time of the current subtitle.
-- Sets the state in the current subtitle line under construction.
function SrtReader:read_interval(line)
	local start_text, finish_text = line:match("^%s*(%d+:%d+:%d+,%d+)%s*-->%s*(%d+:%d+:%d+,%d+)%s*$")
	if (not start_text or not finish_text) then
		return "Malformed subtitle number on line " .. self.current_line_number .. ". Please try another encoding in 'Subtitles file and settings'"
	end
	local start = Timestamp.of_text(start_text):add_microseconds(self.subtitle_delay) -- - self.user_delay_before)
	local finish = Timestamp.of_text(finish_text):add_microseconds(self.subtitle_delay) -- + self.user_delay_after)
	self.current_subtitle_line:set_start(start)
	self.current_subtitle_line:set_finish(finish)
end

-- Reads the line containing the current subtitle text content.
function SrtReader:read_content(line)
	self.current_subtitle_line:append_content(line)
end


-- Class: SubtitleLine.
-- Class representing a subtitle line with its content and appearance timestamp interval.
SubtitleLine = {}
SubtitleLine.__index = SubtitleLine

-- Constructor method. Creates an empty subtitle line to be filled.
function SubtitleLine.new()
	local self = setmetatable({}, SubtitleLine)
	self.start = nil
	self.finish = nil
	self.encoding = nil
	self.content = ""
	self.hidden = ""
	self.hidden_table = {}
	return self
end

-- Sets the start timestamp of the appearance interval.
function SubtitleLine:set_start(start)
	self.start = start
	
end

-- Sets the finish timestamp of the appearance interval.
function SubtitleLine:set_finish(finish)
	self.finish = finish
end

-- Appends content to the subtitle line.
function SubtitleLine:append_content(content)
	self.content = self.content .. decode(content,self.encoding)
	self.hidden_table={}
	for word in self.content:gmatch(readable_char) do
		table.insert(self.hidden_table,1)
	end
	
	self:update_hidden()
end

-- Updates the hidden table of a subtitle line(0 for show, 1 for hide) according to input.
-- Compares word to word and set to 0 the hidden_table index of guessed words
-- Then updates the hidden content of the current_subtitle_line
-- Then reveals content
function SubtitleLine:update_hidden_table(input)
	local index
	for word_input in input:gmatch(readable_char) do
		index = 0
		for word_corre in self.content:gmatch(readable_char) do
			index = index+1
			if word_input:lower()==word_corre:lower() then
				self.hidden_table[index]=0
			--print(word_input:lower() .. " == " .. word_corre:lower() .. " ==> true")
			else
			--print(word_input:lower() .. " == " .. word_corre:lower() .. " ==> false")
			end	
		end
	end
	local gonext
	gonext=self:update_hidden()
	self:reveal()
	return gonext
end

-- Finds and shows the words that are marked as found
-- When all words are found, gonext is return to 1
function SubtitleLine:update_hidden()
	self.hidden = self.content
	local gonext=1
	local index=0
	for word in self.content:gmatch(readable_char) do
		index=index+1
		if self.hidden_table[index]==1 then
			self:hide_word(word)
			gonext=0
		end
	end
	return gonext
end

-- Sets all hidden table value to 0 (Help function)
function SubtitleLine:reveal_all()
	for k, v in ipairs(current_subtitle_line.hidden_table) do
		current_subtitle_line.hidden_table[k]=0
	end
	self:update_hidden()
	self:reveal()	
end

-- Injects hidden in the correction field
function SubtitleLine:reveal()
	gui:inject_subtitle_words(self.hidden)
end

-- Hides a word in a hidden subtitle line
function SubtitleLine:hide_word(word)
	local pattern={{word_recogn_char .. "(" .. word .. ")" .. word_recogn_char,"%1" .. hide_string(word) .. "%3"},{"^(" .. word .. ")" .. word_recogn_char, hide_string(word) .. "%2"},{word_recogn_char .. "(" .. word .. ")$","%1" .. hide_string(word)}}
	for i = 1, 3 do
		if string.find(self.hidden,pattern[i][1]) then
			self.hidden = string.gsub(self.hidden,pattern[i][1], pattern[i][2])
		end
	end
end

-- Gets the start timestamp of the appearance interval.
function SubtitleLine:get_start()
	return self.start
end

-- Gets the finish timestamp of the appearance interval.
function SubtitleLine:get_finish()
	return self.finish
end

-- Gets the content of the subtitle line.
function SubtitleLine:get_content()
	return self.content
end

-- Gets the hidden version of a sub line
function SubtitleLine:get_hidden()
	return self.hidden
end

-- Checks whether a timestamp is contained in the subtitle appearance interval (both inclusive).
function SubtitleLine:is_in_interval(timestamp)
	return (timestamp:compare_to(self.start) >= 0) and (timestamp:compare_to(self.finish) <= 0)
end

-- Class: Timestamp.
-- Class representing a player timestamp.
-- Identical to Subtitle Word Search addon
Timestamp = {}
Timestamp.__index = Timestamp

-- Constructor method. Creates an empty timestamp instance.
function Timestamp.new()
	local self = setmetatable({}, Timestamp)
	self.text = nil
	self.milliseconds = nil
	self.microseconds = nil
	return self
end

-- Factory method. Creates a new timestamp from text in <hh:mm:ss,fff format>.
-- Computes the equivalent microseconds.
function Timestamp.of_text(text)
	local instance = Timestamp.new()
	instance.text = text

	local hours, minutes, seconds, millis = text:match("(%d+):(%d+):(%d+),(%d+)")
	instance.milliseconds = (tonumber(hours) * 3600 + tonumber(minutes) * 60 + tonumber(seconds) + tonumber(millis) / 1000) * 1000
	instance.microseconds = (tonumber(hours) * 3600 + tonumber(minutes) * 60 + tonumber(seconds) + tonumber(millis) / 1000) * 1000000
	return instance
end

-- Factory method. Creates a new timestamp from microseconds.
-- Computes the text representation in <hh:mm:ss,fff> format.
function Timestamp.of_microseconds(total_microseconds)
	local instance = Timestamp.new()
	instance.microseconds = total_microseconds

	local milliseconds = math.floor((total_microseconds % 1000000) / 1000)
	local hours = math.floor(total_microseconds / 3600000000)
	local minutes = math.floor((total_microseconds % 3600000000) / 60000000)
	local seconds = math.floor((total_microseconds % 60000000) / 1000000)

	instance.text = string.format("%02d:%02d:%02d,%03d", hours, minutes, seconds, milliseconds)

	return instance
end

-- Factory method. Creates a new timestamp from the playing time of the video.
function Timestamp.now()
	local playing_time_microseconds = vlc.var.get(vlc.object.input(), "time")
	return Timestamp.of_microseconds(playing_time_microseconds)
end

-- Gets a representation of the timestamp in <hh:mm:ss> format.
function Timestamp:to_string()
	return self.text:sub(1, -5)
end

-- Gets a representation of the timestamp in microseconds.
function Timestamp:to_microseconds()
	return self.microseconds
end

-- Adds a number of microseconds to a timestamp. Returns a new instance.
function Timestamp:add_microseconds(microseconds)
	local result_microseconds = self.microseconds + microseconds
	return Timestamp.of_microseconds(result_microseconds)
end

-- Compares this timestamp to the given timestamp.
function Timestamp:compare_to(t)
	if (self.microseconds < t.microseconds) then
		return -1
	elseif (self.microseconds > t.microseconds) then
		return 1
	else
		return 0
	end
end

-- Checks whether a timestamp is within the bounds of the video length or not.
function Timestamp:is_in_video_bounds(video_length_microseconds)
	return ((self.microseconds >= 0) and (self.microseconds <= video_length_microseconds))
end

---------- Utility functions ----------

-- Builds the runseq string to be put in bookmark10
function Serialize(t)
	if type(t)=="table" then
		local s='{'
		for k,v in pairs(t) do
			if type(k)~='number' then k='"'..k..'"' end
			s = s..'['..k..']='..Serialize(v)..',' -- recursion
		end
		return s..'}'
	elseif type(t)=="string" then
		return string.format("%q", t)
	else
		return tostring(t)
	end
end

-- Transforms the list of intf into a table
function split_string(s, d)
	local t={}
	local i=1
	local ss, j, k
	local b=true
	while b do
		j,k = string.find(s,d,i)
		if j then
			ss=string.sub(s,i,j-1)
			i=k+1
		else
			ss=string.sub(s,i)
			b=false
		end
		table.insert(t, ss)
	end
	return t
end

-- Returns a hidden "underscored" string of the same size as the argument
function hide_string(string)
	output, _ = string.gsub(string,".","_")
	return output
end

-- Checks if a string is a blank string (empty or only blanks).
function is_blank(s)
	if (s:find("^%s*$")) then
		return true
	end

	return false
end

-- Converts or keeps to UTF-8
-- Should work for all ISO_8859-1 characters existing in UTF-8
function decode(line,local_encoding)
	local output_string=""
	local error=0
	if (local_encoding=="ISO_8859-1" or local_encoding=="ISO_8859-1-SIG") and (line) then
		for letter in line:gmatch("(.)") do
			if string.byte(letter)>255 then
				output_string = output_string .. letter --no conversion supported
			elseif string.byte(letter)>127 and string.byte(letter)< 256 then
				local equivalent_byteuni={byteuni_from_byteiso(string.byte(letter))}
				if (string.char(equivalent_byteuni[1],equivalent_byteuni[2])) then
					output_string=output_string .. string.char(equivalent_byteuni[1],equivalent_byteuni[2])
				else
					output_string = output_string .. letter --no conversion supported
				end
			elseif (string.byte(letter,1)) then
				output_string = output_string .. letter --no conversion needed
			end
		end
	elseif (line) then
		output_string = line
	end	
	return output_string
end

--Removes the 3 first bytes of the first line of UTF-8/ISO_8859-1 signed file
function remove_charset_signature(line,local_encoding,line_index_srt)
	if local_encoding=="UTF-8-SIG" or local_encoding=="ISO_8859-1-SIG" then
		if line_index_srt==1 then
			string=string.sub(line,4,string.len(line))
		else
			string = line
		end
	else
		string = line
	end
	return string
end

-- Check if the current operating system is Unix-like.
function is_unix_os()
	if (vlc.config.homedir():find("^/")) then
		return true
	else
		return false
	end
end

-- Get the list of filenames inside a given directory.
function list_directory(directory)
	local filenames = {}

	local listing_command
	if (is_unix_os()) then
		listing_command = 'ls -p "' .. directory .. '" | grep -v /'
	else
		listing_command = 'dir "' .. directory .. '" /b /a-d'
	end

	local pfile = io.popen(listing_command, "r")
	if (pfile) then
		for filename in pfile:lines() do
			filenames[#filenames + 1] = filename
		end
		pfile:close()
	else
		filenames = nil
	end

	return filenames
end

-- Get the playing video directory and filename.
function get_video_file_location()
	local is_movie_opened=vlc.input.item()
	if (not is_movie_opened) then
		return	
	else
		local decoded_media_uri = vlc.strings.decode_uri(vlc.input.item():uri())
		local directory_path, filename = decoded_media_uri:match("^file:///(.+/)(.+%..+)$")
		return directory_path, filename
	end
end

-- Converts the ISO_8859-1 bytes between 128 and 255 to the equivalent bytes (same character in UTF-8)
function byteuni_from_byteiso(n)
	local table = {{128, 194, 128},{129, 194, 129},{130, 194, 130},{131, 194, 131},{132, 194, 132},
	{133, 194, 133},{134, 194, 134},{135, 194, 135},{136, 194, 136},{137, 194, 137},
	{138, 194, 138},{139, 194, 139},{140, 194, 140},{141, 194, 141},{142, 194, 142},
	{143, 194, 143},{144, 194, 144},{145, 194, 145},{146, 194, 146},{147, 194, 147},
	{148, 194, 148},{149, 194, 149},{150, 194, 150},{151, 194, 151},{152, 194, 152},
	{153, 194, 153},{154, 194, 154},{155, 194, 155},{156, 194, 156},{157, 194, 157},
	{158, 194, 158},{159, 194, 159},{160, 194, 160},{161, 194, 161},{162, 194, 162},
	{163, 194, 163},{164, 194, 164},{165, 194, 165},{166, 194, 166},{167, 194, 167},
	{168, 194, 168},{169, 194, 169},{170, 194, 170},{171, 194, 171},{172, 194, 172},
	{173, 194, 173},{174, 194, 174},{175, 194, 175},{176, 194, 176},{177, 194, 177},
	{178, 194, 178},{179, 194, 179},{180, 194, 180},{181, 194, 181},{182, 194, 182},
	{183, 194, 183},{184, 194, 184},{185, 194, 185},{186, 194, 186},{187, 194, 187},
	{188, 194, 188},{189, 194, 189},{190, 194, 190},{191, 194, 191},{192, 195, 128},
	{193, 195, 129},{194, 195, 130},{195, 195, 131},{196, 195, 132},{197, 195, 133},
	{198, 195, 134},{199, 195, 135},{200, 195, 136},{201, 195, 137},{202, 195, 138},
	{203, 195, 139},{204, 195, 140},{205, 195, 141},{206, 195, 142},{207, 195, 143},
	{208, 195, 144},{209, 195, 145},{210, 195, 146},{211, 195, 147},{212, 195, 148},
	{213, 195, 149},{214, 195, 150},{215, 195, 151},{216, 195, 152},{217, 195, 153},
	{218, 195, 154},{219, 195, 155},{220, 195, 156},{221, 195, 157},{222, 195, 158},
	{223, 195, 159},{224, 195, 160},{225, 195, 161},{226, 195, 162},{227, 195, 163},
	{228, 195, 164},{229, 195, 165},{230, 195, 166},{231, 195, 167},{232, 195, 168},
	{233, 195, 169},{234, 195, 170},{235, 195, 171},{236, 195, 172},{237, 195, 173},
	{238, 195, 174},{239, 195, 175},{240, 195, 176},{241, 195, 177},{242, 195, 178},
	{243, 195, 179},{244, 195, 180},{245, 195, 181},{246, 195, 182},{247, 195, 183},
	{248, 195, 184},{249, 195, 185},{250, 195, 186},{251, 195, 187},{252, 195, 188},
	{253, 195, 189},{254, 195, 190},{255, 195, 191}}
	
	return table[n-127][2], table[n-127][3]
end
