#!/bin/bash
# bright WM section
mri_binarize --i FinaltemplateDKTMajority.nii.gz --o FinaltemplateDKTMajorityGMMask.nii.gz --min 1000 --dilate 1
mri_binarize --i FinaltemplateDKTMajority.nii.gz --o FinaltemplateDKTMajorityWMMask.nii.gz --match 2 41
mri_binarize --i FinaltemplateDKTMajority.nii.gz --o FinaltemplateDKTMajorityLHWMMask.nii.gz --match 2
mri_binarize --i FinaltemplateDKTMajority.nii.gz --o FinaltemplateDKTMajorityRHWMMask.nii.gz --match 41

fslcpgeom Finaltemplate1.nii.gz FinaltemplateDKTMajorityWMMask.nii.gz
ThresholdImage 3 Finaltemplate1.nii.gz Finaltemplate1WMSegmentation.nii.gz Otsu 2 FinaltemplateDKTMajorityWMMask.nii.gz

fslmaths Finaltemplate1WMSegmentation.nii.gz -thr 3 -uthr 3 -mas FinaltemplateDKTMajorityLHWMMask.nii.gz -bin FinaltemplateBrightWMLH.nii.gz
ImageMath 3 FinaltemplateBrightWMLH.nii.gz GetLargestComponent FinaltemplateBrightWMLH.nii.gz
fslmaths Finaltemplate1WMSegmentation.nii.gz -thr 3 -uthr 3 -mas FinaltemplateDKTMajorityRHWMMask.nii.gz -bin FinaltemplateBrightWMRH.nii.gz
ImageMath 3 FinaltemplateBrightWMRH.nii.gz GetLargestComponent FinaltemplateBrightWMRH.nii.gz
fslmaths FinaltemplateBrightWMLH.nii.gz -add FinaltemplateBrightWMRH.nii.gz FinaltemplateBrightWM.nii.gz
fslmaths FinaltemplateDKTMajorityGMMask.nii.gz -dilF FinaltemplateDKTMajorityGMMaskDilated.nii.gz
fslmaths FinaltemplateDKTMajorityGMMaskDilated.nii.gz -mul -1 -add 1 -mas FinaltemplateBrightWM.nii.gz FinaltemplateBrightWM.nii.gz -odt char
mri_binarize --i FinaltemplateDKTMajority.nii.gz --o FinaltemplateDKTMajorityVentClosed.nii.gz --match 4 43 --dilate 7 --erode 7
fslmaths FinaltemplateDKTMajorityVentClosed.nii.gz -mul -1 -add 1 -mul FinaltemplateBrightWM.nii.gz FinaltemplateBrightWM.nii.gz
ComponentAreaFilter -a 400 FinaltemplateBrightWM.nii.gz FinaltemplateBrightWM.nii.gz

./GaussianLaplacian -s 1 Finaltemplate0.nii.gz Finaltemplate0Laplacian1.nii.gz
mri_binarize --i Finaltemplate0Laplacian1.nii.gz --o Finaltemplate0Laplacian1Neg.nii.gz --max 0
mri_binarize --i Finaltemplate0Laplacian1.nii.gz --o Finaltemplate0Laplacian1Pos.nii.gz --min 0 --mask FinaltemplateDKTMajorityWMMask.nii.gz

fslmaths FinaltemplateDKTMajorityGMMask.nii.gz -mul -1 -add 1 -mul Finaltemplate0Laplacian1Pos.nii.gz -add FinaltemplateBrightWM.nii.gz -bin FinaltemplateBrightWM.nii.gz -odt char

rm -f FinaltemplateBrightWMLH.nii.gz FinaltemplateBrightWMRH.nii.gz FinaltemplateDKTMajorityRHWMMask.nii.gz FinaltemplateDKTMajorityLHWMMask.nii.gz


