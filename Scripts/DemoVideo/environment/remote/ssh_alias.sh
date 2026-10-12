#!/bin/zsh
# ssh_alias.sh add|remove: the devbox alias in ~/.ssh/config, between marker lines so remove takes out exactly it.
# It logs in as the demo user through the loopback forward, with the admin alias's key and known host key.
source ${0:A:h:h:h}/settings.sh
config=$HOME/.ssh/config
begin="# BEGIN JustSessions demo video: remove with Scripts/DemoVideo/demo-video teardown"
end="# END JustSessions demo video"

remove_block() {
  [[ -f $config ]] || return
  awk -v begin="$begin" -v end="$end" '$0 == begin { skipping = 1 } !skipping { print } $0 == end { skipping = 0 }' \
    $config > $config.demo-video && mv $config.demo-video $config && chmod 600 $config
}

case $1 in
  add)
    admin=$(ssh -G $DEMO_VM_ADMIN_ALIAS 2>/dev/null)
    identity_file=$(awk '$1 == "identityfile" { print $2; exit }' <<< $admin)
    host_key_alias=$(awk '$1 == "hostkeyalias" { print $2; exit }' <<< $admin)
    remove_block
    cat >> $config <<BLOCK

$begin
Host $DEMO_SSH_ALIAS
    HostName 127.0.0.1
    Port $DEMO_LOOPBACK_PORT
    User $DEMO_REMOTE_USER
    IdentityFile $identity_file
    IdentitiesOnly yes
    HostKeyAlias ${host_key_alias:-$DEMO_VM_ADMIN_ALIAS}
$end
BLOCK
    echo "added Host $DEMO_SSH_ALIAS to $config"
    ;;
  remove)
    remove_block
    echo "removed Host $DEMO_SSH_ALIAS from $config"
    ;;
  *) echo "usage: ssh_alias.sh add|remove"; exit 1 ;;
esac
