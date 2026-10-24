<div align="center">

# warp-reset

**Rotá tu IP de Cloudflare WARP con un solo comando.**

[![Licencia: MIT](https://img.shields.io/badge/licencia-MIT-blue.svg)](LICENSE)
![Versión](https://img.shields.io/badge/versi%C3%B3n-0.1.0-informational)
![Shell: Bash](https://img.shields.io/badge/shell-Bash-4EAA25?logo=gnubash&logoColor=white)
![Plataforma: Linux | WSL](https://img.shields.io/badge/plataforma-Linux%20%7C%20WSL-lightgrey)

</div>

Script de Bash que borra el registro del cliente WARP, crea uno nuevo, reconecta y espera hasta que la IP de salida cambie.

```console
$ warp-reset
IP antes:   203.0.113.10
IP después: 2a09:bac5:7d:1b9::2c:ea (warp=on)
```

## Inicio rápido

Con Cloudflare WARP ya instalado:

```bash
git clone https://github.com/JesusFernandezz/warp-reset.git
cd warp-reset && ./install.sh
warp-reset
```

Si todavía no tenés WARP, seguí la [instalación](#instalación).

## Contenido

[Requisitos](#requisitos) · [Instalación](#instalación) · [Configuración](#configuración) · [Qué hace](#qué-hace) · [Códigos de salida](#códigos-de-salida) · [Limitaciones](#limitaciones) · [Aviso](#aviso) · [Licencia](#licencia)

## Requisitos

- Bash, `curl` y `awk` (vienen en casi toda distro).
- Cloudflare WARP instalado.

Funciona en dos entornos:

| Entorno | Cliente que usa |
|---|---|
| Linux normal | `warp-cli` de Linux |
| WSL | `warp-cli.exe` del WARP instalado en Windows |

> [!IMPORTANT]
> En WSL no instales el cliente de Linux. Ver [por qué WARP va en Windows](#por-qué-warp-va-en-windows).

## Instalación

### 1. Instalar Cloudflare WARP

<details>
<summary><b>Linux</b></summary>

<br>

**Ubuntu / Debian:**

```bash
curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | sudo gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
. /etc/os-release
echo "deb [signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $VERSION_CODENAME main" | sudo tee /etc/apt/sources.list.d/cloudflare-client.list
sudo apt-get update && sudo apt-get install -y cloudflare-warp
```

Releases soportadas: Ubuntu noble, jammy y resolute; Debian bookworm y trixie (hay builds más viejos para otras). Lista actualizada: <https://pkg.cloudflareclient.com/>.

**Fedora / RHEL / CentOS:**

```bash
sudo curl -fsSL https://pkg.cloudflareclient.com/cloudflare-warp-ascii.repo | sudo tee /etc/yum.repos.d/cloudflare-warp.repo
sudo dnf clean all
sudo dnf install -y cloudflare-warp
```

**Otras distros:** seguí la [guía oficial](https://developers.cloudflare.com/cloudflare-one/team-and-resources/devices/cloudflare-one-client/download/).

Comprobá que el servicio está activo:

```bash
systemctl status warp-svc --no-pager
```

Si no lo está: `sudo systemctl enable --now warp-svc`.

</details>

<details>
<summary><b>WSL</b> (desarrollado en Ubuntu 24.04 sobre WSL2 con <code>networkingMode=mirrored</code>)</summary>

<br>

**Instalar WARP en Windows, no en WSL:**

1. Descargá el [instalador oficial](https://downloads.cloudflareclient.com/v1/download/windows/ga) (la página de descargas es <https://one.one.one.one/>).
2. Ejecutá el instalador y seguí el asistente.
3. Abrí la app **Cloudflare WARP** desde el menú Inicio, aceptá los términos de uso y activá el interruptor.

Comprobá desde WSL que `warp-cli.exe` responde. Debería decir `Connected`:

```bash
"/mnt/c/Program Files/Cloudflare/Cloudflare WARP/warp-cli.exe" status
```

**Comprobar que WSL sale por WARP:**

```bash
curl -s https://www.cloudflare.com/cdn-cgi/trace | grep -E "^(ip|warp)="
```

Si ves `warp=on`, está bien. Si ves `warp=off`, revisá tu `C:\Users\<vos>\.wslconfig`. Con esta configuración WSL comparte la red de Windows:

```ini
[wsl2]
networkingMode=mirrored
```

Después ejecutá `wsl --shutdown` en PowerShell y abrí WSL de nuevo.

**Si instalaste WARP en otra ruta**, indicala al ejecutar:

```bash
WARP_CLI="/mnt/c/ruta/a/warp-cli.exe" warp-reset
```

#### Por qué WARP va en Windows

El cliente de Linux dentro de WSL2 modo `mirrored` choca con las rutas y el DNS que ya gestiona Windows. En las pruebas fallaba con `Connectivity check failed due to DNS Lookup Failed`. Con WARP en Windows, WSL hereda el túnel sin configurar nada más.

</details>

### 2. Instalar warp-reset

```bash
git clone https://github.com/JesusFernandezz/warp-reset.git
cd warp-reset
./install.sh
```

Instala en `~/.local/bin/warp-reset` (sin sudo). Si `~/.local/bin` no está en tu `PATH`:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc && source ~/.bashrc
```

### 3. Usar

```bash
warp-reset
```

> [!WARNING]
> ⚠️ `registration delete` borra tu registro de WARP. Si usás una cuenta de Zero Trust o WARP+, te desvincula de ella. Este script está pensado para el WARP gratuito.

## Configuración

Variables de entorno opcionales:

| Variable | Por defecto | Descripción |
|---|---|---|
| `WARP_CLI` | autodetecta | Ruta al ejecutable `warp-cli` |
| `WARP_ON_TIMEOUT` | `45` | Segundos esperando a que el tráfico salga por WARP |
| `NEW_IP_TIMEOUT` | `45` | Segundos extra esperando una IP distinta de la anterior |

Ejemplo:

```bash
NEW_IP_TIMEOUT=90 warp-reset
```

## Qué hace

1. Guarda la IP actual consultando `https://www.cloudflare.com/cdn-cgi/trace`.
2. Ejecuta `warp-cli disconnect`, `registration delete`, `registration new` y `connect`.
3. Espera hasta que el trace muestre `warp=on` (el túnel realmente activo).
4. Si la IP sigue igual que la anterior, sigue consultando hasta `NEW_IP_TIMEOUT`.

## Códigos de salida

| Código | Significado |
|---|---|
| `0` | La IP cambió |
| `1` | Error de uso o no se encontró `warp-cli` |
| `2` | La IP no cambió tras el tiempo de espera |
| `3` | WARP no se activó (`warp=off`) |

## Limitaciones

- **Misma IP:** Cloudflare asigna IPs por región y datacenter. Un registro nuevo puede devolver la misma IP, y el script termina con código `2` aunque el reset haya funcionado.
- **IPv6:** el trace muestra la IP que usa `curl` por defecto, que puede ser IPv6. Para ver la IPv4: `curl -4 -s https://www.cloudflare.com/cdn-cgi/trace`.
- **Corte breve:** durante unos segundos no tenés conexión por WARP.

## Aviso

> [!CAUTION]
> 🚫 Cambiar de IP para evitar límites de uso de un servicio puede violar sus términos. Usalo bajo tu responsabilidad y revisá las condiciones del servicio que consumís. El proyecto no está afiliado a Cloudflare.

## Licencia

[MIT](LICENSE)
