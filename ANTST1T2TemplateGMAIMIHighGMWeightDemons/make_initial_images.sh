#!/bin/bash

# register all images to template using flirt

LAPREMDIR=$HOME/MCRIownCloud/deve2-chris.adamson/neonatal/LaPrem

TEMPLATE=P01

T=`tmpnam`

CSV=subjects.csv
rm -f $CSV

for i in `cat $LAPREMDIR/subjects.list.labelled`
do
    echo "${i}.nii.gz,${i}_t1.nii.gz,${i}.gm.mask.nii.gz," >> $CSV
    mri_convert $LAPREMDIR/freesurfer/$i/mri/norm.mgz ${i}_orig.nii.gz
    mri_convert $LAPREMDIR/freesurfer/$i/mri/ribbon.mgz ${i}_ribbon_orig.nii.gz
    cp ../../LabelledLaPrem/RawT1RadiologicalIsotropicN4/${i}.nii.gz ${i}_t1_orig.nii.gz
    #ResampleImageBySpacing 3 ${i}_orig.nii.gz ${i}.nii.gz 1 1 1 1 0 0
    #ResampleImageBySpacing 3 ${i}_ribbon_orig.nii.gz ${i}_ribbon.nii.gz 1 1 1 0 0 1
    mri_convert ${i}_orig.nii.gz ${i}.nii.gz
    mri_convert ${i}_ribbon_orig.nii.gz ${i}_ribbon.nii.gz
    mri_convert ${i}_t1_orig.nii.gz ${i}_t1.nii.gz
    mri_binarize --i ${i}_ribbon.nii.gz --o ${i}.gm.mask.nii.gz --match 3 42
    rm -f ${i}_orig.nii.gz ${i}_ribbon_orig.nii.gz ${i}_ribbon.nii.gz ${i}_t1_orig.nii.gz

done
