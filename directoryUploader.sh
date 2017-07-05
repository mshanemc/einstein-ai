#!/bin/bash
token=$1
labelId=$2
datasetId=$3
MYPWD=$(pwd)

# Remove any spaces or commas...typical for iOS photo names, but examples API doesn't like them
for f in *\ *; do mv "$f" "${f// /_}"; done
for f in *\,*; do mv "$f" "${f//,/_}"; done

FILES=$MYPWD/*
for f in $FILES
do
  echo "Processing $f file..."
  curl -X POST -H "Authorization: Bearer $token" -H "Cache-Control: no-cache" -H "Content-Type: multipart/form-data" -F "name=$f" -F "labelId=$labelId" -F "data=@$f" https://api.metamind.io/v1/vision/datasets/$datasetId/examples # take action on each file. $f store current file name
  #cat $f
done