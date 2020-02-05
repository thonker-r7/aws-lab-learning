#!/bin/bash
#
#	Written by Tim Honker
#	
#	Finds all my bash scripts and scans them for syntax errors and problems
#
set -e
SOURCE_CODE_PATH=$(pwd)

find "$SOURCE_CODE_PATH" -type f -iname '*.sh' -exec shellcheck {} \;
