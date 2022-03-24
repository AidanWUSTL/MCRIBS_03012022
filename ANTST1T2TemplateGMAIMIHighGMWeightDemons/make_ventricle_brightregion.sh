#!/bin/bash

GMMATCH=
for j in `seq 1000 1035`
do
	GMMATCH="$GMMATCH $j `expr $j + 1000`"
done

for i in `cat ../subjects.list`
do
	#mri_mask -transfer 64 ${i}_dkt_with_skull_label.nii.gz ${i}_dkt.nii.gz ${i}_dkt_with_skull_label.nii.gz
	#./GaussianLaplacian -s 1 ${i}_t2.nii.gz ${i}_t2_laplacian1.nii.gz 
	#mri_binarize --i ${i}_t2_laplacian1.nii.gz --o ${i}_t2_laplacian1_pos.nii.gz --min 0 --noverbose
	
	mri_binarize --i ${i}_dkt.nii.gz --o ${i}_vent_and_centre_bright.nii.gz --match 4 43 31 63 14 --noverbose
	mri_binarize --i ${i}_dkt.nii.gz --o ${i}_vents_dilated.nii.gz --match 4 43 9 48 --dilate 4 --noverbose
	mri_binarize --i ${i}_dkt.nii.gz --o ${i}_vents_dilated.nii.gz --match 24 --mask ${i}_vents_dilated.nii.gz --noverbose
	fslmaths ${i}_vent_and_centre_bright.nii.gz -add ${i}_vents_dilated.nii.gz ${i}_vent_and_centre_bright.nii.gz -odt char
	rm -f ${i}_vents_dilated.nii.gz
done
