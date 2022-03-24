#!/usr/bin/env python3

import sys
import os
import nibabel
import numpy

if len(sys.argv) < 3:
    print("Usage: " + sys.argv[0] + " <infile> <outfile>")
    print("Computes mean over time only using non-zero voxels")
    quit()

inFileName = sys.argv[1]
outFileName = sys.argv[2]

if not os.path.isfile(inFileName):
    print("couldnt find input file")
    quit()

NII = nibabel.load(inFileName)
IMG = NII.get_fdata()

if IMG.ndim == 4:
    numNonZero = numpy.sum(IMG == 0, axis = 3)
    numNonZero[numNonZero == 0] = 1
    newIMG = numpy.single(numpy.sum(IMG, axis = 3) / numNonZero)
    outNII = nibabel.Nifti1Image(newIMG, affine = NII.affine)
    nibabel.save(outNII, outFileName)
else:
    print("image must be 4D")
