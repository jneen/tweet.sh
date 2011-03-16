#!/bin/bash
. "$TWEET_PATH"/vendor/OAuth.sh
tweet::api() {
  echo curl http://twitter.com/"$@" 2>/dev/null
  curl http://twitter.com/"$@" 2>/dev/null
  echo
}

tweet::say() {
  tweet::api /statuses/update -d status="$@"
}

tweet::timeline() {
  tweet::api /statuses/public_timeline.json
  echo
}

json::extract() {
  local json="$(cat -)"
  json="${json:1:${#json}-2}"
  val="$(tr ',' '\n' <<<"$json" | fgrep "\"$1\"" | cut -d: -f2-)"
}

tweet::set_access_token() {
  tweet::cached_access_token && return

  oauth_consumer_key="$TWEET_OAUTH_CONSUMER_KEY"
  oauth_consumer_secret="$TWEET_OAUTH_CONSUMER_SECRET"
  oauth_signature_method="HMAC-SHA1"
  oauth_version='1.0'
  oauth_nonce="$(OAuth_nonce)"
  oauth

  params = (
    $(OAuth_param 'oauth_consumer_key' "$TWEET_OAUTH_CONSUMER_KEY")
    $(OAuth_param 'oauth_signature_method' 'HMAC-SHA1')
    $(OAuth_param 'oauth_version' '1.0')
    $(OAuth_param 'oauth_timestamp' "$(Oauth_timestamp)")
    $(OAuth_param 'oauth_callback' 'http://localhost:3005/the_dance/process_callback?service_provider_id=11')
  )

  base_string=$(OAuth_base_string 'POST' https://api.twitter.com/oauth/request_token ${params[@]})
  signature=$(_OAuth_signature HMAC-SHA1 "$base_string" "$TWEET_OAUTH_CONSUMER_SECRET")
}

tweet::cached_access_token() {
  [[ -n "$access_token" ]] && return

  local access_token_path="$(tweet::dotdir)/access_token"

  if [[ -s "$access_token_path" ]]; then
    access_token=$(cat "$access_token_path")
  else
    false
  fi
}
