#!/bin/bash

#export ANTSPATH=/group/deve2/data/addo/ANTs/bin
#export PATH=$ANTSPATH:$PATH
#buildtemplateparallel.sh -d 3 -m 30x50x20 -o Final -r 1 -c 0 -i 4 -j 1 -n 0 -r 1 -s CC -t RA -z `pwd`/InitialTemplate.nii.gz P*.nii.gz V*.nii.gz
#buildtemplateparallel.sh -d 3 -m 30x50x20 -o Final -r 1 -c 0 -i 4 -j 1 -n 0 -r 0 -s MI -t RA -z `pwd`/InitialTemplate.nii.gz P*.nii.gz V*.nii.gz

#TEMPLATE=P02

#PADAMOUNT=5

#ImageMath 3 Initialtemplate0.nii.gz PadImage ${TEMPLATE}.nii.gz $PADAMOUNT
#ImageMath 3 Initialtemplate1.nii.gz PadImage ${TEMPLATE}_t1.nii.gz $PADAMOUNT
#ImageMath 3 Initialtemplate2.nii.gz PadImage ${TEMPLATE}.gm.mask.nii.gz $PADAMOUNT

#antsMultivariateTemplateConstruction2.sh -w 0.1x0.1x2x2x2x2x2x2x2x2 -a 0 -d 3 -k 10 -b 1 -v 8gb -c 0 -o `pwd`/Final -r 0 -y 0 -i 4 -j 2 -m MI -m MI -m DEMONS -m DEMONS -m DEMONS -m DEMONS -m DEMONS -m DEMONS -m DEMONS -m DEMONS -t SyN -n 0 -z Initialtemplate0.nii.gz -z Initialtemplate1.nii.gz -z Initialtemplate2.nii.gz -z Initialtemplate3.nii.gz -z Initialtemplate4.nii.gz -z Initialtemplate5.nii.gz -z Initialtemplate6.nii.gz -z Initialtemplate7.nii.gz -z Initialtemplate8.nii.gz -z Initialtemplate9.nii.gz subjects.csv
antsMultivariateTemplateConstruction2.sh -w 0.1x0.1x5x1x1x1 -e 1 -a 0 -d 3 -k 6 -b 1 -v 8gb -c 2 -o `pwd`/Final -r 0 -y 0 -i 9 -j 2 -m MI -m MI -m DEMONS -m DEMONS -m DEMONS -m DEMONS -t SyN -n 0 -z Initialtemplate0.nii.gz -z Initialtemplate1.nii.gz -z Initialtemplate2.nii.gz -z Initialtemplate3.nii.gz -z Initialtemplate4.nii.gz -z Initialtemplate5.nii.gz subjects.csv
#antsMultivariateTemplateConstruction2.sh -d 3 -b 1 -v 4gb -c 5 -o `pwd`/Final -f 4x2x1 -s 2x1x0vox -q 32x20x4 -r 0  -i 4 -j 1 -m CC -t SyN -n 0 `pwd`/P*.nii.gz `pwd`/V*.nii.gz
#antsMultivariateTemplateConstruction2.sh -d 3 -b 1 -v 4gb -o Final -r 0 -c 2 -i 4 -j `nproc` -m CC -t SyN -n 0 -l 0 -s 5x3x2x1x0 -f 10x6x4x2x1 -q 100x100x70x50x0 P*.nii.gz V*.nii.gz
