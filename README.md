# Claude Code Client

A convenient batch script (`.cmd`) to install, update, and run the official **Claude Code** CLI client in an isolated environment on Windows.

This script automates the download of the `claude.exe` executable, isolates configuration files from the main system, and provides an easy-to-use setup interface for the API connection.

---

## Key Features

1. **Isolated Environment (Sandbox / Portable Mode)**:
   - The script overrides the `USERPROFILE` environment variable, pointing it to the `claude` folder inside the script's directory.
   - All global caches, settings, authorization sessions, and Claude Code plugins are stored locally in the script's directory, keeping your global Windows user profile clean.

2. **Automatic Installation**:
   - On the first run, the script automatically checks for the latest version of Claude Code on Anthropic's servers, downloads it using `curl`, and sets it up in the correct directories.

3. **Flexible Configuration via `.env`**:
   - On first startup, the script prompts you to enter the following parameters:
     - `ANTHROPIC_BASE_URL` (defaults to the official API: `https://api.anthropic.com`, but you can specify a custom proxy server).
     - `ANTHROPIC_AUTH_TOKEN` (authorization token, useful when using proxies or custom gateways).
     - `MODEL` (default model, e.g., `claude-opus-4-6`, `claude-sonnet-4-6`, etc.).
   - The configuration is saved to the local `resources\.env` file and is automatically loaded on subsequent runs.

4. **System PATH Integration**:
   - The script checks if its folder is added to the user's system `Path` environment variable.
   - If not, it offers to add it automatically, making a registry backup to `resources\env_backup.reg` beforehand for safety.

5. **CLI Argument Forwarding**:
   - All arguments passed to `ccc.cmd` are directly forwarded to the underlying executable (e.g., `ccc.cmd /fast` or `ccc.cmd --help`).

---

## Directory Structure After Setup

After the first run, the script creates the following directory structure:

```text
📁 Your_Project_Folder/
├── 📄 ccc.cmd          # Startup script
├── 📁 claude/          # Local USERPROFILE (isolated environment)
│   ├── 📁 .claude/     # Configurations, cache, session history, and plugins
│   └── 📁 .local/
│       ├── 📁 bin/                    # Active claude.exe binary
│       └── 📁 share/claude/versions/  # Archive of downloaded versions
└── 📁 resources/             # Script resources
    ├── 📄 .env               # Connection settings (URL, Token, Model)
    ├── 📄 claude.exe         # Copied executable file
    └── 📄 env_backup.reg     # Registry backup (created before modifying PATH)
```

---

## Requirements

- Operating System: **Windows 10 / 11**
- Pre-installed `curl` utility (comes built-in with all modern versions of Windows 10/11)
- Internet connection to download the binary and communicate with the API

---

## Usage

### First Launch

1. Double-click `ccc.cmd` or run it from the console:
   ```cmd
   ccc.cmd
   ```
2. The script will prompt you to enter the configuration details. If you want to use the default settings (official Anthropic API, `claude-opus-4-6` model, and no extra auth tokens), simply press **Enter** on each prompt.
3. Wait for `claude.exe` to finish downloading.
4. When prompted to add the directory to your system `PATH`, enter `y` (yes) or `n` (no). Choosing `y` will allow you to call the client from any console folder using the `ccc` command.

### Regular Launch

Once configured, you can simply run the script to start an interactive Claude Code session:
```cmd
ccc.cmd
```

You can also pass any standard Claude Code arguments:
```cmd
ccc.cmd --version
ccc.cmd --model claude-opus-4-6
```

---

## Manual Updates and Configuration Changes

- If you need to change the API URL, token, or default model, open `resources\.env` in any text editor and update the values:
  ```env
  ANTHROPIC_BASE_URL=https://api.anthropic.com
  ANTHROPIC_AUTH_TOKEN=your_token_here
  MODEL=claude-opus-4-6
  ```
- To reset settings and go through the initial configuration steps again, simply delete `resources\.env`.
