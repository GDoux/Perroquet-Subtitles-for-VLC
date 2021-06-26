# Perroquet Subtitles for VLC

Train your listening comprehension by rewriting your favorite movies' subs (with correction)

Pratiquez votre compréhension orale en retranscrivant les sous-titres de vos films favoris (inclut la correction)

- [ENGLISH](#english)
- [FRANÇAIS](#français)
- [MISCELLANEOUS](#miscellaneous)

# ENGLISH

## Description

This Lua extension for VLC enables you to practice your listening comprehension in a foreign language. 

Assuming you have a copy of a movie/video file with a synced subtitle file (.srt) in original language (or at least in the same language as the audio track):

* Perroquet Subtitles for VLC "cuts" the movie in sequences
* In each sequence, you try to understand what is said in the movie and write your guess in the input field
* Perroquet compares what you guessed with the actual subbtitles and tells you when you were right
* You can replay sequences and get help when you are stuck

Improve your listening and writing abilities in many languages and on a very large variety of video and audio tracks!

## Getting Started

### Dependencies & Versions

##### <strong>V1.1
Tested with:
  * VLC 3.0.14 Vetinari for Linux Ubuntu 18.04
  * VLC 3.0.16 Vetinari for Windows</strong>

##### V1.0:
Tested with:
  * VLC 3.0.8 Vetinari for Linux Ubuntu 18.04

### Installing

Copy the <a href=https://github.com/GDoux/Perroquet-Subtitles-for-VLC/blob/main/perroquet.lua> perroquet.lua </a> and <a href=https://github.com/GDoux/Perroquet-Subtitles-for-VLC/blob/main/perroquet_intf.lua> perroquet_intf.lua </a> files to the following folders (depends on your OS) :

* Windows
    * All Users:
          * perroquet.lua in	Program Files\VideoLAN\VLC\lua\extensions\
          * perroquet_intf.lua in	Program Files\VideoLAN\VLC\lua\intf\
    * Current user: [not tested]
          * perroquet.lua in 	%APPDATA%\vlc\lua\extensions\
          * perroquet_intf.lua in	%APPDATA%\vlc\lua\extensions\
* Mac OS X [not tested]
    * All Users:
          * perroquet.lua in	/Applications/VLC.app/Contents/MacOS/share/lua/extensions/
          * perroquet_intf.lua in	/Applications/VLC.app/Contents/MacOS/share/lua/intf/
    * Current user:
          * perroquet.lua in 	/Users/%your_name%/Library/ApplicationSupport/org.videolan.vlc/lua/extensions/
          * perroquet_intf.lua in	/Users/%your_name%/Library/ApplicationSupport/org.videolan.vlc/lua/intf/
* Linux (you may have to `chmod 755` the files)
    * All Users:
          * perroquet.lua in	/usr/lib/vlc/lua/playlist/ or /usr/share/vlc/lua/extensions/
          * perroquet_intf.lua in	/usr/lib/vlc/lua/playlist/ or /usr/share/vlc/lua/intf/
    * Current user: [not tested]
          * perroquet.lua in 	~/.local/share/vlc/lua/extensions/
          * perroquet_intf.lua in	~/.local/share/vlc/lua/intf/
    * Snap: (the number 2288 maybe different on your system)
          * perroquet.lua in 	~/snap/vlc/2288/.local/share/vlc/lua/extensions/
          * perroquet_intf.lua in	~/snap/vlc/2288/.local/share/vlc/lua/intf/
		
Then open VLC and select `Perroquet Subtitles for VLC` in the `view` menu. Click on `SAVE` and restart VLC.

## Executing program

#### Starting up
Assuming you movie file is "MOVIE_FILE.avi" (or .mkv, .mp4, etc.) and that you have a synced subtitles file "SUB_FOR_MOVIE_FILE.srt"
0) Open VLC and select `Perroquet Subtitles for VLC` in the `view` menu. Click on `SAVE` and restart VLC
1) Rename "SUB_FOR_MOVIE_FILE.srt" to "MOVIE_FILE.perroquet" or "MOVIE_FILE[ANY_CHARACTERS].perroquet"
2) Put the newly created "MOVIE_FILE.perroquet" file in the same folder as "MOVIE_FILE.avi"
3) Make sure no .srt file or subs file named like "MOVIE_FILE[ANY_CHARACTERS].srt" and in the same folder as "MOVIE_FILE.avi" (or subs will appear in VLC...)
4) Open "MOVIE_FILE.avi" with VLC
5) In the VLC toolbar, click on View , then on Perroquet Subtitles for VLC
6) A new gui (window) should open

#### Using
Then you should be able to do the following
1) Perroquet file is loaded by default, consult the Help section if you have error or encoding problems
2) Pick a sequence with VLC or `<<` / `>>` buttons and click on `(Re)play`
3) Fill what you understand in the Input field and click on `Try!` button
4) Check in the field under `(Re)play` button what you got and missed. Click on `(Re)play` if you want to hear the sequence again
5) When you correctly write the sequence, VLC replays the sequence one last time and goes to the next sequence
6) If you are stuck, click on `Help!`

*Notes: 
    *files like "MOVIE_FILE[ANY_CHARACTERS].perroquet.srt" are also accepted but you may have to deactivate the sub tracks in VLC interface.
    *you can use the `Tab`, `Shift+Tab` and `Enter` to navigate within the Perroquet Subtitles for VLC window*
 
## Help

### General
* The program supports several encodings for the subtitles (files encoded in ISO-8859-1, UTF-8 and UTF-8-SIG were successfully tested). Please let me know if your sub file is not supported.
* Although subtitle files seldom correspond exactly to the audio track, subs are almost always close enough to the track to still provide a good learning experience. Use the button `Help` when you feel the subs are different from the track.
* Subs for deafened or hard or hearing person are usually very good files to train. They may however enhance non-verbal sounds in the track, usually with "(...)" such as in "(Indistinct chatter)"

### Subtitle files and settings:
* If you have several ".Perroquet" files, select one of them in the drowdown list and click on load
* If you have an error "Malformed subtitle...", try to change the default UTF-8 encoding to "UTF-8-SIG" or "ISO_8859-1-SIG" in the dedicated Dropdown menu. Then click on load.
* If you have unrecognized/weird character such as � or Ã£, try to change the default UTF-8 encoding to "ISO_8859-1" in the dedicated Dropdown menu. Then click on load
* If the sequence are too short or start too late (and you cannot hear the whole sequence), try to
	* change the `Delay before` and `Delay After` (default to 1s) to a larger one
	* manually change the synchronization  with `g` and `h` key in VLC
	* resync your original srt file with a dedicated tool

### Other
If you want to deactivate the Perroquet_intf interface, go to Tools> Preferences and select "All" under `show settings` bullet. Then go to Interface> Main interface> Lua and delete the field `Lua interface`. Save and restart vlc.

### Debugging

The program can be debugged by running VLC in verbose mode. Under linux this means:
```sh
vlc --verbose=2
```
Under windows: open VLC, then `ctrl+M` and change verbosity to 2.

# FRANÇAIS

# MISCELLANEOUS

## Author

Gaspard DOUXCHAMPS

## Version History

* Planned 1.1
    * Test on windows
    * Translate Readme in French
    
* 1.0
    * Initial Release tested on linux

* Main possible improvements:
    * replace "freeze" by "wait" in (Re)play
    * support and test srt file for better compatibility
    * test and run on windows
    * implement color code when "input" is getting close to "correction"
    * translate this readme in other languages

## License

This project is licensed under the GNU GPL v3 License - see the LICENSE.md file for details

## Acknowledgments

Inspiration :
* Perroquet Team and Fred Bertolus for the original software Perroquet (https://launchpad.net/perroquet)

Code snippet :
* The `Perroquet.lua` script was adapted from the "Subtitle Word Search" add-on by Tomás Crespo (https://github.com/tcrespog/vlc-subtitle-word-search/)
* The `Time v3.2` script by Mederi was adapted for the version 1.1 (https://addons.videolan.org/p/1154032/)

Other:
* DomPizzie for the Simple README template (https://gist.github.com/DomPizzie/7a5ff55ffa9081f2de27c315f5018afc)


