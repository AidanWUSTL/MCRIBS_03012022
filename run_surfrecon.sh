#!/bin/bash
#SBATCH --job-name=surfrecon
#SBATCH -n1
#SBATCH -N1
#SBATCH --time=24:00:00
#SBATCH --mem=2GB
#SBATCH --cpus-per-task=4
#SBATCH --constraint=SouthLevel1

#T=`tmpnam`

#export FREESURFER_HOME=/usr/local/freesurfer-7.1.1
#. $FREESURFER_HOME/SetUpFreeSurfer.sh
export SUBJECTS_DIR=`pwd`/freesurfer

if [ -z "$1" ]
then
	echo "Usage $0 <subjid> [options]"
	exit
fi

while (( "$#" ))
do
	case $1 in
		-noensureoutsidepial)
		NOENSURE=--deformablenoensurepialoutside
		;;
		-largeclose)
		LARGECLOSE=--deformablelargeclose
		;;
		*)
		SUBJID=$1
		;;
	esac
	shift;
done

#echo noensure $NOENSURE
#echo largeclose $LARGECLOSE
#exit
GMMATCH=
for j in `seq 1000 1035`
do
	GMMATCH="$GMMATCH $j `expr $j + 1000`"
done

#mri_convert $TISSUESEGDIROrigSkullStripNoTentorumVent/$1/${1}_labelfusionimage_dkt.nii.gz freesurfer/$1/mri/aseg.presurf.mgz
#mri_convert $TISSUESEGDIROrigSkullStripNoTentorumVent/$1/${1}_labelfusionimage_dkt.nii.gz freesurfer/${SUBJID}/mri/mcribs_dkt.nii.gz
#MCRIBReconAll --surfrecon --deformablet1only $NOENSURE -openmp 24 ${SUBJID}
export TISSUESEGDIR=/indata/TissueSegMCRIBS
export TEMPLATEDIR=/opt/MCRIBS/ANTST1T2TemplateGMAIMIHighGMWeightDemons
#export TEMPLATEDIR=/group/deve2/data/addo/neonatal/OrigImagesLabelledLaPrem/ANTST1T2TemplateGMAIMIHighGMWeightDemons
export OUTPUTPREFIX=${TISSUESEGDIR}/${SUBJID}/${SUBJID}

antsApplyTransforms -v -d 3 --reference-image ${OUTPUTPREFIX}_t2w_restore.nii.gz --input $TEMPLATEDIR/FinaltemplateRibbonMajority.nii.gz \
	--transform [${OUTPUTPREFIX}_skullstrip_affine0GenericAffine.mat,1] \
	--transform ${OUTPUTPREFIX}_skullstrip_reg1InverseWarp.nii.gz \
	--interpolation GenericLabel \
	--output-data-type short \
	--output ${OUTPUTPREFIX}_majority_dkt_compositereg_ribbon.nii.gz

if [ ! -f "${OUTPUTPREFIX}_labelfusionimage_dkt_antsinit_edited.nii.gz" ]
then
	cp ${OUTPUTPREFIX}_labelfusionimage_dkt_antsinit.nii.gz ${OUTPUTPREFIX}_labelfusionimage_dkt_antsinit_edited.nii.gz
fi
/opt/MCRIBS/PostProcessDKTLabelFusion $SUBJID
/opt/MCRIBS/FSToDrawEMLabels $TISSUESEGDIR/${SUBJID}/${SUBJID}_labelfusionimage_regions.nii.gz /indata/TissueSeg/${SUBJID}_all_labels_manedit.nii.gz
cp $TISSUESEGDIR/${SUBJID}/${SUBJID}_t2w_restore.nii.gz /indata/TissueSeg/${SUBJID}_t2w_restore.nii.gz
cp $TISSUESEGDIR/${SUBJID}/${SUBJID}_brain_mask.nii.gz /indata/TissueSeg/${SUBJID}_brain_mask.nii.gz

mkdir -p /indata/freesurfer/${SUBJID}/mri

mkdir -p /indata/SurfReconDeformable/${SUBJID}/temp

/opt/MCRIBS/MRIBinarize --i $TISSUESEGDIR/${SUBJID}/${SUBJID}_labelfusionimage_dkt_antsinit_edited.nii.gz --o /indata/SurfReconDeformable/${SUBJID}/temp/wm_force.nii.gz --match 18 54 4 43 31 63 --noverbose --binval -1

/opt/MCRIBS/MRIBinarize --i $TISSUESEGDIR/${SUBJID}/${SUBJID}_labelfusionimage_dkt_antsinit_edited.nii.gz --o /indata/SurfReconDeformable/${SUBJID}/temp/wm.nii.gz --match 2 41 --noverbose

/opt/MCRIBS/MRIBinarize --i $TISSUESEGDIR/${SUBJID}/${SUBJID}_labelfusionimage_dkt_antsinit_edited.nii.gz --o /indata/SurfReconDeformable/${SUBJID}/temp/wm_force_hippo.nii.gz --match 17 53 --noverbose --erode 1
fslmaths /indata/SurfReconDeformable/${SUBJID}/temp/wm_force_hippo.nii.gz -mul -1 -add /indata/SurfReconDeformable/${SUBJID}/temp/wm_force.nii.gz /indata/SurfReconDeformable/${SUBJID}/temp/wm_force.nii.gz
rm -f /indata/SurfReconDeformable/${SUBJID}/temp/wm_force_hippo.nii.gz

#./MRIBinarize --i $TISSUESEGDIR/${SUBJID}/${SUBJID}_labelfusionimage_dkt_antsinit_edited.nii.gz --o SurfReconDeformable/${SUBJID}/temp/pericalcarine.nii.gz --match 1021 2021 --dilate 2 --noverbose
#fslmaths SurfReconDeformable/${SUBJID}/temp/pericalcarine -mas SurfReconDeformable/${SUBJID}/temp/wm -bin SurfReconDeformable/${SUBJID}/temp/peri_wm.nii.gz
#for z in `seq 1 5`
#do
#	./MRIBinarize --i SurfReconDeformable/${SUBJID}/temp/peri_wm.nii.gz --o SurfReconDeformable/${SUBJID}/temp/peri_wm.nii.gz --match 1 --dilate 1 --noverbose
#	fslmaths SurfReconDeformable/${SUBJID}/temp/peri_wm -mas SurfReconDeformable/${SUBJID}/temp/wm -bin SurfReconDeformable/${SUBJID}/temp/peri_wm -odt char
#done
#fslmaths SurfReconDeformable/${SUBJID}/temp/peri_wm -mul -1 -add SurfReconDeformable/${SUBJID}/temp/wm_force.nii.gz SurfReconDeformable/${SUBJID}/temp/wm_force.nii.gz

/opt/MCRIBS/MRIBinarize --i $TISSUESEGDIR/${SUBJID}/${SUBJID}_t2w_restore_brain_dn_atropos3_priors_segmentation.nii.gz --o /indata/SurfReconDeformable/${SUBJID}/temp/prior_csf.nii.gz --match 3 --dilate --noverbose
fslmaths /indata/SurfReconDeformable/${SUBJID}/temp/prior_csf.nii.gz -mul -1 -add /indata/SurfReconDeformable/${SUBJID}/temp/wm_force.nii.gz /indata/SurfReconDeformable/${SUBJID}/temp/wm_force.nii.gz
rm -f /indata/SurfReconDeformable/${SUBJID}/temp/prior_csf.nii.gz

/opt/MCRIBS/MRIBinarize --i $TISSUESEGDIR/${SUBJID}/${SUBJID}_labelfusionimage_dkt_antsinit_edited.nii.gz --o /indata/SurfReconDeformable/${SUBJID}/temp/gm.nii.gz --match $GMMATCH --noverbose

/opt/MCRIBS/MRIBinarize --i $TISSUESEGDIR/${SUBJID}/${SUBJID}_labelfusionimage_dkt_antsinit_edited.nii.gz --o /indata/SurfReconDeformable/${SUBJID}/temp/cerebellum.nii.gz --match 91 93 --noverbose

fslmaths $TISSUESEGDIR/${SUBJID}/${SUBJID}_brain_mask -mul -1 -add 1 -add /indata/SurfReconDeformable/${SUBJID}/temp/cerebellum.nii.gz $TISSUESEGDIR/${SUBJID}/${SUBJID}_brain_mask_inv 
rm -f /indata/SurfReconDeformable/${SUBJID}/temp/cerebellum.nii.gz
ImageMath 3 $TISSUESEGDIR/${SUBJID}/${SUBJID}_brain_mask_dt.nii.gz D $TISSUESEGDIR/${SUBJID}/${SUBJID}_brain_mask_inv.nii.gz

#/MRIBinarize --i $TISSUESEGDIR/${SUBJID}/${SUBJID}_t2w_restore_brain_dn_atropos3_priors_segmentation.nii.gz --o SurfReconDeformable/${SUBJID}/temp/pial_force.nii.gz --match 0 1 --noverbose

fslmaths $TISSUESEGDIR/${SUBJID}/${SUBJID}_brain_mask_dt -uthr 4 -bin -mas /indata/SurfReconDeformable/${SUBJID}/temp/gm.nii.gz -div 2 -add /indata/SurfReconDeformable/${SUBJID}/temp/wm_force /indata/SurfReconDeformable/${SUBJID}/temp/wm_force

fslmaths $TISSUESEGDIR/${SUBJID}/${SUBJID}_brain_mask_dt -uthr 4 -bin -mas /indata/SurfReconDeformable/${SUBJID}/temp/gm.nii.gz -mul -1 -add $TISSUESEGDIR/${SUBJID}/${SUBJID}_brain_mask_inv /indata/SurfReconDeformable/${SUBJID}/temp/pial_force

/opt/MCRIBS/MRIBinarize --i $TISSUESEGDIR/${SUBJID}/${SUBJID}_labelfusionimage_dkt_antsinit_edited.nii.gz --o /indata/SurfReconDeformable/${SUBJID}/temp/cc_thalamus.nii.gz --match 192 9 48 --dilate 5 --erode 5 --noverbose
fslmaths /indata/SurfReconDeformable/${SUBJID}/temp/cc_thalamus.nii.gz -mul -1 /indata/SurfReconDeformable/${SUBJID}/temp/cc_thalamus.nii.gz 
fslmaths /indata/SurfReconDeformable/${SUBJID}/temp/wm_force -add /indata/SurfReconDeformable/${SUBJID}/temp/cc_thalamus.nii.gz -mul 2 /indata/SurfReconDeformable/${SUBJID}/temp/wm_force
rm -f /indata/SurfReconDeformable/${SUBJID}/temp/gm.nii.gz /indata/SurfReconDeformable/${SUBJID}/temp/wm.nii.gz /indata/SurfReconDeformable/${SUBJID}/temp/cc_thalamus.nii.gz $TISSUESEGDIR/${SUBJID}/${SUBJID}_brain_mask_inv.nii.gz $TISSUESEGDIR/${SUBJID}/${SUBJID}_brain_mask_dt.nii.gz

#./MRIBinarize --i $TISSUESEGDIR/${SUBJID}/${SUBJID}_labelfusionimage_dkt_antsinit_edited.nii.gz --o SurfReconDeformable/${SUBJID}/temp/wm_force_ventgm.nii.gz --match 1021 2021 --noverbose --dilate 3
#./MRIBinarize --i $TISSUESEGDIR/${SUBJID}/${SUBJID}_labelfusionimage_dkt_antsinit_edited.nii.gz --o SurfReconDeformable/${SUBJID}/temp/wm_force_vent.nii.gz --match 4 43 --noverbose --dilate 3
#./MRIBinarize --i $TISSUESEGDIR/${SUBJID}/${SUBJID}_t2w_restore_brain_dn_majority_gm_segmentation.nii.gz --o SurfReconDeformable/${SUBJID}/temp/wm_force_ventmask.nii.gz --match 2 --noverbose

#fslmaths SurfReconDeformable/${SUBJID}/temp/wm_force_ventgm.nii.gz -mul SurfReconDeformable/${SUBJID}/temp/wm_force_vent.nii.gz -mul SurfReconDeformable/${SUBJID}/temp/wm_force_ventmask.nii.gz -add SurfReconDeformable/${SUBJID}/temp/wm_force.nii.gz SurfReconDeformable/${SUBJID}/temp/wm_force.nii.gz
#rm -f SurfReconDeformable/${SUBJID}/temp/wm_force_vent.nii.gz SurfReconDeformable/${SUBJID}/temp/wm_force_ventgm.nii.gz

#./MRIBinarize --i $TISSUESEGDIR/${SUBJID}/${SUBJID}_labelfusionimage_dkt_antsinit_edited.nii.gz --o SurfReconDeformable/${SUBJID}/temp/wm_force_hippo.nii.gz --match 17 53 --noverbose
#fslmaths SurfReconDeformable/${SUBJID}/temp/wm_force_hippo.nii.gz -mul -0.1 -add SurfReconDeformable/${SUBJID}/temp/wm_force.nii.gz SurfReconDeformable/${SUBJID}/temp/wm_force.nii.gz

/opt/MCRIBS/MRIBinarize --i $TISSUESEGDIR/${SUBJID}/${SUBJID}_labelfusionimage_dkt_antsinit_edited.nii.gz --o /indata/SurfReconDeformable/${SUBJID}/temp/wm.nii.gz --match 2 41 --erode 1 --noverbose
fslmaths /indata/SurfReconDeformable/${SUBJID}/temp/wm.nii.gz -mul -1 -add /indata/SurfReconDeformable/${SUBJID}/temp/wm_force.nii.gz /indata/SurfReconDeformable/${SUBJID}/temp/wm_force.nii.gz
rm -f /indata/SurfReconDeformable/${SUBJID}/temp/wm.nii.gz
#mri_convert $TISSUESEGDIR/${SUBJID}/${SUBJID}_labelfusionimage_dkt_antsinit_edited.nii.gz freesurfer/${SUBJID}/mri/aseg.presurf.mgz
GMREPLACE=
for j in `seq 1000 1035`
do
       GMREPLACE="$GMREPLACE --replace $j 3"
       GMREPLACE="$GMREPLACE --replace `expr $j + 1000` 42"
done
/opt/MCRIBS/MRIBinarize --i $TISSUESEGDIR/${SUBJID}/${SUBJID}_labelfusionimage_dkt_antsinit_edited.nii.gz --o /indata/freesurfer/${SUBJID}/mri/aseg.presurf.mgz $GMREPLACE
mri_mask /indata/TissueSeg/${SUBJID}_t2w_restore.nii.gz /indata/TissueSeg/${SUBJID}_brain_mask.nii.gz /indata/freesurfer/${SUBJID}/mri/brainmask.mgz
mri_convert /indata/TissueSeg/${SUBJID}_t2w_restore.nii.gz /indata/freesurfer/${SUBJID}/mri/norm.mgz

NUMPROC=`nproc`
NUMTHREADS=`expr $NUMPROC / 2`
#NUMTHREADS=`expr $NUMPROC`
NUMTHREADS=`nproc`
NUMTHREADS=4
export VTK_MAX_THREADS=$NUMTHREADS
MCRIBReconAll --surfrecon $NOENSURE $LARGECLOSE -openmp $NUMTHREADS ${SUBJID}
#MCRIBReconAll --surfrecon $NOENSURE $LARGECLOSE -openmp 1 ${SUBJID}
#export VTK_MAX_THREADS=2
#MCRIBReconAll --surfrecon $NOENSURE -openmp 2 ${SUBJID}
#./MRIBinarize --i freesurfer/${SUBJID}/mri/ribbon.mgz --o freesurfer/${SUBJID}/mri/ribbon_mask.mgz --min 1 --noverbose
