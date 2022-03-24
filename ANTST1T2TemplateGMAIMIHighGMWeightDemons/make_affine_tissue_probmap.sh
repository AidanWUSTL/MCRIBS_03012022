#!/bin/bash

for i in `cat ../subjects.list`
do
	#mri_mask -transfer 64 ${i}_dkt_with_skull_label.nii.gz ${i}_dkt.nii.gz ${i}_dkt_with_skull_label.nii.gz
	if [ "YES" == "NOS" ]
	then
	./GaussianLaplacian -s 1 ${i}_t2.nii.gz ${i}_t2_laplacian1.nii.gz 
	mri_convert ../freesurfer/$i/mri/ribbon.mgz ${i}_ribbon.nii.gz
		antsApplyTransforms -d 3 -v --output-data-type short \
			--transform Final${i}0GenericAffine.mat \
			--reference-image Finaltemplate0.nii.gz \
			--interpolation GenericLabel \
			--input ${i}_dkt.nii.gz \
			--output ${i}_dkt_to_template_affine.nii.gz &
		antsApplyTransforms -d 3 -v --output-data-type short \
			--transform Final${i}0GenericAffine.mat \
			--reference-image Finaltemplate0.nii.gz \
			--interpolation GenericLabel \
			--input ${i}_dkt_with_skull_label.nii.gz \
			--output ${i}_dkt_with_skull_label_to_template_affine.nii.gz &
		antsApplyTransforms -d 3 -v --output-data-type short \
			--transform Final${i}0GenericAffine.mat \
			--interpolation GenericLabel \
			--reference-image Finaltemplate0.nii.gz \
			--input ${i}_ribbon.nii.gz \
			--output ${i}_ribbon_to_template_affine.nii.gz &
		antsApplyTransforms -d 3 -v --output-data-type short \
			--transform Final${i}0GenericAffine.mat \
			--reference-image Finaltemplate0.nii.gz \
			--input ${i}_skull_orig.nii.gz \
			--output Final${i}SkullOrigWarpedToTemplateAffine.nii.gz &
		antsApplyTransforms -d 3 -v --output-data-type float \
			--transform Final${i}0GenericAffine.mat \
			--reference-image Finaltemplate0.nii.gz \
			--input ${i}_brain_mask.nii.gz \
			--output Final${i}BrainMaskWarpedToTemplateAffine.nii.gz &
		antsApplyTransforms -d 3 -v --output-data-type float \
			--transform Final${i}0GenericAffine.mat \
			--reference-image Finaltemplate0.nii.gz \
			--input ${i}_t2_laplacian1.nii.gz \
			--output ${i}_t2_laplacian1_to_template_affine.nii.gz &
	fi
	DKTIMAGES="$DKTIMAGES ${i}_dkt_to_template.nii.gz"
	DKTWSKULLIMAGES="$DKTWSKULLIMAGES ${i}_dkt_with_skull_label_to_template_affine.nii.gz"
	RIBBONIMAGES="$RIBBONIMAGES ${i}_ribbon_to_template_affine.nii.gz"

#fslmaths ${i}_t2 -mas ${i}_brain_mask ${i}_t2_brain &
#fslmaths ${i}_t1 -mas ${i}_brain_mask ${i}_t1_brain &
	#mri_binarize --i ${i}_dkt.nii.gz --o ${i}_reg_mask.nii.gz --min 1 --dilate 2 --noverbose
#mri_binarize --i ${i}_dkt.nii.gz --o ${i}_dkt_wm_lh.nii.gz --match 2 --noverbose &
#mri_binarize --i ${i}_dkt.nii.gz --o ${i}_dkt_wm_rh.nii.gz --match 41 --noverbose &
	#mri_binarize --i ${i}_dkt.nii.gz --o ${i}_dkt_csf.nii.gz --match 24 --noverbose
	#ImageMath 3 ${i}_t1_laplacian3.nii.gz Laplacian ${i}_t1.nii.gz 3 &
	#ImageMath 3 ${i}_t2_laplacian3.nii.gz Laplacian ${i}_t2.nii.gz 3 &
	wait;
	#CSFIMAGES="$CSFIMAGES ${i}_dkt_csf.nii.gz"
done

GMMATCH=
for j in `seq 1000 1035`
do
        GMMATCH="$GMMATCH $j `expr $j + 1000`"
done

ImageMath 3 FinaltemplateAffineDKTWithSkullMajority.nii.gz MajorityVoting $DKTWSKULLIMAGES

mri_binarize --i FinaltemplateAffineDKTMajority.nii.gz --o FinaltemplateAffineDKTMajorityCerebellumMask.nii.gz --match 90 91 93 75 76 --noverbose

fslmerge -a all_dkt $DKTWSKULLIMAGES
mri_binarize --i all_dkt.nii.gz --o all_dkt_csf_tissue.nii.gz --match 24 4 43 14 15
fslmaths all_dkt_csf_tissue.nii.gz -Tmean FinaltemplateAffineDKTTissueProbCSF.nii.gz

mri_binarize --i all_dkt.nii.gz --o all_dkt_gm_tissue.nii.gz --match $GMMATCH
fslmaths all_dkt_gm_tissue.nii.gz -Tmean FinaltemplateAffineDKTTissueProbGM.nii.gz

fslmerge -a all_t2_laplacian1 *_t2_laplacian1_to_template.nii.gz
mri_binarize --i all_t2_laplacian1.nii.gz --o all_t2_laplacian1_pos.nii.gz --min 0 --noverbose
fslmaths all_t2_laplacian1_pos.nii.gz -Tmean all_t2_laplacian1_pos_mean.nii.gz 
fslmaths all_t2_laplacian1_pos_mean.nii.gz -mas FinaltemplateAffineDKTMajorityCerebellumMask.nii.gz all_t2_laplacian1_pos_prob.nii.gz
fslmaths all_t2_laplacian1_pos_prob.nii.gz -add FinaltemplateAffineDKTTissueProbGM.nii.gz FinaltemplateAffineDKTTissueProbGM.nii.gz


exit
ImageMath 3 FinaltemplateDKTMajority.nii.gz MajorityVoting $DKTIMAGES
ImageMath 3 FinaltemplateDKTWithSkullMajority.nii.gz MajorityVoting $DKTWSKULLIMAGES
ImageMath 3 FinaltemplateRibbonMajority.nii.gz MajorityVoting $RIBBONIMAGES

GMMATCH=
for j in `seq 1000 1035`
do
        GMMATCH="$GMMATCH $j `expr $j + 1000`"
done

fslmerge -a all_dkt $DKTWSKULLIMAGES
fslmaths all_dkt -thr 24 -uthr 24 -bin -Tmean all_csfprob
mri_binarize --i all_csfprob.nii.gz --o all_csfprob_masked.nii.gz --min 0.2
ImageMath 3 FinaltemplateDKTCSF.nii.gz MC all_csfprob_masked.nii.gz 4


mri_binarize --i all_dkt.nii.gz --o all_dkt_csf.nii.gz --match 24
fslmaths all_dkt_csf.nii.gz -Tmean FinaltemplateDKTProbCSF.nii.gz

mri_binarize --i all_dkt.nii.gz --o all_dkt_gm_tissue.nii.gz --match $GMMATCH
fslmaths all_dkt_gm_tissue.nii.gz -Tmean FinaltemplateDKTTissueProbGM.nii.gz

rm -f all_csfprob.nii.gz all_csfprob_masked.nii.gz all_dkt_gm_tissue.nii.gz all_dkt_csf_tissue.nii.gz


fslmerge -a all_t2_laplacian1 *_t2_laplacian1_to_template.nii.gz
mri_binarize --i all_t2_laplacian1.nii.gz --o all_t2_laplacian1_pos.nii.gz --min 0 --noverbose
fslmaths all_t2_laplacian1_pos.nii.gz -Tmean all_t2_laplacian1_pos_mean.nii.gz 
fslmaths all_t2_laplacian1_pos_mean.nii.gz -mas FinaltemplateDKTMajorityCerebellumMask.nii.gz all_t2_laplacian1_pos_prob.nii.gz
fslmaths all_t2_laplacian1_pos_prob.nii.gz -add FinaltemplateDKTTissueProbGM.nii.gz FinaltemplateDKTTissueProbGM.nii.gz

mri_binarize --i FinaltemplateDKTMajority.nii.gz --o FinaltemplateDKTMajorityWMMask.nii.gz --match 2 41 --noverbose

mri_binarize --i FinaltemplateDKTMajority.nii.gz --o GMToRemove.nii.gz --match 9 48 13 52 12 51 11 50 4 43 28 60 $GMMATCH --dilate 2 --noverbose

fslmaths all_t2_laplacian1_pos_mean.nii.gz -mas FinaltemplateDKTMajorityWMMask.nii.gz all_t2_laplacian1_pos_prob_wm.nii.gz
fslmaths GMToRemove.nii.gz -mul -1 -add 1 -mul all_t2_laplacian1_pos_prob_wm.nii.gz all_t2_laplacian1_pos_prob_wm.nii.gz
#rm -f all_t2_laplacian1_pos.nii.gz all_t2_laplacian1.nii.gz P*_t2_laplacian1*.nii.gz
rm -f GMToRemove.nii.gz
fslmaths FinaltemplateDKTTissueProbGM.nii.gz -add all_t2_laplacian1_pos_prob_wm.nii.gz FinaltemplateDKTTissueProbGM.nii.gz
rm -f all_t2_laplacian1_pos.nii.gz all_t2_laplacian1.nii.gz

# remove the subcortical grey
#rm -f $DKTWSKULLIMAGES $DKTIMAGES
AverageImages 3 AllSkullOrigWarpedToTemplate.nii.gz 0 Final*SkullOrigWarpedToTemplate.nii.gz 

mri_binarize --i FinaltemplateDKTMajority.nii.gz --o FinaltemplateDKTMajorityForeground.nii.gz --match 0 258 --inv
fslmaths FinaltemplateDKTMajorityForeground.nii.gz -add AllSkullOrigWarpedToTemplate.nii.gz -thr 0.1 -bin FinalMask.nii.gz
ImageMath 3 FinalMask.nii.gz MC FinalMask.nii.gz 4
rm -f Final*SkullOrigWarpedToTemplate.nii.gz
fslmaths AllSkullOrigWarpedToTemplate.nii.gz -thr 0.5 -bin AllSkullOrigWarpedToTemplate.nii.gz

mri_binarize --i FinaltemplateDKTMajority.nii.gz --o FinaltemplateDKTMajorityLateralVentricles.nii.gz --match 4 43 --noverbose

#rm -f $DKTIMAGES $RIBBONIMAGES
fslmerge -a AllBrainMasks Final*BrainMaskWarpedToTemplate.nii.gz
fslmaths AllBrainMasks -Tmean FinaltemplateBrainProb
rm -f AllBrainMasks.nii.gz Final*BrainMaskWarpedToTemplate.nii.gz
mri_binarize --i FinaltemplateBrainProb.nii.gz --o FinaltemplateBrainMask.nii.gz --min 0.5 --noverbose
mri_binarize --i FinaltemplateDKTMajority.nii.gz --o FinaltemplateDKTMajorityCerebellumMask.nii.gz --match 90 91 93 75 76 --dilate 10 --noverbose
mri_mask FinaltemplateDKTMajorityCerebellumMask.nii.gz FinaltemplateBrainMask.nii.gz FinaltemplateDKTMajorityCerebellumMask.nii.gz
mri_binarize --i FinaltemplateDKTMajority.nii.gz --o FinaltemplateDKTMajorityCerebellumLabelMask.nii.gz --match 90 91 93 75 76 --noverbose

mri_binarize --i FinaltemplateDKTMajority.nii.gz --o FinaltemplateDKTMajorityCerebellumMidbrainMask.nii.gz --match 90 91 93 75 76 9 48 170 14 --dilate 10 --noverbose
mri_binarize --i FinaltemplateDKTMajority.nii.gz --o FinaltemplateDKTMajoritySubCorticalGreyMask.nii.gz --match 9 48 13 52 12 51 11 50 --noverbose
mri_binarize --i FinaltemplateDKTMajority.nii.gz --o FinaltemplateDKTMajorityGMMask.nii.gz --match $GMMATCH --noverbose

#ImageMath 3 FinaltemplateDKTMajorityGMMaskClosed.nii.gz MC FinaltemplateDKTMajorityGMMask.nii.gz 2
mri_binarize --i FinaltemplateDKTMajorityGMMask.nii.gz --o FinaltemplateDKTMajorityGMMaskClosed.nii.gz --match 1 --dilate 3 --erode 3
ImageMath 3 FinaltemplateDKTMajorityGMMaskClosedDT.nii.gz MaurerDistance FinaltemplateDKTMajorityGMMaskClosed.nii.gz
fslmaths FinaltemplateDKTMajorityGMMaskClosedDT.nii.gz -mul -1 -thr 0 FinaltemplateDKTMajorityGMMaskClosedDTPos.nii.gz

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

mri_binarize --i FinaltemplateDKTMajority.nii.gz --o FinaltemplateDKTMajority_reg_skullmask.nii.gz --match 91 75 76 90 93 258 165 24 0 170 --inv --dilate 9
mri_binarize --i FinaltemplateDKTMajority.nii.gz --o FinaltemplateDKTMajority_reg_skullmask_topbit.nii.gz --match 1028 2028 --noverbose
ImageMath 3 FinaltemplateDKTMajority_reg_skullmask_topbit.nii.gz MD FinaltemplateDKTMajority_reg_skullmask_topbit.nii.gz 20
fslmaths FinaltemplateDKTMajority_reg_skullmask_topbit.nii.gz -add FinaltemplateDKTMajority_reg_skullmask.nii.gz -mul Finaltemplate5.nii.gz Finaltemplate5Masked.nii.gz
fslmaths FinaltemplateDKTMajority_reg_skullmask_topbit.nii.gz -add FinaltemplateDKTMajority_reg_skullmask.nii.gz -mul FinaltemplateDKTCSF.nii.gz -bin FinaltemplateDKTCSFNoCerebellum.nii.gz
rm -f FinaltemplateDKTMajority_reg_skullmask_topbit.nii.gz Finaltemplate1Laplacian.nii.gz Finaltemplate0Laplacian.nii.gz


