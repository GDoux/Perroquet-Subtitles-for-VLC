# Perroquet Subtitles for VLC

Train your listening comprehension by rewriting your favorite movies' subs (with correction)

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

#### V1.0:
Tested with :
  * VLC 3.0.8 Vetinari for Linux Ubuntu 18.04

#### V1.1 [Not released]
Will be tested with :
  * VLC 3.0.8 Vetinari for Linux Ubuntu 18.04

To be tested for Windows

### Installing

Copy the <a href=https://github.com/GDoux/Perroquet-Subtitles-for-VLC/blob/main/perroquet.lua> perroquet.lua </a> file into (depends on your OS) :

* Linux
	* All users: `/usr/lib/vlc/lua/playlist/ or /usr/share/vlc/lua/extensions/`
	* Current user: `~/.local/share/vlc/lua/extensions/`

## Executing program

#### Starting up
Assuming you movie file is "MOVIE_FILE.avi" (or .mkv, .mp4, etc.) and that you have a synced "SUB_FOR_MOVIE_FILE.srt"
1) Rename "SUB_FOR_MOVIE_FILE.srt" to "MOVIE_FILE.perroquet" or "MOVIE_FILE[ANY_CHARACTERS].perroquet"
2) Put the newly created "MOVIE_FILE.perroquet" file in the same folder as "MOVIE_FILE.avi"
3) Make sure no .srt file or subs file named like "MOVIE_FILE[ANY_CHARACTERS].srt" and in the same folder as "MOVIE_FILE.avi" (or subs will appear in vlc...)
4) Open "MOVIE_FILE.avi" with vlc
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

## Help

### General
* The program should support several encodings for the subtitles (files encoded in ISO-8859-1, UTF-8 and UTF-8-SIG were successfully tested). Please let me know if your sub file is not supported.
* Although subtitle files seldom correspond exactly to the audio track, subs are almost always close enough to the track to still provide a good learning experience. Use the button `Help` when you feel the subs are different from the track.
* Subs for deafened or hard or hearing person are usually very good files to train. They may however enhance non-verbal sounds in the track, usually with "(...)" such as in "(Indistinct chatter)"

### Subtitle files and settings:
* If you have several ".Perroquet" files, select one of them in the drowdown list and click on load
* If you have an error "Malformed subtitle...", try to change the UTF-8 encoding to another encoding and click on load
* If you have unrecognized/weird character such as � or Ã£, try to change the UTF-8 encoding to another encoding and click on load
* If the sequence are too short or start too late (and you cannot hear the whole sequence), try to
	* change the `Delay before` and `Delay After` (default to 1s) to a larger one
	* manually change the synchronization  with `g` and `h` key in VLC

### Other
* In long sequences, VLC might show you a "Extension not responding message", you shoud ignore it.
* In v1.0, the program uses a `repeat ... until ...` approach equivalent to a `freeze`, this is why you are advised not to do any action in the Perroquet Subtitles for VLC gui when replaying a sequence
* How to run the program
* Step-by-step bullets

### Debugging

The program can be debugged by running VLC in verbose mode. Under linux this means:
```sh
vlc --verbose=2
```

## Author

Gaspard DOUXCHAMPS

## Version History

* Planned 1.1
    * Test on windows
    * Translate Readme in French
    
* 1.0
    * Initial Release tested on linux

Main possible improvements:
-replace "freeze" by "wait" in (Re)play
-support and test srt file for better compatibility
-test and run on windows
-implement color code when "input" is getting close to "correction"
-translate this readme in other languages

## License

This project is licensed under the GNU GPL v3 License - see the LICENSE.md file for details

## Acknowledgments

Inspiration :
* Perroquet Team and Fred Bertolus for the original software Perroquet (https://launchpad.net/perroquet)

Code snippet :
* `Perroquet.lua` script was adapated from the "Subtitle Word Search" add-on (https://github.com/tcrespog/vlc-subtitle-word-search/) by Tomás Crespo

Other:
* DomPizzie for the Simple README template (https://gist.github.com/DomPizzie/7a5ff55ffa9081f2de27c315f5018afc)


