:camera: Screen capture support scripts for Linux :penguin:
===========================================================

these scripts to support screen capture.



## Dependencies
- [naelstrof/slop](https://github.com/naelstrof/slop) ... select screen region.
- [naelstrof/maim](https://github.com/naelstrof/maim) ... take screen shot.
- [FFmpeg](https://www.ffmpeg.org/) ... record screen.

### install dependent pacakges.
```sh
# Debian (apt)
% sudo apt install ffmpeg maim slop

# Arch
% sudo pacman -S ffmpeg maim slop
```



## How to use
### :camera: Take the screen shot
```sh
% ./take_ss.sh -h

Usage: take_ss.sh [-o] [-h] [-d] output.png

Description:
    Take the screen shot.

Options:
    -o  if the output file already exists, then it will be overwrite.
    -h  Show help.
    -d  Debug mode.

```


### :movie_camera: Record the screen

```sh
% ./rec_screen.sh -h

Usage: rec_screen.sh [-t REC_TIME] [-o] [-h] [-d] output.gif

Description:
    Record the screen.

Options:
    -t  Recording time [sec]. default 7 sec.
    -o  if the output file already exists, then it will be overwrite.
    -h  Show help.
    -d  Debug mode.

```

