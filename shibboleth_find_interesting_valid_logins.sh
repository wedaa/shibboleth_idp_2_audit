#!/bin/sh
#
# This is just a sample way of getting "interesting" data out of the output files of analyze_cas_tsv_files.pl
file=$1
grep VALID\ LOGIN\ TOTAL $file |sort -t , -n -k4 |sed 's/US://g' |sed 's/US-Marist://g'|sed 's/IT:IT:/IT:/g' |sed 's/FR:FR:/FR:/g'

