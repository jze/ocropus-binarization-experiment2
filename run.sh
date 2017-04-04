#!/bin/bash

function runScantailor() {
	DPI=$1
	THRESHOLD=$2
	mkdir -p out
	scantailor-cli --dpi=300 --output-dpi=$DPI --layout=1 --threshold=$THRESHOLD color.jpeg out/ && mv out/color.tif work.tif
	ocropus-gpageseg -q --usegauss work.tif
	ocropus-rpred -q -m fraktur.pyrnn.gz work/*.bin.png
	cp ground-truth/*.gt.txt work/
	echo -ne "$DPI\t$THRESHOLD\t"
	ocropus-errs -e work/*.gt.txt |grep ^[0-9]
	rm -fr work/
	rm -f work.tif
	rm -f work.pseg.png
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
	
	exit 0
}

checkPrerequisites

runScantailor 600 0
runScantailor 600 10
runScantailor 600 20
runScantailor 600 30
