#!/bin/bash -x

mri_binarize --i FinaltemplateDKTWithSkullMajority.nii.gz --o FinaltemplateDKTWithSkullMajorityCSF.nii.gz --match 24 --noverbose
CSFMEAN=`fslstats Finaltemplate1.nii.gz -k FinaltemplateDKTWithSkullMajorityCSF.nii.gz -m`


fslmaths DKTTentorumMask -dilF -eroF -mul -1 -add 1 -mul Finaltemplate1 Finaltemplate1NoTentorum
fslmaths DKTTentorumMask -dilF -eroF -mul $CSFMEAN -add Finaltemplate1NoTentorum Finaltemplate1NoTentorum
