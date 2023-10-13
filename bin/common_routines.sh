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

checkDatabaseConnection() {
  pg_user=$(echo $1 | sed s+postgresql://++ | awk -F':' '{ print $1}')
  pg_host_port=$(echo $1 | awk -F':' '{ print $3}' \
           | awk -F'@' '{ print $2}' | awk -F'/' '{ print $1 }')
  pg_host=$(echo $pg_host_port  | awk -F':' '{print $1}')
  pg_port=$(echo $pg_host_port  | awk -F':' '{print $2}')
  if [ ! -z "$pg_port" ]; then
    pg_isready -U $pg_user -h $pg_host -p $pg_port || (echo "No db connection." && exit 1)
  else
    pg_isready -U $pg_user -h $pg_host || (echo "No db connection" && exit 1)
  fi
}