#!/bin/bash

ImageMath 3 FinaltemplateDKTMajorityGMMaskClosed.nii.gz MC FinaltemplateDKTMajorityGMMask.nii.gz 2
ImageMath 3 FinaltemplateDKTMajorityGMMaskClosed.nii.gz Neg FinaltemplateDKTMajorityGMMaskClosed.nii.gz

#mri_binarize --i FinaltemplateDKTMajorityGMMask.nii.gz --o FinaltemplateDKTMajorityGMMaskClosed.nii.gz --match 1 --dilate 3 --erode 3
ImageMath 3 FinaltemplateDKTMajorityGMMaskClosedDTPos.nii.gz D FinaltemplateDKTMajorityGMMaskClosed.nii.gz
