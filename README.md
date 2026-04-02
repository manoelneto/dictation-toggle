# Dictation Toggle

Voice-to-text tool for Linux that records speech, transcribes it locally with Whisper.cpp, then uses OpenAI to aggressively restructure and improve the text before typing it into your active window.

## Features

- **Press once** to start recording (captures context: window title, clipboard, selected text)
- **Press again** to stop, transcribe, improve, and type the result
- **Context-aware**: sends your active window, clipboard, and text selection to the LLM so it adapts the style
- **Clipboard ready**: improved text is also copied to clipboard for Ctrl+V
- **Persistent notification** while recording, with progress updates during processing
- **Fallback**: if the API is unavailable, uses raw Whisper transcription

## Requirements

### System packages

```bash
# Ubuntu/Linux Mint/Debian
sudo apt install sox xdotool xclip jq curl libsox-fmt-all
```

- `sox` - audio recording (`rec` command)
- `xdotool` - typing into focused window and reading window titles
- `xclip` - clipboard access (read selection, copy result)
- `jq` - JSON processing for API calls
- `curl` - HTTP requests to OpenAI API
- `gdbus` - desktop notifications (usually pre-installed on GNOME/Cinnamon)

### Whisper.cpp (local speech recognition)

```bash
# Clone and build
git clone https://github.com/ggerganov/whisper.cpp.git ~/.local/share/whisper.cpp
cd ~/.local/share/whisper.cpp
cmake -B build
cmake --build build --config Release

# Download the large-v3 model (best accuracy, ~2.9GB)
bash models/download-ggml-model.sh large-v3
```

### OpenAI API key

1. Go to [platform.openai.com/api-keys](https://platform.openai.com/api-keys)
2. Create a new API key
3. Add it to your shell config:

```bash
echo 'export OPENAI_API_KEY="sk-your-key-here"' >> ~/.zshrc
source ~/.zshrc
```

## Installation

### 1. Copy the script

```bash
mkdir -p ~/bin
cp dictation-toggle ~/bin/dictation-toggle
chmod +x ~/bin/dictation-toggle
```

Make sure `~/bin` is in your PATH:

```bash
# Add to ~/.zshrc or ~/.bashrc if not already there
export PATH="$HOME/bin:$PATH"
```

### 2. Create a symlink (optional, for ~/.local/bin)

```bash
ln -sf ~/bin/dictation-toggle ~/.local/bin/dictation-toggle
```

### 3. Set up the keyboard shortcut

#### Cinnamon (Linux Mint)

1. Open **System Settings** > **Keyboard** > **Shortcuts** > **Custom Shortcuts**
2. Click **Add custom shortcut**
3. Name: `Dictation Toggle`
4. Command: `/home/YOUR_USERNAME/.local/bin/dictation-toggle`
5. Click **Add** then press **Super+D** to assign the shortcut

#### GNOME

```bash
# Set via gsettings
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name 'Dictation Toggle'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command "$HOME/.local/bin/dictation-toggle"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding '<Super>d'
```

## Usage

1. **Select text** or copy context to your clipboard (optional - gives the AI context)
2. Press **Super+D** - a "Recording..." notification appears
3. Speak your text
4. Press **Super+D** again - recording stops
5. Move your cursor to where you want the text (while it processes)
6. The improved text is typed into the focused window AND copied to clipboard
7. Use **Ctrl+V** to paste it elsewhere if needed

## Configuration

### Change the AI model

Edit `dictation-toggle` and change the `OPENAI_MODEL` variable:

```bash
OPENAI_MODEL="gpt-5.4-mini"   # Fast and cheap (default)
OPENAI_MODEL="gpt-5.4"        # Higher quality
OPENAI_MODEL="gpt-5.4-pro"    # Best quality
```

### Change the Whisper model

For faster (but less accurate) transcription:

```bash
# Download a smaller model
cd ~/.local/share/whisper.cpp
bash models/download-ggml-model.sh medium.en  # English only, faster

# Then edit dictation-toggle:
MODEL="$HOME/.local/share/whisper.cpp/models/ggml-medium.en.bin"
```

### Troubleshooting

Check the log file for errors:

```bash
cat /tmp/whisper-dictation.log
```

Common issues:
- **No sound recorded**: Check `rec` works: `rec -r 16000 -c 1 -b 16 /tmp/test.wav` then Ctrl+C
- **API errors**: Verify your key: `echo $OPENAI_API_KEY`
- **Notification not showing**: Check `notify-send "test" "hello"` works
- **Text not typed**: Check `xdotool type "hello"` works in a text field

## License

MIT
