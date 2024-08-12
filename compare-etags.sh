profile1=lightyear-shared-qa
profile2=lightyear-shared-stage

set +x # disable debugging

auth() {
  echo "Authenticating with SSO"
  aws sso login --profile "$profile1"
  aws sso login --profile "$profile2"
}

debug() {
  echo "Enabled debugging"
  set -x # enable debugging
}

usage() {
  profile1_buckets=$(aws s3 ls --profile "$profile1" | grep s3-binaries-* | grep -v "^.*log.*" | awk '{print $3}')
  profile2_buckets=$(aws s3 ls --profile "$profile2" | grep s3-binaries-* | grep -v "^.*log.*" | awk '{print $3}')

  echo $profile1_buckets
  echo $profile2_buckets

  for bucket1 in $profile1_buckets; do
      bootstrap_list=$(aws s3 ls --recursive s3://"$bucket1" --profile $profile1 | grep bootstrap.zip | awk '{print $4}')
    for bucket2 in $profile2_buckets; do
      for zip in $bootstrap_list; do
        etag1=$(aws s3api head-object --bucket "$bucket1" --profile "$profile1" --key "$zip" --query ETag --output text)
        etag2=$(aws s3api head-object --bucket "$bucket2" --profile "$profile2" --key "$zip" --query ETag --output text)
        echo -e "{bucket: $bucket1; key: $zip; etag: $etag1}\n{bucket: $bucket2; key: $zip; etag: $etag2}"
        if [[ ! "$etag1" = "$etag2" ]]; then
          echo "not equal"
        else
          echo "equal"
        fi
      done
    done
  done
}

main() {
  if [[ "$#" -eq 0 ]]; then
      usage
  fi
  while [[ "$#" -gt 0 ]]; do
    case "$1" in 
    -a | --auth ) 
      auth
      ;;
    -d | --debug ) 
      debug
      ;;
    esac
    shift
  done
  usage
}

main $@