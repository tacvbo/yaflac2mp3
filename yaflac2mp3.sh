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

LAME_OPTS="--vbr-new -V 0 -b 320"

old_IFS=${IFS}
IFS='
'
files=( `find . -type f -name '*flac'` )
IFS=${old_IFS}


for N_files in ${!files[@]}
  do
    old_IFS=${IFS}
    IFS='
'
    vars=( `metaflac --no-utf8-convert --export-tags-to=- "${files[${N_files}]}"` )
    IFS=${old_IFS}
    for N_vars in ${!vars[@]}
      do
        export "$(echo "${vars[${N_vars}]%=*}" | tr [:upper:] [:lower:])=\"${vars[${N_vars}]#*=}\""
    done
    flac -dc "${files[${N_files}]}" |\
    lame --ignore-tag-errors --add-id3v2 ${LAME_OPTS} \
        ${artist:+--ta "${artist}"} \
        ${tracknumber:+--tn "${tracknumber}"} \
        ${title:+--tt "${title}"} \
        ${album:+--tl "${album}"} \
        ${date:+--ty "${date}"} \
        ${genre:+--tg "${genre}"} \
        ${comment:+--tc "${comment}"} -\
          "${files[${N_files}]/\.flac/.mp3}"
done
