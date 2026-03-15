<div align="center">

  ██████╗ ███████╗██████╗  ██████╗ 
  ╚════██╗██╔════╝██╔══██╗██╔═████╗
   █████╔╝█████╗  ██████╔╝██║██╔██║
  ██╔═══╝ ██╔══╝  ██╔══██╗████╔╝██║
  ███████╗███████╗██║  ██║╚██████╔╝
  ╚══════╝╚══════╝╚═╝  ╚═╝ ╚═════╝ 


**Gestor de alias de comandos para Arch Linux.**  
Escribe menos. Haz más.

![Python](https://img.shields.io/badge/Python-3.10%2B-blue?style=flat-square&logo=python)
![Platform](https://img.shields.io/badge/Platform-Arch%20Linux-1793d1?style=flat-square&logo=arch-linux)
![Version](https://img.shields.io/badge/Version-1.0.0-red?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)

</div>

---

## ¿Qué es ZER0?

ZER0 es una herramienta de línea de comandos con **modo interactivo (REPL)**. Al abrirlo entras a una sesión propia con prompt estilo terminal donde ejecutas tus alias directamente, sin escribir `zero` cada vez.

```
[luis@ZER0 ~]$ upd
[luis@ZER0 ~]$ list
[luis@ZER0 ~]$ add gs "git status"
[luis@ZER0 ~]$ exit
```

La primera vez que lo abras, ZER0 te pregunta tu nombre y lo recuerda en cada sesión.

---

## Instalación

### Requisitos

- Arch Linux
- Python 3.10 o superior
- `bash`, `zsh` o `fish`

### Pasos

```bash
# 1. Clona el repositorio
git clone https://github.com/L0GLabs/ZER0.git
cd ZER0

# 2. Dale permisos al instalador
chmod +x install.sh

# 3. Instala
./install.sh

# 4. Recarga tu shell
source ~/.bashrc   # bash
source ~/.zshrc    # zsh
```

El instalador se encarga de todo automáticamente:

- Copia `zero` a `~/.local/bin/` (siempre en tu PATH)
- Agrega el alias `-Z` a tu shell
- Exporta `Z=zero` para que `$Z` funcione como invocación
- Soporta bash, zsh y fish

---

## Cómo abrir ZER0

Desde cualquier carpeta de tu terminal escribe cualquiera de estos:

```bash
zero
-Z
$Z
```

Los tres abren el modo interactivo de ZER0.

---

## Modo interactivo

Al abrir ZER0 entras a una sesión con tu propio prompt:

```
[tuusuario@ZER0 ~]$ 
```

Desde aquí escribes los comandos **sin prefijo**:

| Comando | Descripción |
|---|---|
| `list` | Listar todos los atajos guardados |
| `add <atajo> <cmd>` | Agregar o actualizar un atajo |
| `rm <atajo>` | Eliminar un atajo |
| `<atajo> [args…]` | Ejecutar un atajo |
| `help` | Mostrar ayuda |
| `version` | Mostrar versión |
| `exit` / `quit` | Salir de ZER0 |

También puedes salir con `Ctrl+C`.

---

## Ejemplos

```bash
# Abrir ZER0
zero

# Dentro del prompt de ZER0:
[luis@ZER0 ~]$ add upd "sudo pacman -Syu"
[luis@ZER0 ~]$ add gs "git status"
[luis@ZER0 ~]$ add gp "git push origin main"
[luis@ZER0 ~]$ add py "python3"

# Ejecutar atajos
[luis@ZER0 ~]$ upd
[luis@ZER0 ~]$ gs
[luis@ZER0 ~]$ py script.py

# Ver todos los atajos
[luis@ZER0 ~]$ list

# Salir
[luis@ZER0 ~]$ exit
```

---

## Configuración

ZER0 guarda todo en:

```
~/.config/zer0/config.json
```

Ejemplo:

```json
{
  "name": "Luis",
  "aliases": {
    "upd": "sudo pacman -Syu",
    "gs": "git status",
    "gp": "git push origin main"
  }
}
```

Puedes editarlo manualmente si lo prefieres.

---

## Estructura del proyecto

```
ZER0/
├── zer0.py       # Programa principal
├── install.sh    # Instalador
└── README.md     # Este archivo
```

---

## Desinstalar

```bash
rm ~/.local/bin/zero
rm -rf ~/.config/zer0
```

Y elimina el bloque `# ─── ZER0 ───` de tu `.bashrc` / `.zshrc`.

---

## Desarrollado por

<div align="center">

**LogLabs**

[![GitHub](https://img.shields.io/badge/GitHub-L0GLabs-181717?style=flat-square&logo=github)](https://github.com/L0GLabs)
[![Repo](https://img.shields.io/badge/Repo-ZER0-red?style=flat-square&logo=github)](https://github.com/L0GLabs/ZER0)

</div>
