#!/bin/bash

ContextOutput=Contextual.csv
FaceOutput=Faces.csv

echo "Category,SubCategory,FileName" > ${ContextOutput}
for oneFile in `ls -1d ../Contextual/*/*/*jpg`
do
    echo ${oneFile}

    Category=`echo ${oneFile} | awk -F/ '{print $3}'`
    SubCategory=`echo ${oneFile} | awk -F/ '{print $4}'`
    FileName=`echo ${oneFile} | awk -F/ '{print $5}'`

    echo "${Category},${SubCategory},${FileName}" >> ${ContextOutput}
done

echo "Number,Gender,Expression,FileName" > ${FaceOutput}
for oneFile in `ls -1d ../Faces/*/*png`
do
    echo ${oneFile}

    FileName=`basename ${oneFile}`
    Number=`echo ${FileName} | awk -F_ '{print $1}'`
    Number=${Number/[FM]/}
    Gender=`echo ${oneFile} | awk -F/ '{print $3}'`
    Expression=`echo ${FileName} | awk -F_ '{print $2}'`

    echo "${Number},${Gender},${Expression},${FileName}" >> ${FaceOutput}
done

Rscript MergeRaceFace.R
