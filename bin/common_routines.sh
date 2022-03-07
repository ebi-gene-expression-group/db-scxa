require_env_var() {
  if [[ -z ${!1} ]]
  then
    echo "$1 env var is needed." && exit 1
  fi
}

get_host_from_hostport() {
  echo $(echo $1 | awk -F':' '{ print $1 }')
}

get_port_from_hostport() {
  echo $(echo $1 | awk -F':' '{ print $2 }')
}
