#!/bin/bash

set -e

REPO_URL="https://github.com/szdaniel4/ncore_streamer.git"
INSTALL_DIR="$HOME/.local/bin/ncore_streamer"
BIN_DIR="$HOME/.local/bin"

echo "==> Installing ncore-streamer..."

if ! command -v peerflix >/dev/null 2>&1; then
    echo "Error: peerflix is not installed."
    echo "for install it, type 'npm install peerflix -g'"
    exit 1
fi

if ! command -v git >/dev/null 2>&1; then
    echo "Error: git is not installed."
    exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
    echo "Error: python3 is not installed."
    exit 1
fi

if [ -d "$INSTALL_DIR" ]; then
    echo "==> Removing previous installation..."
    rm -rf "$INSTALL_DIR"
fi

mkdir -p "$(dirname "$INSTALL_DIR")"

echo "==> Downloading ncore-streamer..."
git clone "$REPO_URL" "$INSTALL_DIR"


echo "==> Creating virtual environment..."
python3 -m venv "$INSTALL_DIR/.venv"

echo "==> Installing Python dependencies..."
"$INSTALL_DIR/.venv/bin/pip" install -r "$INSTALL_DIR/requirements.txt"

echo "==> Opening ncore-streamer configuration..."
mv "$INSTALL_DIR/ncore/config.example.py" "$INSTALL_DIR/ncore/config.py"
echo "==> You can edit the configuration file at: $INSTALL_DIR/ncore/config.py"
echo "==> You can also run 'nstream' without configuring."

mkdir -p "$BIN_DIR"

cat > "$BIN_DIR/nstream" <<EOF
#!/bin/bash

INSTALL_DIR="$INSTALL_DIR"

case "\$1" in
    update)
        echo "==> Updating ncore-streamer..."
        git -C "\$INSTALL_DIR" pull
        "\$INSTALL_DIR/.venv/bin/pip" install -r "\$INSTALL_DIR/requirements.txt"
        echo "==> Update complete."
        ;;

    uninstall)
        echo "==> Removing ncore-streamer..."
        rm -rf "\$INSTALL_DIR"
        rm -f "\$HOME/.local/bin/nstream"
        echo "==> ncore-streamer has been removed."
        ;;
    
    config)
        nano "\$INSTALL_DIR/ncore/config.py"
        ;;

    *)
        exec "\$INSTALL_DIR/.venv/bin/python" "\$INSTALL_DIR/main.py" "\$@"
        ;;
esac
EOF

chmod +x "$BIN_DIR/nstream"

if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    case "$SHELL" in
        */zsh)
            SHELL_CONFIG="$HOME/.zshrc"
            ;;
        */bash)
            SHELL_CONFIG="$HOME/.bashrc"
            ;;
        *)
            SHELL_CONFIG=""
            ;;
    esac

    if [ -n "$SHELL_CONFIG" ]; then
        if ! grep -Fxq 'export PATH="$HOME/.local/bin:$PATH"' "$SHELL_CONFIG"; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_CONFIG"
        fi
    else
        echo ""
        echo "WARNING: $BIN_DIR is not in your PATH."
        echo ""
        echo "Add this line to your shell configuration:"
        echo ""
        echo "export PATH=\"\$HOME/.local/bin:\$PATH\""
        echo ""
    fi

    export PATH="$BIN_DIR:$PATH"
fi

echo ""
echo "======================================"
echo " ncore-streamer installed successfully"
echo "======================================"
echo ""
echo "Run:"
echo "  nstream"
echo ""
echo "Update:"
echo "  nstream update"
echo ""
echo "Uninstall:"
echo "  nstream uninstall"
echo ""
echo "Configure:"
echo "  nstream config"
echo ""