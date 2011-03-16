#!/bin/bash

if [[ -z "$LOADED_UTIL" ]]; then
LOADED_UTIL=1

config() {
  alias "$1"="_config $2"
}

debug() {
  if [[ -n "$DEBUG" ]]; then
    echo "$@" >&2
  fi
}

_config() {
  local _var="$1"; shift
  if [[ -n "$@" ]]; then
    export "$_var"="$@"
  else
    if [[ -n "${!_var}" ]]; then
      echo "${!_var}"
    else
      err "No $_var set"
    fi
  fi
}

err() {
  echo "Error: $@" >&2
  exit 1
}

# adapted from
# http://stackoverflow.com/questions/296536/urlencode-from-a-bash-script
urlencode() {
# debug BEGIN urlencode "\$@:[$@]"
  if [[ -n "$1" ]]; then
    local url="$1"
  else
    local url="$(cat -)"
  fi

  # make sure hexdump exists, if not, just give back the url
  type hexdump >/dev/null 2>/dev/null || err "could not find hexdump"

  echo "$url" | hexdump -v -e '1/1 "%02x\t"' -e '1/1 "%_c\n"' | LANG=C awk '
    $1 == "20"                  { printf("%s",   "+"); next   } # space becomes plus
    $1 ~  /0[adAD]/             {                      next   } # strip newlines
    $2 ~  /^[_a-zA-Z0-9.*()-]$/ { printf("%s",   $2);  next   } # pass through what we can
                                { printf("%%%s", toupper($1)) } # take hex value of everything else
  '
# debug END urlencode
}

join() {
  local delimiter="$1"
  read line
  echo -n "$line"
  while read line; do
    echo -n "$delimiter"
    echo -n "$line"
  done
}

# separate a key=value pair into key and value
kv() {
# debug BEGIN kv "\$@:[$@]"
  local __str="$1"; shift
  local __k="$1"; shift
  local __v="$1"; shift
  export "$__k"="${__str%%=*}"
  export "$__v"="${__str#*=}"
# debug BEGIN kv
}

fi
