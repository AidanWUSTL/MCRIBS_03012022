#!/bin/bash

TEMPLATE=P01

export SUBJECTS_DIR=`pwd`/../../LaPrem/freesurfer

mkdir -p $SUBJECTS_DIR/fsaverage/mri $SUBJECTS_DIR/fsaverage/surf
#mri_convert Finaltemplate0.nii.gz $SUBJECTS_DIR/fsaverage/mri/norm.mgz
#mri_convert Finaltemplate0.nii.gz $SUBJECTS_DIR/fsaverage/mri/T2.mgz
#mri_convert Finaltemplate1.nii.gz $SUBJECTS_DIR/fsaverage/mri/T1.mgz
#for i in `cat ../subjects.list`
##for i in P01 
#do
#	MATTRANSFORM=Final${i}0GenericAffine.mat
#	ConvertTransformFile 3 $MATTRANSFORM ${MATTRANSFORM%.mat}.txt 
#	c3d_affine_tool -ref Finaltemplate0.nii.gz -src ${i}_t2.nii.gz -itk $MATTRANSFORM -ras2fsl -o ${MATTRANSFORM%.mat}.fsl.mat
#	lta_convert --infsl ${MATTRANSFORM%.mat}.fsl.mat --src ${i}_t2.nii.gz --trg Finaltemplate0.nii.gz --outlta ${i}_to_template.lta
#	rm -f ${MATTRANSFORM%.mat}.txt
#
#	WARPTRANSFORM=Final${i}1Warp.nii.gz
#	mri_warp_convert --inlps $WARPTRANSFORM --outm3z ${WARPTRANSFORM%.nii.gz}.m3z -g $WARPTRANSFORM
#	
#	mkdir -p surfs_1_flirt/$i surfs_2_antslinear/$i surfs_3_template/$i
#	
#	antsApplyTransforms -d 3 -v \
#		--transform $MATTRANSFORM \
#		--reference-image Finaltemplate0.nii.gz \
#		--input ${i}_t2.nii.gz \
#		--output ${i}_t2Affine.nii.gz
#	
#	mri_transform -out_like Finaltemplate0.nii.gz ${i}_t2.nii.gz ${i}_to_template.lta ${i}_t2AffineFS.nii.gz 
#	for CURSURF in white inflated pial
#	do
#		for CURHEMI in lh rh
#		do
#			mris_transform $SUBJECTS_DIR/$i/surf/$CURHEMI.$CURSURF ${i}_to_template.lta surfs_2_antslinear/$i/$CURHEMI.$CURSURF
#			mris_convert --vol-geom Finaltemplate0.nii.gz surfs_2_antslinear/$i/$CURHEMI.$CURSURF surfs_2_antslinear/$i/$CURHEMI.$CURSURF
#			
#			if [ "$CURSURF" == "inflated" ]
#			then
#				cp surfs_2_antslinear/$i/$CURHEMI.$CURSURF $SUBJECTS_DIR/$i/surf/$CURHEMI.$CURSURF.ANTSTemplate
#			else
#				mris_transform surfs_2_antslinear/$i/$CURHEMI.$CURSURF ${WARPTRANSFORM%.nii.gz}.m3z surfs_3_template/$i/$CURHEMI.$CURSURF
#				mris_convert --vol-geom Finaltemplate0.nii.gz surfs_3_template/$i/$CURHEMI.$CURSURF surfs_3_template/$i/$CURHEMI.$CURSURF
#				cp surfs_3_template/$i/$CURHEMI.$CURSURF $SUBJECTS_DIR/$i/surf/$CURHEMI.$CURSURF.ANTSTemplate
#			fi
#			#cp surfs_2_antslinear/$i/$CURHEMI.$CURSURF ../freesurfer/$i/surf/$CURHEMI.$CURSURF.ANTSTemplate
#			
#			mri_surf2surf --srcsubject $i --sval-xyz $CURSURF.ANTSTemplate --trgsubject ico --trgicoorder 7 --srcsurfreg sphere.reg2 --tfmt surf --tval $SUBJECTS_DIR/$i/surf/$CURHEMI.$CURSURF.ANTSTemplate.resampled --tval-xyz Finaltemplate0.nii.gz --hemi $CURHEMI
#			
#			#use this one
#			#mri_surf2surf --srcsubject $i --sval-xyz $CURSURF.ANTSTemplate --trgsubject ico --trgicoorder 7 --srcsurfreg sphere.reg2 --tval $SUBJECTS_DIR/$i/surf/$CURHEMI.$CURSURF.ANTSTemplate.resampled --tval-xyz Finaltemplate0.nii.gz --hemi $CURHEMI
#			
#
##mri_surf2surf --srcsubject $i --sval-xyz $CURSURF.ANTSTemplate --trgsubject $TEMPLATE --surfreg sphere.reg2 --tval $SUBJECTS_DIR/$i/surf/$CURHEMI.$CURSURF.ANTSTemplate.resampled --tval-xyz Finaltemplate0.nii.gz --hemi $CURHEMI
#
#		done
#	done
#done
rm -fr surfs_1_flirt surfs_2_antslinear surfs_3_template *.m3z
P=`pwd`
for CURSURF in white inflated pial
do
	for CURHEMI in lh rh
	do
		CMD="./FSAverageSurfaces $SUBJECTS_DIR/fsaverage/surf/$CURHEMI.$CURSURF.nofix"
		for i in `cat ../subjects.list`
		do
			CMD="$CMD $SUBJECTS_DIR/$i/surf/$CURHEMI.$CURSURF.ANTSTemplate.resampled"
		done
		$CMD
		mris_remove_intersection $SUBJECTS_DIR/fsaverage/surf/$CURHEMI.$CURSURF.nofix $SUBJECTS_DIR/fsaverage/surf/$CURHEMI.$CURSURF
		rm -f $SUBJECTS_DIR/fsaverage/surf/$CURHEMI.$CURSURF.nofix
		mris_convert --vol-geom Finaltemplate0.nii.gz $SUBJECTS_DIR/fsaverage/surf/$CURHEMI.$CURSURF $SUBJECTS_DIR/fsaverage/surf/$CURHEMI.$CURSURF
		cd $SUBJECTS_DIR/fsaverage/surf
		mris_smooth -n 3 -nw -seed 1234 $CURHEMI.white $CURHEMI.smoothwm
		mris_curvature -w -a 10 ${CURHEMI}.smoothwm
		cp ${CURHEMI}.smoothwm.H ${CURHEMI}.curv

		cd $P
	done
done

