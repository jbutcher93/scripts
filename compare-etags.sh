profile1=lightyear-shared-qa
profile2=lightyear-shared-stage

set +x # disable debugging

time_elapsed() {
  date1=$1
  date2=$(date)

  os_arch=$(uname -s)
  if [[ "$os_arch" = "Darwin" ]]; then
    timestamp1=$(date -j -f "%a %b %d %H:%M:%S %Z %Y" "$date1" "+%s")
    timestamp2=$(date -j -f "%a %b %d %H:%M:%S %Z %Y" "$date2" "+%s")
  else
    timestamp1=$(date -d "$date1" +%s)
    timestamp2=$(date -d "$date2" +%s)
  fi

  diff=$((timestamp2 - timestamp1))
  hours=$((diff / 3600))
  minutes=$(( (diff % 3600) / 60 ))
  seconds=$((diff % 60))

  echo "Time elapsed: $hours hours, $minutes minutes, $seconds seconds"
}

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
  date1=$(date)

  profile1_bucket=$(aws s3 ls --profile "$profile1" | grep s3-binaries-.*-us-east-1 | grep -v "^.*log.*" | awk '{print $3}')
  profile2_bucket=$(aws s3 ls --profile "$profile2" | grep s3-binaries-.*-us-east-1 | grep -v "^.*log.*" | awk '{print $3}')

  bootstrap_list=$(aws s3 ls --recursive s3://"$profile1_bucket" --profile $profile1 | grep bootstrap.zip | awk '{print $4}' | grep -v "bin/bootstrap")
  for zip in $bootstrap_list; do
    aws s3api head-object --bucket "$profile1_bucket" --profile "$profile1" --key "$zip" --query ETag --output text > etag1 &
    pid1=$!
    aws s3api head-object --bucket "$profile2_bucket" --profile "$profile2" --key "$zip" --query ETag --output text > etag2 &
    pid2=$!

    wait $pid1
    etag1_result=$?
    wait $pid2
    etag2_result=$?
    
    etag1=$(cat etag1)
    etag2=$(cat etag2)

    if [[ $etag1_result -eq 0 && $etag2_result -eq 0 ]]; then
      if [[ ! "$etag1" = "$etag2" ]]; then
        echo "not equal"
        echo -e "{bucket: $profile1_bucket; key: $zip; etag: $etag1}\n{bucket: $profile2_bucket; key: $zip; etag: $etag2}\n"
      fi
    else
      echo "An error occurred while fetching ETags"
    fi
  done

  time_elapsed "$date1"

  rm etag1 etag2
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