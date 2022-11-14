#! /bin/sh
set +o noclobber
# ======================================================
# This script is intended to scan many pages
# over the ADF of a Brother MFC-7420 or MFC-7820N
# and save it in one pdf file.
# Manual turn of the pages and scanning it via a second
# run of the scanner is possible during the scan, since
# a graphical Pop-Up will show up in order to ask if the
# back sides should be scanned as well.
# ======================================================
# $1 = scanner device
# $2 = friendly name
#

#
# Settings
#
device=$1 #see with scanimage -L
open_filemanager="false" # open file manager to display created pdf.
reverse_order="true" # "true" | "false"
# normally you grab the pile of paper, turn it around and
# put it in the ADF again, so that the order of the backsides
# is reversed, this "true" makes the script taking care of it.
outputdir="$HOME/brscan"
tmptemplate="brscan-XXXXXX"
output_file="$outputdir/brscan_`date +%F_%H-%M-%S`.pdf"

#scan options
resolution=300 #see scanimage --help (1200 is max on MFC-7360N)
mode="24bit Color" #see scanimage --help

#
# Start Script
#
mkdir -p $outputdir
touch $output_file
tmp_dir=`mktemp -d "$outputdir/$tmptemplate"`

# tiffcp does not support B&W jpegs
if [ "$mode" = "Black" ];  then
	comp="zip"
else
	comp="jpeg"
fi

# From Brother, sleeping 1 sec here
if [ "`which usleep`" != '' ]; then
	usleep 10000
else
	sleep 0.01
fi

#
# ================================================
# Here is the actual scan command
# Scan the odd sides with even index starting at 0
# ================================================
#echo Dziala >> /tmp/started
#echo scanimage --device-name \"$FIXED_DEVICE_NAME\" --resolution $resolution --format=tiff --mode \"$mode\" --batch=\"$tmp_dir/tmp-image%02d\" --batch-start=0 --batch-increment=2 >> /tmp/started
#scanimage --device-name "$device" --resolution $resolution --format=tiff --mode "$mode" --batch="$tmp_dir/tmp-image%02d" --batch-start=0 --batch-increment=2 2>>/tmp/started
#scanimage --resolution $resolution --format=tiff --mode "$mode" --batch="$tmp_dir/tmp-image%02d" --batch-start=0 --batch-increment=2
#
#
#scanimage --resolution $resolution --format=tiff --mode "$mode" --batch="$tmp_dir/tmp-image%02d" --batch-start=0 --batch-increment=2

batchstart=1
batchincrement=2
scanimage --device-name="$device" --resolution $resolution --format=tiff --mode "$mode" --batch-start=$batchstart --batch-increment=$batchincrement --batch="$tmp_dir/tmp-image%02d"

echo DOOON!!



# 
# get maximal index of pictures scanned so far
for image in $tmp_dir/tmp-image*
do
	echo "$image"
	currentrun=`basename $image | sed -e "s/.*tmp-image\([0-9]\+\)/\1/"`
	# strip zeros, for not to confuse the shell
	currentrun=`echo $currentrun | sed -e"s/^0*//"`
	
if [ -z $currentrun ]; then 
	currentrun=0
else
	currentrun=$(($currentrun))
fi

if [ -z $lo_run ] ; then lo_run=$currentrun ; fi
if [ -z $hi_run ] ; then hi_run=$currentrun ; fi
if [ $lo_run -gt $currentrun ];then
	lo_run=$currentrun
fi
if [ $hi_run -lt $currentrun ]; then
	hi_run=$currentrun
fi

echo "Current run = $currentrun"

done

#if zenity --question --text "Rueckseiten auch scannen?"; then
#	zenity --warning --text "Bitte Seiten aus Einzelblatteinzugablage entnehmen,\nim Bund mit den Rueckseiten nach oben wieder in den Einzelblatteinzug einlegen.\nDann OK klicken."
# ==============================================
# set the second scan to be in correct order
# for easy compilation of pdf
# ==============================================
#if [ $reverse_order="true" ]; then
#	batchstart=`expr $hi_run + 1`
#	batchincrement=-2

#else
#	batchstart=1
#	batchincrement=2
#fi
#	echo "starting at $batchstart with increment $batchincrement"
#	# scanning the backsides with odd indices starting at high or 1 depending on order ;-)
#	# and saving them with odd indices starting at highestnumber+1 with increment
#	# -2 or just with odd indices starting at 1 if no reverse 
#	# order is set.
#	#scanimage --device-name "$device" --resolution $resolution --format=tiff --mode "$mode" --batch-start=$batchstart --batch-increment=$batchincrement --batch="$tmp_dir/tmp-image%02d"
#	scanimage --resolution $resolution --format=tiff --mode "$mode" --batch-start=$batchstart --batch-increment=$batchincrement --batch="$tmp_dir/tmp-image%02d"

### END IF ZENITY
#fi
# ==============================================
# Now all sides are scanned and we continue with
# converting them to a nice pdf file
# ==============================================
image=`mktemp $tmp_dir/tifcollect-XXXXX`
# ==============================================
# tiffcp does not support B&W jpegs
# ==============================================
if [ "$mode" = "Black" -o "$mode" = "Gray[Error Diffusion]" ]; then
	comp="zip"
else
	comp="jpeg"
fi
# all tiffs are merged in one compressed tiff
tiffcp -s -r 32 -c $comp $tmp_dir/tmp-image* $image
# this makes the pdf file, the complicated procedure
# is a workaround for some trouble with tiff2pdf
#tiff2pdf -x$resolution -y$resolution -o"$output_file" "$image"
convert "$image" "$output_file"
# ==============================================
# Deleting temporary files
# ==============================================
#rm $image
#chmod 600 "$output_file"
#rm $tmp_dir/*
#rmdir $tmp_dir
echo "Deleting $tmp_dir"
rm -fr $tmp_dir
echo "Done"
# ==============================================
# Starting File Manager if requested
# ==============================================
if $open_filemanager = "true";then
	if [ "`which nautilus`" != '' ];then
		nautilus $outputdir
	else
	if [ "`which konqueror`" != '' ];then
		konqueror $outputdir
	else
	if [ "`which d3lphin`" != '' ];then
		d3lphin $outputdir
	fi
fi

fi
fi
exit 0
