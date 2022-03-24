#!/bin/bash

for i in `cat ../subjects.list`
do
	if [ ! -f "${i}_fissuremask.nii.gz" ]
	then
		fslmaths ${i}_t1 -mul 0 ${i}_fissuremask -odt char
	fi

	mri_binarize --i ${i}_dkt.nii.gz --o ${i}_dkt_notwm.nii.gz --match 2 41 --inv
	fslmaths ${i}_fissuremask -mas ${i}_dkt_notwm ${i}_fissuremask -odt char
	rm -f ${i}_dkt_notwm.nii.gz
	antsApplyTransforms -d 3 -v --output-data-type short \
		--transform Final${i}1Warp.nii.gz \
		--transform Final${i}0GenericAffine.mat \
		--interpolation NearestNeighbor \
		--reference-image Finaltemplate0.nii.gz \
		--input ${i}_fissuremask.nii.gz \
		--output ${i}_fissuremask_to_template.nii.gz
	RIBBONIMAGES="$RIBBONIMAGES ${i}_fissuremask_to_template.nii.gz"
done

fslmerge -a tmp $RIBBONIMAGES
fslmaths tmp -Tmean -bin FinaltemplateFissureMask
rm -f tmp.nii.gz
