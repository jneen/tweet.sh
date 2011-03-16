#!/bin/bash

. "$TWEET_PATH"/lib/util.sh

if [[ -z "$LOADED_OAUTH" ]]; then
echo "Loading oauth" >&2
LOADED_OAUTH=1

# generate a nonce
oauth::nonce() {
  {
    echo "$$"
    date +%s+%N
    echo "$RANDOM"
  } | md5sum | cut -d' ' -f1
}

oauth::timestamp() {
  date +%s
}

oauth::signing_key() {
  echo "$(urlencode <<<"$(oauth::secret)")&$(urlencode <<<"$oauth_token_secret")"
}

oauth::sign::HMAC-SHA1() {
debug BEGIN HMAC-SHA1 "[$@]"
  local in="$(cat -)"
  in="$(echo -n "$in")"
  debug "in:[$in]"
  echo -n "$in" | openssl dgst -sha1 -binary -hmac "$(oauth::signing_key)" | base64
debug END HMAC-SHA1
}

oauth::base_string() {
  local r="$http_method"
  r="$r&$(urlencode "$base_uri")"
  r="$r&$(oauth::request_params | oauth::urlencode_params | urlencode)"
  echo "$r"
}

oauth::urlencode_params() {
  while read kv; do
    kv "$kv" k v
    echo "$(urlencode "$k")=$(urlencode "$v")"
  done | sort | join '&'
}

oauth::signature() {
debug "oauth::base_string $(oauth::base_string)"
  oauth::base_string | oauth::sign::HMAC-SHA1 # | urlencode
}

oauth::auth_params() {
  oauth::request_params
  echo oauth_signature="$(oauth::signature)"
}

oauth::formatted_auth_params() {
  oauth::auth_params | {
    # quote the values for twitter, now
    while read pair; do
      kv "$pair" k v
      echo "$k"=\""$v"\"
    done
  } | join ', '
}

oauth::auth_header() {
  debug "Authorization: OAuth $(oauth::formatted_auth_params)"
  echo "Authorization: OAuth $(oauth::formatted_auth_params)"
}

oauth::request_params() {
debug BEGIN oauth::request_params "[$@]"
  [[ -z "$nonce" ]] && nonce="$(oauth::nonce)"
  echo oauth_callback=oob
  echo oauth_consumer_key="$(oauth::key)"
  echo oauth_nonce="$nonce"
  echo oauth_signature_method="HMAC-SHA1"
  echo oauth_timestamp="$(oauth::timestamp)"
  echo oauth_version="1.0"
debug END oauth::request_params
}

oauth::request() {
# debug BEGIN oauth::request "[$@]"
  local params="$(oauth::request_params)"
  debug "done with auth header"
  # debug curl -d\"Authorization: $auth\" -X\"$http_method\" \"$base_uri\" \"$@\"
  curl \
    -X"$http_method" \
    -d"$(oauth::urlencode_params <<<"$params")" \
    -H"$(oauth::auth_header)" \
    "$base_uri" "$@"
  r=$?
  echo
# debug end oauth::request
return $r
}

oauth::request_token() {
debug BEGIN oauth::request_token "[$@]"
  local base_uri="$(oauth::request_url)"
  local http_method=POST
  oauth::request
debug END oauth::request_token
}

config oauth::secret        OAUTH_SECRET
config oauth::key           OAUTH_KEY
config oauth::request_url   OAUTH_REQUEST_URL
config oauth::access_url    OAUTH_ACCESS_URL
config oauth::authorize_url OAUTH_AUTHORIZE_URL
fi
