#!/bin/zsh
# teardown_remote_host.sh: removes the demo user and its files from the VM, restores the VM's hostname, and removes
# the devbox alias from this Mac.
source ${0:A:h:h:h}/settings.sh

ssh -o BatchMode=yes $DEMO_VM_ADMIN_ALIAS "DEMO_REMOTE_USER=$DEMO_REMOTE_USER DEMO_SSH_ALIAS=$DEMO_SSH_ALIAS bash -s" <<'REMOTE'
if id $DEMO_REMOTE_USER >/dev/null 2>&1; then
  sudo pkill -u $DEMO_REMOTE_USER || true
  sleep 1
  sudo userdel -r $DEMO_REMOTE_USER 2>/dev/null && echo "VM: removed user $DEMO_REMOTE_USER and its home"
fi
if [ -f /var/lib/justsessions-demo/original-hostname ]; then
  sudo hostnamectl set-hostname "$(cat /var/lib/justsessions-demo/original-hostname)"
  sudo rm -rf /var/lib/justsessions-demo
elif [ "$(hostname)" = "$DEMO_SSH_ALIAS" ]; then
  echo "VM: no saved hostname; set it back with: sudo hostnamectl set-hostname <name>"
fi
echo "VM: hostname $(hostname)"
REMOTE

$DEMO_VIDEO_TOOLS/environment/remote/ssh_alias.sh remove
