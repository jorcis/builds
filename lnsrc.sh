#!/bin/bash
DEST_DIR="$1"
mkdir -p $DEST_DIR
shift
for SOURCE_FILE in "$@"
	do 
		ln -s $(readlink -f $SOURCE_FILE) $DEST_DIR/$(awk 'END{ var=FILENAME; n=split (var,a,/\//); print a[n]}' $SOURCE_FILE)
	done