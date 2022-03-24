#!/bin/bash

i=$1
T1DIR=../RawT1RadiologicalIsotropicN4BrainMask
T2DIR=../RawT2RadiologicalIsotropicN4BrainMask

#ImageMath 3 ${i}_t1_edge.nii.gz Canny ${i}_t1.nii.gz 3 0.1 0.7
#mageMath 3 ${i}_t1_laplacian.nii.gz Laplacian ${i}_t1.nii.gz 2 
#ThresholdImage 3 ${i}_t2.nii.gz ${i}_t2Otsu1.nii.gz Otsu 1
#ThresholdImage 3 ${i}_t2.nii.gz ${i}_t2Otsu2.nii.gz Otsu 2
ThresholdImage 3 ${i}_t2.nii.gz ${i}_t2Otsu3.nii.gz Otsu 3
ThresholdImage 3 ${i}_t2.nii.gz ${i}_t2Otsu4.nii.gz Otsu 4
#ThresholdImage 3 ${i}_t1.nii.gz ${i}_t1Otsu4.nii.gz Otsu 4

mri_binarize --i ${i}_dkt.nii.gz --o ${i}_dkt_background.nii.gz --match 0 258 --erode 1 --noverbose
mri_binarize --i ${i}_t2Otsu4.nii.gz --o ${i}_t2Otsu4Skull.nii.gz --match 1 --noverbose
mri_binarize --i ${i}_t2Otsu3.nii.gz --o ${i}_t2Otsu3Skull.nii.gz --match 1 2 --noverbose
fslcpgeom ${i}_t2.nii.gz ${i}_dkt_background.nii.gz
#ThresholdImage 3 ${i}_t2.nii.gz ${i}_t2Otsu1Background.nii.gz Otsu 1 ${i}_dkt_background.nii.gz
#ThresholdImage 3 ${i}_t2.nii.gz ${i}_t2Otsu2Background.nii.gz Otsu 2 ${i}_dkt_background.nii.gz
#ThresholdImage 3 ${i}_t2.nii.gz ${i}_t2Otsu3Background.nii.gz Otsu 3 ${i}_dkt_background.nii.gz
mri_binarize --i ${i}_t2Otsu1Background.nii.gz --o ${i}_t2Otsu1BackgroundSkull.nii.gz --match 2 --noverbose
./LaplaceFilter ${i}_t2.nii.gz ${i}_t2Laplacian.nii.gz
./LaplaceFilter ${i}_t1.nii.gz ${i}_t1Laplacian.nii.gz
mri_binarize --i ${i}_t2Laplacian.nii.gz --o ${i}_t2Laplacianmask.nii.gz --max -10 --noverbose
mri_binarize --i ${i}_t1Laplacian.nii.gz --o ${i}_t1Laplacianmask.nii.gz --max -10 --noverbose
mri_binarize --i ${i}_dkt.nii.gz --o ${i}_dkt_foreground.nii.gz --match 258 0 24 4 43 --inv --noverbose
#mri_binarize --i ${i}_dkt.nii.gz --o ${i}_dkt_background.nii.gz --match 258 0 --noverbose
mri_binarize --i ${i}_dkt.nii.gz --o ${i}_dkt_csf.nii.gz --match 24 4 43 --noverbose

TEMPLATEDIR=/home/addo/MCRIownCloud/deve2-chris.adamson/neonatal/DHCPBrainMaskAtlas

if [ ! -f "${i}_dhcp_reg1Warp.nii.gz" ]
then
	antsRegistration -v -d 3 -u 1 -w [ 0.025,0.975 ] --verbose 1 --float 1 \
	    --initial-moving-transform [ $TEMPLATEDIR/Finaltemplate1Padded.nii.gz,${i}_t1.nii.gz,1 ] \
	    --transform Rigid[ 0.1 ] --metric MI[ $TEMPLATEDIR/Finaltemplate1Padded.nii.gz,${i}_t1.nii.gz,1,32,Regular,0.8 ] --convergence [ 1000x500x250x100,1e-6,10 ] --shrink-factors 12x8x4x2 --smoothing-sigmas 4x3x2x1vox \
	    --transform Affine[ 0.1 ] --metric MI[ $TEMPLATEDIR/Finaltemplate1Padded.nii.gz,${i}_t1.nii.gz,1,32,Regular,0.8 ] --convergence [ 1000x500x250x100,1e-6,10 ] --shrink-factors 12x8x4x2 --smoothing-sigmas 4x3x2x1vox \
	    --transform SyN[0.1,3,0] --metric MI[ $TEMPLATEDIR/Finaltemplate0Padded.nii.gz,${i}_t2.nii.gz,1,32 ] --metric MI[ $TEMPLATEDIR/Finaltemplate1Padded.nii.gz,${i}_t1.nii.gz,1,32 ] --convergence [ 200x100x50x0,1e-6,10 ] --shrink-factors 6x4x2x1 --smoothing-sigmas 4x2x1x0vox \
	    --output ${i}_dhcp_reg
fi

antsApplyTransforms --dimensionality 3 --verbose \
    --input ${TEMPLATEDIR}/FinaltemplatePaddedRegMask.nii.gz \
    --reference-image ${i}_t1.nii.gz \
    --transform [${i}_dhcp_reg0GenericAffine.mat,1] \
    --transform ${i}_dhcp_reg1InverseWarp.nii.gz \
    --interpolation NearestNeighbor \
    --output ${i}_FinaltemplatePaddedRegMask.nii.gz

ImageMath 3 ${i}_FinaltemplatePaddedRegMask.nii.gz MD ${i}_FinaltemplatePaddedRegMask.nii.gz 2


#SKULLMEAN=`fslstats ${i}_t1.nii.gz -k ${i}_t2OtsuSkull.nii.gz -R | awk '{ print $2 }'`
#TISSUEMEAN=`fslstats ${i}_t1.nii.gz -k ${i}_dkt_foreground.nii.gz -m`
#CSFMEAN=`fslstats ${i}_t1.nii.gz -k ${i}_dkt_csf.nii.gz -m`

fslcpgeom ${i}_t1.nii.gz ${i}_dkt_background.nii.gz
#ThresholdImage 3 ${i}_t1.nii.gz ${i}_t1_background_otsu3.nii.gz Kmeans 3 ${i}_dkt_background.nii.gz
ImageMath 3 ${i}_t1_opened.nii.gz GO ${i}_t1.nii.gz 3
fslmaths ${i}_t1 -sub ${i}_t1_opened.nii.gz ${i}_t1_tophat.nii.gz 
ThresholdImage 3 ${i}_t1_tophat.nii.gz ${i}_t1_tophat_background_kmeans2.nii.gz Kmeans 2 ${i}_dkt_background.nii.gz

mri_binarize --i ${i}_t1_tophat_background_kmeans2.nii.gz --o ${i}_t1_tophat_background_kmeans2_mask.nii.gz --match 2 3
#ThresholdImage 3 ${i}_t1.nii.gz ${i}_t1_background_kmeans4.nii.gz Kmeans 4 ${i}_dkt_background.nii.gz &
#ThresholdImage 3 ${i}_t1.nii.gz ${i}_t1_background_kmeans5.nii.gz Kmeans 5 ${i}_dkt_background.nii.gz &
#ThresholdImage 3 ${i}_t1.nii.gz ${i}_t1_background_otsu4.nii.gz Otsu 4 ${i}_dkt_background.nii.gz &
#wait;
#fslmaths ${i}_t1_background_kmeans5 -thr 4 -bin ${i}_t1_background_kmeans5_mask
#mri_binarize --i ${i}_t1_background_kmeans5.nii.gz --o ${i}_t1_background_kmeans5_mask.nii.gz --min 4

./TopHatHysteresis $i
#./ComponentAreaFilter -a 10 ${i}_tophat_hysteresis.nii.gz ${i}_tophat_hysteresis.nii.gz 
#mri_binarize --i ${i}_dkt.nii.gz --o ${i}_dkt_background.nii.gz --match 0 258 --erode 1 --noverbose
mri_binarize --i ${i}_dkt.nii.gz --o ${i}_dkt_nottissue.nii.gz --match 0 258 --noverbose
ImageMath 3 ${i}_dkt_nottissue_opened.nii.gz MO ${i}_dkt_nottissue.nii.gz 4

#fslmaths ${i}_t2Otsu4Skull.nii.gz -add ${i}_t2Otsu3Skull.nii.gz -add ${i}_t2Otsu1BackgroundSkull.nii.gz -add ${i}_t1Laplacianmask.nii.gz -mas ${i}_dkt_background.nii.gz -bin -add ${i}_t1_tophat_background_kmeans2_mask -mas ${i}_FinaltemplatePaddedRegMask ${i}_t2OtsuSkull.nii.gz -odt char

if [ "$i" == "P04" ]
then
	fslmaths ${i}_t2Otsu4Skull.nii.gz -add ${i}_t2Otsu3Skull.nii.gz -add ${i}_t2Otsu1BackgroundSkull.nii.gz -add ${i}_t1_tophat_background_kmeans2_mask.nii.gz -mas ${i}_dkt_nottissue_opened.nii.gz -bin ${i}_t2OtsuSkull.nii.gz -odt char
	#./ComponentAreaFilter -a 50 ${i}_t2OtsuSkull.nii.gz ${i}_t2OtsuSkull.nii.gz

	./RetainP04CapMask P04
	fslmaths ${i}_t2OtsuSkull.nii.gz -mas ${i}_FinaltemplatePaddedRegMask -add ${i}_tokeep.nii.gz -bin -sub ${i}_toremovebump -thr 0 -bin ${i}_t2OtsuSkull.nii.gz

	#ImageMath 3 ${i}_t2OtsuSkull.nii.gz GetLargestComponent ${i}_t2OtsuSkull.nii.gz
else
	fslmaths ${i}_t2Otsu4Skull.nii.gz -add ${i}_t2Otsu3Skull.nii.gz -add ${i}_t2Otsu1BackgroundSkull.nii.gz -add ${i}_t1_tophat_background_kmeans2_mask.nii.gz -mas ${i}_FinaltemplatePaddedRegMask -mas ${i}_dkt_nottissue_opened.nii.gz -bin ${i}_t2OtsuSkull.nii.gz -odt char
fi
#slmaths ${i}_t2Otsu4Skull.nii.gz -add ${i}_t2Otsu3Skull.nii.gz -add ${i}_t2Otsu1BackgroundSkull.nii.gz -add ${i}_t2Laplacianmask.nii.gz -mas ${i}_dkt_background.nii.gz -bin  -mas ${i}_FinaltemplatePaddedRegMask ${i}_t2OtsuSkullNoTopHat.nii.gz -odt char
#./WatershedSkull $i
#./ReconstructionSkull $i
#./ComponentAreaFilter -a 10 ${i}_t2OtsuSkull.nii.gz ${i}_t2OtsuSkull.nii.gz
#./RemoveExternalAtCSF $i
#ImageMath 3 ${i}_t2_edge.nii.gz Canny ${i}_t2.nii.gz 3 0.1 0.7
#mri_binarize --i ${i}_t2_edge.nii.gz --o ${i}_t2_edge_dilated.nii.gz --match 1 --dilate 1
#mri_binarize --i ${i}_dkt.nii.gz --o ${i}_dkt_foreground.nii.gz --match 0 258 --inv --noverbose
#mri_binarize --i ${i}_dkt.nii.gz --o ${i}_dkt_background.nii.gz --match 0 258 --noverbose
#mri_binarize --i ${i}_dkt_foreground.nii.gz --o ${i}_dkt_foreground_dilated.nii.gz --match 1 --dilate 1 --noverbose

#fslmaths ${i}_t2_edge_dilated.nii.gz -mas ${i}_dkt_foreground_dilated.nii.gz -mas ${i}_dkt_background.nii.gz ${i}_t2_edge_to_remove.nii.gz
cp ${i}_t2OtsuSkull.nii.gz ${i}_skull_orig.nii.gz


#./ComponentAreaFilter -a 10 ${i}_t2OtsuSkullNoTopHat.nii.gz ${i}_t2OtsuSkullNoTopHat.nii.gz

#ImageMath 3 ${i}_t2OtsuSkull.nii.gz GetLargestComponent ${i}_t2OtsuSkull.nii.gz
#rm -f ${i}_t2Otsu4Skull.nii.gz ${i}_t2Otsu3Skull.nii.gz ${i}_t2Otsu1BackgroundSkull.nii.gz ${i}_t2Laplacianmask.nii.gz
#rm -f ${i}_t2Otsu3Background.nii.gz ${i}_t2Otsu2Background.nii.gz ${i}_t1Otsu3Background.nii.gz
#rm -f ${i}_t2Otsu[1234].nii.gz ${i}_t2OtsuSkullNoTopHat.nii.gz

#rm -f ${i}_tophat_hysteresis.nii.gz
#rm -f ${i}Otsu*
exit
#fslmaths ${i}_t1.nii.gz -edge ${i}_t1_edge.nii.gz
#mri_binarize --i ${i}_t1_laplacian.nii.gz --o ${i}_t1_laplacian_low.nii.gz --max 0.4
#fslmaths ${i}_t1.nii.gz -mul 0 ${i}_skull_manual.nii.gz -odt char
#exit
#PADAMOUNT=5
#ImageMath 3 ${i}_dkt_padded.nii.gz PadImage ${i}_dkt.nii.gz $PADAMOUNT
#ImageMath 3 ${i}_t1_padded.nii.gz PadImage ${i}_t1.nii.gz $PADAMOUNT
#ImageMath 3 ${i}_t2_padded.nii.gz PadImage ${i}_t1.nii.gz $PADAMOUNT
#
#mri_binarize --i ${i}_dkt_padded.nii.gz --o ${i}_skull_atropos_mask.nii.gz --match 0 85 --dilate 5
#fslcpgeom ${i}_t1_padded.nii.gz ${i}_skull_atropos_mask.nii.gz
#fslcpgeom ${i}_t1_padded.nii.gz ${i}_t2_padded.nii.gz
#
#Atropos -a ${i}_t2_padded.nii.gz -a ${i}_t1_padded.nii.gz -d 3 -o ${i}_atropos.nii.gz -x ${i}_skull_atropos_mask.nii.gz -i kmeans[ 5 ] -c [ 3,0.0 ] -k Gaussian -m [ 0.1,1x1x1 ] -r 1 --verbose 1
#fslmaths ${i}_atropos.nii.gz ${i}_atropos.nii.gz -odt char
#ImageMath 3 ${i}_atropos.nii.gz PadImage ${i}_atropos.nii.gz -${PADAMOUNT}
