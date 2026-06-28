#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Error: run this script as root." >&2
  exit 1
fi

PKGS=(
  openssh
  git
  make
  firefox
  xclip
  xorg-server
  xorg-xinit
)

echo "Installing required packages..."
pacman -Sy --noconfirm --needed "${PKGS[@]}"

read -r -p "Username to create: " NEW_USER

if ! id "$NEW_USER" >/dev/null 2>&1; then
  useradd -m -s /bin/bash "$NEW_USER"
fi

echo "Set password for $NEW_USER"
passwd "$NEW_USER"

USER_HOME="$(getent passwd "$NEW_USER" | cut -d: -f6)"

install -d -m 700 -o "$NEW_USER" -g "$NEW_USER" "$USER_HOME/.ssh"

if [[ ! -f "$USER_HOME/.ssh/id_ed25519" ]]; then
  su - "$NEW_USER" -c "ssh-keygen -t ed25519 -N '' -f ~/.ssh/id_ed25519 -C '$NEW_USER@$(hostname)'"
fi

cat >"$USER_HOME/.xinitrc" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

xclip -selection clipboard < "$HOME/.ssh/id_ed25519.pub" || true
firefox https://github.com/settings/keys &
wait $!
touch /tmp/.user_init_done

if [[ -f "$HOME/.ssh/id_ed25519" && -f /tmp/.user_init_done ]]; then
  mkdir -p "$HOME/repos"
  if [[ ! -d "$HOME/repos/arch" ]]; then
    export GIT_SSH_COMMAND='ssh -o StrictHostKeyChecking=accept-new'
    git clone git@github.com:talkerbox/sys_init.git "$HOME/repos/sys_init"
    git clone git@github.com:talkerbox/sys_arch.git "$HOME/repos/sys_arch"
  fi
fi
EOF

chown "$NEW_USER:$NEW_USER" "$USER_HOME/.xinitrc"
chmod 700 "$USER_HOME/.xinitrc"

cat <<EOF

Prepared successfully.

Next steps:
1. Log out from root console completely.
2. Log in as user: $NEW_USER
3. Run:
   startx

What will happen:
- your public SSH key will be copied to clipboard
- Firefox will open GitHub SSH key settings
- after Firefox closes, /tmp/.user_init_done will be created
- then the script will try to clone:
  git@github.com:talkerbox/sys_arch.git
  into ~/repos/sys_arch

EOF
