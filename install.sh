#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

check_requirements() {
    echo -e "\n${YELLOW}🔍 Verificando requisitos...${NC}"
    
    if ! command -v python3 &> /dev/null; then
        echo -e "${RED}❌ Python 3 no está instalado${NC}"
        exit 1
    fi
    
    python_version=$(python3 -c 'import sys; print(f"{sys.version_info[0]}.{sys.version_info[1]}")')
    if [ "$python_version" \< "3.10" ]; then
        echo -e "${RED}❌ Se requiere Python 3.10 o superior${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Python $python_version detectado${NC}"
}

setup_directories() {
    echo -e "\n${YELLOW}📁 Creando directorios...${NC}"
    mkdir -p ~/.local/bin
    mkdir -p ~/.config/zer0
    mkdir -p ~/.cache/zer0
    echo -e "${GREEN}✅ Directorios creados${NC}"
}

get_user_preferences() {
    echo -e "\n${YELLOW}🌐 Idioma (1=Español, 2=English):${NC}"
    read -p "> " lang_choice
    
    if [ "$lang_choice" = "1" ]; then
        lang="es"
        echo -e "${GREEN}✅ Español seleccionado${NC}"
    else
        lang="en"
        echo -e "${GREEN}✅ English selected${NC}"
    fi
    
    echo -e "\n${YELLOW}👤 Tu nombre:${NC}"
    read -p "> " user_name
    [ -z "$user_name" ] && user_name="user"
    
    echo -e "\n${YELLOW}🎨 Modo aprendiz? (1=Si, 2=No):${NC}"
    read -p "> " learn_choice
    learn="false"
    [ "$learn_choice" = "1" ] && learn="true" && echo -e "${GREEN}✅ Activado${NC}"
}

create_initial_config() {
    cat > ~/.config/zer0/config.json << EOF
{
    "name": "$user_name",
    "lang": "$lang",
    "learn_mode": $learn,
    "theme": "default",
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
import os, sys, json, signal, readline, atexit
from pathlib import Path
from datetime import datetime

NC = '\033[0m'
RED = '\033[0;31m'
GREEN = '\033[0;32m'
YELLOW = '\033[1;33m'
BLUE = '\033[0;34m'
CYAN = '\033[0;36m'

CONFIG_DIR = Path.home() / ".config/zer0"
CONFIG_FILE = CONFIG_DIR / "config.json"
HISTORY_FILE = Path.home() / ".cache/zer0/history"

class ZER0:
    def __init__(self, learn_mode=False):
        self.config = self.load_config()
        self.running = True
        self.learn_mode = learn_mode or self.config.get('learn_mode', False)
        self.setup_readline()
        signal.signal(signal.SIGINT, lambda s,f: sys.exit(0))
        
        if not self.config.get('aliases'):
            self.config['aliases'] = {}
            self.load_default_shortcuts()
    
    def setup_readline(self):
        try:
            readline.read_history_file(HISTORY_FILE)
        except:
            pass
        atexit.register(readline.write_history_file, HISTORY_FILE)
    
    def load_config(self):
        try:
            with open(CONFIG_FILE) as f:
                return json.load(f)
        except:
            return {"name":"user","lang":"en","learn_mode":False,"theme":"default","aliases":{}}
    
    def save_config(self):
        with open(CONFIG_FILE, 'w') as f:
            json.dump(self.config, f, indent=2)
    
    def get_default_shortcuts(self):
        return {
            "upd": "sudo pacman -Syu", "ins": "sudo pacman -S", "rem": "sudo pacman -Rns",
            "search": "pacman -Ss", "orphans": "sudo pacman -Rns $(pacman -Qdtq)",
            "unlock": "sudo rm /var/lib/pacman/db.lck",
            "gs": "git status", "ga": "git add .", "gc": "git commit -m",
            "gp": "git push", "gpl": "git pull", "glog": "git log --oneline --graph --decorate",
            "sstart": "sudo systemctl start", "sstop": "sudo systemctl stop",
            "srestart": "sudo systemctl restart", "sstatus": "sudo systemctl status",
            "slist": "systemctl list-units --type=service",
            "dps": "docker ps", "dcu": "docker-compose up -d", "dcd": "docker-compose down",
            "dlogs": "docker logs -f", "dprune": "docker system prune -af",
            "py": "python3", "pip": "pip install", "node": "node", "npm": "npm install",
            "ip": "ip addr", "ping": "ping -c 4", "df": "df -h", "du": "du -sh",
            "ps": "ps aux", "top": "htop", "kill": "kill -9", "neofetch": "neofetch", "arch": "uname -a"
        }
    
    def get_descriptions(self):
        return {
            "upd": {"cmd":"sudo pacman -Syu","desc":"Actualiza el sistema","cat":"pacman"},
            "ins": {"cmd":"sudo pacman -S","desc":"Instala un paquete","cat":"pacman"},
            "gs": {"cmd":"git status","desc":"Estado del repositorio","cat":"git"},
            "ga": {"cmd":"git add .","desc":"Añade archivos","cat":"git"},
        }
    
    def load_default_shortcuts(self):
        for name, cmd in self.get_default_shortcuts().items():
            self.config['aliases'][name] = cmd
        self.save_config()
    
    def show_banner(self):
        os.system('clear')
        print(f"{BLUE}")
        print("██████╗ ███████╗██████╗  ██████╗ ")
        print("╚════██╗██╔════╝██╔══██╗██╔═████╗")
        print(" █████╔╝█████╗  ██████╔╝██║██╔██║")
        print("██╔═══╝ ██╔══╝  ██╔══██╗████╔╝██║")
        print("███████╗███████╗██║  ██║╚██████╔╝")
        print("╚══════╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ")
        print(f"{NC}v1.0.4{NC}")
        print("📌 ZER0 is online. Type 'help'\n")
    
    def get_prompt(self):
        return f"[{self.config.get('name','user')}@ZER0 ~]$ "
    
    def run(self):
        self.show_banner()
        while self.running:
            try:
                cmd = input(self.get_prompt()).strip()
                if cmd:
                    self.process_command(cmd)
            except (EOFError, KeyboardInterrupt):
                print("\n👋 Bye!")
                break
    
    def process_command(self, cmd):
        parts = cmd.split(maxsplit=1)
        command = parts[0].lower()
        args = parts[1] if len(parts) > 1 else ""
        
        cmds = {
            'exit': self.do_exit, 'quit': self.do_exit, 'q': self.do_exit,
            'list': self.do_list, 'ls': self.do_list,
            'add': lambda: self.do_add(args), 'a': lambda: self.do_add(args),
            'rm': lambda: self.do_rm(args), 'remove': lambda: self.do_rm(args), 'del': lambda: self.do_rm(args),
            'search': lambda: self.do_search(args),
            'explain': lambda: self.do_explain(args),
            'learn': self.do_learn,
            'theme': lambda: self.do_theme(args),
            'export': lambda: self.do_export(args),
            'import': lambda: self.do_import(args),
            'lang': self.do_lang,
            'help': self.do_help, '-h': self.do_help, '--help': self.do_help,
            'version': self.do_version, '-v': self.do_version,
            'clear': self.show_banner, 'cls': self.show_banner, 'c': self.show_banner,
            'about': self.do_about,
        }
        
        if command in cmds:
            cmds[command]()
        else:
            self.run_alias(command, args)
    
    def do_exit(self): self.running = False
    def do_version(self): print("ZER0 v1.0.4")
    
    def do_list(self):
        if not self.config['aliases']:
            print("📭 No hay alias")
            return
        print("\n📋 Alias guardados:")
        for name, cmd in sorted(self.config['aliases'].items()):
            desc = self.get_descriptions().get(name, {}).get('desc', '')
            print(f"  {name:10} → {cmd} {desc}")
    
    def do_add(self, args):
        parts = args.split(maxsplit=1)
        if len(parts) < 2:
            print("❌ Uso: add <nombre> <comando>")
            return
        name, cmd = parts
        self.config['aliases'][name] = cmd
        self.save_config()
        print(f"✅ {name} guardado")
    
    def do_rm(self, args):
        if args in self.config['aliases']:
            del self.config['aliases'][args]
            self.save_config()
            print(f"✅ {args} eliminado")
        else:
            print(f"❌ {args} no encontrado")
    
    def do_search(self, pattern):
        if not pattern:
            print("❌ Uso: search <patrón>")
            return
        results = {n:c for n,c in self.config['aliases'].items() if pattern in n or pattern in c}
        if results:
            print(f"\n🔍 '{pattern}':")
            for n,c in results.items():
                print(f"  {n} → {c}")
        else:
            print("😕 No encontrado")
    
    def do_explain(self, alias):
        if alias in self.get_descriptions():
            info = self.get_descriptions()[alias]
            print(f"\n📚 {alias}: {info['desc']}")
        else:
            print(f"❌ No hay explicación para {alias}")
    
    def do_learn(self):
        self.learn_mode = not self.learn_mode
        self.config['learn_mode'] = self.learn_mode
        self.save_config()
        print(f"📚 Modo aprendiz: {'ON' if self.learn_mode else 'OFF'}")
    
    def do_theme(self, args):
        print("🎨 Tema: default (único por ahora)")
    
    def do_export(self, args):
        f = args or f"zer0_{datetime.now().strftime('%Y%m%d')}.json"
        with open(f, 'w') as fh:
            json.dump(self.config['aliases'], fh, indent=2)
        print(f"✅ Exportado a {f}")
    
    def do_import(self, args):
        if not args:
            print("❌ Uso: import <archivo>")
            return
        with open(args) as f:
            new = json.load(f)
        self.config['aliases'].update(new)
        self.save_config()
        print(f"✅ Importados {len(new)} alias")
    
    def do_lang(self):
        print("1. Español\n2. English")
        c = input("> ")
        self.config['lang'] = 'es' if c == '1' else 'en'
        self.save_config()
        print("✅ Idioma cambiado")
    
    def do_help(self):
        print("""
📚 Comandos:
  list              - Listar alias
  add <nom> <cmd>   - Agregar alias
  rm <nom>          - Eliminar alias
  search <patrón>   - Buscar
  explain <alias>   - Explicar
  learn             - Modo aprendiz
  export [archivo]  - Exportar
  import <archivo>  - Importar
  lang              - Idioma
  theme             - Tema
  clear             - Limpiar
  version           - Versión
  exit              - Salir
        """)
    
    def do_about(self):
        print("\nZER0 v1.0.4 - By LogLabs\n")
    
    def run_alias(self, alias, args):
        if alias in self.config['aliases']:
            cmd = self.config['aliases'][alias]
            full = f"{cmd} {args}".strip()
            if self.learn_mode:
                print(f"→ {full}")
            os.system(full)
        else:
            print(f"❌ '{alias}' no existe. Usa 'list'")

def main():
    learn_mode = '--learn' in sys.argv
    ZER0(learn_mode).run()

if __name__ == "__main__":
    main()
EOF
    
    chmod +x ~/.local/bin/zero
    echo -e "${GREEN}✅ ZER0 instalado${NC}"
}

configure_shell() {
    echo -e "\n${YELLOW}⚙️ Configurando shell...${NC}"
    shrc="$HOME/.bashrc"
    [ -n "$ZSH_VERSION" ] && shrc="$HOME/.zshrc"
    
    if ! grep -q "# ─── ZER0 ───" "$shrc" 2>/dev/null; then
        cat >> "$shrc" << EOF

# ─── ZER0 ───
alias -Z='zero'
export Z=zero
# ────────────
EOF
        echo -e "${GREEN}✅ Configurado en $shrc${NC}"
    fi
}

show_completion() {
    echo ""
    echo -e "${GREEN}🎉 ¡Instalado!${NC}"
    echo -e "${CYAN}════════════════════════════${NC}"
    echo -e "👉 ${YELLOW}source ~/.bashrc${NC}"
    echo -e "👉 ${WHITE}zero${NC} o ${WHITE}-Z${NC} o ${WHITE}\$Z${NC}"
    echo -e "${CYAN}════════════════════════════${NC}"
}

main() {
    show_banner
    check_requirements
    setup_directories
    get_user_preferences
    create_initial_config
    create_python_files
    configure_shell
    show_completion
}

main "$@"
