#!/bin/bash
#
# Copyright 2008 Octavio Ruiz
# Distributed under the terms of the GNU General Public License v3
# $Header: $
#
# Yet Another FLAC to MP3 script
#
# Author:
#       Octavio Ruiz (Ta^3) <tacvbo@tacvbo.net>
# Contributors:
#        Zythme <zythmer@gmail.com>
# Thanks:
#       Those comments at:
#       http://www.linuxtutorialblog.com/post/solution-converting-flac-to-mp3
#       Thatch's fork and fixes at:
#       http://github.com/
# WebPage:
#       https://github.com/tacvbo/yaflac2mp3/tree
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY. YOU USE AT YOUR OWN RISK. THE AUTHOR
# WILL NOT BE LIABLE FOR DATA LOSS, DAMAGES, LOSS OF PROFITS OR ANY
# OTHER  KIND OF LOSS WHILE USING OR MISUSING THIS SOFTWARE.
# See the GNU General Public License for more details.

LAME_OPTS="-b 320 -h"
LAME=$(which lame)
FLAC=$(which flac)
SOURCE="."
DEST="."
ID3=""

usage()
{
    EXIT=${1:-1}

    cat<<EOF

Usage: $0 [-l <lame>] [-f <flac>] [-x <lame_opts>]
          [-s <source>] [-d <dest>] [-o] [-i]
Usage: $0 -h

Default options:
  <lame_opts> = ${LAME_OPTS}
  <lame>      = ${LAME}
  <flac>      = ${FLAC}
  <source>    = ${SOURCE}
  <dest>      = ${DEST}
  <id3_tool>  = ${ID3}

  If you use -o, an existing mp3 file at destination dir it's overwritten

  If you use -i, id3_tool is set to id3v2.
  This is only necessary if your LAME version doesn't tag properly

EOF

    exit ${EXIT}
}

while getopts l:f:x:d:s:hio name; do

    case "${name}" in
        l)
            LAME="${OPTARG}"
            ;;
        f)
            FLAC="${OPTARG}"
            ;;
        x)
            LAME_OPTS="${OPTARG}"
            ;;
        s)
            SOURCE="${OPTARG}"
            ;;
        d)
            DEST="${OPTARG}"
            ;;
        o)
            OVRWRT=yes
            ;;
        i)
            ID3="$(which id3v2 || echo '')"
            if [[ ! -x "$ID3" ]]; then
                echo -e "Requested id3v2 but not found.  Only using lame.\n\n"
            fi
            ;;
        h)
            usage 0
            ;;
        ?)
            usage 1
            ;;
    esac
done

if [[ ! -d "${DEST}" ]]; then
  mkdir -p "${DEST}"
  [[ "$?" != "0" ]] && exit 2
fi
[[ ! -d "${SOURCE}" ]] && echo "\"${SOURCE}\" is not a directory" && usage 1

old_IFS=${IFS}
IFS='
'
files=( $( find "${SOURCE}" \( -type f -o -type l \) -a -iname '*.flac' ) )

for N_files in ${!files[@]}
  do
    dst_file="${DEST}/${files[${N_files}]/%\.flac/.mp3}"
    [[ -e "$dst_file" ]] && [[ -z $OVRWRT ]] && continue
    vars=( $( metaflac --no-utf8-convert --export-tags-to=- "${files[${N_files}]}" ) )

    for N_vars in ${!vars[@]}
      do
#       export "$(echo "${vars[${N_vars}]%=*}" | tr [:upper:] [:lower:])=${vars[${N_vars}]#*=}"
        varname="$(echo "${vars[${N_vars}]%=*}" | tr [:upper:] [:lower:])"
        varstring="${vars[${N_vars}]#*=}"
        export "${varname// /_}=${varstring}"
    done

    "${FLAC}" -dc "${files[${N_files}]}" |\
    "${LAME}" --ignore-tag-errors --add-id3v2 "${LAME_OPTS}" \
        ${artist:+--ta} ${artist} \
        ${tracknumber:+--tn} ${tracknumber} \
        ${title:+--tt} ${title} \
        ${album:+--tl} ${album} \
        ${date:+--ty} ${date} \
        ${genre:+--tg} ${genre} \
        ${comment:+--tc} ${comment} \
        - "${dst_file}"

    # User should only run this if they know their version of lame doesn't tag
    # properly.  Does this happen in practice?  LAME 3.98 supports id3 v1 and v2
    [[ -x ${ID3} ]] && ${ID3} \
        ${artist:+--artist} ${artist} \
        ${tracknumber:+--track} ${tracknumber} \
        ${title:+--song} ${title} \
        ${album:+--album} ${album} \
        ${date:+--year} ${date} \
        ${genre:+--genre} ${genre} \
        ${comment:+--comment} ${comment} \
          "${dst_file}"

done
IFS=${old_IFS}

exit 0
