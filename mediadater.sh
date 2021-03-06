#!/bin/bash

#   Mediadater - A small utility for managing media files
#   Copyright (C) 2014 Niklas Rosenqvist
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.

#Functions
function script_dir {
	echo "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
}

function script_name {
	echo "$(basename $0)"
}

function ask {
    read -n 1 -r -p "$1 (y/n) "
	echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        return 0
    else
		return 1
    fi
}

function join {
	local IFS="$1"
	shift
	echo "$*"
}

function log {
	if [ $logging -eq 0 ]; then
		echo "$1" | tee -a "$logfile"
	else
		echo "$1"
	fi
}

function rename {
	#Make sure file exists
	if [ ! -f "$1" ]; then
		log "The file \"$1\" can't be found."
		return 1
	fi

	#Get media meta data
	local fullname="$(basename "$1")"
	local extension="${fullname##*.}"
	local filename="${fullname%.*}"
	local exifdata="$(exiftool -dateFormat "$dateformat" "$fullname")"
	local timestamp="$(echo "$exifdata" | grep 'Create Date')"
	timestamp="${timestamp##*: }"
	local cameramodel="$(echo "$exifdata" | grep 'Camera Model Name')"
	cameramodel="${cameramodel##*: }"
    
    #Skip if creation date can't be determined
	if [ -z "$timestamp" ]; then
		if [ $verbose -eq 0 ]; then
			log "Skipped \"$fullname\" - Couldn't determine file creation date"
		fi
		return 0
	fi

	#Set name suffix (default is cameramodel)
	if [ $suffixset -ne 0 ]; then
		if [ ! -z "$cameramodel" ]; then
			suffix="_$cameramodel"
		else
			suffix=""
		fi
	fi

	local newname="${prefix}${timestamp}${suffix}.$extension"

	#Skip if name hasn't been changed
	if [[ "$fullname" == "$newname" ]]; then
		if [ $verbose -eq 0 ]; then
			log "Skipped \"$fullname\" - same name"
		fi
		return 0
	fi

	#If newname already exist, loop until we find a unique name
	if [ -e "$newname" ]; then
		for i in $(seq -w 99); do
			if [ $i -eq 99 ]; then
				echo "ERROR: More than 98 files with the same timestamp."
				exit 1
			fi

			newname="${prefix}${timestamp}${suffix}_${i}.$extension"

			if [[ ! -e "$newname" ]] || [[ "$fullname" == "$newname" ]]; then
				break
			fi
		done
	fi

	#Skip if name hasn't been changed
	if [[ "$fullname" == "$newname" ]]; then
		if [ $verbose -eq 0 ]; then
			log "Skipped \"$fullname\" - same name"
		fi
		return 0
	fi

	#Rename
	mv "$fullname" "$newname"
	local vmsg="Renamed \"$fullname\" -> \"$newname\""

	#Rename related XMP file if set to
	if [ $xmp -eq 0 ] && [ -f "$fullname.xmp" ]; then
		sed -i "s/$fullname/$newname/g" "$fullname.xmp"
		mv "$fullname.xmp" "$newname.xmp"

		if [ $verbose -eq 0 ]; then
			vmsg="${vmsg} and edited related XMP-file"
		fi
	fi

	if [ $verbose -eq 0 ]; then
		log "${vmsg}"
	fi

	#Successful
	return 0
}

# Variables
xmp=1
verbose=1
dateformat="%Y%m%d_%H%M%S"
suffix=""
suffixset=1
logging=1
logfile="mediadater_log.txt"
prefix=""
supportedformats=(3FR 3G2 3GP2 3GP 3GPP AIFF AIF AIFC APE ARW AVI BMP DIB BTF TIFF TIF CR2 CRW CIFF CS1 DCP DIVX DJVU DJV DNG DV DVB ERF FFF FFF FLAC FLV FPF FPX GIF HDP WDP HDR IIQ J2C JPC JP2 JPM JPX JPEG JPG K25 KDC LA M2TS MTS M2T TS M4A M4B M4P M4V MEF MIFF MIF MKA MKV MOS MOV QT MP3 MP4 MPC MPEG MPG M2V MPO MQV MRW NEF NRW OFR OGG ORF PAC PCD PEF PGF PICT PCT PMP PNG JNG MNG PSD PSB PSP PSPIMAGE QTIF QTI QIF RA RAF RAW RAW RM RV RMVB RW2 RWL SR2 SRF SRW THM TIFF TIF VOB WAV WEBM WEBP WMA WMV WV X3F)
regextest="($(join "|" "${supportedformats[@]}"))\$"
regexfind=".*\.\($(join "|" "${supportedformats[@]}")\)"
regexfind="${regexfind//|/\\|}"

#Parse arguments
while getopts ":f:id:vp:s:xl" opt; do
	case $opt in
		d) #date format
			dateformat="$OPTARG"
			;;
		v) #verbose
			verbose=0
			;;
		p) #prefix
			prefix="$OPTARG"
			;;
		s) #suffix
			suffix="$OPTARG"
			suffixset=0
			;;
		x) #also rename darktable XMP-file
			xmp=0
			;;
		l) #Log output
			if [ -e "$logfile" ]; then
				rm "$logfile"
			fi

			logging=0
			;;
		\?)
    		echo "Invalid option: -$OPTARG" >&2
			exit 1
    		;;
		:)
    		echo "Option -$OPTARG requires an argument." >&2
    		exit 1
    		;;
	esac
done

shift $((OPTIND-1))

#Make regex case insensitive
shopt -s nocasematch
counter=1

#Process pipe input
if readlink /proc/$$/fd/0 | grep -q "^pipe:"; then
	#Read arguments from STDIN
	IFS=$'\n' read -d '' -r -a arguments

	for file in "${arguments[@]}"; do
		if [[ "$file" =~ $regextest ]]; then
			echo -ne "$counter/${#arguments[@]}:\t"
			rename "$file"
		else
			echo -e "$counter/${#arguments[@]}:\t\"$file\" is not of a supported file type."
		fi

		counter=$(($counter+1))
	done
#Terminal input
elif file $( readlink /proc/$$/fd/0 ) | grep -q "character special"; then
	#Files specified
	if [ $# -gt 0 ]; then
		#Loop through files
		for file in "$@"
		do
			if [[ "$file" =~ $regextest ]]; then
				echo -ne "$counter/$#:\t"
				rename "$file"
			else
				echo -e "$counter/$#:\t\"$file\" is not of a supported file type."
			fi

			counter=$(($counter+1))
		done
	#No files specified (directory mode)
	else
		ask "You haven't specified a file or pattern to search for. This means that you will rename every supported file in this directory. Do you wish to continue?"

		if [ $? -ne 0 ]; then
			echo "Aborting..."
			exit 0
		fi

		#Find all supported file types
		IFS=$'\n'
		files=($(find . -maxdepth 1 -type f -iregex "$regexfind" | sort -V))

		for file in "${files[@]}"
		do
			echo -ne "$counter/${#files[@]}:\t"
			rename "$file"
			counter=$(($counter+1))
		done
	fi
#File input
else
	#Get file list so that we can show the progress
	files=()
	while read file
	do
		files+=("$file")
	done

	for file in "${files[@]}"
	do
		if [[ "$file" =~ $regextest ]]; then
			echo -ne "$counter/${#files[@]}:\t"
			rename "$file"
		else
			echo -e "$counter/${#files[@]}:\t\"$file\" is not of a supported file type."
		fi

		counter=$(($counter+1))
	done
fi

exit 0
