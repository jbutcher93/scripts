#!/usr/bin/env bash

# This script is used to get the count of WhatsApp messages between users.

# Create the following environment variables:
# 1. "WAAPI_TOKEN" with the value of your WhatsApp API token.
# 2. "WAAPI_INSTANCE_ID" with the value of your WhatsApp API instance ID.

# curl --request GET \
#      --url "https://waapi.app/api/v1/instances/$WAAPI_INSTANCE_ID/client/me" \
#      --header "accept: application/json" \
#      --header "authorization: Bearer $WAAPI_TOKEN" \

curl --request POST \
     --url "https://waapi.app/api/v1/instances/$WAAPI_INSTANCE_ID/client/action/get-number-id" \
     --header 'accept: application/json' \
     --header "authorization: Bearer $WAAPI_TOKEN" \
     --header 'content-type: application/json' \
     --data '{"number": "2023779702"}' | jq .

messages=$(curl --request POST \
     --url "https://waapi.app/api/v1/instances/$WAAPI_INSTANCE_ID/client/action/fetch-messages" \
     --header 'accept: application/json' \
     --header "authorization: Bearer $WAAPI_TOKEN" \
     --header 'content-type: application/json' \
     --data '
     {
        "chatId": "12023779702@c.us",
        "limit": "200"
      }
      ' | jq -c '.data.data[]') # -c is used to output each object in the array on a new line

fabiola_counter=0
john_counter=0

while IFS= read -r message; do
  user=$(echo "$message" | jq -c '.message._data.from.user')
  if [[ $user = *"12023779702"* ]]; then
    ((fabiola_counter++))
  elif [[ $user = *"12023680849"* ]]; then
    ((john_counter++))
  fi
  message=$(echo "$message" | jq -c '.message._data.body')
  echo "User: $user, Message: $message"
done <<< "$messages"

echo "Fabiola: $fabiola_counter messages"
echo "John: $john_counter messages"