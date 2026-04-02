# Dictation Toggle

Voice-to-text tool for Linux that records speech, transcribes it locally with Whisper.cpp (GPU-accelerated), then uses OpenAI to aggressively restructure and improve the text before typing it into your active window.

## Features

- **Press once** to start recording (captures context: window title, clipboard, selected text)
- **Press again** to stop, transcribe, improve, and type the result
- **Context-aware**: sends your active window, clipboard, and text selection to the LLM so it adapts the style
- **Embedded instructions**: say things like "translate to Portuguese" or "make this formal" in your dictation
- **Clipboard ready**: improved text is also copied to clipboard for Ctrl+V
- **Persistent notification** while recording, with progress updates during processing
- **GPU-accelerated**: uses CUDA for fast Whisper.cpp transcription
- **Verbose logging**: full pipeline logged to `/tmp/whisper-dictation.log`
- **Fallback**: if the API is unavailable, uses raw Whisper transcription

## Requirements

### System packages

```bash
# Ubuntu/Linux Mint/Debian
sudo apt install sox libsox-fmt-all xdotool xclip jq curl
```

| Package | Purpose |
|---------|---------|
| `sox` / `libsox-fmt-all` | Audio recording (`rec` command) with format support |
| `xdotool` | Typing into focused window and reading window titles |
| `xclip` | Clipboard access (read selection, copy result) |
| `jq` | JSON processing for API calls |
| `curl` | HTTP requests to OpenAI API |
| `gdbus` | Desktop notifications (pre-installed on GNOME/Cinnamon) |

### NVIDIA GPU drivers and CUDA toolkit

Whisper.cpp uses your GPU for fast transcription. You need the NVIDIA driver and CUDA toolkit installed.

#### 1. Install NVIDIA drivers

```bash
# Check if you already have a driver
nvidia-smi

# If not installed, use the driver manager (Linux Mint / Ubuntu)
sudo ubuntu-drivers autoinstall
# Or install a specific version:
sudo apt install nvidia-driver-580
```

After installing, **reboot** your machine.

#### 2. Install CUDA toolkit

```bash
# Option A: Install from NVIDIA's repository (recommended for latest version)
# Visit https://developer.nvidia.com/cuda-downloads and follow instructions for your distro

# Option B: Install from Ubuntu/Mint repositories
sudo apt install nvidia-cuda-toolkit

# Verify installation
nvcc --version
```

#### 3. Set CUDA environment variables

Add to your `~/.zshrc` or `~/.bashrc`:

```bash
export PATH="/usr/local/cuda/bin:$PATH"
export LD_LIBRARY_PATH="/usr/local/cuda/lib64:$LD_LIBRARY_PATH"
```

Then reload: `source ~/.zshrc`

#### 4. Verify GPU is working

```bash
# Should show your GPU model, driver version, and CUDA version
nvidia-smi

# Example output:
# NVIDIA GeForce RTX 5060        Driver: 580.126.09    CUDA: 13.0
```

### Whisper.cpp (local speech recognition with GPU)

#### 1. Clone the repository

```bash
git clone https://github.com/ggerganov/whisper.cpp.git ~/.local/share/whisper.cpp
cd ~/.local/share/whisper.cpp
```

#### 2. Build with CUDA support

```bash
# Configure with CUDA enabled
cmake -B build -DGGML_CUDA=ON

# Build (use -j to parallelize, e.g., -j8 for 8 cores)
cmake --build build --config Release -j$(nproc)
```

**If the build fails**, check:
- `nvcc --version` works (CUDA compiler)
- `nvidia-smi` shows your GPU
- You have `cmake` >= 3.18: `sudo apt install cmake`
- You have build tools: `sudo apt install build-essential`

#### 3. Verify CUDA is linked

```bash
# Should show libcudart, libcublas, libggml-cuda in the output
ldd ~/.local/share/whisper.cpp/build/bin/whisper-cli | grep cuda
```

If no CUDA libraries appear, the build didn't pick up CUDA. Re-run cmake with `-DGGML_CUDA=ON` explicitly.

#### 4. Download a model

```bash
cd ~/.local/share/whisper.cpp

# large-v3 (recommended - best accuracy, ~2.9GB, fast with GPU)
bash models/download-ggml-model.sh large-v3

# Alternative models (trade accuracy for speed/size):
# bash models/download-ggml-model.sh medium.en   # ~1.5GB, English only
# bash models/download-ggml-model.sh small.en     # ~466MB, English only
# bash models/download-ggml-model.sh base.en      # ~142MB, English only
```

The script uses `ggml-large-v3.bin` by default. With a GPU, even the large model transcribes in a few seconds.

#### 5. Test Whisper works

```bash
# Record a short test clip
rec -r 16000 -c 1 -b 16 /tmp/test.wav
# (speak something, then Ctrl+C)

# Transcribe it
~/.local/share/whisper.cpp/build/bin/whisper-cli \
  -m ~/.local/share/whisper.cpp/models/ggml-large-v3.bin \
  -f /tmp/test.wav --no-timestamps -nt

# Clean up
rm /tmp/test.wav
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

### 1. Clone this repo and copy the script

```bash
git clone https://github.com/manoelneto/dictation-toggle.git /tmp/dictation-toggle
cd /tmp/dictation-toggle

# Option A: Run the install script
bash install.sh

# Option B: Manual install
mkdir -p ~/bin ~/.local/bin
cp dictation-toggle ~/bin/dictation-toggle
chmod +x ~/bin/dictation-toggle
ln -sf ~/bin/dictation-toggle ~/.local/bin/dictation-toggle
```

Make sure `~/bin` is in your PATH:

```bash
# Add to ~/.zshrc or ~/.bashrc if not already there
export PATH="$HOME/bin:$PATH"
```

### 2. Set up the keyboard shortcut

#### Cinnamon (Linux Mint)

1. Open **System Settings** > **Keyboard** > **Shortcuts** > **Custom Shortcuts**
2. Click **Add custom shortcut**
3. Name: `Dictation Toggle`
4. Command: `/home/YOUR_USERNAME/.local/bin/dictation-toggle`
5. Click **Add** then press **Super+D** to assign the shortcut

#### GNOME

```bash
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings \
  "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']"

dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/name "'Dictation Toggle'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/command "'$HOME/.local/bin/dictation-toggle'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/binding "'<Super>d'"
```

## Usage

1. **Select text** or copy context to your clipboard (optional - gives the AI context)
2. Press **Super+D** - a "Recording..." notification appears
3. Speak your text
4. Press **Super+D** again - recording stops
5. Move your cursor to where you want the text (while it processes)
6. The improved text is typed into the focused window AND copied to clipboard
7. Use **Ctrl+V** to paste it elsewhere if needed

### Embedded instructions

You can include instructions for the LLM in your dictation:

| You say | Result |
|---------|--------|
| "translate to Portuguese: I need to finish this by Friday" | "Eu preciso terminar isso ate sexta-feira" |
| "make this formal: hey can you look at this for me" | "Could you please review this at your earliest convenience?" |
| "write as bullet list: we need to fix login update dashboard and add tests" | Formatted bullet list |
| "summarize: (long text)" | A concise summary |

Without any instructions, the default behavior is to output in English with aggressive restructuring.

## Configuration

### Change the AI model

Edit `dictation-toggle` and change the `OPENAI_MODEL` variable:

```bash
OPENAI_MODEL="gpt-5.4-mini"   # Fast and cheap (default)
OPENAI_MODEL="gpt-5.4"        # Higher quality
OPENAI_MODEL="gpt-5.4-pro"    # Best quality
```

### Change the Whisper model

Edit `dictation-toggle` and change the `MODEL` variable:

```bash
MODEL="$HOME/.local/share/whisper.cpp/models/ggml-large-v3.bin"   # Best accuracy (default)
MODEL="$HOME/.local/share/whisper.cpp/models/ggml-medium.en.bin"  # Faster, English only
MODEL="$HOME/.local/share/whisper.cpp/models/ggml-small.en.bin"   # Fastest, English only
```

## Logging

Every dictation session is fully logged to `/tmp/whisper-dictation.log`:

```
================================================================
2026-04-02 16:30:00 | NEW DICTATION SESSION
================================================================
2026-04-02 16:30:00 | WHISPER: Starting transcription...
2026-04-02 16:30:05 | WHISPER RAW: so basically I want to like change this thing
2026-04-02 16:30:05 | CONTEXT - Window: Visual Studio Code
2026-04-02 16:30:05 | CONTEXT - Selection: def calculate_total
2026-04-02 16:30:05 | CONTEXT - Clipboard: some copied text
2026-04-02 16:30:05 | MODEL: gpt-5.4-mini
2026-04-02 16:30:07 | API SUCCESS (HTTP 200) | prompt_tokens=245 completion_tokens=32 total_tokens=277
2026-04-02 16:30:07 | IMPROVED TEXT: I want to modify this component.
2026-04-02 16:30:07 | FINAL: Text inserted and copied to clipboard
```

Watch it live: `tail -f /tmp/whisper-dictation.log`

## Troubleshooting

| Problem | Fix |
|---------|-----|
| No sound recorded | Test: `rec -r 16000 -c 1 -b 16 /tmp/test.wav` then Ctrl+C |
| API key not found | Check: `echo $OPENAI_API_KEY` (must be set in `~/.zshrc`) |
| Whisper slow (no GPU) | Verify: `ldd ~/.local/share/whisper.cpp/build/bin/whisper-cli \| grep cuda` |
| CUDA not found during build | Install: `sudo apt install nvidia-cuda-toolkit` and rebuild |
| Notification not showing | Test: `notify-send "test" "hello"` |
| Text not typed | Test: `xdotool type "hello"` in a text field |
| Script not triggered by shortcut | Check `~/.local/bin/dictation-toggle` exists and is executable |

## Full setup checklist for a new machine

```bash
# 1. System packages
sudo apt install sox libsox-fmt-all xdotool xclip jq curl build-essential cmake

# 2. NVIDIA driver (reboot after)
sudo ubuntu-drivers autoinstall

# 3. CUDA toolkit
sudo apt install nvidia-cuda-toolkit
echo 'export PATH="/usr/local/cuda/bin:$PATH"' >> ~/.zshrc
echo 'export LD_LIBRARY_PATH="/usr/local/cuda/lib64:$LD_LIBRARY_PATH"' >> ~/.zshrc
source ~/.zshrc

# 4. Whisper.cpp with CUDA
git clone https://github.com/ggerganov/whisper.cpp.git ~/.local/share/whisper.cpp
cd ~/.local/share/whisper.cpp
cmake -B build -DGGML_CUDA=ON
cmake --build build --config Release -j$(nproc)
bash models/download-ggml-model.sh large-v3

# 5. OpenAI API key
echo 'export OPENAI_API_KEY="sk-your-key-here"' >> ~/.zshrc
source ~/.zshrc

# 6. Install the script
git clone https://github.com/manoelneto/dictation-toggle.git /tmp/dictation-toggle
cd /tmp/dictation-toggle && bash install.sh

# 7. Set up Super+D shortcut (see instructions above for your DE)
```

## License

MIT
