#!/bin/bash

# 
# Run the character recognition, determine the error rate and clean up.
# Error rate will be stored in a variable "error".
# 
function recognitionAndError() {
	ocropus-rpred -q -Q2 -m fraktur.pyrnn.gz work/*.png
	cp ground-truth/*.gt.txt work/
	error=`ocropus-errs -e work/*.gt.txt |grep ^[0-9]`
}

function clean() {
	rm -f work.*
	rm -fr work/
}

function runScantailor() {
	DPI=$1
	THRESHOLD=$2
	mkdir -p out
	scantailor-cli --dpi=300 --output-dpi=$DPI --layout=1 --threshold=$THRESHOLD color.jpeg out/ && mv out/color.tif work.tif
	ocropus-gpageseg -n -q --csminheight 100000 --usegauss work.tif
	recognitionAndError
	echo -e "$DPI\t$THRESHOLD\t$error" >> scantailor.csv
	rm -fr out/
	clean
}

function checkPrerequisites() {
	scantailor-cli -h > /dev/null 2>/dev/null
	if [ $? != 0 ]; then
		echo "ScanTailtor not installed? Could not execute 'scantailor-cli'. Check README.md"
		exit 1
	fi
	
	ocropus-gpageseg -h > /dev/null 2>/dev/null
	if [ $? != 0 ]; then
		echo "OCRopus not installed? Could not execute 'ocropus-gpageseg'. Check README.md"
		exit 1
	fi
}

function runNetbpm() {
	djpeg color.jpeg | ppmtopgm |pgmnorm -wvalue 185 -bvalue 120 > work.pgm
	ocropus-gpageseg -n -q --csminheight 100000 --usegauss work.pgm
	recognitionAndError
	echo -e "gpageseg bin\t$error" >> gray.csv
	
	ocropus-nlbin work.pgm
	ocropus-gpageseg -q -n --csminheight 100000 --usegauss work.bin.png 
	recognitionAndError
	echo -e "nlbin+gpageseg bin\t$error" >> gray.csv
	
	ocropus-gpageseg -q -n --gray --csminheight 100000 --usegauss work.nrm.png 
	rm -f work/*.bin.png
	recognitionAndError
	echo -e "nlbin+gpageseg gray\t$error" >> gray.csv
	
	clean
}

checkPrerequisites

runNetbpm

runScantailor 600 0
runScantailor 600 10
runScantailor 600 20
runScantailor 600 30
runScantailor 400 0
runScantailor 400 10
runScantailor 400 20
runScantailor 400 30
runScantailor 300 0
runScantailor 300 10
runScantailor 300 20
runScantailor 300 30

echo "Results can be found in scantailor.csv and gray.csv"
