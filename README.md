Mediadater
==========

Mediadater is a small BASH CLI utility for Linux, used to rename media files created by recording devices. By default it renames the files to the date the file was created, plus the camera model. It's behaviour is very flexible and it can work with all picture, audio and video files that [Exiftool supports](https://en.wikipedia.org/wiki/ExifTool#Supported_file_types). It's licensed with the GNU GPLv3 License.

##Installation
To install, download the `mediadater` script and place it somewhere in your PATH. Give it execution permissions:
```
chmod +x mediadater
```

It also requires `sed` which is probably included in your distribution and `exiftool` which is in the Ubuntu repositories:
```
sudo apt-get install libimage-exiftool-perl
```

##Usage
The argument you provide can either be a file or multiple files as separate arguments (and even a pattern through shell expansion). By default the file is named after the created date followed by the camera model if the tag is available (e.g. `20140101_122301_Nikon D60.jpg`).

Example usage:
```
mediadater -vx -s "My friends camera" DSC_*.JPG
```

You can specify the files to rename in several different ways. You can specify them, pipe the input, use file input, or even run with nothing specified at all and the script will use `find` to locate every supported file in the current working directory, but first prompt you and ask if that is really what you want to do.

##Parameters

Parameter | Explanation
--------- | -----------
-d        | Set a date format for the file names using the `strftime` syntax.
-v        | Print the changes being made.
-p        | Prefix the file name (before the date).
-s        | Suffix, by default it tries to use the camera model but it can be helpful to use a custom suffix, for example if you want to name files from different occasions, like "Vacation" and "Wedding".
-x        | If a related [Darktable](http://www.darktable.org/) XMP-file is found this will also edit it so that it's still connected to the new file name.
