#!/bin/bash

for i in `tail -n+2 ../subjects.list`
do
	fslcpgeom ${i}_t2.nii.gz ${i}_ventricles.nii.gz

	mri_binarize --i ${i}_dkt.nii.gz --match 31 4 --o ${i}_dkt_lh_vent_mask_atropos.nii.gz
	mri_binarize --i ${i}_dkt.nii.gz --match 63 43 --o ${i}_dkt_rh_vent_mask_atropos.nii.gz
	
	fslcpgeom ${i}_t2.nii.gz ${i}_dkt_lh_vent_mask_atropos.nii.gz
	fslcpgeom ${i}_t2.nii.gz ${i}_dkt_rh_vent_mask_atropos.nii.gz
	#mri_binarize --i ${i}_dkt.nii.gz --match 31 --dilate 2 --o ${i}_dkt_choroid_lh_mask_atropos.nii.gz --mask ${i}_dkt_init_atropos.nii.gz
	#mri_binarize --i ${i}_dkt.nii.gz --match 63 --dilate 2 --o ${i}_dkt_choroid_rh_mask_atropos.nii.gz --mask ${i}_dkt_init_atropos.nii.gz
	Atropos -a ${i}_t2.nii.gz -d 3 -o ${i}_dkt_lh_vent_segmentation.nii.gz -x ${i}_dkt_lh_vent_mask_atropos.nii.gz -i kmeans[ 5 ] -c [ 3,0.0 ] -k Gaussian -m [ 0.1,1x1x1 ] -r 1 --verbose 1 
	Atropos -a ${i}_t2.nii.gz -d 3 -o ${i}_dkt_rh_vent_segmentation.nii.gz -x ${i}_dkt_rh_vent_mask_atropos.nii.gz -i kmeans[ 5 ] -c [ 3,0.0 ] -k Gaussian -m [ 0.1,1x1x1 ] -r 1 --verbose 1 
	fslmaths  ${i}_dkt_lh_vent_segmentation.nii.gz ${i}_dkt_lh_vent_segmentation.nii.gz -odt char
	fslmaths  ${i}_dkt_rh_vent_segmentation.nii.gz ${i}_dkt_rh_vent_segmentation.nii.gz -odt char
	
	mri_binarize --i ${i}_dkt_lh_vent_mask_atropos.nii.gz --o ${i}_dkt_lh_vent_mask_atropos_inside_mask.nii.gz --match 1 --erode 1 
	mri_binarize --i ${i}_dkt_lh_vent_segmentation.nii.gz --o ${i}_dkt_lh_vent_lower_classes.nii.gz --match 1 2 3 4 --mask ${i}_dkt_lh_vent_mask_atropos_inside_mask.nii.gz --dilate 4 --erode 4
	
	LabelClustersUniquely 3 ${i}_dkt_lh_vent_lower_classes.nii.gz ${i}_dkt_lh_vent_segmentation_init_choroid.nii.gz 2
	fslmaths ${i}_dkt_lh_vent_segmentation_init_choroid.nii.gz -bin ${i}_dkt_lh_vent_segmentation_init_choroid.nii.gz -odt char

	#mri_binarize --i ${i}_dkt_lh_vent_segmentation.nii.gz --o ${i}_dkt_lh_vent_segmentation_init_choroid.nii.gz --match 1
	#ImageMath 3 ${i}_dkt_lh_vent_segmentation_init_choroid.nii.gz GetLargestComponent ${i}_dkt_lh_vent_segmentation_init_choroid.nii.gz
	mri_binarize --i ${i}_dkt_lh_vent_segmentation_init_choroid.nii.gz --min 1 --o ${i}_dkt_lh_vent_segmentation_init_choroid_dilated.nii.gz --dilate 1
	mri_binarize --i ${i}_dkt_lh_vent_segmentation.nii.gz --match 1 2 --mask ${i}_dkt_lh_vent_segmentation_init_choroid_dilated.nii.gz --binval 1 --o ${i}_dkt_lh_vent_segmentation_init_choroid_to_add.nii.gz
	fslmaths ${i}_dkt_lh_vent_segmentation_init_choroid.nii.gz -add ${i}_dkt_lh_vent_segmentation_init_choroid_to_add.nii.gz -bin ${i}_dkt_lh_vent_segmentation_choroid.nii.gz -odt char
	ImageMath 3 ${i}_dkt_lh_vent_segmentation_choroid.nii.gz GetLargestComponent ${i}_dkt_lh_vent_segmentation_choroid.nii.gz
	mri_binarize --i ${i}_dkt_lh_vent_segmentation_choroid.nii.gz --min 1 --o ${i}_dkt_lh_vent_segmentation_choroid.nii.gz --binval 31
	
	mri_binarize --i ${i}_dkt_rh_vent_mask_atropos.nii.gz --o ${i}_dkt_rh_vent_mask_atropos_inside_mask.nii.gz --match 1 --erode 1 
	mri_binarize --i ${i}_dkt_rh_vent_segmentation.nii.gz --o ${i}_dkt_rh_vent_lower_classes.nii.gz --match 1 2 3 4 --mask ${i}_dkt_rh_vent_mask_atropos_inside_mask.nii.gz --dilate 4 --erode 4
	
	LabelClustersUniquely 3 ${i}_dkt_rh_vent_lower_classes.nii.gz ${i}_dkt_rh_vent_segmentation_init_choroid.nii.gz 2
	fslmaths ${i}_dkt_rh_vent_segmentation_init_choroid.nii.gz -bin ${i}_dkt_rh_vent_segmentation_init_choroid.nii.gz -odt char
	#mri_binarize --i ${i}_dkt_rh_vent_segmentation.nii.gz --o ${i}_dkt_rh_vent_segmentation_init_choroid_border.nii.gz --match 1 2
	#ImageMath 3 ${i}_dkt_rh_vent_segmentation_init_choroid.nii.gz GetLargestComponent ${i}_dkt_rh_vent_segmentation_init_choroid.nii.gz
	mri_binarize --i ${i}_dkt_rh_vent_segmentation_init_choroid.nii.gz --min 1 --o ${i}_dkt_rh_vent_segmentation_init_choroid_dilated.nii.gz --dilate 1
	mri_binarize --i ${i}_dkt_rh_vent_segmentation.nii.gz --match 1 2 --mask ${i}_dkt_rh_vent_segmentation_init_choroid_dilated.nii.gz --o ${i}_dkt_rh_vent_segmentation_init_choroid_to_add.nii.gz
	fslmaths ${i}_dkt_rh_vent_segmentation_init_choroid.nii.gz -add ${i}_dkt_rh_vent_segmentation_init_choroid_to_add.nii.gz -bin ${i}_dkt_rh_vent_segmentation_choroid.nii.gz -odt char
	ImageMath 3 ${i}_dkt_rh_vent_segmentation_choroid.nii.gz GetLargestComponent ${i}_dkt_rh_vent_segmentation_choroid.nii.gz
	mri_binarize --i ${i}_dkt_rh_vent_segmentation_choroid.nii.gz --min 1 --o ${i}_dkt_rh_vent_segmentation_choroid.nii.gz --binval 63
	cp ${i}_dkt.nii.gz ${i}_dkt_new.nii.gz
	
	mri_mask -transfer 31 ${i}_dkt.nii.gz ${i}_dkt_lh_vent_segmentation_choroid.nii.gz ${i}_dkt_new.nii.gz
	mri_mask -transfer 63 ${i}_dkt_new.nii.gz ${i}_dkt_rh_vent_segmentation_choroid.nii.gz ${i}_dkt_new.nii.gz

	#fslcpgeom ${i}_t2.nii.gz ${i}_dkt_vent_mask_atropos.nii.gz
	#fslcpgeom ${i}_t2.nii.gz ${i}_dkt_choroid_lh_mask_atropos.nii.gz
	#fslcpgeom ${i}_t2.nii.gz ${i}_dkt_choroid_rh_mask_atropos.nii.gz
		
	#Atropos -a ${i}_t2.nii.gz -d 3 -o ${i}_choroid_lh_segmentation.nii.gz -x  ${i}_dkt_choroid_lh_mask_atropos.nii.gz -i kmeans[ 5 ] -c [ 3,0.0 ] -k Gaussian -m [ 0.1,1x1x1 ] -r 1 --verbose 1 &
	#Atropos -a ${i}_t2.nii.gz -d 3 -o ${i}_choroid_rh_segmentation.nii.gz -x  ${i}_dkt_choroid_rh_mask_atropos.nii.gz -i kmeans[ 5 ] -c [ 3,0.0 ] -k Gaussian -m [ 0.1,1x1x1 ] -r 1 --verbose 1 &
	#wait;
	#Atropos -a ${i}_t2.nii.gz -d 3 -o ${i}_wm+ventricles_segmentation.nii.gz -x ${i}_dkt_rightvent_mask_atropos.nii.gz -i kmeans[ 5 ] -c [ 3,0.0 ] -k Gaussian -m [ 0.1,1x1x1 ] -r 1 --verbose 1
	#fslmaths ${i}_choroid_lh_segmentation.nii.gz ${i}_choroid_lh_segmentation.nii.gz -odt char
	#fslmaths ${i}_choroid_rh_segmentation.nii.gz ${i}_choroid_rh_segmentation.nii.gz -odt char
	
	#mri_binarize --i ${i}_choroid_lh_segmentation.nii.gz --o ${i}_choroid_lh_segmentation_add_to_ventricle.nii.gz --match 3 4 5 --dilate 1 --erode 1 --binval 4

	#mri_binarize --i ${i}_choroid_rh_segmentation.nii.gz --o ${i}_choroid_rh_segmentation_add_to_ventricle.nii.gz --match 3 4 5 --dilate 1 --erode 1 --binval 43
	#cp ${i}_dkt.nii.gz ${i}_dkt_new.nii.gz
	#mri_mask -transfer 4 ${i}_dkt_new.nii.gz ${i}_choroid_lh_segmentation_add_to_ventricle.nii.gz ${i}_dkt_new.nii.gz
	#mri_mask -transfer 43 ${i}_dkt_new.nii.gz ${i}_choroid_rh_segmentation_add_to_ventricle.nii.gz ${i}_dkt_new.nii.gz

	#mri_binarize --i ${i}_wm+ventricles_segmentation.nii.gz --o ${i}_wm+ventricles_segmentation_high.nii.gz --match 3 4 5
	#mri_binarize --i ${i}_dkt.nii.gz --match 43 --o ${i}_dkt_init_rightventricle.nii.gz --dilate 1
	#mri_mask ${i}_dkt_init_rightventricle.nii.gz ${i}_wm+ventricles_segmentation_high.nii.gz ${i}_dkt_init_rightventricle.nii.gz
#	exit
#	Atropos -a ${i}_t2.nii.gz -d 3 -o ${i}_ventricles_segmentation.nii.gz -x ${i}_ventricles.nii.gz -i kmeans[ 3 ] -c [ 3,0.0 ] -k Gaussian -m [ 0.1,1x1x1 ] -r 1 --verbose 1
#        fslmaths ${i}_ventricles_segmentation.nii.gz ${i}_ventricles_segmentation.nii.gz -odt char
#	mri_binarize --i ${i}_ventricles_segmentation.nii.gz --o ${i}_ventricles_eroded.nii.gz --min 1 --erode 1
#	mri_binarize --i ${i}_ventricles_segmentation.nii.gz --o ${i}_ventricles_segmentation_init_choroid.nii.gz --match 1
#	fslmaths ${i}_ventricles_segmentation_init_choroid.nii.gz -mas ${i}_ventricles_eroded.nii.gz ${i}_ventricles_segmentation_init_choroid.nii.gz -odt char
#	LabelClustersUniquely 3 ${i}_ventricles_segmentation_init_choroid.nii.gz ${i}_ventricles_segmentation_choroid.nii.gz 5
#	mri_binarize --i ${i}_ventricles_segmentation_choroid.nii.gz --match 2 --o ${i}_ventricles_segmentation_choroid_rh.nii.gz --dilate 1
#	mri_mask ${i}_ventricles_segmentation_choroid_rh.nii.gz ${i}_ventricles_segmentation_init_choroid.nii.gz ${i}_ventricles_segmentation_choroid_rh.nii.gz
#	mri_binarize --i ${i}_ventricles_segmentation_choroid_rh.nii.gz --o ${i}_ventricles_segmentation_choroid_rh.nii.gz --replace 1 63
#
#	mri_binarize --i ${i}_ventricles_segmentation_choroid.nii.gz --match 1 --o ${i}_ventricles_segmentation_choroid_lh.nii.gz --dilate 1
#	mri_mask ${i}_ventricles_segmentation_choroid_lh.nii.gz ${i}_ventricles_segmentation_init_choroid.nii.gz ${i}_ventricles_segmentation_choroid_lh.nii.gz
#	mri_binarize --i ${i}_ventricles_segmentation_choroid_lh.nii.gz  --o ${i}_ventricles_segmentation_choroid_lh.nii.gz --replace 1 31
done

