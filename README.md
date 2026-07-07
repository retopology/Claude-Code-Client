<h1 align="center">Claude Code Client</h1>
<p align="center"><code>v1.2.0</code></p>
<p align="center">
  English | <a href="README.ru.md">Русский</a>
</p>

A convenient batch script (`.cmd`) for installing, updating, and running the official **Claude Code** CLI client in an isolated environment on Windows.

This script automates the download of the `claude.exe` executable, isolates configuration files from the main system, and provides a simple interface for configuring API connectivity.

---

## Key Features

1. **Isolated Environment (Sandbox / Portable Mode)**:
   - The script overrides the `USERPROFILE` environment variable, pointing it to the `claude` folder inside the script's directory.
   - All global caches, settings, authentication sessions, and Claude Code plugins are stored locally in the script's directory, keeping the global Windows user profile clean.

2. **Automatic Installation**:
   - On the first run, the script automatically checks for the latest version of Claude Code on Anthropic's servers, downloads it using `curl`, and sets it up in the appropriate directories.

3. **Flexible Configuration via `settings.ini`**:
   - On the first run, the script will prompt you to enter the following parameters:
     - `ANTHROPIC_BASE_URL` (defaults to the official API: `https://api.anthropic.com`, but you can specify your own proxy server).
     - `ANTHROPIC_AUTH_TOKEN` (authorization token, useful when using proxies or custom gateways).
     - `MODEL_NAME` (default model, e.g., `claude-opus-4-6`, `claude-sonnet-4-6`, etc.).
     - `UPDATE_BRANCH` (update branch: `main` or `dev`).
   - The configuration is saved to a local `resources\settings.ini` file and automatically loaded on subsequent runs.

4. **Profile System**:
   - The `settings.ini` file supports named sections (profiles), allowing you to store multiple configurations in a single file.
   - A profile can be specified via the `--profile`/`-p` flag with a section name, or selected interactively from a list by running `--profile` without an argument.
   - Example `settings.ini` with a profile:
     ```ini
      ANTHROPIC_BASE_URL=http://localhost:20128/v1
      ANTHROPIC_AUTH_TOKEN=sk-88cc84a27b153ff0-46fd23-2dcde1b5
      MODEL_NAME=openrouter/anthropic/claude-opus-4.6
      UPDATE_BRANCH=dev
      UPDATE_REPOSITORY=https://github.com/retopology/Claude-Code-Client
      UPDATE_MASK=raw/refs/heads/{BRANCH}/claude.cmd

      [Claude Opus 4.8]
      MODEL_NAME=openrouter/anthropic/claude-opus-4.8

      [Ollama Qwen3.5:9b]
      ANTHROPIC_BASE_URL=http://localhost:11434
      MODEL_NAME=qwen3.5:9b
     ```

5. **Script Update**:
   - Built-in update mechanism via the `--update-script`/`-u` flag.
   - The script downloads the latest version from the specified repository and branch, compares versions, and offers to install the update if one is available.
   - Before updating, the current version is saved in `resources\old versions\`.

6. **System PATH Integration**:
   - On first installation, the script checks whether its folder has been added to the user's system `Path` environment variable.
   - If not, it offers to add it automatically, first creating a registry backup in `resources\env_backup.reg` for safety.

7. **Command-Line Argument Passthrough**:
   - All arguments except `--profile`/`-p` and `--update-script`/`-u` are passed directly to the underlying executable (e.g., `claude /fast` or `claude --help`).

---

## Directory Structure After Setup

After the first run, the script will create the following directory structure:

```text
📁 Your_Folder/
├── 📄 claude.cmd       # Startup script
├── 📁 claude/          # Local USERPROFILE (isolated environment)
│   ├── 📁 .claude/     # Configurations, cache, session history, and plugins
│   └── 📁 .local/
│       ├── 📁 bin/                    # Active claude.exe binary
│       └── 📁 share/claude/versions/  # Archive of downloaded versions
└── 📁 resources/
    ├── 📁 old versions/      # Previous script versions (saved during updates)
    ├── 📄 settings.ini       # Connection settings (URL, token, model, profiles)
    ├── 📄 claude.exe         # Copied executable file
    └── 📄 env_backup.reg     # Registry backup (created before modifying PATH)
```

---

## Requirements

- Operating System: **Windows 10 / 11**
- Pre-installed `curl` utility (built into all modern versions of Windows 10/11)
- Internet connection for downloading the executable and interacting with the API

---

## Usage

### First Run

1. Double-click `claude.cmd` or run it from the console:
   ```cmd
   claude
   ```
2. The script will prompt you to enter configuration parameters. If you want to use the default settings (official Anthropic API, `claude-opus-4-6` model, and no additional authorization tokens), simply press **Enter** at each prompt.
3. Wait for the `claude.exe` download to complete.
4. When prompted to add the directory to the system `PATH`, enter `y` (yes) or `n` (no). Choosing `y` will allow you to invoke the client from any folder in the console using the `claude` command.

### Regular Usage

After setup, you can simply run the script to start an interactive Claude Code session:
```cmd
claude
```

You can also pass any standard Claude Code arguments:
```cmd
claude --version
claude /fast
```

### Profiles

Run with a specific profile:
```cmd
claude --profile work
claude -p work
```

Interactive profile selection:
```cmd
claude --profile
claude -p
```

### Script Update

```cmd
claude --update-script
claude -u
claude -u dev
```

<div align="right">
  <img src="https://count.getloli.com/@retopology?name=retopology&theme=rule34&padding=1&offset=0&align=center&scale=1.5&pixelated=1&darkmode=0" width="1" height="1" alt=""/>
  <img src="https://api.visitorbadge.io/api/visitors?path=https%3A%2F%2Fgithub.com%2Fretopology&label=(%E2%97%95%E2%80%BF%E2%97%95%E2%9C%BF)&labelColor=%230d1117&countColor=%2300c647" width="1" height="1" alt=""/>
  <img src="https://hitscounter.dev/api/hit?url=https%3A%2F%2Fgithub.com%2Fretopology&label=&icon=github&color=%230d1117&message=&style=for-the-badge&tz=UTC" width="1" height="1" alt=""/>
</div>