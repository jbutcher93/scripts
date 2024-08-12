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

compare_etags() {
  profile1_buckets=$(aws s3 ls --profile "$profile1" | grep s3-binaries-* | grep -v "^.*log.*" | awk '{print $3}')
  profile2_buckets=$(aws s3 ls --profile "$profile2" | grep s3-binaries-* | grep -v "^.*log.*" | awk '{print $3}')

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

help() {
    cat <<EOT

A script to help compare etags on bootstrap.zip files in AWS s3 buckets between two profiles

Usage: ./compare-etags.sh [flags]

Flags:
    -a, --auth      Authenticate with SSO on given profiles
    -d, --debug     Enable debugging
    -h, --help      Help for script

EOT
    exit 0
}

main() {
  if [[ "$#" -eq 0 ]]; then
      compare_etags
  fi
  while [[ "$#" -gt 0 ]]; do
    case "$1" in 
    -a | --auth ) 
      auth
      ;;
    -d | --debug ) 
      debug
      ;;
    -h | --help ) 
      help
      ;;
    esac
    shift
  done
  compare_etags
}

main $@