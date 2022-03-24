#!/bin/bash

i=$1
T1DIR=../RawT1RadiologicalIsotropicN4BrainMask
T2DIR=../RawT2RadiologicalIsotropicN4BrainMask

#NINETYFIVET1=`fslstats $T1DIR/${i}.nii.gz -k ../RawT2RadiologicalIsotropicSkullStrip/${i}BrainExtractionMask.nii.gz -P 95`
#NINETYFIVET2=`fslstats $T2DIR/${i}.nii.gz -k ../RawT2RadiologicalIsotropicSkullStrip/${i}BrainExtractionMask.nii.gz -P 95`
#ImageMath 3 ${i}_t2.nii.gz WindowImage $T2DIR/${i}.nii.gz 0 $NINETYFIVET2 0 1000
#ImageMath 3 ${i}_t1.nii.gz WindowImage $T1DIR/${i}.nii.gz 0 $NINETYFIVET1 0 1000

RescaleNinetyFivePercentile -m ../RawDKTRadiologicalIsotropicSkullStrip/${i}BrainExtractionMask.nii.gz $T2DIR/${i}.nii.gz ${i}_t2.nii.gz
RescaleNinetyFivePercentile -m ../RawDKTRadiologicalIsotropicSkullStrip/${i}BrainExtractionMask.nii.gz $T1DIR/${i}.nii.gz ${i}_t1.nii.gz

fslmaths ${i}_t2.nii.gz ${i}_t2.nii.gz -odt short
fslmaths ${i}_t1.nii.gz ${i}_t1.nii.gz -odt short


ThresholdImage 3 ${i}_t1.nii.gz ${i}_t1Otsu2.nii.gz Otsu 2
ThresholdImage 3 ${i}_t2.nii.gz ${i}_t2Otsu2.nii.gz Otsu 2

if [ "${i}" != "P01" ]
then
	fslmaths ${i}_t1Otsu2.nii.gz -add ${i}_t2Otsu2.nii.gz -bin ${i}Otsu2 -odt char
else
	fslmaths ${i}_t2Otsu2.nii.gz -bin ${i}Otsu2 -odt char
	ImageMath 3 ${i}Otsu2.nii.gz MD ${i}Otsu2.nii.gz 2
fi
ImageMath 3 ${i}Otsu2Opened.nii.gz MO ${i}Otsu2.nii.gz 3
ImageMath 3 ${i}Otsu2Largest.nii.gz GetLargestComponent ${i}Otsu2Opened.nii.gz
ImageMath 3 ${i}Otsu2Largest.nii.gz MD ${i}Otsu2Largest.nii.gz 3

ROI=`fslstats ${i}Otsu2Largest -w`
echo $ROI > ${i}_roi.txt

GMMATCH=""

for j in `seq 1000 1035`
do
    GMMATCH="$GMMATCH $j"
    GMMATCH="$GMMATCH `expr $j + 1000`"
done

mri_binarize --i ../OrigLabelsToT2/${i}_dkt.nii.gz --o ${i}_gm.nii.gz --match $GMMATCH
mri_binarize --i ../OrigLabelsToT2/${i}_dkt.nii.gz --o ${i}_ventricles.nii.gz --match 14 15 4 43 31 63
mri_binarize --i ../OrigLabelsToT2/${i}_dkt.nii.gz --o ${i}_choroid.nii.gz --match 31 63
mri_binarize --i ../OrigLabelsToT2/${i}_dkt.nii.gz --o ${i}_cerebellum.nii.gz --match 91 93 90 75 76 
#mri_binarize --i ../OrigLabelsToT2/${i}_dkt.nii.gz --o ${i}_cc.nii.gz --match 192 
#mri_binarize --i ../OrigLabelsToT2/${i}_dkt.nii.gz --o ${i}_accumbens.nii.gz --match 26 58
#mri_binarize --i ../OrigLabelsToT2/${i}_dkt.nii.gz --o ${i}_putamen.nii.gz --match 12 51
#mri_binarize --i ../OrigLabelsToT2/${i}_dkt.nii.gz --o ${i}_pallidum.nii.gz --match 13 52
#mri_binarize --i ../OrigLabelsToT2/${i}_dkt.nii.gz --o ${i}_caudate.nii.gz --match 11 50

for j in t2 t1 gm ventricles cerebellum 
do
	fslroi ${i}_${j} ${i}_${j} $ROI
done
fslroi ../OrigLabelsToT2/${i}_dkt.nii.gz ${i}_dkt $ROI
fslroi ../RawDKTRadiologicalIsotropicSkullStrip/${i}BrainExtractionMask ${i}_brain_mask $ROI
#rm -f ${i}Otsu2Opened.nii.gz ${i}Otsu2Largest.nii.gz ${i}Otsu2Opened.nii.gz ${i}_t1Otsu2.nii.gz ${i}_t2Otsu2.nii.gz ${i}Otsu2.nii.gz

