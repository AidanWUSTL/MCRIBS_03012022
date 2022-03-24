#!/bin/bash

for i in `cat ../subjects.list`
do
	mri_binarize --i ${i}_dkt_with_skull_label.nii.gz --o ${i}_dkt_with_skull_label_occipital_mask.nii.gz --match 1011 2011 1013 2013 1021 2021 --dilate 3 --noverbose
	
	mri_binarize --i ${i}_dkt_with_skull_label.nii.gz --o ${i}_dkt_with_skull_label_skull.nii.gz --match 165 --noverbose
	
	fslmaths ${i}_dkt_with_skull_label_occipital_mask.nii.gz -mas ${i}_dkt_with_skull_label_skull.nii.gz -bin -mul 258 tmp
	mri_mask -transfer 258 ${i}_dkt_with_skull_label.nii.gz tmp.nii.gz ${i}_dkt_with_skull_label.nii.gz
	rm -f tmp.nii.gz ${i}_dkt_with_skull_label_skull.nii.gz ${i}_dkt_with_skull_label_occipital_mask.nii.gz
done
