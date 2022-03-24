#!/bin/bash -x

for i in `cat ../subjects.list`
do
	fslmaths ${i}_brain_mask.nii.gz -mul -1 -add 1 ${i}_notbrain_mask.nii.gz
	fslcpgeom ${i}_t1.nii.gz ${i}_notbrain_mask.nii.gz
	ThresholdImage 3 ${i}_t1.nii.gz ${i}_t1_otsu2.nii.gz Otsu 2
	mri_binarize --i ${i}_dkt.nii.gz --o ${i}_notbrain_mask.nii.gz --match 258 0
	mri_binarize --i ${i}_dkt.nii.gz --o ${i}_dkt_closed.nii.gz --match 258 0 --inv
	ImageMath 3 ${i}_dkt_closed.nii.gz MC ${i}_dkt_closed.nii.gz 5 
	fslmaths ${i}_dkt_closed.nii.gz -mul -1 -add 1 ${i}_dkt_closed.nii.gz	
	ImageMath 3 ${i}_t1Laplacian.nii.gz Laplacian ${i}_t1.nii.gz
	fslmaths ${i}_t1Laplacian.nii.gz -mul -1 -thr 0 -bin -mas ${i}_notbrain_mask.nii.gz -mas ${i}_t1_otsu2.nii.gz ${i}_negoutside.nii.gz
	fslmaths ${i}_fissuremask -mul -1 -add 1 -mul ${i}_negoutside.nii.gz -mas ${i}_dkt_closed.nii.gz -mul 165 ${i}_negoutside.nii.gz
	mri_mask -transfer 165 ${i}_dkt.nii.gz ${i}_negoutside.nii.gz ${i}_dkt_with_skull_label.nii.gz
done
