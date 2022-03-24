#!/bin/bash -x

TARGET=P02

T1DIR=../RawT1RadiologicalIsotropicN4BrainMask
T2DIR=../RawT2RadiologicalIsotropicN4BrainMask

mkdir -p InitialAffineWarps

T=`mktemp`
rm -f $T

# rescale the images so that the 95th percentile in the brain matches

rm -f .commands
for i in `cat ../subjects.list`
do
	echo "./make_initial_template_init_crop.sh $i" >> .commands
	#echo "${i}_t2.nii.gz,${i}_t1.nii.gz,${i}_gm.nii.gz,${i}_ventricles.nii.gz,${i}_cerebellum.nii.gz,${i}_cc.nii.gz,${i}_accumbens.nii.gz,${i}_putamen.nii.gz,${i}_pallidum.nii.gz,${i}_caudate.nii.gz" >> $T
	echo "${i}_t2.nii.gz,${i}_t1.nii.gz,${i}_gm.nii.gz,${i}_ventricles.nii.gz,${i}_cerebellum.nii.gz,${i}_skull_orig.nii.gz" >> $T
done
#parallel -j10 --ungroup < .commands
rm -f .commands
mv $T subjects.csv
PADAMOUNT=30

ORIGX=`fslsize ${TARGET}_t1 | grep -e "^dim1" | awk '{ print $2 }'`
ORIGY=`fslsize ${TARGET}_t1 | grep -e "^dim2" | awk '{ print $2 }'`
ORIGZ=`fslsize ${TARGET}_t1 | grep -e "^dim3" | awk '{ print $2 }'`
echo $ORIGX $ORIGY $ORIGZ

ImageMath 3 ${TARGET}_t2Padded1.nii.gz PadImage ${TARGET}_t2.nii.gz $PADAMOUNT
ImageMath 3 ${TARGET}_t1Padded1.nii.gz PadImage ${TARGET}_t1.nii.gz $PADAMOUNT

fslroi ${TARGET}_t2Padded1 ${TARGET}_t2Padded `expr $PADAMOUNT - 5` `expr $PADAMOUNT - 25 + $ORIGX + $PADAMOUNT - 25` `expr $PADAMOUNT - 5` `expr $PADAMOUNT - 25 + $ORIGY + $PADAMOUNT - 25` `expr $PADAMOUNT - 5` `expr $ORIGZ + $PADAMOUNT - 25 + $PADAMOUNT`
fslroi ${TARGET}_t1Padded1 ${TARGET}_t1Padded `expr $PADAMOUNT - 5` `expr $PADAMOUNT - 25 + $ORIGX + $PADAMOUNT - 25` `expr $PADAMOUNT - 5` `expr $PADAMOUNT - 25 + $ORIGY + $PADAMOUNT - 25` `expr $PADAMOUNT - 5` `expr $ORIGZ + $PADAMOUNT - 25 + $PADAMOUNT`

imrm ${TARGET}_t2Padded1
imrm ${TARGET}_t1Padded1
IMAGES="t2
t1
gm
ventricles
cerebellum
skull_orig"

for i in `cat ../subjects.list`
do
	#antsRegistrationSyN.sh -d 3 -f ${TARGET}_t1Padded.nii.gz -m ${i}_t1.nii.gz -o InitialAffineWarps/${i}RegToTarget -n `nproc` -t a -p f
	#rm -f InitialAffineWarps/${i}*Warped.nii.gz
	
	for j in $IMAGES
	do
		antsApplyTransforms -d 3 -v --output-data-type float \
			--transform InitialAffineWarps/${i}RegToTarget0GenericAffine.mat \
			--reference-image ${TARGET}_t2Padded.nii.gz \
			--input ${i}_${j}.nii.gz \
			--output Initial${i}_${j}.nii.gz &
	done
    wait;
done
I=0

# don't put P04 in the initial skull 
mv InitialP04_skull_orig.nii.gz InitialP04_skull_orig_unused.nii.gz
mv InitialP04_t1.nii.gz InitialP04_t1_unused.nii.gz
mv InitialP04_t2.nii.gz InitialP04_t2_unused.nii.gz
for i in $IMAGES
do
	fslmerge -a all_$i.nii.gz Initial*_$i.nii.gz &
	I=`expr $I + 1`
done
wait;
I=0
for i in $IMAGES
do
	fslmaths all_$i.nii.gz -Tmean Initialtemplate${I}.nii.gz &
	I=`expr $I + 1`
done
wait;

for i in $IMAGES
do
    imrm all_$i.nii.gz
done
rm -f InitialP*
#AverageImages 3 Initialtemplate1_tmp.nii.gz 0 Initial*_t1.nii.gz
#AverageImages 3 Initialtemplate0_tmp.nii.gz 0 Initial*_t2.nii.gz
#AverageImages 3 Initialtemplate2_tmp.nii.gz 0 Initial*_gm.nii.gz


#ImageMath 3 Initialtemplate0.nii.gz PadImage Initialtemplate0_tmp.nii.gz $PADAMOUNT
#ImageMath 3 Initialtemplate1.nii.gz PadImage Initialtemplate1_tmp.nii.gz $PADAMOUNT
#ImageMath 3 Initialtemplate2.nii.gz PadImage Initialtemplate2_tmp.nii.gz $PADAMOUNT
exit
ImageMath 3 Initialtemplate0.nii.gz Sharpen Initialtemplate0.nii.gz &
ImageMath 3 Initialtemplate1.nii.gz Sharpen Initialtemplate1.nii.gz &
wait;
ThresholdImage 3 Initialtemplate0.nii.gz Initialtemplate0Otsu2.nii.gz Otsu 2
#fslstats Initialtemplate0Otsu2.nii.gz -w
ThresholdImage 3 Initialtemplate1.nii.gz Initialtemplate1Otsu2.nii.gz Otsu 2
#fslstats Initialtemplate1Otsu2.nii.gz -w
fslmaths Initialtemplate0Otsu2.nii.gz -add Initialtemplate1Otsu2.nii.gz -bin InitialtemplateOtsu2.nii.gz
ImageMath 3 InitialtemplateOtsu2Largest.nii.gz GetLargestComponent InitialtemplateOtsu2.nii.gz
fslmaths InitialtemplateOtsu2Largest.nii.gz -dilF InitialtemplateOtsu2Largest.nii.gz -odt char
ROI=`fslstats InitialtemplateOtsu2Largest.nii.gz -w`
fslroi Initialtemplate0 Initialtemplate0Cropped $ROI &
fslroi Initialtemplate1 Initialtemplate1Cropped $ROI &
fslroi Initialtemplate2 Initialtemplate2Cropped $ROI &
fslroi Initialtemplate3 Initialtemplate3Cropped $ROI &
fslroi Initialtemplate4 Initialtemplate4Cropped $ROI &
fslroi Initialtemplate5 Initialtemplate5Cropped $ROI &
wait;
ImageMath 3 Initialtemplate0.nii.gz PadImage Initialtemplate0Cropped.nii.gz $PADAMOUNT &
ImageMath 3 Initialtemplate1.nii.gz PadImage Initialtemplate1Cropped.nii.gz $PADAMOUNT &
ImageMath 3 Initialtemplate2.nii.gz PadImage Initialtemplate2Cropped.nii.gz $PADAMOUNT &
ImageMath 3 Initialtemplate3.nii.gz PadImage Initialtemplate3Cropped.nii.gz $PADAMOUNT &
ImageMath 3 Initialtemplate4.nii.gz PadImage Initialtemplate4Cropped.nii.gz $PADAMOUNT &
ImageMath 3 Initialtemplate5.nii.gz PadImage Initialtemplate5Cropped.nii.gz $PADAMOUNT &
wait;
rm Initialtemplate*Cropped* InitialtemplateOtsu2Largest.nii.gz Initialtemplate1Otsu2.nii.gz Initialtemplate0Otsu2.nii.gz

