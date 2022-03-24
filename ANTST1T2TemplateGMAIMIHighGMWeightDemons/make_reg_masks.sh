#!/bin/bash

for i in `cat ../subjects.list`
do
	mri_binarize --i ${i}_dkt.nii.gz --o ${i}_dkt_tissue.nii.gz --match 0 258 165 --inv --noverbose
	ImageMath 3 ${i}_dkt_tissue_dilated.nii.gz MD ${i}_dkt_tissue.nii.gz 15

	ThresholdImage 3 ${i}_t1.nii.gz ${i}_t1_otsu2.nii.gz Otsu 2
	mri_binarize --i ${i}_t1_otsu2.nii.gz --o ${i}_t1_otsu2_mask.nii.gz --min 1 --noverbose

	ImageMath 3 ${i}_t1_otsu2_mask_closed.nii.gz MC ${i}_t1_otsu2_mask.nii.gz 4

	#ImageMath 3 ${i}_t1_otsu2_mask_opened.nii.gz MO ${i}_t1_otsu2_mask.nii.gz 2
	#ImageMath 3 ${i}_t1_reg_mask.nii.gz MC ${i}_t1_otsu2_mask_opened.nii.gz 5

	#fslmaths ${i}_t1_reg_mask.nii.gz ${i}_t1_reg_mask.nii.gz -odt char
	fslmaths ${i}_dkt_tissue_dilated.nii.gz -mas ${i}_t1_otsu2_mask_closed.nii.gz ${i}_t1_reg_mask.nii.gz -odt char
	ImageMath 3 ${i}_t1_reg_mask.nii.gz MC ${i}_t1_reg_mask.nii.gz 15
	ImageMath 3 ${i}_t1_reg_mask.nii.gz MD ${i}_t1_reg_mask.nii.gz 5

	rm -f ${i}_t1_otsu2_mask_opened.nii.gz ${i}_t1_otsu2_mask.nii.gz ${i}_t1_otsu2.nii.gz ${i}_t1_otsu2_mask_closed.nii.gz
done
