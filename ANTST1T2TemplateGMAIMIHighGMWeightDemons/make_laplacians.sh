#!/bin/bash

for i in `seq 0 1`
do
	for J in `seq 1 4`
	do
		ImageMath 3 Finaltemplate${i}Laplacian${J}.nii.gz Laplacian Finaltemplate${i}.nii.gz $J
	done
done
