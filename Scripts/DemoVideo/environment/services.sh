#!/bin/zsh
# services.sh start|stop|status: the background helpers a recording needs, the canned model server and the
# loopback forward to the VM. Their logs and process IDs are in $DEMO_WORK/services.
source ${0:A:h:h}/settings.sh
folder=$DEMO_WORK/services
mkdir -p $folder

running() { [[ -f $folder/$1.pid ]] && kill -0 $(<$folder/$1.pid) 2>/dev/null }

start_one() {
  local name=$1; shift
  if running $name; then echo "$name: already running"; return; fi
  nohup "$@" > $folder/$name.log 2>&1 &
  echo $! > $folder/$name.pid
  sleep 0.5
  running $name && echo "$name: started" || { echo "$name: failed, see $folder/$name.log"; return 1; }
}

case $1 in
  start)
    start_one canned-model-server python3 $DEMO_VIDEO_TOOLS/environment/canned_model_server.py $DEMO_MODEL_PORT
    vm_address=$(ssh -G $DEMO_VM_ADMIN_ALIAS 2>/dev/null | awk '$1 == "hostname" { print $2 }')
    start_one loopback-forward python3 $DEMO_VIDEO_TOOLS/environment/loopback_forward.py $DEMO_LOOPBACK_PORT $vm_address
    ;;
  stop)
    for name in canned-model-server loopback-forward; do
      if running $name; then kill $(<$folder/$name.pid) && echo "$name: stopped"; fi
      rm -f $folder/$name.pid
    done
    ;;
  status)
    for name in canned-model-server loopback-forward; do running $name && echo "$name: running" || echo "$name: stopped"; done
    ;;
  *) echo "usage: services.sh start|stop|status"; exit 1 ;;
esac
