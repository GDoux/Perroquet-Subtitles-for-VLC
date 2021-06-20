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

### Executing program

Assuming you movie file is "MOVIE_FILE.avi" (or .mkv, .mp4, etc.) and that you have a synced "SUB_FOR_MOVIE_FILE.srt"
1) Rename "SUB_FOR_MOVIE_FILE.srt" to "MOVIE_FILE.perroquet" or "MOVIE_FILE[ANY_CHARACTERS].perroquet"
2) Put the newly created "MOVIE_FILE.perroquet" file in the same folder as "MOVIE_FILE.avi"
3) Open "MOVIE_FILE.avi" with vlc
4) In the VLC toolbar, click on View , then on Perroquet Subtitles for VLC
5) A new gui (window) should opeb : start using!

#### More details

```
code blocks for commands
```

## Help

### Subtitle files and settings:
* If you have several ".Perroquet" files, select one of them in the drowdown list and click on load
* If you have an error "Malformed subtitle...", try to change the UTF-8 encoding to another encoding
* If you have unrecognized (weird
* How to run the program
* Step-by-step bullets
* Although subtitle files seldom correspond exactly to the audio track, subs are almost always close enough to the track to still provide  
* The program should support several encodings for the subtitles (files encoded in ISO-8859-1, UTF-8 and UTF-8-SIG were successfully tested). Please let me know if your sub file is not supported.
* 

The program can be debugged 
```
command to run if program contains helper info
```

## Authors

Contributors names and contact info

ex. Dominique Pizzie  
ex. [@DomPizzie](https://twitter.com/dompizzie)

## Version History

* 0.2
    * Various bug fixes and optimizations
    * See [commit change]() or See [release history]()
* 0.1
    * Initial Release

## License

This project is licensed under the GNU GPL v3 License - see the LICENSE.md file for details

## Acknowledgments

Inspiration, code snippets, etc.
* [awesome-readme](https://github.com/matiassingers/awesome-readme)
* [PurpleBooth](https://gist.github.com/PurpleBooth/109311bb0361f32d87a2)
* [dbader](https://github.com/dbader/readme-template)
* [zenorocha](https://gist.github.com/zenorocha/4526327)
* [fvcproductions](https://gist.github.com/fvcproductions/1bfc2d4aecb01a834b46)
