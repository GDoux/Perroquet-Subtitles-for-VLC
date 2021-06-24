--[[
Program: Perroquet Subtitles for VLC
Purpose: Train your listening comprehension by rewriting your favorite movies' subs (with correction)
Author: Gaspard DOUXCHAMPS
License: GNU GENERAL PUBLIC LICENSE
Release-Date: 20/06/2021
Credits: to Fred Bertolus and the Perroquet Team for the original software (https://launchpad.net/perroquet) and to Tomás Crespo for the "Subtitle Word Search" add-on (https://addons.videolan.org/p/1154033/)
]]

config = {}
local cfg = {}

function descriptor()
	return {
		title = "Perroquet Subtitles for VLC",
		version = "1.1",
		author = "Gaspard DOUXCHAMPS",
		--url = "https://github.com/tcrespog/vlc-subtitle-word-search",
		shortdesc = "Perroquet1.1 Subtitles for VLC",
		description = "Train your listening comprehension by rewriting your favorite movies' subs (with correction)",
		capabilities = {}
	}
end

---------- VLC entrypoints ----------

function activate()
	os.setlocale("C", "all") -- just in case
	Get_config()
	if (config) and (config.TIME) then
		cfg = config.TIME
		cfg.start=false
	else
		vlc.msg.err("config not loaded")
	end
	local VLC_extraintf, VLC_luaintf, t, ti = VLC_intf_settings()
	if not ti or VLC_luaintf~="perroquet_intf" then 
		trigger_menu(2) 
	else 
		trigger_menu(1) 
	end
end

function close()
	vlc.deactivate();
end

----------Menu---------------

function trigger_menu(id)
	if self then
		if self.dialog then
			self.dialog:delete() 
		end
	end
	if id==1 then -- Control panel
		initialize_gui()
		initialize_encodings()
		initialize_subtitle_files()
		load_subtitle_file()
	elseif id==2 then -- Settings
		self = Gui:new()
		self.dialog = vlc.dialog("Perroquet for VLC")		
		enable_extraintf = self.dialog:add_check_box("Enable interface: ", true,1,1,1,1)
		ti_luaintf = self.dialog:add_text_input("perroquet_intf",2,1,2,1)
		self.dialog:add_button("SAVE!", click_SAVE_settings,1,2,1,1)
		self.dialog:add_button("CANCEL", click_CANCEL_settings,2,2,1,1)
		--	lb_message = dlg:add_label("CLI options: --extraintf=luaintf --lua-intf="..intf_script,1,3,3,1)
		local VLC_extraintf, VLC_luaintf, t, ti = VLC_intf_settings()
		lb_message = self.dialog:add_label("Current status: " .. (ti and "ENABLED" or "DISABLED") .. " " .. tostring(VLC_luaintf),1,3,3,1)	
	end
end

-----------INTF activation----------------
function click_SAVE_settings()
	local VLC_extraintf, VLC_luaintf, t, ti = VLC_intf_settings()

	if enable_extraintf:get_checked() then
		--vlc.config.set("extraintf", "luaintf")
		if not ti then table.insert(t, "luaintf") end
		vlc.config.set("lua-intf", ti_luaintf:get_text())
	else
		--vlc.config.set("extraintf", "")
		if ti then table.remove(t, ti) end
	end
	vlc.config.set("extraintf", table.concat(t, ":"))
	lb_message:set_text("Please restart VLC for changes to take effect!")
end

function click_CANCEL_settings()
	trigger_menu(1)
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

config={}

--readable_char="([%wçã]+)"
readable_char="([%wçÀ-ÿæœÆŒß]+)"
word_recogn_char= "([^%w^ç^À-ÿ^æ^œ^Æ^Œ^ß]+)"

function initialize_gui()
	gui = Gui.new()
	gui:render()
end

-- Generates the list of enconding/decoding capabilities
function initialize_encodings() 
	if (is_unix_os()) then
		encodings = {"UTF-8", "UTF-8-SIG", "UTF-16", "ISO_8859-1", "ISO_639-1"}
	else
		encodings = {"UTF-8", "UTF-8-SIG"}
	end
	gui:inject_encodings(encodings)
end

-- Look for the candidate perroquet files and adds them to the GUI dropdown.
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

-- Load a perroquet file.
-- Then shows the subtitle hidden words corresponding to the current time, or to the closest next sequence, or displays an error message if something went wrong.
function load_subtitle_file()
	if (current_subtitle_file) then
		current_subtitle_file:clear()
		gui:print_error_message("")
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

-- Show the hidden words appearing at the current timestamp, or at the closest next sequence.
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

-- Show the words corresponding to the current subtitle.
function navigate_still()
	navigate(0)
end

-- Show the words corresponding to the subtitle that goes before the current one.
function navigate_backward()
	navigate(-1)
end

-- Show the words corresponding to the subtitle that goes after the current one.
function navigate_forward()
	navigate(1)
end

-- Show the words corresponding to the subtitle shifted `n` lines.
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

-- Show the hidden words of a subtitle along with the associated timestamp in the corresponding list widget.
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
	--input_string=decode(gui.input_subs:get_text(),"UTF-8",2)
	gonext=current_subtitle_line:update_hidden_table(input_string)
	gui:update()
	if gonext==1 then
		navigate_forward_and_play()
	end
end

-- Replays the current sequence and play the next sequence. Displays hidden words of next sequence
function navigate_forward_and_play()
	local old_start = current_subtitle_line:get_start():to_microseconds()
	navigate(1)
	run(old_start - gui.delay_before:get_text()*1000, current_subtitle_line.finish.microseconds + gui.delay_after:get_text()*1000)
end

-- Replays the current sequence
function go_to_subtitle_timestamp()
	if (not current_subtitle_file) then
		return
	end
	navigate(0)
	run(current_subtitle_line:get_start():to_microseconds() - gui.delay_before:get_text()*1000,current_subtitle_line.finish.microseconds + gui.delay_after:get_text()*1000)
end

-- Runs a video sequence between two times. Can be improved with a "wait" instead of a "freeze"
--[[function run(begin_time, finish_time)
	vlc.var.set(vlc.object.input(), "time", begin_time)
	vlc.playlist.play()
	repeat
		t=vlc.var.get(vlc.object.input(), "time") --sleep while running
	until (finish_time < t)
	vlc.playlist.pause()
end]]

function run(begin_time, finish_time)
	cfg.start = true
	cfg.begin_time = begin_time
	cfg.finish_time=finish_time
	vlc.var.set(vlc.object.input(), "time", begin_time)
	vlc.playlist.play()
	Set_config(cfg, "TIME")
--	dlg:set_title(descriptor().title)
end

function help()
	current_subtitle_line:reveal_all()
end

function Get_config()
	local s = vlc.config.get("bookmark10")
	if not s or not string.match(s, "^config={.*}$") then 
		s = "config={}"
		vlc.msg.err(s)
	else
		vlc.msg.err("temoin") 
	end
	assert(loadstring(s))() -- global var
end

function Set_config(cfg_table, cfg_title)
	if not cfg_table then cfg_table={} end
	if not cfg_title then cfg_title=descriptor().title end
	Get_config()
	config[cfg_title]=cfg_table
	vlc.config.set("bookmark10", "config="..Serialize(config))
end

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
	else --if type(t)=="boolean" or type(t)=="number" then
		return tostring(t)
	end
end

---------- Classes ----------

-- Class: Gui.
-- Renders the GUI (Graphical User Interface).
Gui = {}
Gui.__index = Gui

-- Constructor method. Create the GUI instance.
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

-- Render the VLC extension grid dialog.
function Gui:render()
	self.dialog = vlc.dialog("Perroquet for VLC")
	self:draw_file_section()
	self:draw_input_section()
	self:draw_correction_section()
	self:draw_button_section()
	self.dialog:show()
end

-- Increment the index of the last row in the GUI and returns the value previous to the increment.
-- Equivalent to the typical construct `n++` of other programming languages.
-- @return {number} The last row number value previous to the increment.
function Gui:increment_row()
	local previous_last_row = self.last_row
	self.last_row = self.last_row + 1
	return previous_last_row
end

-- Draw the perroquet files selector section. The order matters to ease the use of tab, arrows and enter key
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

-- Draw the input section
function Gui:draw_input_section()
	self.dialog:add_label("<h4>Input</h4>", 1, self:increment_row())
	self.input_subs = self.dialog:add_text_input("Write here what you understand here and click on Try!",1,self.last_row,4)
	self.dialog:add_button("Try!", user_input_subs, 5, self:increment_row())
end

-- Draw the correction field
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

--Build the encoding dropdown widget
function Gui:inject_encodings(encodings)
	for index, encoding in ipairs(encodings) do
		gui:inject_encoding(encoding, index)
	end
end

--Add an encoding to the corresponding dropdown widget
function Gui:inject_encoding(encoding, index)
	self.encodings_dropdown:add_value(encoding,index)
end

--Build the perroquet files dropdown widget
function Gui:inject_subtitle_files(subtitle_files)
	for index, subtitle_file in ipairs(subtitle_files) do
		gui:inject_subtitle_file(subtitle_file:get_name(), index)
	end
end

-- Add a perroquet file name to the corresponding dropdown widget.
-- @param name {string} The subtitle file name.
-- @param index {number} The search engine index in the global array of subtitle files.
function Gui:inject_subtitle_file(name, index)
	self.files_dropdown:add_value(name, index)
end

-- Show the content of the correction field (hidden words)
function Gui:inject_subtitle_words(text)
	self.correction:set_text("<h2><font color=DarkRed><center>" .. text .. "</center></font></h2>")
end


function Gui:get_selected_encoding_index()
	return self.encodings_dropdown:get_value()
end

-- Get the index of the selected subtitle file in the corresponding dropdown widget.
-- @return {number} The index of the selected file.
function Gui:get_selected_subtitle_file_index()
	return self.files_dropdown:get_value()
end

-- Print a timestamp in the specific label.
-- @param timestamp {Timestamp} The timestamp to print.
function Gui:print_timestamp(timestamp_start,timestamp_finish)
   self.timestamp_label:set_text(timestamp_start:to_string() .. " to " ..  timestamp_finish:to_string())
end

function Gui:print_error_message(error_message)
	self.correction:set_text("<h3><font color=red><center>" .. error_message .. "</center></font></h3>")
--	self:print_html(html_error_message)
end

-- Update the GUI. Useful to render partial updates before a method returns.
function Gui:update()
	self.dialog:update()
end

-- Class: SubtitleFileDiscoverer.
-- Discovers the candidate subtitle files in the filesystem.
SubtitleFileDiscoverer = {}
SubtitleFileDiscoverer.__index = SubtitleFileDiscoverer

-- Constructor method. Create a subtitle file discoverer.
-- @param extension {string} The extension of the file to discover. Ex. "srt".
-- @return {SubtitleFileDiscoverer} The subtitle discoverer instance.
function SubtitleFileDiscoverer.new(extension)
	local self = setmetatable({}, SubtitleFileDiscoverer)
	-- extension {string} The file extension to discover
	self.extension = extension
	return self
end

-- Get the file system's paths to the found subtitles of the playing video
-- @return {array<SubtitleFile>} The array of discovered files.
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

-- Get an array of filenames that have the same name as the given filename but differ in extension.
-- @param target_filename {string} The filename to match (without the extension). Ex. "video".
-- @param filename_listing {array<string>} The array of filenames to compare.
-- @param extension {string} The extension to match. Ex. ".srt".
-- @return {array<string>} The array of matching filenames. Ex. { "video.srt", "video.eng.srt", ... }.
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

-- Constructor method. Create a subtitle file.
-- @param path {string} The absolute path of the file.
-- @param name {string} The name of the file.
-- @return {SubtitleFile} The subtitle file instance.
function SubtitleFile.new(path, name)
	local self = setmetatable({}, SubtitleFile)
	-- path {string} The path of the subtitle file.
	self.path = path
	-- name {string} The name of the subtitle file.
	self.name = name
	-- subtitle_lines {array<SubtitleLine>} The subtitle lines in the file.
	self.subtitle_lines = nil
	-- current_line_index {number} The index of the current subtitle.
	self.current_line_index = nil
	return self
end

-- Set the subtitle lines read from the file.
-- @param {array<SubtitleLine>} The array of subtitle lines in order of appearance.
function SubtitleFile:set_subtitle_lines(subtitle_lines)
	self.subtitle_lines = subtitle_lines
end

-- Get the name of the subtitle file.
-- @return {string} The name of the subtitle file.
function SubtitleFile:get_name()
	return self.name
end

-- Get the path of the subtitle file.
-- @return {string} The path of the subtitle file.
function SubtitleFile:get_path()
	return self.path
end

-- Search the subtitle line at the given timestamp.
-- Performs a binary search over the ordered subtitle lines.
-- Updates the value of the current line index, which would point to an index with fractional part if nothing was found.
-- @param {Timestamp} The timestamp to search the subtitle at.
-- @return {SubtitleLine} The found line, `nil` if no line was found for the timestamp.
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

function SubtitleFile:pick_closest_line(timestamp)
	local deltaT=1000000
	local shift_timestamp = Timestamp.of_microseconds(timestamp:to_microseconds() + deltaT)
	repeat 
	found_line = self:search_line_at(shift_timestamp)
	shift_timestamp = Timestamp.of_microseconds(shift_timestamp:to_microseconds() + deltaT)
	until self:is_valid_line_index()
return found_line
end

-- Set an index with fractional part, indicating the place near two consecutive indices where a value not found should be.
-- @param lower_bound {number} The lower bound index of the value proximity.
-- @param upper_bound {number} The upper bound index of the value proximity.
-- @param timestamp {Timestamp} The not found value timestamp.
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

-- Check if the current index is pointing to an actual subtitle, or rather to a middle ground.
-- @return {boolean} `true` if the current line index points to a valid line, `false` otherwise.
function SubtitleFile:is_valid_line_index()
	return (self.current_line_index == math.floor(self.current_line_index))
end

-- Get the subtitle line shifting `n` lines from the current line.
-- The lines to shift must be between -1, 0 and +1. A value of 0 returns the current line, or `nil` if not pointing to a valid line.
-- @param n {number} The number of lines to shift.
-- @return The shifted line, `nil` if the shift exceeds the array bounds or doesn't point to anything.
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

-- Clear the subtitle lines of the file.
-- Note the current line index is not cleared.
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
-- @param filepath {string} The path of the file to read.
-- @param subtitle_delay {number} The subtitle delay in microseconds. Can be negative.
-- @return {SrtReader} The SRT reader instance.
function SrtReader.new(filepath, subtitle_delay, video_length_microseconds,encoding)
	local self = setmetatable({}, SrtReader)
	-- filepath {string} The path of the file to read.
	self.filepath = filepath
	-- subtitle_delay {number} The subtitle delay in microseconds.
	self.subtitle_delay = subtitle_delay
	-- video_length_microseconds {number} The length of the video in microseconds.
	self.video_length_microseconds = video_length_microseconds
	-- enconding {string}, the encoding selected by user when loading
	self.encoding = encoding
	-- current_line_number {number} The line number of the text file being read.
	self.current_line_number = 1
	-- subtitle_lines {array<SubtitleLine>} The subtitle lines in the file.
	self.subtitle_lines = {}
	-- current_index {number} The index corresponding to the current subtitle line being read.
	self.current_index = 1
	-- current_number {number} The number of the subtitle line being read.
	self.current_number = 1
	-- current_subtitle_line {SubtitleLine} The subtitle line being constructed.
	self.current_subtitle_line = nil
	-- state {number} The current state in the reader's state machine
	self.current_state = SrtReader.READING_NUMBER
	return self
end

-- Read the file according to encoding and extracts all subtitle lines. 
-- @return {array<SubtitleLine>} The resulting subtitle lines.
-- @return {string} An error message if some I/O error or processing occurs, nil if everything goes well
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
		--[[if encoding=="UTF-8" then
		elseif encoding=="UTF-8-SIG" then
			if index==1 then
				line=string.sub(line,4,string.len(line))
			end
		else
			line = vlc.strings.from_charset(encoding,line)
		end]]
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

-- Process a file line depending on the state machine status.
-- @param line {string} The file line to read.
-- @return {string} An error message if something goes wrong, `nil` if everything goes well
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

-- Process a file line looking for a subtitle number.
-- @param line {string} The file line to read.
-- @return {string} An error message if something goes wrong, `nil` if everything goes well.
function SrtReader:process_number(line)
	if (is_blank(line)) then return end

	local error_message = self:read_number(line)
	self.current_state = SrtReader.READING_INTERVAL

	return error_message
end

-- Process a file line looking for a subtitle appearance interval.
-- @param line {string} The file line to read.
-- @return {string} An error message if something goes wrong, `nil` if everything goes well.
function SrtReader:process_interval(line)
	if (is_blank(line)) then return end

	local error_message = self:read_interval(line)
	self.current_state = SrtReader.READING_CONTENT

	return error_message
end

-- Process a file line looking for subtitle content.
-- @param line {string} The file line to read.
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

-- Read the line containing the number of the current subtitle.
-- Checks if the number is expected.
-- @param line {string} The file line to read.
-- @return {string} The error message if something goes wrong, `nil` if everything goes well
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

-- Read the line containing the interval appearance time of the current subtitle.
-- Set the state in the current subtitle line under construction.
-- @param line {string} The file line to read.
-- @return {string} The error message if something goes wrong, `nil` if everything goes well
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

-- Read the line containing the current subtitle text content.
-- Appends the content to the overall subtitle under construction.
-- @param line {string} The file line to read.
function SrtReader:read_content(line)
	self.current_subtitle_line:append_content(line)
end


-- Class: SubtitleLine.
-- Class representing a subtitle line with its content and appearance timestamp interval.
SubtitleLine = {}
SubtitleLine.__index = SubtitleLine

-- Constructor method. Create an empty subtitle line to be filled.
-- @return {SubtitleLine} The subtitle line instance.
function SubtitleLine.new()
	local self = setmetatable({}, SubtitleLine)
	-- start {Timestamp} The start timestamp of the appearance interval.
	self.start = nil
	-- finish {Timestamp} The finish timestamp of the appearance interval.
	self.finish = nil
	self.encoding = nil
	-- content {string} The text content of the subtitle.
	self.content = ""
	self.hidden = ""
	self.hidden_table = {}
	return self
end

-- Set the start timestamp of the appearance interval.
-- @param start {Timestamp} The start timestamp of the appearance interval.
function SubtitleLine:set_start(start)
	self.start = start
	
end

-- Set the finish timestamp of the appearance interval.
-- @param finish {Timestamp} The finish timestamp of the appearance interval.
function SubtitleLine:set_finish(finish)
	self.finish = finish
end

-- Append content to the subtitle line.
-- @param content {string} The text content to append.
function SubtitleLine:append_content(content)
	self.content = self.content .. decode(content,self.encoding)
	
	local append = string.gsub(content,"[^%p%s]","_")
	self.hidden = self.hidden .. append

	self.hidden_table={}
	for word in self.content:gmatch(readable_char) do
		table.insert(self.hidden_table,1)
	end
end

-- Update the hidden table of a subtitle line(0 for show, 1 for hide) according to input.
-- Compare word to word and set to 0 the  hidden_table index of guessed words
-- Then reveal content
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

function SubtitleLine:update_hidden()
	--print(self.content)
	self.hidden = self.content
	local gonext=1
	local index=0
--[[	for word in self.content:gmatch(readable_words) do
		local pattern={{"(%W+)(" .. word .. ")(%W+)","%1" .. blank(word) .. "%3"},{"^(" .. word .. ")(%W+)", blank(word) .. "%2"},{"(%W+)(" .. word .. ")$","%1" .. blank(word)}}]]
	for word in self.content:gmatch(readable_char) do
		local pattern={{word_recogn_char .. "(" .. word .. ")" .. word_recogn_char,"%1" .. blank(word) .. "%3"},{"^(" .. word .. ")" .. word_recogn_char, blank(word) .. "%2"},{word_recogn_char .. "(" .. word .. ")$","%1" .. blank(word)}}
		index=index+1
		if self.hidden_table[index]==1 then
			for i = 1, 3 do
    				if string.find(self.hidden,pattern[i][1]) then
					self.hidden = string.gsub(self.hidden,pattern[i][1], pattern[i][2])
					gonext=0
				end
			end
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

-- Rebuilds hidden subs according to hidden table, then inject results in the correction field
-- when all words are guessed, returns the gonext parameters that triggers the navigate_forward_and_play() function when at 1
function SubtitleLine:reveal()
	gui:inject_subtitle_words(self.hidden)
end

-- Get the start timestamp of the appearance interval.
-- @return {Timestamp} The start timestamp of the appearance interval.
function SubtitleLine:get_start()
	return self.start
end

-- Get the finish timestamp of the appearance interval.
function SubtitleLine:get_finish()
	return self.finish
end

-- Get the content of the subtitle line.
-- @return {string} The content of the subtitle.
function SubtitleLine:get_content()
	return self.content
end

-- Get the hidden version of a sub line
function SubtitleLine:get_hidden()
	return self.hidden
end

-- Check whether a timestamp is contained in the subtitle appearance interval (both inclusive).
-- @param timestamp {Timestamp} The timestamp to check.
-- @return {boolean} True if the timestamp is in the interval, false otherwise.
function SubtitleLine:is_in_interval(timestamp)
	return (timestamp:compare_to(self.start) >= 0) and (timestamp:compare_to(self.finish) <= 0)
end

-- Class: Timestamp.
-- Class representing a player timestamp.
-- Identical to Subtitle Word Search addon
Timestamp = {}
Timestamp.__index = Timestamp

-- Constructor method. Creates an empty timestamp instance.
-- @return {Timestamp} The timestamp instance.
function Timestamp.new()
	local self = setmetatable({}, Timestamp)
	-- text {string} The timestamp in <hh:mm:ss,fff> format.
	self.text = nil
	-- microseconds {number} The timestamp in microseconds.
	self.milliseconds = nil
	self.microseconds = nil
	return self
end

-- Factory method. Create a new timestamp from text in <hh:mm:ss,fff format>.
-- Computes the equivalent microseconds.
-- @param text {string} The timestamp in <hh:mm:ss,fff> format.
-- @return {Timestamp} The timestamp instance.
function Timestamp.of_text(text)
	local instance = Timestamp.new()
	instance.text = text

	local hours, minutes, seconds, millis = text:match("(%d+):(%d+):(%d+),(%d+)")
	instance.milliseconds = (tonumber(hours) * 3600 + tonumber(minutes) * 60 + tonumber(seconds) + tonumber(millis) / 1000) * 1000
	instance.microseconds = (tonumber(hours) * 3600 + tonumber(minutes) * 60 + tonumber(seconds) + tonumber(millis) / 1000) * 1000000
	return instance
end

-- Factory method. Create a new timestamp from microseconds.
-- Computes the text representation in <hh:mm:ss,fff> format.
-- @param total_microseconds {number} The number of microseconds.
-- @return {Timestamp} The timestamp instance.
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

-- Factory method. Create a new timestamp from the playing time of the video.
-- @return {Timestamp} The timestamp instance.
function Timestamp.now()
	local playing_time_microseconds = vlc.var.get(vlc.object.input(), "time")
	return Timestamp.of_microseconds(playing_time_microseconds)
end

-- Get a representation of the timestamp in <hh:mm:ss> format.
-- @return {string} The timestamp in <hh:mm:ss> format.
function Timestamp:to_string()
	return self.text:sub(1, -5)
end

-- Get a representation of the timestamp in microseconds.
-- @return {number} The timestamp in microseconds.
function Timestamp:to_microseconds()
	return self.microseconds
end

-- Add a number of microseconds to a timestamp. Returns a new instance.
-- @param microseconds {number} The number of microseconds to add; can be negative.
-- @return {Timestamp} The resulting new timestamp instance.

function Timestamp:add_microseconds(microseconds)
	local result_microseconds = self.microseconds + microseconds
	return Timestamp.of_microseconds(result_microseconds)
end

-- Compares this timestamp to the given timestamp.
-- @param t {Timestamp} The timestamp to compare to.
-- @return {number} A negative number if this is lower than `t`, a positive number if this is greater than `t`, zero if both are equal.
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
-- @return {boolean} `true` if is greater than 0 and lower than the video length, `false` otherwise.
function Timestamp:is_in_video_bounds(video_length_microseconds)
	return ((self.microseconds >= 0) and (self.microseconds <= video_length_microseconds))
end

---------- Utility functions ----------

function VLC_intf_settings()
	local VLC_extraintf = vlc.config.get("extraintf") -- enabled VLC interfaces
	local VLC_luaintf = vlc.config.get("lua-intf") -- Lua Interface script name
	local t={}
	local ti=false
	if VLC_extraintf then
		t=split_string(VLC_extraintf, ":")
		for i,v in ipairs(t) do
			if v=="luaintf" then
				ti=i
				break
			end
		end
	end
	return VLC_extraintf, VLC_luaintf, t, ti
end

function split_string(s, d) -- string, delimiter pattern
	local t={}
	local i=1
	local ss, j, k
	local b=false
	while true do
		j,k = string.find(s,d,i)
		if j then
			ss=string.sub(s,i,j-1)
			i=k+1
		else
			ss=string.sub(s,i)
			b=true
		end
		table.insert(t, ss)
		if b then break end
	end
	return t
end

function blank(string)
	output, _ = string.gsub(string,".","_")
	return output
end

-- Check if a string is a blank string (empty or only blanks).
-- @param s {string} The string to check.
-- @return {boolean} `true` if the string is a blank string, `false` otherwise.
function is_blank(s)
	if (s:find("^%s*$")) then
		return true
	end

	return false
end

function decode(line,local_encoding)
	local string
	if (is_unix_os()) and (line) then 	
		string = vlc.strings.from_charset(local_encoding,line)
	elseif (line) then
		string = line
	end
	return string
end

function remove_charset_signature(line,local_encoding,line_index_srt)
	if local_encoding=="UTF-8-SIG" then
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
-- @return {boolean} `true` if the operating system is Unix-like, `false` otherwise.
function is_unix_os()
	if (vlc.config.homedir():find("^/")) then
		return true
	end

	return false
end

-- Get the list of filenames inside a given directory.
-- @param path {string} The directory path separated by slashes. Ex. "directory1/directory2/".
-- @return {array} The array of file names inside the directory, `nil` if the files listing could not be retrieved.
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
-- @return {string} The absolute directory path where the file is located (separated by slashes and without root slash).
-- @return {string} The name of the video file.
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
