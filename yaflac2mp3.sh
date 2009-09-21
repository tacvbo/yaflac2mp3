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
# WebPage:
#       https://github.com/tacvbo/yaflac2mp3/tree
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY. YOU USE AT YOUR OWN RISK. THE AUTHOR
# WILL NOT BE LIABLE FOR DATA LOSS, DAMAGES, LOSS OF PROFITS OR ANY
# OTHER  KIND OF LOSS WHILE USING OR MISUSING THIS SOFTWARE.
# See the GNU General Public License for more details.

LAME_OPTS="-V 0 --vbr-new"
LAME="lame"
FLAC="flac"
DIR="."
ID3=""

usage()
{
    EXIT=${1:-1}

    cat<<EOF

Usage: $0 [-l <lame>] [-f <flac>] [-x <lame_opts>] [-d <dir>] [-i]
Usage: $0 -h

Default options:
  <lame_opts> = ${LAME_OPTS}
  <lame>      = ${LAME}
  <flac>      = ${FLAC}
  <dir>       = ${DIR}
  <id3_tool>  = ${ID3}

  If you use -i, id3_tool is set to id3v2.
  This is only necessary if your LAME version doesn't tag properly

EOF

    exit ${EXIT}
}

while getopts l:f:x:d:hi name; do
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
        d)
            DIR="${OPTARG}"
            ;;
        h)
            usage 0
            ;;
        i)
            ID3="$(which id3v2 || echo '')"
            if [ ! -x "$ID3" ]; then
                printf "Requested id3v2 but not found.  Only using lame.\n\n"
            fi
            ;;
        ?)
            usage 1
            ;;
    esac
done

[[ ! -d "${DIR}" ]]  && printf "\"${DIR}\" is not a directory\n\n" && usage 1

old_IFS=${IFS}
IFS='
'
files=( `find "${DIR}" \( -type f -o -type l \) -a -name '*.flac'` )

for N_files in ${!files[@]}
  do
    vars=( `metaflac --no-utf8-convert --export-tags-to=- "${files[${N_files}]}"` )

    for N_vars in ${!vars[@]}
      do
#        Grr
#        varname="$(echo "${vars[${N_vars}]%=*}" | tr [:upper:] [:lower:])"
#        varstring="${vars[${N_vars}]#*=}"
#        export "${varname// /_}=${varstring// /_}"
        export "$(echo "${vars[${N_vars}]%=*}" | tr [:upper:] [:lower:])=${vars[${N_vars}]#*=}"
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
        - "${files[${N_files}]/\.flac/.mp3}"

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
        "${files[${N_files}]/\.flac/.mp3}"

done
IFS=${old_IFS}

exit 0
