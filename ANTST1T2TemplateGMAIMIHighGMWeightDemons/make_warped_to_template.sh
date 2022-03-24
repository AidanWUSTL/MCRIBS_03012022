#!/bin/bash

for i in `cat ../subjects.list`
do
   	antsApplyTransforms -d 3 -v --output-data-type float \
		--transform Final${i}1Warp.nii.gz \
		--transform Final${i}0GenericAffine.mat \
        --reference-image Finaltemplate0.nii.gz \
        --input ${i}_t2.nii.gz \
        --output ${i}_t2WarpedToTemplate.nii.gz
   	antsApplyTransforms -d 3 -v --output-data-type float \
		--transform Final${i}1Warp.nii.gz \
		--transform Final${i}0GenericAffine.mat \
        --reference-image Finaltemplate0.nii.gz \
        --input ${i}_t1.nii.gz \
        --output ${i}_t1WarpedToTemplate.nii.gz
    	antsApplyTransforms -d 3 -v --output-data-type float \
		--transform Final${i}1Warp.nii.gz \
		--transform Final${i}0GenericAffine.mat \
        --reference-image Finaltemplate0.nii.gz \
        --input ${i}_gm.nii.gz \
        --output ${i}_gmWarpedToTemplate.nii.gz
done


fslmerge -a all_t1WarpedToTemplate P*_t1WarpedToTemplate.nii.gz
fslmerge -a all_t2WarpedToTemplate P*_t2WarpedToTemplate.nii.gz
fslmerge -a all_gmWarpedToTemplate P*_gmWarpedToTemplate.nii.gz

./mean_nonzero_time.py all_t2WarpedToTemplate.nii.gz all_t2WarpedToTemplate_mean.nii.gz
./mean_nonzero_time.py all_t1WarpedToTemplate.nii.gz all_t1WarpedToTemplate_mean.nii.gz
ImageMath 3 all_t2WarpedToTemplate_mean_sharpened.nii.gz Sharpen all_t2WarpedToTemplate_mean.nii.gz
