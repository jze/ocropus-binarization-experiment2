#!/bin/bash

function runScantailor() {
	DPI=$1
	THRESHOLD=$2
	mkdir -p out
	scantailor-cli --dpi=300 --output-dpi=$DPI --layout=1 --threshold=$THRESHOLD color.jpeg out/ && mv out/color.tif work.tif
	ocropus-gpageseg -q --usegauss work.tif
	ocropus-rpred -q -m ~/sandbox/ocropy/models/fraktur.pyrnn.gz work/*.bin.png
	cp ground-truth/*.gt.txt work/
	echo -ne "$DPI\t$THRESHOLD\t"
	ocropus-errs -e work/*.gt.txt |grep ^[0-9]
	rm -fr work/
	rm -f work.tif
	rm -f work.pseg.png
}

runScantailor 600 0
runScantailor 600 10
runScantailor 600 20
runScantailor 600 30
