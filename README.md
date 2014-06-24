Mediadater
==========

Mediadater is a small BASH CLI utility for Linux, used to rename media files created by recording devices. By default it renames the files to the date the file was created and the camera model. It's behaviour is very flexible and it can work with all picture, audio and video files that [Exiftool supports](https://en.wikipedia.org/wiki/ExifTool#Supported_file_types). It's licensed with the GNU GPLv3 License.

##Installation
To install, download the `mediadater` script and place it somewhere in your PATH. Give it execution permissions:
```
chmod +x mediadater
```

It also requires `sed` which is probably included in your distribution and `exiftool` which is in the Ubuntu repositories:
```
sudo apt-get install exiftool
```

##Usage
If you run mediadater without any arguments it uses it's defaults to rename every supported file in the current working directory. The argument you provide can either be a file or multiple files as separate arguments. The file name can also be a pattern supported by the default `name` parameter of `find`, e.g. `*.jpg` to select every JPG-file in the directory. By default it's named after the created date followed by the camera model if the tag is available (e.g. `20140101_122301_Nikon D60.jpg`).

Example usage:
```
mediadater -vx -s "My friends camera" DSC_*.JPG
```

There are a bunch of parameters which can be set to change it's behaviour as well.

##Parameters

Parameter | Long Parameter | Explanation
--------- | -------------- | -----------
-f        | --find         | If you want to use a custom find command you can specify it here within quotations.
-i        | --insensitive  | Make the name matching case insensitive.
-d        | --dateformat   | Set a date format for the file names using the `strftime` syntax.
-v        | --verbose      | Print the changes being made.
-p        | --prefix       | Prefix the file name (before the date).
-s        | --suffix       | Suffix, by default it tries to use the camera model but it can be helpful to use a custom suffix.
-x        | --xmp          | If a related [Darktable](http://www.darktable.org/) XMP-file is found this will also edit it so that it's still connected to the new file name.
