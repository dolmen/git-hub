set -e

source json.bash

get-var json-lib
if [ -n "$json_lib" ]; then
  source "$json_lib"
fi


#------------------------------------------------------------------------------
# JSON support functions:
#------------------------------------------------------------------------------
# Format a JSON object from an input list of key/value pairs.
json-dump-object() {
  local json='{' value=
  while [ $# -gt 0 ]; do
    if [[ "$2" =~ (^[\[\{]|^(null|true|false)$|^[0-9]+$) ]]; then
      json="$json\"$1\":$2"
    else
      value="${2//\"/\\\"}"
      json="$json\"$1\":\"${value//$'\n'/\\n}\""
    fi
    shift; shift || true
    if [ $# -gt 0 ]; then
      json="$json,"
    fi
  done
  json="$json}"
  echo "$json"
}

json-dump-array() {
  local json='['
  while [ $# -gt 0 ]; do
    json="$json\"$1\""
    shift
    if [ $# -gt 0 ]; then
      json="$json,"
    fi
  done
  json="$json]"
  echo "$json"
}

# Format a JSON object from an array.
json-dump-object-pairs() {
  local regex='(^\[|^null$|^[0-9]+$)'
  local json='{'
  for ((i = 0; i < ${#pairs[@]}; i = i+2)); do
    local value="${pairs[$((i+1))]}"
    value="${value//\"/\\\"}"
    if [[ "$value" =~ $regex ]]; then
      json="$json\"${pairs[$i]}\":$value"
    else
      json="$json\"${pairs[$i]}\":\"$value\""
    fi
    if [ $((${#pairs[@]} - $i)) -gt 2 ]; then
      json="$json,"
    fi
  done
  json="$json}"
  echo "$json"
}

pretty-json-object() {
  declare -a keys=("$@")

  echo '{'
  for (( i = 0; i < ${#keys[@]}; i++)); do
    local key="${keys[$i]}"
    local key="${key//__/\/}"
    local value="$(JSON.get "/$key" - || true)"
    if [ -n "$value" ]; then
      printf "    \"%s\": %s" "$key" "$value"
      [[ $(($i+1)) -lt ${#keys[@]} ]] && printf ','
      printf "\n"
    fi
  done
  echo '}'
}

json-var-list() {
  local fields="$@"
  while IFS='\n' read -r line; do
    [[ -z "$line" ]] && break
    if [[ "$line" =~ ^$key_prefix/([0-9]+)/([^\	]+)\	(.*) ]]; then
      local value="${BASH_REMATCH[3]}"
      [ "$value" == null ] && value=''
      value="${value#\"}"
      value="${value%\"}"
      key="${BASH_REMATCH[2]}_${BASH_REMATCH[1]}"
      key="${key//\//__}"
      printf -v "$key" "%s" "$value"
    else
      die "Unexpected line '$line'"
    fi
  done < <(
    echo "$JSON__cache" |
      grep -E "^$key_prefix/[0-9]+/(${fields// /|})\b" || echo ''
  )
}

json-prune-cache() {
  JSON__cache="$(echo "$JSON__cache" | grep -E "$1" || echo '')"
}

json-prune-hash() {
  local fields="$@"
  fields="${fields//__/\/}"
  json-prune-cache "^/(${fields// /|})\b"
}

# vim: set lisp:
