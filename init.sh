#!/usr/bin/env bash
set -euo pipefail

SCRIPT_PATH="$(readlink -f "$0")"

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

su - "$NEW_USER" -c "
set -euo pipefail

if [[ ! -f ~/.ssh/id_ed25519 ]]; then
  ssh-keygen -t ed25519 -N '' -f ~/.ssh/id_ed25519 -C '$NEW_USER@$(hostname)'
fi

cat > ~/.xinitrc <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

xclip -selection clipboard < \"\$HOME/.ssh/id_ed25519.pub\" || true
firefox https://github.com/settings/keys &
wait \$!
touch /tmp/.user_init_done
EOF

chmod +x ~/.xinitrc
exec startx
"

if [[ -f "$USER_HOME/.ssh/id_ed25519" && -f /tmp/.user_init_done ]]; then
  su - "$NEW_USER" -c "
    set -euo pipefail
    mkdir -p ~/repos
    if [[ ! -d ~/repos/arch ]]; then
      git clone [email protected]:talkerbox/arch.git ~/repos/arch
    fi
  "

  if [[ -d "$USER_HOME/repos/arch/.git" ]]; then
    rm -f -- "$SCRIPT_PATH"
  fi
else
  echo "Error: SSH key or /tmp/.user_init_done missing." >&2
  exit 1
fi
