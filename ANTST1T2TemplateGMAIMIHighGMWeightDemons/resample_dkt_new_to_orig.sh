#!/bin/bash

for i in `cat ../subjects.list`
do
	echo $i
	#flirt -in ${i}_dkt_new -ref ../OrigLabelsToT2/${i}_dkt -out ../OrigLabelsToT2/${i}_dkt_new -applyxfm -interp nearestneighbour -datatype short
	mri_convert ${i}_dkt_new.nii.gz -rl ../OrigLabelsToT2/${i}_dkt.nii.gz -rt nearest ../OrigLabelsToT2/${i}_dkt_new.nii.gz
done
