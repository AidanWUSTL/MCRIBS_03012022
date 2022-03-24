#!/bin/bash -x

for i in `cat ../subjects.list`
do
	mri_convert ../freesurfer/$i/mri/ribbon.mgz ${i}_ribbon.nii.gz
	antsApplyTransforms -d 3 -v --output-data-type short \
		--transform Final${i}1Warp.nii.gz \
		--transform Final${i}0GenericAffine.mat \
		--interpolation GenericLabel \
		--reference-image Finaltemplate0.nii.gz \
		--input ${i}_ribbon.nii.gz \
		--output ${i}_ribbon_to_template.nii.gz
	RIBBONIMAGES="$RIBBONIMAGES ${i}_ribbon_to_template.nii.gz"

done
ImageMath 3 FinaltemplateRibbonMajority.nii.gz MajorityVoting $RIBBONIMAGES
rm -f $RIBBONIMAGES

mri_binarize --i FinaltemplateRibbonMajority.nii.gz --o FinaltemplateRibbonMajorityGMClosed.nii.gz --match 3 42 --dilate 4 --erode 4 --noverbose


mri_binarize --i FinaltemplateRibbonMajority.nii.gz --o FinaltemplateRibbonMajorityWMLH.nii.gz --match 2 --noverbose
mri_binarize --i FinaltemplateRibbonMajority.nii.gz --o FinaltemplateRibbonMajorityWMRH.nii.gz --match 41 --noverbose

ImageMath 3 FinaltemplateRibbonMajorityOrigWMLHDT.nii.gz MaurerDistance FinaltemplateRibbonMajorityWMLH.nii.gz
ImageMath 3 FinaltemplateRibbonMajorityOrigWMRHDT.nii.gz MaurerDistance FinaltemplateRibbonMajorityWMRH.nii.gz
fslmaths FinaltemplateRibbonMajorityOrigWMLHDT.nii.gz -mul -1 FinaltemplateRibbonMajorityOrigWMLHDT.nii.gz
fslmaths FinaltemplateRibbonMajorityOrigWMRHDT.nii.gz -mul -1 FinaltemplateRibbonMajorityOrigWMRHDT.nii.gz

for i in `seq 1 4`
do
	mri_binarize --i FinaltemplateRibbonMajorityWMLH.nii.gz --o FinaltemplateRibbonMajorityWMLH.nii.gz --match 1 --dilate 1 --noverbose
	mri_binarize --i FinaltemplateRibbonMajorityWMRH.nii.gz --o FinaltemplateRibbonMajorityWMRH.nii.gz --match 1 --dilate 1 --noverbose
	fslmaths FinaltemplateRibbonMajorityGMClosed.nii.gz -mul -1 -add 1 -mul FinaltemplateRibbonMajorityWMLH.nii.gz FinaltemplateRibbonMajorityWMLH.nii.gz -odt char
	fslmaths FinaltemplateRibbonMajorityGMClosed.nii.gz -mul -1 -add 1 -mul FinaltemplateRibbonMajorityWMRH.nii.gz FinaltemplateRibbonMajorityWMRH.nii.gz -odt char
done

fslmaths FinaltemplateRibbonMajorityWMRH.nii.gz -mas FinaltemplateRibbonMajorityWMLH.nii.gz FinaltemplateRibbonMajorityWMToAdd.nii.gz
fslmaths FinaltemplateRibbonMajority.nii.gz -thr 1 -bin -mul -1 -add 1 -mas FinaltemplateRibbonMajorityWMToAdd.nii.gz FinaltemplateRibbonMajorityWMToAdd.nii.gz -odt char
fslmerge -a tmp FinaltemplateRibbonMajorityOrigWMLHDT.nii.gz FinaltemplateRibbonMajorityOrigWMRHDT.nii.gz
fslmaths tmp -Tmaxn tmpt
mri_binarize --i tmpt.nii.gz --o tmptoreplace.nii.gz --replace 0 2 --replace 1 41
mri_binarize --i FinaltemplateDKTMajority.nii.gz --o FinaltemplateDKTMajorityNotBrainstem.nii.gz --match 15 170 --inv --noverbose

fslmaths tmptoreplace.nii.gz -mas FinaltemplateRibbonMajorityWMToAdd.nii.gz -add FinaltemplateRibbonMajority.nii.gz -mas FinaltemplateDKTMajorityNotBrainstem.nii.gz FinaltemplateRibbonMajority.nii.gz
rm -f tmpt.nii.gz tmptoreplace.nii.gz FinaltemplateRibbonMajorityOrigWMLHDT.nii.gz FinaltemplateRibbonMajorityOrigWMRHDT.nii.gz FinaltemplateRibbonMajorityWMToAdd.nii.gz FinaltemplateRibbonMajorityWMRH.nii.gz FinaltemplateRibbonMajorityWMLH.nii.gz FinaltemplateRibbonMajorityGMClosed.nii.gz
