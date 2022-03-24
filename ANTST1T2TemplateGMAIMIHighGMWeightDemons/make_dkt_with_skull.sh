#!/bin/bash

for i in `cat ../subjects.list`
do
	mri_binarize --i ${i}_skull_orig.nii.gz --o ${i}_skull_orig_dkt.nii.gz --replace 1 165
	#mri_binarize --i ${i}_dkt.nii.gz --o ${i}_dkt_tmp.nii.gz --replace 258 0
	cp ${i}_dkt.nii.gz ${i}_dkt_tmp.nii.gz
	#mri_binarize --i ${i}_dkt_tmp.nii.gz --o ${i}_dkt_tmp_mask.nii.gz --match 0 --erode 1
	
	#rm -f ${i}_dkt_with_skull_label.nii.gz	
	#fslmaths ${i}_skull_orig_dkt.nii.gz -mas ${i}_dkt_tmp_mask.nii.gz ${i}_skull_orig_dkt.nii.gz
	
	antsApplyTransforms -d 3 -v --output-data-type short \
		--transform [Final${i}0GenericAffine.mat,1] \
		--transform Final${i}1InverseWarp.nii.gz \
		--reference-image ${i}_t2.nii.gz \
		--interpolation NearestNeighbor \
		--input DKTWithSkullLabelMajorityFissureMask.nii.gz \
		--output ${i}_DKTWithSkullLabelMajorityFissureMask.nii.gz
	fslmaths ${i}_DKTWithSkullLabelMajorityFissureMask.nii.gz -mul -1 -add 1 -mul ${i}_skull_orig_dkt.nii.gz ${i}_skull_orig_dkt.nii.gz -odt char
	
	./ComponentAreaFilter ${i}_skull_orig_dkt.nii.gz ${i}_skull_orig_dkt_mask.nii.gz
	fslmaths ${i}_skull_orig_dkt.nii.gz -mas ${i}_skull_orig_dkt_mask.nii.gz ${i}_skull_orig_dkt.nii.gz
	mri_mask -transfer 165 ${i}_dkt_tmp.nii.gz ${i}_skull_orig_dkt.nii.gz ${i}_dkt_with_skull_label.nii.gz
	rm -f ${i}_skull_orig_dkt.nii.gz ${i}_dkt_tmp.nii.gz ${i}_dkt_tmp_mask.nii.gz ${i}_skull_orig_dkt_mask.nii.gz ${i}_DKTWithSkullLabelMajorityFissureMask.nii.gz
	
	antsApplyTransforms -d 3 -v --output-data-type short \
		--transform Final${i}1Warp.nii.gz \
		--transform Final${i}0GenericAffine.mat \
		--reference-image Finaltemplate0.nii.gz \
		--interpolation GenericLabel \
		--input ${i}_dkt_with_skull_label.nii.gz \
		--output ${i}_dkt_with_skull_label_to_template.nii.gz
	DKTIMAGES="$DKTIMAGES ${i}_dkt_with_skull_label_to_template.nii.gz"
done
ImageMath 3 FinaltemplateDKTWithSkullLabelMajority.nii.gz MajorityVoting $DKTIMAGES
rm -f $DKTIMAGES
#fslmaths FinaltemplateDKTWithSkullLabelMajority.nii.gz -mul 0 DKTWithSkullLabelMajorityFissureMask.nii.gz -odt char
