#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

show_banner() {
    clear
    echo -e "${BLUE}"
    cat << "EOF"
██████╗ ███████╗██████╗  ██████╗ 
╚════██╗██╔════╝██╔══██╗██╔═████╗
 █████╔╝█████╗  ██████╔╝██║██╔██║
██╔═══╝ ██╔══╝  ██╔══██╗████╔╝██║
███████╗███████╗██║  ██║╚██████╔╝
╚══════╝╚══════╝╚═╝  ╚═╝ ╚═════╝ 
EOF
    echo -e "${NC}"
    echo -e "${GREEN}ZER0 Installer v1.0.4${NC}"
    echo -e "${CYAN}Command alias manager for Arch Linux${NC}"
    echo "================================"
    echo ""
}

select_option() {
    ESC=$(printf "\033")
    cursor_blink_on()  { printf "$ESC[?25h"; }
    cursor_blink_off() { printf "$ESC[?25l"; }
    cursor_to()        { printf "$ESC[$1;${2:-1}H"; }
    print_option()     { printf "   $1 "; }
    print_selected()   { printf "  $ESC[7m $1 $ESC[27m"; }
    get_cursor_row()   { IFS=';' read -sdR -p $'\E[6n' ROW COL; echo ${ROW#*[}; }
    key_input()        { read -s -n3 key 2>/dev/null >&2; [[ $key = $ESC[A ]] && echo up; [[ $key = $ESC[B ]] && echo down; }

    local options=("$@")
    local selected=0
    local cursor_row=$(get_cursor_row)
    local start_row=$((cursor_row - ${#options[@]} - 1))
    
    trap "cursor_blink_on; stty echo; printf '\n'; exit" 2
    cursor_blink_off
    
    while true; do
        for i in "${!options[@]}"; do
            cursor_to $((start_row + i))
            if [ $i -eq $selected ]; then
                print_selected "${options[$i]}"
            else
                print_option "${options[$i]}"
            fi
        done
        
        case $(key_input) in
            up)    selected=$(( (selected - 1 + ${#options[@]}) % ${#options[@]} )) ;;
            down)  selected=$(( (selected + 1) % ${#options[@]} )) ;;
            '')    break ;;
        esac
    done
    
    cursor_to $((start_row + ${#options[@]}))
    cursor_blink_on
    
    return $selected
}

check_requirements() {
    echo -e "\n${YELLOW}🔍 Verificando requisitos...${NC}"
    
    if ! command -v python3 &> /dev/null; then
        echo -e "${RED}❌ Python 3 no está instalado${NC}"
        echo "   Instálalo con: sudo pacman -S python"
        exit 1
    fi
    
    python_version=$(python3 -c 'import sys; print(f"{sys.version_info[0]}.{sys.version_info[1]}")')
    required_version="3.10"
    if [ "$(printf '%s\n' "$required_version" "$python_version" | sort -V | head -n1)" != "$required_version" ]; then
        echo -e "${RED}❌ Se requiere Python $required_version o superior (tienes $python_version)${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Python $python_version detectado${NC}"
    
    if [[ ! -f /etc/arch-release ]] && [[ ! -f /etc/os-release ]] || ! grep -qi "arch" /etc/os-release 2>/dev/null; then
        echo -e "${YELLOW}⚠️  Este programa está diseñado para Arch Linux${NC}"
        echo "   Algunos comandos pueden no funcionar en otras distribuciones"
    fi
}

setup_directories() {
    echo -e "\n${YELLOW}📁 Creando estructura de directorios...${NC}"
    mkdir -p ~/.local/bin
    mkdir -p ~/.config/zer0
    mkdir -p ~/.cache/zer0
    mkdir -p ~/.local/share/zer0/languages
    mkdir -p ~/.local/share/zer0/themes
    echo -e "${GREEN}✅ Directorios creados${NC}"
}

get_user_preferences() {
    echo -e "\n${YELLOW}🌐 Selecciona tu idioma / Select your language:${NC}"
    options=("Español" "English")
    select_option "${options[@]}"
    language=$?
    
    if [ $language -eq 0 ]; then
        lang="es"
        echo -e "${GREEN}✅ Idioma seleccionado: Español${NC}"
    else
        lang="en"
        echo -e "${GREEN}✅ Language selected: English${NC}"
    fi
    
    echo -e "\n${YELLOW}👤 ¿Cómo te llamas? / What's your name?${NC}"
    read -p "> " user_name
    if [ -z "$user_name" ]; then
        user_name="user"
    fi
    
    echo -e "\n${YELLOW}🎨 ¿Quieres activar el modo aprendiz? (explica cada comando)${NC}"
    echo -e "${CYAN}   Enable learn mode? (explains each command)${NC}"
    options=("Sí / Yes" "No / No")
    select_option "${options[@]}"
    learn_mode=$?
    
    if [ $learn_mode -eq 0 ]; then
        learn="true"
        echo -e "${GREEN}✅ Modo aprendiz activado${NC}"
    else
        learn="false"
        echo -e "${GREEN}✅ Modo aprendiz desactivado${NC}"
    fi
    
    echo -e "\n${YELLOW}🎨 Selecciona un tema / Select a theme:${NC}"
    options=("Default" "Dark" "Light" "Hacker")
    select_option "${options[@]}"
    theme=$?
    
    case $theme in
        0) theme_name="default" ;;
        1) theme_name="dark" ;;
        2) theme_name="light" ;;
        3) theme_name="hacker" ;;
    esac
    echo -e "${GREEN}✅ Tema seleccionado: $theme_name${NC}"
}

create_initial_config() {
    echo -e "\n${YELLOW}⚙️  Creando configuración inicial...${NC}"
    
    cat > ~/.config/zer0/config.json << EOF
{
    "name": "$user_name",
    "lang": "$lang",
    "learn_mode": $learn,
    "theme": "$theme_name",
    "version": "1.0.4",
    "aliases": {}
}
EOF
    echo -e "${GREEN}✅ Configuración creada${NC}"
}

create_python_files() {
    echo -e "\n${YELLOW}🐍 Instalando ZER0...${NC}"
    
    cat > ~/.local/bin/zero << 'EOF'
#!/usr/bin/env python3
import os
import sys
import json
import signal
import readline
import atexit
from pathlib import Path
from datetime import datetime

CONFIG_DIR = Path.home() / ".config" / "zer0"
CACHE_DIR = Path.home() / ".cache" / "zer0"
DATA_DIR = Path.home() / ".local" / "share" / "zer0"
CONFIG_FILE = CONFIG_DIR / "config.json"
HISTORY_FILE = CACHE_DIR / "history"

class ZER0:
    def __init__(self, learn_mode=False):
        self.config = self.load_config()
        self.running = True
        self.learn_mode = learn_mode or self.config.get('learn_mode', False)
        self.theme = self.config.get('theme', 'default')
        self.setup_readline()
        self.setup_signal_handlers()
        self.default_shortcuts = self.get_default_shortcuts()
        self.descriptions = self.get_descriptions()
        
        if not self.config.get('aliases'):
            self.config['aliases'] = {}
            self.load_default_shortcuts()
    
    def setup_signal_handlers(self):
        signal.signal(signal.SIGINT, self.signal_handler)
    
    def signal_handler(self, sig, frame):
        print("\n\n👋 ¡Hasta luego!")
        sys.exit(0)
    
    def setup_readline(self):
        try:
            readline.read_history_file(HISTORY_FILE)
        except FileNotFoundError:
            pass
        atexit.register(readline.write_history_file, HISTORY_FILE)
        readline.parse_and_bind("tab: complete")
    
    def load_config(self):
        try:
            with open(CONFIG_FILE, 'r') as f:
                return json.load(f)
        except:
            return {"name": "user", "lang": "en", "learn_mode": False, "theme": "default", "aliases": {}}
    
    def save_config(self):
        with open(CONFIG_FILE, 'w') as f:
            json.dump(self.config, f, indent=2)
    
    def get_default_shortcuts(self):
        return {
            "upd": "sudo pacman -Syu",
            "ins": "sudo pacman -S",
            "rem": "sudo pacman -Rns",
            "search": "pacman -Ss",
            "orphans": "sudo pacman -Rns $(pacman -Qdtq)",
            "unlock": "sudo rm /var/lib/pacman/db.lck",
            "gs": "git status",
            "ga": "git add .",
            "gc": "git commit -m",
            "gp": "git push",
            "gpl": "git pull",
            "glog": "git log --oneline --graph --decorate",
            "sstart": "sudo systemctl start",
            "sstop": "sudo systemctl stop",
            "srestart": "sudo systemctl restart",
            "sstatus": "sudo systemctl status",
            "slist": "systemctl list-units --type=service",
            "dps": "docker ps",
            "dcu": "docker-compose up -d",
            "dcd": "docker-compose down",
            "dlogs": "docker logs -f",
            "dprune": "docker system prune -af",
            "py": "python3",
            "pip": "pip install",
            "node": "node",
            "npm": "npm install",
            "ip": "ip addr",
            "ping": "ping -c 4",
            "df": "df -h",
            "du": "du -sh",
            "ps": "ps aux",
            "top": "htop",
            "kill": "kill -9",
            "neofetch": "neofetch",
            "arch": "uname -a"
        }
    
    def get_descriptions(self):
        return {
            "upd": {"cmd": "sudo pacman -Syu", "desc": "Actualiza el sistema (Sync + Upgrade)", "cat": "pacman"},
            "ins": {"cmd": "sudo pacman -S", "desc": "Instala un paquete", "cat": "pacman"},
            "rem": {"cmd": "sudo pacman -Rns", "desc": "Elimina un paquete y sus dependencias", "cat": "pacman"},
            "search": {"cmd": "pacman -Ss", "desc": "Busca un paquete en los repositorios", "cat": "pacman"},
            "gs": {"cmd": "git status", "desc": "Muestra el estado del repositorio", "cat": "git"},
            "ga": {"cmd": "git add .", "desc": "Añade todos los archivos al staging", "cat": "git"},
            "gc": {"cmd": "git commit -m", "desc": "Crea un commit con mensaje", "cat": "git"},
            "gp": {"cmd": "git push", "desc": "Sube los cambios al remoto", "cat": "git"},
            "gpl": {"cmd": "git pull", "desc": "Baja los cambios del remoto", "cat": "git"}
        }
    
    def load_default_shortcuts(self):
        for name, cmd in self.default_shortcuts.items():
            if name not in self.config['aliases']:
                self.config['aliases'][name] = cmd
        self.save_config()
    
    def show_banner(self):
        themes = {
            "default": {"prompt": "📌", "color": ""},
            "dark": {"prompt": "🌙", "color": "\033[90m"},
            "light": {"prompt": "☀️", "color": "\033[97m"},
            "hacker": {"prompt": "💻", "color": "\033[92m"}
        }
        theme = themes.get(self.theme, themes["default"])
        
        os.system('clear' if os.name == 'posix' else 'cls')
        print(f"{theme['color']}")
        print("██████╗ ███████╗██████╗  ██████╗ ")
        print("╚════██╗██╔════╝██╔══██╗██╔═████╗")
        print(" █████╔╝█████╗  ██████╔╝██║██╔██║")
        print("██╔═══╝ ██╔══╝  ██╔══██╗████╔╝██║")
        print("███████╗███████╗██║  ██║╚██████╔╝")
        print("╚══════╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ")
        print(f"{theme['color']}v1.0.4{NC}")
        print(f"{theme['prompt']} ZER0 is online. Type 'help' for commands.\n")
    
    def get_prompt(self):
        themes = {
            "default": f"[{self.config.get('name', 'user')}@ZER0 ~]$ ",
            "dark": f"\033[90m[{self.config.get('name', 'user')}@ZER0 ~]$\033[0m ",
            "light": f"\033[97m[{self.config.get('name', 'user')}@ZER0 ~]$\033[0m ",
            "hacker": f"\033[92m[{self.config.get('name', 'user')}@ZER0 ~]$\033[0m "
        }
        return themes.get(self.theme, themes["default"])
    
    def run(self):
        self.show_banner()
        
        while self.running:
            try:
                cmd = input(self.get_prompt()).strip()
                if not cmd:
                    continue
                self.process_command(cmd)
            except EOFError:
                self.do_exit()
            except KeyboardInterrupt:
                print("\n")
                continue
    
    def process_command(self, cmd):
        parts = cmd.split(maxsplit=1)
        command = parts[0].lower()
        args = parts[1] if len(parts) > 1 else ""
        
        if command in ['exit', 'quit', 'q']:
            self.do_exit()
        elif command in ['list', 'ls']:
            self.do_list()
        elif command in ['add', 'a']:
            self.do_add(args)
        elif command in ['rm', 'remove', 'del']:
            self.do_rm(args)
        elif command == 'lang':
            self.do_lang()
        elif command == 'theme':
            self.do_theme(args)
        elif command == 'learn':
            self.do_learn()
        elif command == 'export':
            self.do_export(args)
        elif command == 'import':
            self.do_import(args)
        elif command == 'search':
            self.do_search(args)
        elif command == 'explain':
            self.do_explain(args)
        elif command == 'category':
            self.do_category(args)
        elif command in ['help', '--help', '-h']:
            self.do_help()
        elif command in ['version', '-v']:
            self.do_version()
        elif command in ['clear', 'cls', 'c']:
            self.show_banner()
        elif command == 'about':
            self.do_about()
        else:
            self.run_alias(command, args)
    
    def do_exit(self):
        print("👋 ¡Hasta luego!")
        self.running = False
    
    def do_list(self):
        if not self.config['aliases']:
            print("📭 No hay alias guardados")
            return
        
        print(f"\n📋 Alias guardados ({len(self.config['aliases'])}):")
        categories = {}
        for name, cmd in self.config['aliases'].items():
            cat = self.descriptions.get(name, {}).get('cat', 'user')
            if cat not in categories:
                categories[cat] = []
            categories[cat].append((name, cmd))
        
        for cat, aliases in categories.items():
            print(f"\n  {cat.upper()}:")
            for name, cmd in sorted(aliases):
                desc = self.descriptions.get(name, {}).get('desc', '')
                if desc:
                    print(f"    {name:10} → {cmd:30} # {desc}")
                else:
                    print(f"    {name:10} → {cmd}")
        print("")
    
    def do_add(self, args):
        if not args:
            print("❌ Uso: add <nombre> <comando>")
            return
        
        parts = args.split(maxsplit=1)
        if len(parts) < 2:
            print("❌ Uso: add <nombre> <comando>")
            return
        
        name, cmd = parts
        self.config['aliases'][name] = cmd
        self.save_config()
        print(f"✅ Alias guardado: {name} → {cmd}")
    
    def do_rm(self, args):
        if not args or args not in self.config['aliases']:
            print(f"❌ Alias '{args}' no encontrado")
            return
        
        del self.config['aliases'][args]
        self.save_config()
        print(f"✅ Alias eliminado: {args}")
    
    def do_lang(self):
        print("🌐 Cambiando idioma...")
        print("1. Español")
        print("2. English")
        choice = input("Selecciona (1/2): ").strip()
        
        if choice == "1":
            self.config['lang'] = 'es'
            print("✅ Idioma cambiado a Español")
        elif choice == "2":
            self.config['lang'] = 'en'
            print("✅ Language changed to English")
        else:
            print("❌ Opción no válida")
            return
        self.save_config()
    
    def do_theme(self, args):
        if not args:
            print(f"🎨 Tema actual: {self.theme}")
            print("Temas disponibles: default, dark, light, hacker")
            return
        
        if args in ['default', 'dark', 'light', 'hacker']:
            self.theme = args
            self.config['theme'] = args
            self.save_config()
            print(f"🎨 Tema cambiado a: {args}")
            self.show_banner()
        else:
            print("❌ Tema no válido. Opciones: default, dark, light, hacker")
    
    def do_learn(self):
        self.learn_mode = not self.learn_mode
        self.config['learn_mode'] = self.learn_mode
        self.save_config()
        estado = "activado" if self.learn_mode else "desactivado"
        print(f"📚 Modo aprendiz {estado}")
    
    def do_export(self, args):
        filename = args if args else f"zer0_backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        try:
            with open(filename, 'w') as f:
                json.dump(self.config['aliases'], f, indent=2)
            print(f"✅ Alias exportados a: {filename}")
        except Exception as e:
            print(f"❌ Error al exportar: {e}")
    
    def do_import(self, args):
        if not args:
            print("❌ Uso: import <archivo>")
            return
        
        try:
            with open(args, 'r') as f:
                new_aliases = json.load(f)
            self.config['aliases'].update(new_aliases)
            self.save_config()
            print(f"✅ {len(new_aliases)} alias importados desde: {args}")
        except Exception as e:
            print(f"❌ Error al importar: {e}")
    
    def do_search(self, pattern):
        if not pattern:
            print("❌ Uso: search <patrón>")
            return
        
        pattern = pattern.lower()
        results = {}
        
        for alias, cmd in self.config['aliases'].items():
            if (pattern in alias.lower() or 
                pattern in cmd.lower() or
                (alias in self.descriptions and 
                 pattern in self.descriptions[alias]['desc'].lower())):
                results[alias] = cmd
        
        if results:
            print(f"\n🔍 Resultados para '{pattern}':")
            for alias, cmd in sorted(results.items()):
                desc = self.descriptions.get(alias, {}).get('desc', '')
                if desc:
                    print(f"  {alias:10} → {cmd:30} # {desc}")
                else:
                    print(f"  {alias:10} → {cmd}")
            print("")
        else:
            print(f"😕 No se encontraron alias para '{pattern}'")
    
    def do_explain(self, alias):
        if not alias:
            print("❌ Uso: explain <alias>")
            return
        
        if alias in self.descriptions:
            info = self.descriptions[alias]
            print(f"\n📚 Explicación de '{alias}':")
            print(f"   Comando: {info['cmd']}")
            print(f"   Descripción: {info['desc']}")
            print(f"   Categoría: {info['cat']}")
            if alias in self.config['aliases']:
                print(f"   Estado: ✅ Activado")
            else:
                print(f"   Estado: ❌ No está en tus alias")
        elif alias in self.config['aliases']:
            print(f"\n📚 Explicación de '{alias}':")
            print(f"   Comando: {self.config['aliases'][alias]}")
            print(f"   Descripción: Alias personalizado definido por el usuario")
            print(f"   Categoría: user")
        else:
            print(f"❌ Alias '{alias}' no encontrado")
    
    def do_category(self, args):
        if not args:
            categories = {}
            for alias in self.config['aliases']:
                cat = self.descriptions.get(alias, {}).get('cat', 'user')
                if cat not in categories:
                    categories[cat] = 0
                categories[cat] += 1
            
            print("\n📂 Categorías disponibles:")
            for cat, count in sorted(categories.items()):
                print(f"  - {cat}: {count} alias")
            return
        
        parts = args.split()
        if parts[0] == "load" and len(parts) > 1:
            cat = parts[1]
            loaded = 0
            for alias, info in self.descriptions.items():
                if info['cat'] == cat and alias not in self.config['aliases']:
                    self.config['aliases'][alias] = info['cmd']
                    loaded += 1
            if loaded > 0:
                self.save_config()
                print(f"✅ {loaded} alias de '{cat}' cargados")
            else:
                print(f"❌ No se encontraron alias nuevos para '{cat}'")
    
    def do_help(self):
        print("\n📚 Comandos disponibles:")
        print("  list, ls              - Listar todos los alias")
        print("  add <nom> <cmd>        - Agregar/actualizar alias")
        print("  rm <nom>               - Eliminar alias")
        print("  search <patrón>        - Buscar alias")
        print("  explain <alias>        - Explicar qué hace un alias")
        print("  category               - Ver categorías")
        print("  category load <cat>    - Cargar categoría completa")
        print("  export [archivo]       - Exportar alias")
        print("  import <archivo>       - Importar alias")
        print("  lang                   - Cambiar idioma")
        print("  theme [nombre]         - Cambiar tema")
        print("  learn                  - Activar/desactivar modo aprendiz")
        print("  clear, cls             - Limpiar pantalla")
        print("  about                  - Información de ZER0")
        print("  version, -v            - Ver versión")
        print("  exit, quit, q          - Salir")
        print("")
    
    def do_version(self):
        print("ZER0 v1.0.4")
    
    def do_about(self):
        print("\n██████╗ ███████╗██████╗  ██████╗ ")
        print("╚════██╗██╔════╝██╔══██╗██╔═████╗")
        print(" █████╔╝█████╗  ██████╔╝██║██╔██║")
        print("██╔═══╝ ██╔══╝  ██╔══██╗████╔╝██║")
        print("███████╗███████╗██║  ██║╚██████╔╝")
        print("╚══════╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ")
        print("\nZER0 v1.0.4")
        print("Command alias manager for Arch Linux")
        print("Desarrollado por LogLabs")
        print("Licencia MIT")
        print("https://github.com/LogLabsHQ/ZER0\n")
    
    def run_alias(self, alias, args):
        if alias in self.config['aliases']:
            cmd = self.config['aliases'][alias]
            full_cmd = f"{cmd} {args}".strip()
            
            if self.learn_mode:
                print(f"→ {full_cmd}")
                if alias in self.descriptions:
                    print(f"📚 {self.descriptions[alias]['desc']}")
            
            os.system(full_cmd)
        else:
            print(f"❌ Alias '{alias}' no encontrado. Usa 'list' para ver todos.")

def main():
    learn_mode = '--learn' in sys.argv
    app = ZER0(learn_mode)
    app.run()

if __name__ == "__main__":
    main()
EOF
    
    chmod +x ~/.local/bin/zero
    echo -e "${GREEN}✅ ZER0 instalado en ~/.local/bin/zero${NC}"
}

create_language_files() {
    echo -e "\n${YELLOW}🌐 Instalando archivos de idioma...${NC}"
    
    cat > ~/.local/share/zer0/languages/es.json << EOF
{
    "welcome": "¡Bienvenido a ZER0!",
    "goodbye": "¡Hasta luego!",
    "not_found": "no encontrado",
    "added": "agregado",
    "removed": "eliminado",
    "list_title": "Lista de alias",
    "help_title": "Ayuda",
    "error": "Error"
}
EOF

    cat > ~/.local/share/zer0/languages/en.json << EOF
{
    "welcome": "Welcome to ZER0!",
    "goodbye": "Goodbye!",
    "not_found": "not found",
    "added": "added",
    "removed": "removed",
    "list_title": "Alias list",
    "help_title": "Help",
    "error": "Error"
}
EOF
    echo -e "${GREEN}✅ Archivos de idioma instalados${NC}"
}

create_theme_files() {
    echo -e "\n${YELLOW}🎨 Instalando temas...${NC}"
    
    cat > ~/.local/share/zer0/themes/default.theme << EOF
prompt_color=none
banner_color=blue
text_color=none
EOF

    cat > ~/.local/share/zer0/themes/dark.theme << EOF
prompt_color=90
banner_color=90
text_color=90
EOF

    cat > ~/.local/share/zer0/themes/light.theme << EOF
prompt_color=97
banner_color=97
text_color=97
EOF

    cat > ~/.local/share/zer0/themes/hacker.theme << EOF
prompt_color=92
banner_color=92
text_color=92
EOF
    echo -e "${GREEN}✅ Temas instalados${NC}"
}

configure_shell() {
    echo -e "\n${YELLOW}⚙️  Configurando shell...${NC}"
    
    shell_config=""
    shell_type=""
    
    if [ -n "$BASH" ]; then
        shell_config="$HOME/.bashrc"
        shell_type="bash"
    elif [ -n "$ZSH_VERSION" ]; then
        shell_config="$HOME/.zshrc"
        shell_type="zsh"
    elif [ -f "$HOME/.config/fish/config.fish" ]; then
        shell_config="$HOME/.config/fish/config.fish"
        shell_type="fish"
    fi
    
    if [ -n "$shell_config" ]; then
        if ! grep -q "# ─── ZER0 ───" "$shell_config" 2>/dev/null; then
            cat >> "$shell_config" << EOF

# ─── ZER0 ──────────────────────────────────
alias -Z='zero'
export Z=zero
# ───────────────────────────────────────────
EOF
            echo -e "${GREEN}✅ Configuración añadida a $shell_config${NC}"
        else
            echo -e "${YELLOW}⚠️  ZER0 ya está configurado en $shell_config${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  No se pudo detectar el archivo de configuración de shell${NC}"
        echo "   Añade manualmente: alias -Z='zero' y export Z=zero"
    fi
    
    echo -e "${GREEN}✅ Shell configurada: $shell_type${NC}"
}

show_completion() {
    echo ""
    echo -e "${GREEN}🎉 ¡Instalación completada con éxito!${NC}"
    echo -e "${CYAN}════════════════════════════════════════${NC}"
    echo -e "🔹 Ejecuta: ${YELLOW}source ~/.bashrc${NC} (o reinicia la terminal)"
    echo -e "🔹 Comandos disponibles:"
    echo -e "   • ${WHITE}zero${NC}        - Modo interactivo"
    echo -e "   • ${WHITE}zero --learn${NC} - Modo interactivo + explicaciones"
    echo -e "   • ${WHITE}-Z${NC}           - Atajo rápido"
    echo -e "   • ${WHITE}\$Z${NC}           - Variable de entorno"
    echo -e "${CYAN}════════════════════════════════════════${NC}"
    echo -e "${BLUE}¡Disfruta de ZER0! 🚀${NC}"
    echo ""
}

main() {
    show_banner
    check_requirements
    setup_directories
    get_user_preferences
    create_initial_config
    create_python_files
    create_language_files
    create_theme_files
    configure_shell
    show_completion
}

main "$@"
