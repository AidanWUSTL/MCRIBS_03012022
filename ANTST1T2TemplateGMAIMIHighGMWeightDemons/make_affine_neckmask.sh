#!/bin/bash

for i in `cat ../subjects.list`
do
	#mri_mask -transfer 64 ${i}_dkt_with_skull_label.nii.gz ${i}_dkt.nii.gz ${i}_dkt_with_skull_label.nii.gz
	antsApplyTransforms -d 3 -v --output-data-type short \
		--transform Final${i}1Warp.nii.gz \
		--transform Final${i}0GenericAffine.mat \
		--reference-image Finaltemplate0.nii.gz \
		--interpolation GenericLabel \
		--input ${i}_dkt.nii.gz \
		--output ${i}_dkt_to_template.nii.gz
	DKTIMAGES="$DKTIMAGES ${i}_dkt_to_template.nii.gz"
	antsApplyTransforms -d 3 -v --output-data-type short \
		--transform Final${i}1Warp.nii.gz \
		--transform Final${i}0GenericAffine.mat \
		--reference-image Finaltemplate0.nii.gz \
		--interpolation GenericLabel \
		--input ${i}_dkt_with_skull_label.nii.gz \
		--output ${i}_dkt_with_skull_label_to_template.nii.gz
	DKTWSKULLIMAGES="$DKTWSKULLIMAGES ${i}_dkt_with_skull_label_to_template.nii.gz"

	antsApplyTransforms -d 3 -v --output-data-type float \
		--transform Final${i}1Warp.nii.gz \
		--transform Final${i}0GenericAffine.mat \
		--reference-image Finaltemplate0.nii.gz \
		--input ${i}_brain_mask.nii.gz \
		--output Final${i}BrainMaskWarpedToTemplate.nii.gz
	fslmaths ${i}_t2 -mas ${i}_brain_mask ${i}_t2_brain
	fslmaths ${i}_t1 -mas ${i}_brain_mask ${i}_t1_brain
	#mri_binarize --i ${i}_dkt.nii.gz --o ${i}_reg_mask.nii.gz --min 1 --dilate 2 --noverbose
	mri_convert ../freesurfer/$i/mri/ribbon.mgz ${i}_ribbon.nii.gz
	antsApplyTransforms -d 3 -v --output-data-type short \
		--transform Final${i}1Warp.nii.gz \
		--transform Final${i}0GenericAffine.mat \
		--interpolation GenericLabel \
		--reference-image Finaltemplate0.nii.gz \
		--input ${i}_ribbon.nii.gz \
		--output ${i}_ribbon_to_template.nii.gz
	RIBBONIMAGES="$RIBBONIMAGES ${i}_ribbon_to_template.nii.gz"
	antsApplyTransforms -d 3 -v --output-data-type short \
		--transform Final${i}1Warp.nii.gz \
		--transform Final${i}0GenericAffine.mat \
		--reference-image Finaltemplate0.nii.gz \
		--input ${i}_skull_orig.nii.gz \
		--output Final${i}SkullOrigWarpedToTemplate.nii.gz
	mri_binarize --i ${i}_dkt.nii.gz --o ${i}_dkt_wm_lh.nii.gz --match 2 --noverbose
	mri_binarize --i ${i}_dkt.nii.gz --o ${i}_dkt_wm_rh.nii.gz --match 41 --noverbose
	ImageMath 3 ${i}_t1_laplacian3.nii.gz Laplacian ${i}_t1.nii.gz 3
	ImageMath 3 ${i}_t2_laplacian3.nii.gz Laplacian ${i}_t2.nii.gz 3
done
ImageMath 3 FinaltemplateDKTMajority.nii.gz MajorityVoting $DKTIMAGES
ImageMath 3 FinaltemplateDKTWithSkullMajority.nii.gz MajorityVoting $DKTWSKULLIMAGES
ImageMath 3 FinaltemplateRibbonMajority.nii.gz MajorityVoting $RIBBONIMAGES
rm -f $DKTWSKULLIMAGES $DKTIMAGES
AverageImages 3 AllSkullOrigWarpedToTemplate.nii.gz 0 Final*SkullOrigWarpedToTemplate.nii.gz 

mri_binarize --i FinaltemplateDKTMajority.nii.gz --o FinaltemplateDKTMajorityForeground.nii.gz --match 0 258 --inv
fslmaths FinaltemplateDKTMajorityForeground.nii.gz -add AllSkullOrigWarpedToTemplate.nii.gz -thr 0.1 -bin FinalMask.nii.gz
ImageMath 3 FinalMask.nii.gz MC FinalMask.nii.gz 4
rm -f Final*SkullOrigWarpedToTemplate.nii.gz
fslmaths AllSkullOrigWarpedToTemplate.nii.gz -thr 0.5 -bin AllSkullOrigWarpedToTemplate.nii.gz

mri_binarize --i FinaltemplateDKTMajority.nii.gz --o FinaltemplateDKTMajorityLateralVentricles.nii.gz --match 4 43 --noverbose

rm -f $DKTIMAGES $RIBBONIMAGES
fslmerge -a AllBrainMasks Final*BrainMaskWarpedToTemplate.nii.gz
fslmaths AllBrainMasks -Tmean FinaltemplateBrainProb
rm -f AllBrainMasks.nii.gz Final*BrainMaskWarpedToTemplate.nii.gz
mri_binarize --i FinaltemplateBrainProb.nii.gz --o FinaltemplateBrainMask.nii.gz --min 0.5 --noverbose
mri_binarize --i FinaltemplateDKTMajority.nii.gz --o FinaltemplateDKTMajorityCerebellumMask.nii.gz --match 90 91 93 75 76 --dilate 10 --noverbose
mri_mask FinaltemplateDKTMajorityCerebellumMask.nii.gz FinaltemplateBrainMask.nii.gz FinaltemplateDKTMajorityCerebellumMask.nii.gz

mri_binarize --i FinaltemplateDKTMajority.nii.gz --o FinaltemplateDKTMajorityCerebellumMidbrainMask.nii.gz --match 90 91 93 75 76 9 48 170 14 --dilate 10 --noverbose
GMMATCH=

for j in `seq 1000 1035`
do  
	GMMATCH="$GMMATCH $j `expr $j + 1000`"
done
mri_binarize --i FinaltemplateDKTMajority.nii.gz --o FinaltemplateDKTMajorityGMMask.nii.gz --match $GMMATCH --noverbose

#@#ImageMath 3 FinaltemplateBrainProbRegistrationMask.nii.gz MD FinaltemplateBrainMask.nii.gz 10
ThresholdImage 3 Finaltemplate0.nii.gz Finaltemplate0Otsu2.nii.gz Otsu 2
ThresholdImage 3 Finaltemplate1.nii.gz Finaltemplate1Otsu2.nii.gz Otsu 2
fslmaths Finaltemplate0Otsu2.nii.gz -add Finaltemplate1Otsu2.nii.gz -bin FinaltemplateOtsu2.nii.gz
ImageMath 3 FinaltemplateOtsu2Filled.nii.gz FillHoles FinaltemplateOtsu2.nii.gz 2
ImageMath 3 FinaltemplateBrainProbRegistrationMask.nii.gz MC FinaltemplateOtsu2Filled.nii.gz 4
ImageMath 3 FinaltemplateBrainProbRegistrationMask.nii.gz MD FinaltemplateBrainProbRegistrationMask.nii.gz 1
ImageMath 3 FinaltemplateBrainProbRegistrationMask.nii.gz MO FinaltemplateBrainProbRegistrationMask.nii.gz 2
#fslmaths FinaltemplateBrainProbRegistrationMask.nii.gz -dilF FinaltemplateBrainProbRegistrationMask.nii.gz

rm -f FinaltemplateOtsu2.nii.gz FinaltemplateOtsu2Filled.nii.gz Finaltemplate1Otsu2.nii.gz Finaltemplate0Otsu2.nii.gz
fslmaths Finaltemplate0 -mas FinaltemplateBrainMask Finaltemplate0Brain
fslmaths Finaltemplate1 -mas FinaltemplateBrainMask Finaltemplate1Brain
#ImageMath 3 Finaltemplate0BrainLaplacian.nii.gz Laplacian Finaltemplate0Brain.nii.gz
#ImageMath 3 Finaltemplate1BrainLaplacian.nii.gz Laplacian Finaltemplate1Brain.nii.gz
mri_binarize --i Finaltemplate2.nii.gz --o FinalTemplateASegMajorityGM.nii.gz --min 0.7 --noverbose

fslmerge -a tmp1 Finaltemplate1P*.nii.gz
fslmerge -a tmp5 Finaltemplate5P*.nii.gz
fslmaths tmp1 -bin -Tmean -mul 10 tmpsum
fslmaths tmp5 -Tmean -mul 10 -div tmpsum -nan Finaltemplate5.nii.gz
ImageMath 3 Finaltemplate5.nii.gz Sharpen Finaltemplate5.nii.gz
rm -f tmp1.nii.gz tmp5.nii.gz tmpmean.nii.gz tmpsum.nii.gz

for i in `seq 0 1`
do
	fslmerge -a tmp Finaltemplate${i}P*.nii.gz
	fslmaths tmp -bin -Tmean -mul 10 tmpsum
	fslmaths tmp -Tmean -mul 10 -div tmpsum -nan Finaltemplate${i}.nii.gz
	ImageMath 3 Finaltemplate${i}.nii.gz Sharpen Finaltemplate${i}.nii.gz
	rm -f tmp.nii.gz tmpmean.nii.gz tmpsum.nii.gz
done
for i in `seq 2 4`
do
	AverageImages 3 Finaltemplate${i}.nii.gz 0 Finaltemplate${i}P*.nii.gz
done
for i in `seq 0 5`
do
	fslmaths Finaltemplate${i} -mas FinalMask Finaltemplate${i}
done
ImageMath 3 Finaltemplate0Laplacian.nii.gz Laplacian Finaltemplate0.nii.gz 1 1
ImageMath 3 Finaltemplate1Laplacian.nii.gz Laplacian Finaltemplate1.nii.gz 1 1

