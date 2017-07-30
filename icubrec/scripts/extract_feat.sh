#!/bin/bash

USAGE="Convert the audio files into features\n"
USAGE=$USAGE"Usage: $0 [-e envt_file] [-f audio_list] [-x extension] audio_root_folder output_folder"

# Set default values
RM_AUDIO_LIST=0
AUDIO_LIST=""

# ":" for options that require a string argument
# "#" for options that require a int argument
while getopts "e:f:hx:" opt; do
    case $opt in
    e)
        ENVT_FILE=$OPTARG;;
    f)
        AUDIO_LIST=$OPTARG;;
    h)
        echo -e $USAGE >&2;
        exit 0;;
    x)
        AUDIO_EXT=$OPTARG;;
    \?)
        echo -e $USAGE >&2;
        exit 1;;
    esac
done

# shifting the options index to the next parameter we didn't take care of
shift $((OPTIND - 1));

AUDIO_ROOT_FOLDER=${1%%/};
OUTPUT_FOLDER=${2%%/};

# Check mandatory arguments
if test -z $AUDIO_ROOT_FOLDER; then
    echo -e $USAGE >&2;
    exit 1;
fi

if test -z $OUTPUT_FOLDER; then
    echo -e $USAGE >&2;
    exit 1;
fi

# Source envt file
if ! test -z $ENVT_FILE; then
    source $ENVT_FILE
fi

if test -z $AUDIO_EXT ; then
    if test -z $AUDIO_FILES_EXT; then
        AUDIO_EXT='wav'
    else
        AUDIO_EXT=$AUDIO_FILES_EXT
    fi
fi

echo "Environment variables:"
echo "ENVT_FILE         = $ENVT_FILE"
echo "AUDIO_LIST        = $AUDIO_LIST"
echo "AUDIO_EXT         = $AUDIO_EXT"
echo "AUDIO_ROOT_FOLDER = $AUDIO_ROOT_FOLDER"
echo "OUTPUT_FOLDER     = $OUTPUT_FOLDER"
echo ""

# If the list of files is not provided, build it
if test -z $AUDIO_LIST; then
    find -L $AUDIO_ROOT_FOLDER -iname "*.$AUDIO_EXT" >audio_files.lst
    AUDIO_LIST=audio_files.lst
    RM_AUDIO_LIST=1
fi

# Creating destination folder structure
cat $AUDIO_LIST | sed -e "s:$AUDIO_ROOT_FOLDER/:$OUTPUT_FOLDER/:g" -e "s:/\?[a-zA-Z0-9_\.]*.$AUDIO_EXT$::i" | uniq | xargs mkdir -p

# Create the list file we need to send to HCopy to convert .wav files to .mfc
paste $AUDIO_LIST $AUDIO_LIST | sed -E "s:$AUDIO_ROOT_FOLDER(\S+)\.$AUDIO_EXT$:$OUTPUT_FOLDER\1\.feat:i" >audio_feat.scp

HCopy -A -T 1 -C $HTK_COMMON/wav.htkc -C $HTK_COMMON/$FEAT_CONF_FILE -C $HTK_COMMON/$CORPORA_CONF_FILE -S audio_feat.scp

rm audio_feat.scp
if test -z $RM_AUDIO_LIST; then
    rm $AUDIO_LIST
fi
