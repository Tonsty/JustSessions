#!/bin/zsh
# setup_remote_host.sh: turns the SSH test VM into the demo's server. It adds the demo user with your test key and
# Claude Code, renames the VM to devbox so prompts show it, and adds the devbox alias on this Mac.
# teardown_remote_host.sh undoes all three.
set -e
source ${0:A:h:h:h}/settings.sh

ssh -o BatchMode=yes $DEMO_VM_ADMIN_ALIAS "DEMO_REMOTE_USER=$DEMO_REMOTE_USER DEMO_SSH_ALIAS=$DEMO_SSH_ALIAS bash -s" <<'REMOTE'
set -e
# Claude Code for the demo user: the admin user's real binary. On the test VM, ~/.local/bin/claude may be a mock.
claude_binary=$(readlink -f ~/.local/bin/claude-real 2>/dev/null || true)
[ -n "$claude_binary" ] || claude_binary=$(ls -1 ~/.local/share/claude/versions/* 2>/dev/null | sort -V | tail -1)
[ -n "$claude_binary" ] || { echo "Install Claude Code for $(whoami) on the VM first."; exit 1; }
id $DEMO_REMOTE_USER >/dev/null 2>&1 || sudo useradd -m -s /bin/bash $DEMO_REMOTE_USER
home=/home/$DEMO_REMOTE_USER
sudo mkdir -p $home/.ssh $home/.local/bin
sudo cp ~/.ssh/authorized_keys $home/.ssh/authorized_keys
sudo cp -L "$claude_binary" $home/.local/bin/claude
sudo chown -R $DEMO_REMOTE_USER:$DEMO_REMOTE_USER $home
sudo chmod 700 $home/.ssh
sudo chmod 600 $home/.ssh/authorized_keys
sudo -u $DEMO_REMOTE_USER bash -c 'grep -q CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC ~/.profile 2>/dev/null ||
  echo "export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1" >> ~/.profile'
# The hostname shows in shell prompts on camera. Keep the original so teardown can put it back.
sudo mkdir -p /var/lib/justsessions-demo
if [ ! -f /var/lib/justsessions-demo/original-hostname ] && [ "$(hostname)" != "$DEMO_SSH_ALIAS" ]; then
  hostname | sudo tee /var/lib/justsessions-demo/original-hostname >/dev/null
fi
sudo hostnamectl set-hostname $DEMO_SSH_ALIAS
echo "VM: user $DEMO_REMOTE_USER with Claude Code $(sudo -u $DEMO_REMOTE_USER $home/.local/bin/claude --version), hostname $(hostname)"
REMOTE

$DEMO_VIDEO_TOOLS/environment/remote/ssh_alias.sh add
