#!/bin/bash

GMMATCH=
for j in `seq 1000 1035`
do
	GMMATCH="$GMMATCH $j `expr $j + 1000`"
done

for i in `cat ../subjects.list`
do
	#mri_mask -transfer 64 ${i}_dkt_with_skull_label.nii.gz ${i}_dkt.nii.gz ${i}_dkt_with_skull_label.nii.gz
	./GaussianLaplacian -s 1 ${i}_t2.nii.gz ${i}_t2_laplacian1.nii.gz 
	mri_binarize --i ${i}_t2_laplacian1.nii.gz --o ${i}_t2_laplacian1_pos.nii.gz --min 0 --noverbose
	
	mri_binarize --i ${i}_dkt.nii.gz --o ${i}_latvent_lh_dilated.nii.gz --match 4 31 --dilate 2 --noverbose
	mri_binarize --i ${i}_dkt.nii.gz --o ${i}_latvent_rh_dilated.nii.gz --match 43 63 --dilate 2 --noverbose
	
	mri_binarize --i ${i}_dkt.nii.gz --o ${i}_dkt_wm_lh.nii.gz --match 2 --noverbose
	mri_binarize --i ${i}_dkt.nii.gz --o ${i}_dkt_wm_rh.nii.gz --match 41 --noverbose 
	fslmaths ${i}_latvent_lh_dilated.nii.gz -mas ${i}_dkt_wm_lh.nii.gz -mas ${i}_t2_laplacian1_pos.nii.gz -mul 997 ${i}_latvent_lh_dark.nii.gz -odt short
	fslmaths ${i}_latvent_rh_dilated.nii.gz -mas ${i}_dkt_wm_rh.nii.gz -mas ${i}_t2_laplacian1_pos.nii.gz -mul 998 ${i}_latvent_rh_dark.nii.gz -odt short
	
	cp ${i}_dkt_with_skull_label.nii.gz ${i}_dkt_with_latvent_rings.nii.gz
	mri_mask -transfer 997 ${i}_dkt_with_latvent_rings.nii.gz ${i}_latvent_lh_dark.nii.gz ${i}_dkt_with_latvent_rings.nii.gz 
	mri_mask -transfer 998 ${i}_dkt_with_latvent_rings.nii.gz ${i}_latvent_rh_dark.nii.gz ${i}_dkt_with_latvent_rings.nii.gz 
	mri_binarize --i ${i}_dkt_with_latvent_rings.nii.gz --o ${i}_dkt_with_latvent_rings_gm.nii.gz --match 997 998 $GMMATCH --noverbose
done
