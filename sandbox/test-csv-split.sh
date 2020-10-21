#!/usr/bin/bash
rm -f big*.csv
perl -MCSV -wE'csv (out => "big.csv", in => [["aa".."az"], ([1..26]) x 603])'
csv-split         -c 15        big.csv
csv-split               -r 250 big.csv
csv-split         -c 15 -r 250 big.csv
csv-split -b bigX -c 15        big.csv
csv-split -b bigX       -r 250 big.csv
csv-split -b bigX -c 15 -r 250 big.csv
for i in big*.csv ; do
    xlscat -i $i
    done
rm -f big*.csv
