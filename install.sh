#!/bin/bash
# Quick install script for dictation-toggle

set -e

echo "=== Dictation Toggle Installer ==="
echo ""

# Check dependencies
echo "Checking dependencies..."
MISSING=()
for cmd in sox rec xdotool xclip jq curl gdbus; do
  if ! command -v "$cmd" &>/dev/null; then
    MISSING+=("$cmd")
  fi
done

if [ ${#MISSING[@]} -gt 0 ]; then
  echo "Missing: ${MISSING[*]}"
  echo "Install with: sudo apt install sox xdotool xclip jq curl libsox-fmt-all"
  exit 1
fi
echo "All dependencies found."

# Copy script
echo "Installing dictation-toggle to ~/bin..."
mkdir -p ~/bin ~/.local/bin
cp dictation-toggle ~/bin/dictation-toggle
chmod +x ~/bin/dictation-toggle
ln -sf ~/bin/dictation-toggle ~/.local/bin/dictation-toggle
echo "Installed."

# Check Whisper
if [ ! -f "$HOME/.local/share/whisper.cpp/build/bin/whisper-cli" ]; then
  echo ""
  echo "WARNING: Whisper.cpp not found at ~/.local/share/whisper.cpp"
  echo "Install it with:"
  echo "  git clone https://github.com/ggerganov/whisper.cpp.git ~/.local/share/whisper.cpp"
  echo "  cd ~/.local/share/whisper.cpp && cmake -B build && cmake --build build --config Release"
  echo "  bash models/download-ggml-model.sh large-v3"
fi

# Check API key
if [ -z "$OPENAI_API_KEY" ]; then
  echo ""
  echo "WARNING: OPENAI_API_KEY not set."
  echo "Add to your ~/.zshrc:"
  echo '  export OPENAI_API_KEY="sk-your-key-here"'
fi

echo ""
echo "Done! Set up a keyboard shortcut (Super+D) pointing to:"
echo "  $HOME/.local/bin/dictation-toggle"
