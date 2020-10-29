#!/bin/bash
MODULE_FILE_NAME=modules.txt
S3_BUCKET_NAME=asdkfjfadj
CNT=0
cat ${MODULE_FILE_NAME} |grep -v "^#" > module_list.txt
while IFS= read -r line; do
  if [[ -z ${line} ]]; then
    continue
  fi
  let CNT=$CNT+1
  Layer_Name=$(echo "$line" |awk -F":" '{print$1}')
  Layer_Description=$(echo "$line" |awk -F":" '{print$2}')
  Pkg_Name=$(echo "$line" |awk -F":" '{print$3}')
  echo "Layer_Name: ${Layer_Name}"
  echo "Layer_Description: ${Layer_Description}"
  echo "Package_Name: ${Pkg_Name}"

  if [[ -z "${Layer_Name// }"  ]] || [[ -z "${Layer_Description// }"  ]] || [[ -z "${Pkg_Name// }"  ]]; then
    echo "Line number $CNT: LayerName, Description or PackageName cannot be blank"
    exit 1
  fi
  echo ${Pkg_Name} |tr , '\n' > ${Layer_Name}_Requirements.txt

    rm -rf python 2>/dev/null
    mkdir python
    echo "Installing packages"
    pip install -r ${Layer_Name}_Requirements.txt -t python/
    echo "Zipping packages"
    zip -r ${Layer_Name}_python.zip python
    ls -lrt
    echo "Pushing to s3 Bucket"
    aws s3 cp ${Layer_Name}_python.zip s3://${S3_BUCKET_NAME}/

    aws lambda publish-layer-version \
      --layer-name ${Layer_Name} \
      --description "${Layer_Description}"  \
      --license-info "MIT" \
      --content S3Bucket=${S3_BUCKET_NAME},S3Key=${Layer_Name}_python.zip \
      --compatible-runtimes python3.6 python3.7
 done < module_list.txt


# for layername in $(cat ${MODULE_FILE_NAME} |awk -F":" '{print $1}' |sort -u)
#   do
#   echo "Working on Layer: ${layername}"
#   cat ${MODULE_FILE_NAME} |awk -F":" '$1=="'$layername'" {print $2}' > ${layername}_Requirements.txt
#   rm -rf python 2>/dev/null
#   mkdir python
#   pip install -r ${layername}_Requirements.txt -t python/
#   zip -r ${layername}_python.zip python
#   aws s3 cp ${layername}_python.zip s3://${S3_BUCKET_NAME}/

#   aws lambda publish-layer-version \
#     --layer-name ${layername} \
#     --description "My Python layer" \
#     --license-info "MIT" \
#     --content S3Bucket=${S3_BUCKET_NAME},S3Key=${layername}_python.zip \
#     --compatible-runtimes python3.6 python3.7
#   done