#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  ZER0 Installer — Arch Linux
#  Desarrollado por LogLabs — https://github.com/LogLabsGit
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

R="\033[38;5;196m"
O="\033[38;5;208m"
Y="\033[38;5;226m"
G="\033[38;5;46m"
C="\033[38;5;51m"
W="\033[97m"
DIM="\033[2m"
B="\033[1m"
RST="\033[0m"

INSTALL_DIR="$HOME/.local/bin"

# ── Banner ────────────────────────────────────────────────────────────────────
clear
echo ""
echo -e "${R}  ██████╗ ███████╗██████╗  ██████╗ ${RST}"
echo -e "${O}  ╚════██╗██╔════╝██╔══██╗██╔═████╗${RST}"
echo -e "${Y}   █████╔╝  ZER0   ██████╔╝██║██╔██║${RST}"
echo -e "${O}  ██╔═══╝ ██╔══╝  ██╔══██╗████╔╝██║${RST}"
echo -e "${R}  ███████╗███████╗██║  ██║╚██████╔╝${RST}"
echo -e "${DIM}  ╚══════╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ${RST}"
echo ""

# ── Selector de idioma con flechas ────────────────────────────────────────────
OPCIONES=("Español" "English")
SELECTED=0

draw_menu() {
    for i in "${!OPCIONES[@]}"; do
        tput el 2>/dev/null || true
        if [[ $i -eq $SELECTED ]]; then
            echo -e "  ${C}▶ ${W}${B}${OPCIONES[$i]}${RST}"
        else
            echo -e "  ${DIM}  ${OPCIONES[$i]}${RST}"
        fi
    done
    tput cuu ${#OPCIONES[@]} 2>/dev/null || true
}

echo -e "  ${W}${B}Elige tu idioma / Choose your language:${RST}"
echo ""

tput civis 2>/dev/null || true   # ocultar cursor

# Dibujar menú inicial
for i in "${!OPCIONES[@]}"; do
    if [[ $i -eq $SELECTED ]]; then
        echo -e "  ${C}▶ ${W}${B}${OPCIONES[$i]}${RST}"
    else
        echo -e "  ${DIM}  ${OPCIONES[$i]}${RST}"
    fi
done
tput cuu ${#OPCIONES[@]} 2>/dev/null || true

while true; do
    IFS= read -rsn1 key
    if [[ $key == $'\x1b' ]]; then
        read -rsn2 -t 0.1 key2
        case "$key2" in
            '[A') (( SELECTED > 0 )) && (( SELECTED-- )) || true ;;
            '[B') (( SELECTED < ${#OPCIONES[@]}-1 )) && (( SELECTED++ )) || true ;;
        esac
        draw_menu
    elif [[ $key == "" || $key == $'\n' ]]; then
        break
    fi
done

# Bajar cursor al final del menú
tput cud ${#OPCIONES[@]} 2>/dev/null || echo -e "\n"
tput cnorm 2>/dev/null || true   # restaurar cursor
echo ""

if [[ $SELECTED -eq 0 ]]; then
    LANG_CODE="es"
    echo -e "  ${G}✔${RST}  Idioma seleccionado: ${W}Español${RST}"
else
    LANG_CODE="en"
    echo -e "  ${G}✔${RST}  Language selected: ${W}English${RST}"
fi
echo ""

# ── Mensajes según idioma ─────────────────────────────────────────────────────
if [[ "$LANG_CODE" == "es" ]]; then
    MSG_INSTALLING="Instalando ZER0 en tu sistema..."
    MSG_NO_PYTHON="Python 3 no encontrado. Instálalo con: sudo pacman -S python"
    MSG_PY_OLD="Se requiere Python 3.10+. Versión actual:"
    MSG_PY_OK="Python detectado"
    MSG_DIR="Directorio:"
    MSG_INSTALLED="Instalado:"
    MSG_CONFIGURED="Configurado:"
    MSG_ALREADY="ya configurado"
    MSG_ACCESSIBLE="zero accesible desde el PATH"
    MSG_RELOAD="Reinicia tu terminal o ejecuta:"
    MSG_DONE="ZER0 instalado correctamente.  ✓"
    MSG_OPEN="Para abrir ZER0 escribe cualquiera de:"
    MSG_DEV="Desarrollado por:"
    MSG_REPO="Repo:"
else
    MSG_INSTALLING="Installing ZER0 on your system..."
    MSG_NO_PYTHON="Python 3 not found. Install it with: sudo pacman -S python"
    MSG_PY_OLD="Python 3.10+ required. Current version:"
    MSG_PY_OK="Python detected"
    MSG_DIR="Directory:"
    MSG_INSTALLED="Installed:"
    MSG_CONFIGURED="Configured:"
    MSG_ALREADY="already configured"
    MSG_ACCESSIBLE="zero accessible from PATH"
    MSG_RELOAD="Restart your terminal or run:"
    MSG_DONE="ZER0 installed successfully.  ✓"
    MSG_OPEN="To open ZER0 type any of:"
    MSG_DEV="Developed by:"
    MSG_REPO="Repo:"
fi

echo -e "${C}  ╭──────────────────────────────────────╮${RST}"
echo -e "${C}  │${RST}  ${B}${MSG_INSTALLING}${RST}   ${C}│${RST}"
echo -e "${C}  ╰──────────────────────────────────────╯${RST}"
echo ""

# ── Verificar Python 3.10+ ────────────────────────────────────────────────────
if ! command -v python3 &>/dev/null; then
    echo -e "  ${R}✘${RST}  ${MSG_NO_PYTHON}\n"
    exit 1
fi

PY_MAJOR=$(python3 -c "import sys; print(sys.version_info.major)")
PY_MINOR=$(python3 -c "import sys; print(sys.version_info.minor)")
PY_VER="$PY_MAJOR.$PY_MINOR"

if [[ "$PY_MAJOR" -lt 3 || ( "$PY_MAJOR" -eq 3 && "$PY_MINOR" -lt 10 ) ]]; then
    echo -e "  ${R}✘${RST}  ${MSG_PY_OLD} ${W}$PY_VER${RST}\n"
    exit 1
fi
echo -e "  ${G}✔${RST}  ${MSG_PY_OK}: ${W}$PY_VER${RST}"

# ── Crear directorio ───────────────────────────────────────────────────────────
mkdir -p "$INSTALL_DIR"
echo -e "  ${G}✔${RST}  ${MSG_DIR} ${DIM}$INSTALL_DIR${RST}"

# ── Escribir zer0.py embebido ─────────────────────────────────────────────────
cat > "$INSTALL_DIR/zero" << PYEOF
#!/usr/bin/env python3
"""
ZER0 — Command alias manager for Arch Linux
Desarrollado por LogLabs — https://github.com/LogLabsGit
"""

import os
import sys
import json
import re
import subprocess
from pathlib import Path

CONFIG_DIR  = Path.home() / ".config" / "zer0"
CONFIG_FILE = CONFIG_DIR / "config.json"

R   = "\033[38;5;196m"
O   = "\033[38;5;208m"
Y   = "\033[38;5;226m"
C   = "\033[38;5;51m"
W   = "\033[97m"
G   = "\033[38;5;46m"
DIM = "\033[2m"
B   = "\033[1m"
RST = "\033[0m"

VERSION = "1.0.0"
AUTHOR  = "LogLabs"
GITHUB  = "https://github.com/LogLabsGit"
REPO    = "https://github.com/LogLabsGit/ZER0"

BANNER = f"""
{R}  ██████╗ ███████╗██████╗  ██████╗ {RST}
{O}  ╚════██╗██╔════╝██╔══██╗██╔═████╗{RST}
{Y}   █████╔╝█████╗  ██████╔╝██║██╔██║{RST}
{O}  ██╔═══╝ ██╔══╝  ██╔══██╗████╔╝██║{RST}
{R}  ███████╗███████╗██║  ██║╚██████╔╝{RST}
{DIM}  ╚══════╝╚══════╝╚═╝  ╚═╝ ╚═════╝ {RST}"""

_ANSI = re.compile(r"\033\[[0-9;]*m")

# ── Textos por idioma ─────────────────────────────────────────────────────────
STRINGS = {
    "es": {
        "welcome_hello":    "  Hola, {name}.             ",
        "welcome_online":   "  ZER0 v{v} está en línea.       ",
        "first_title":      "  Primera vez aquí. ¡Bienvenido!  ",
        "first_sub":        "  ZER0 v{v} — Arch Linux         ",
        "ask_name":         "¿Cómo te llamas?",
        "default_name":     "Usuario",
        "ready":            "  Listo, {name}. ZER0 ya es tuyo.  ",
        "tip":              "Tip: escribe  {help}  para ver los comandos.",
        "dev":              "Desarrollado por:",
        "hint_help":        "Escribe  {help}  para ver los comandos.  {exit}  para salir.",
        "no_aliases":       "No hay atajos guardados todavía.",
        "no_aliases_tip":   "Agrega uno con:  {add}",
        "aliases_title":    "Atajos guardados:",
        "alias_saved":      "Atajo guardado:    {a}  →  {c}",
        "alias_updated":    "Atajo actualizado: {a}  →  {c}",
        "alias_deleted":    "Atajo eliminado:   {a}",
        "alias_not_found":  "El atajo '{a}' no existe.",
        "cmd_not_found":    "Comando o atajo '{a}' no encontrado.",
        "cmd_not_found_tip":"Escribe  {list}  para ver los atajos disponibles.",
        "usage_add":        "Uso:  add <atajo> <comando completo>",
        "usage_rm":         "Uso:  rm <atajo>",
        "goodbye":          "Hasta luego, {name}. 👋",
        "lang_changed":     "Idioma cambiado a Español.",
        "lang_select":      "Elige tu idioma / Choose your language:",
        "help_title":       "Comandos disponibles:",
        "help_cmds": [
            ("list",               "Listar todos los atajos"),
            ("add <atajo> <cmd>",  "Agregar o actualizar un atajo"),
            ("rm  <atajo>",        "Eliminar un atajo"),
            ("<atajo> [args…]",    "Ejecutar un atajo"),
            ("lang",               "Cambiar idioma"),
            ("help",               "Mostrar esta ayuda"),
            ("version",            "Mostrar versión"),
            ("exit / quit",        "Salir de ZER0"),
        ],
    },
    "en": {
        "welcome_hello":    "  Hello, {name}.             ",
        "welcome_online":   "  ZER0 v{v} is online.           ",
        "first_title":      "  First time here. Welcome!       ",
        "first_sub":        "  ZER0 v{v} — Arch Linux         ",
        "ask_name":         "What's your name?",
        "default_name":     "User",
        "ready":            "  Done, {name}. ZER0 is yours.    ",
        "tip":              "Tip: type  {help}  to see all commands.",
        "dev":              "Developed by:",
        "hint_help":        "Type  {help}  to see commands.  {exit}  to quit.",
        "no_aliases":       "No shortcuts saved yet.",
        "no_aliases_tip":   "Add one with:  {add}",
        "aliases_title":    "Saved shortcuts:",
        "alias_saved":      "Shortcut saved:    {a}  →  {c}",
        "alias_updated":    "Shortcut updated:  {a}  →  {c}",
        "alias_deleted":    "Shortcut removed:  {a}",
        "alias_not_found":  "Shortcut '{a}' does not exist.",
        "cmd_not_found":    "Command or shortcut '{a}' not found.",
        "cmd_not_found_tip":"Type  {list}  to see available shortcuts.",
        "usage_add":        "Usage:  add <shortcut> <full command>",
        "usage_rm":         "Usage:  rm <shortcut>",
        "goodbye":          "See you, {name}. 👋",
        "lang_changed":     "Language changed to English.",
        "lang_select":      "Elige tu idioma / Choose your language:",
        "help_title":       "Available commands:",
        "help_cmds": [
            ("list",               "List all shortcuts"),
            ("add <shortcut> <cmd>","Add or update a shortcut"),
            ("rm  <shortcut>",     "Delete a shortcut"),
            ("<shortcut> [args…]", "Run a shortcut"),
            ("lang",               "Change language"),
            ("help",               "Show this help"),
            ("version",            "Show version"),
            ("exit / quit",        "Exit ZER0"),
        ],
    },
}

def t(config: dict, key: str, **kwargs) -> str:
    lang = config.get("lang", "es")
    s = STRINGS.get(lang, STRINGS["es"]).get(key, key)
    if kwargs:
        s = s.format(**kwargs)
    return s

# ── Config ────────────────────────────────────────────────────────────────────

def load_config() -> dict:
    if not CONFIG_FILE.exists():
        return {"name": None, "lang": "es", "aliases": {}}
    try:
        with open(CONFIG_FILE) as f:
            cfg = json.load(f)
            if "lang" not in cfg:
                cfg["lang"] = "es"
            return cfg
    except (json.JSONDecodeError, OSError):
        return {"name": None, "lang": "es", "aliases": {}}

def save_config(config: dict) -> None:
    CONFIG_DIR.mkdir(parents=True, exist_ok=True)
    with open(CONFIG_FILE, "w") as f:
        json.dump(config, f, indent=2, ensure_ascii=False)

# ── UI Helpers ────────────────────────────────────────────────────────────────

def _raw_len(s: str) -> int:
    return len(_ANSI.sub("", s))

def box(lines: list, color: str = C) -> None:
    width = max(_raw_len(l) for l in lines) + 2
    print(f"{color}  ╭{'─' * width}╮{RST}")
    for line in lines:
        pad = width - _raw_len(line) - 1
        print(f"{color}  │{RST} {line}{' ' * pad}{color}│{RST}")
    print(f"{color}  ╰{'─' * width}╯{RST}")

def success(msg: str) -> None:
    print(f"\n  {G}✔{RST}  {msg}\n")

def error(msg: str) -> None:
    print(f"\n  {R}✘{RST}  {msg}\n")

def info(msg: str) -> None:
    print(f"  {DIM}{msg}{RST}")

def print_branding(config: dict) -> None:
    print(f"  {DIM}{t(config, 'dev')} {W}{AUTHOR}{RST}")
    print(f"  {DIM}GitHub  › {C}{GITHUB}{RST}")
    print(f"  {DIM}Repo    › {C}{REPO}{RST}")
    print()

def get_prompt() -> str:
    user = os.environ.get("USER", os.environ.get("LOGNAME", "user"))
    cwd  = Path.cwd()
    home = Path.home()
    try:
        rel = "~" + str(cwd.relative_to(home)) if cwd != home else "~"
    except ValueError:
        rel = str(cwd)
    return f"{G}[{RST}{W}{user}{RST}{G}@{RST}{C}ZER0{RST}{G} {RST}{Y}{rel}{RST}{G}]{RST}{W}\$ {RST}"

# ── Selector de idioma con flechas ────────────────────────────────────────────

def pick_lang() -> str:
    import tty, termios
    options  = [("es", "  Español"), ("en", "  English")]
    selected = 0

    def draw():
        sys.stdout.write(f"\033[{len(options)}A")
        for i, (_, label) in enumerate(options):
            if i == selected:
                sys.stdout.write(f"\r  {C}▶ {W}{B}{label}{RST}\n")
            else:
                sys.stdout.write(f"\r  {DIM}  {label}{RST}\n")
        sys.stdout.flush()

    print(f"\n  {W}{B}{STRINGS['es']['lang_select']}{RST}\n")
    for _, label in options:
        print(f"  {DIM}  {label}{RST}")

    fd  = sys.stdin.fileno()
    old = termios.tcgetattr(fd)
    sys.stdout.write("\033[?25l")  # ocultar cursor
    sys.stdout.flush()

    try:
        tty.setraw(fd)
        draw()
        while True:
            ch = sys.stdin.read(1)
            if ch == "\x1b":
                ch2 = sys.stdin.read(2)
                if ch2 == "[A" and selected > 0:
                    selected -= 1
                    draw()
                elif ch2 == "[B" and selected < len(options) - 1:
                    selected += 1
                    draw()
            elif ch in ("\r", "\n", ""):
                break
            elif ch == "\x03":
                raise KeyboardInterrupt
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, old)
        sys.stdout.write("\033[?25h")  # restaurar cursor
        sys.stdout.flush()

    print()
    return options[selected][0]

# ── First Run ─────────────────────────────────────────────────────────────────

def first_run(config: dict) -> None:
    print(BANNER)
    print()
    # Elegir idioma primero
    lang = pick_lang()
    config["lang"] = lang
    print()

    box([
        t(config, "first_title"),
        t(config, "first_sub", v=VERSION),
    ])
    print()
    try:
        name = input(f"  {W}{t(config, 'ask_name')}{RST}  {DIM}›{RST} ").strip()
    except (KeyboardInterrupt, EOFError):
        print()
        sys.exit(0)

    if not name:
        name = t(config, "default_name")

    config["name"] = name
    save_config(config)

    print()
    box([f"  {t(config, 'ready', name=f'{B}{name}{RST}{G}')}"], color=G)
    print()
    info(t(config, "tip", help=f"{W}help{RST}{DIM}"))
    print()
    print_branding(config)

# ── Welcome ───────────────────────────────────────────────────────────────────

def show_welcome(config: dict) -> None:
    print(BANNER)
    print()
    box([
        t(config, "welcome_hello",  name=f"{B}{config['name']}{RST}{C}"),
        t(config, "welcome_online", v=VERSION),
    ])
    print()
    print_branding(config)

# ── Commands ──────────────────────────────────────────────────────────────────

def list_aliases(config: dict) -> None:
    aliases = config.get("aliases", {})
    if not aliases:
        info(t(config, "no_aliases"))
        print()
        info(t(config, "no_aliases_tip", add=f"{W}add <atajo> <comando>{RST}{DIM}"))
        print()
        return
    print(f"\n  {B}{W}{t(config, 'aliases_title')}{RST}\n")
    max_k = max(len(k) for k in aliases)
    for key, val in sorted(aliases.items()):
        print(f"  {C}  {key:<{max_k}}{RST}  {DIM}→{RST}  {val}")
    print()

def add_alias(config: dict, alias: str, command: str) -> None:
    existed = alias in config["aliases"]
    config["aliases"][alias] = command
    save_config(config)
    key = "alias_updated" if existed else "alias_saved"
    success(t(config, key, a=f"{C}{alias}{RST}", c=command))

def remove_alias(config: dict, alias: str) -> None:
    if alias not in config["aliases"]:
        error(t(config, "alias_not_found", a=alias))
        return
    del config["aliases"][alias]
    save_config(config)
    success(t(config, "alias_deleted", a=f"{C}{alias}{RST}"))

def run_alias(config: dict, alias: str, extra_args: list) -> None:
    aliases = config.get("aliases", {})
    if alias not in aliases:
        error(t(config, "cmd_not_found", a=alias))
        info(t(config, "cmd_not_found_tip", list=f"{W}list{RST}{DIM}"))
        print()
        return
    cmd = aliases[alias]
    if extra_args:
        cmd += " " + " ".join(extra_args)
    subprocess.run(cmd, shell=True)

def change_lang(config: dict) -> None:
    lang = pick_lang()
    config["lang"] = lang
    save_config(config)
    print()
    success(t(config, "lang_changed"))

def show_help(config: dict) -> None:
    print(f"\n  {B}{W}{t(config, 'help_title')}{RST}\n")
    cmds = t(config, "help_cmds")
    max_c = max(len(c) for c, _ in cmds)
    for cmd, desc in cmds:
        print(f"  {C}  {cmd:<{max_c}}{RST}   {DIM}{desc}{RST}")
    print()

def show_version(config: dict) -> None:
    print(f"\n  {B}ZER0{RST}  {DIM}v{VERSION}{RST}\n")
    print_branding(config)

# ── REPL ──────────────────────────────────────────────────────────────────────

def repl(config: dict) -> None:
    show_welcome(config)
    hint = t(config, "hint_help",
             help=f"{W}help{RST}{DIM}",
             exit=f"{W}exit{RST}{DIM}")
    print(f"  {DIM}{hint}{RST}\n")

    while True:
        try:
            line = input(get_prompt()).strip()
        except (KeyboardInterrupt, EOFError):
            print(f"\n\n  {DIM}{t(config, 'goodbye', name=config['name'])}{RST}\n")
            break

        if not line:
            continue

        parts = line.split()
        cmd   = parts[0].lower()
        args  = parts[1:]

        if cmd in ("exit", "quit", "q"):
            print(f"\n  {DIM}{t(config, 'goodbye', name=config['name'])}{RST}\n")
            break
        elif cmd in ("list", "ls", "-l"):
            list_aliases(config)
        elif cmd in ("add", "a"):
            if len(args) < 2:
                error(t(config, "usage_add"))
            else:
                add_alias(config, args[0], " ".join(args[1:]))
        elif cmd in ("rm", "remove", "del", "delete"):
            if not args:
                error(t(config, "usage_rm"))
            else:
                remove_alias(config, args[0])
        elif cmd == "lang":
            change_lang(config)
        elif cmd in ("help", "--help", "-h"):
            show_help(config)
        elif cmd in ("version", "--version", "-v"):
            show_version(config)
        else:
            run_alias(config, cmd, args)

# ── Entry Point ───────────────────────────────────────────────────────────────

def main() -> None:
    config = load_config()
    if config.get("name") is None:
        first_run(config)
        config = load_config()
    repl(config)

if __name__ == "__main__":
    main()
PYEOF

chmod +x "$INSTALL_DIR/zero"
echo -e "  ${G}✔${RST}  ${MSG_INSTALLED} ${DIM}$INSTALL_DIR/zero${RST}"

# ── Bloque shell ──────────────────────────────────────────────────────────────
ZER0_BLOCK='
# ─── ZER0 ────────────────────────────────────────────────
export PATH="$HOME/.local/bin:$PATH"
alias -- -Z="zero"
export Z="zero"
# ─────────────────────────────────────────────────────────'

inject_bash_zsh() {
    local RC="$1"
    [[ ! -f "$RC" ]] && return
    if grep -q '─── ZER0' "$RC" 2>/dev/null; then
        echo -e "  ${DIM}✓  $RC ${MSG_ALREADY}${RST}"
        return
    fi
    echo "$ZER0_BLOCK" >> "$RC"
    echo -e "  ${G}✔${RST}  ${MSG_CONFIGURED} ${DIM}$RC${RST}"
}

inject_fish() {
    local RC="$1"
    [[ ! -f "$RC" ]] && return
    if grep -q 'ZER0' "$RC" 2>/dev/null; then
        echo -e "  ${DIM}✓  $RC ${MSG_ALREADY}${RST}"
        return
    fi
    {
        echo ""
        echo "# ─── ZER0 ────────────────────────────────────────────────"
        echo 'fish_add_path "$HOME/.local/bin"'
        echo 'alias -- -Z="zero"'
        echo 'set -x Z zero'
        echo "# ─────────────────────────────────────────────────────────"
    } >> "$RC"
    echo -e "  ${G}✔${RST}  ${MSG_CONFIGURED} ${DIM}$RC${RST}"
}

[[ -f "$HOME/.bashrc" ]] && inject_bash_zsh "$HOME/.bashrc"
[[ -f "$HOME/.zshrc"  ]] && inject_bash_zsh "$HOME/.zshrc"
[[ -f "$HOME/.config/fish/config.fish" ]] && inject_fish "$HOME/.config/fish/config.fish"

if [[ ! -f "$HOME/.bashrc" && ! -f "$HOME/.zshrc" ]]; then
    echo "$ZER0_BLOCK" >> "$HOME/.bashrc"
fi

export PATH="$HOME/.local/bin:$PATH"

# ── Resultado ─────────────────────────────────────────────────────────────────
echo ""
if command -v zero &>/dev/null; then
    echo -e "  ${G}✔${RST}  ${MSG_ACCESSIBLE}"
else
    echo -e "  ${Y}!${RST}  ${MSG_RELOAD}"
fi

echo ""
echo -e "${G}  ╭────────────────────────────────────────────────╮${RST}"
echo -e "${G}  │${RST}  ${B}${MSG_DONE}${RST}            ${G}│${RST}"
echo -e "${G}  │${RST}                                              ${G}│${RST}"
echo -e "${G}  │${RST}  ${MSG_OPEN}      ${G}│${RST}"
echo -e "${G}  │${RST}                                              ${G}│${RST}"
echo -e "${G}  │${RST}    ${C}zero${RST}    ${C}-Z${RST}    ${C}\$Z${RST}                         ${G}│${RST}"
echo -e "${G}  │${RST}                                              ${G}│${RST}"
echo -e "${G}  ╰────────────────────────────────────────────────╯${RST}"
echo ""
echo -e "  ${DIM}${MSG_RELOAD}${RST}"
echo -e "    ${W}source ~/.bashrc${RST}  ${DIM}(bash)${RST}"
echo -e "    ${W}source ~/.zshrc${RST}   ${DIM}(zsh)${RST}"
echo ""
echo -e "  ${DIM}${MSG_DEV} ${W}LogLabs${RST}"
echo -e "  ${DIM}${MSG_REPO} ${C}https://github.com/LogLabsGit/ZER0${RST}"
echo ""
