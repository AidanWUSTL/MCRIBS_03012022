#!/bin/bash

for i in `cat ../subjects.list`
do
	mv Final${i}_t2*0GenericAffine.mat Final${i}0GenericAffine.mat
	mv Final${i}_t2*1InverseWarp.nii.gz Final${i}1InverseWarp.nii.gz
	mv Final${i}_t2*1Warp.nii.gz Final${i}1Warp.nii.gz
done
