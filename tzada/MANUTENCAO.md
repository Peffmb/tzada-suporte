# Tzada Suporte — manual de manutenção

Acesso remoto da loja Tzada (tzada.org), baseado no RustDesk (open source, AGPL-3.0).
Montado em 2026-11-10.

## Visão geral

| Peça | Onde | O que é |
|---|---|---|
| Servidor RustDesk | VPS `163.245.203.148`, `/opt/rustdesk` | `hbbs` (ID/rendezvous) + `hbbr` (relay), Docker |
| App Tzada (cliente) | GitHub `Peffmb/tzada-suporte` (fork do `rustdesk/rustdesk`) | Compilado no GitHub Actions |
| Instalador | `tzada/setup/tzada-setup.iss` neste repo | Inno Setup, em português |
| Site de download | https://desk.tzada.org — VPS `/opt/tzada-desk` | nginx estático, atrás do nginx do Mailcow |
| DNS | Spaceship | `desk.tzada.org A 163.245.203.148` |

Clone local: `C:\Users\user\dev\tzada-suporte`. Fonte do site: `C:\Users\user\dev\tzada-desk`.
GitHub CLI portátil: `%LOCALAPPDATA%\gh-cli\bin\gh.exe` (conta `Peffmb`, escopos `repo` + `workflow`).

## 1. Servidor (VPS)

- Imagem `rustdesk/rustdesk-server:1.1.14`, `network_mode: host`, `mem_limit 256m` cada.
- Portas: TCP 21115–21119 e UDP 21116 (não há firewall na VPS).
- **Chave pública:** `KRBSACNCXmb5jCF4mJB9zWIDtwuRMbMogjNTRt7jmWs=`
- **Chave privada:** `/opt/rustdesk/data/id_ed25519` — **NUNCA apagar `/opt/rustdesk/data`**. Se a chave
  mudar, todos os apps instalados nos clientes param de conectar (a chave vem embutida no app).
  Fazer backup dessa pasta se for migrar de VPS.

Comandos:
```
cd /opt/rustdesk && docker compose ps
cd /opt/rustdesk && docker compose restart
docker logs --tail 50 rustdesk-hbbs
docker logs --tail 50 rustdesk-hbbr
```
Testar de fora (Windows): `Test-NetConnection 163.245.203.148 -Port 21116`.

Trocar de VPS/IP: subir o mesmo compose com a MESMA pasta `data/`, mudar o DNS e o IP em
`tzada/apply-brand.sh` (TZADA_SERVER) e recompilar o app (os apps antigos apontam pro IP antigo).

## 2. App Tzada (como a marca é aplicada)

| O quê | Onde |
|---|---|
| Nome `Tzada`, servidor e chave | `tzada/apply-brand.sh` — roda no CI e edita `libs/hbb_common/src/config.rs` (submódulo, não commitado) |
| Ícones | `res/icon.ico`, `res/tray-icon.ico`, `res/*.png`, `flutter/windows/runner/resources/app_icon.ico` |
| Logo no app | `flutter/assets/icon.svg`, `icon.png`, `logo*.png` (os .png estão no .gitignore → `git add -f`) |
| Cores (laranja `#F8A51C`) | troca de `0071FF`/`2C8CFF` em `flutter/lib/` |
| Metadados do .exe | `Cargo.toml` `[package.metadata.winres]`, `flutter/windows/runner/Runner.rc` |
| "Powered by RustDesk" oculto | `flutter/lib/common.dart` `loadPowered()` (`isCustomClient`) |
| Link "Site" da tela Sobre | `flutter/lib/desktop/pages/desktop_setting_page.dart` → desk.tzada.org |
| Não se considerar "servidor público" | `src/common.rs` `using_public_server()` só é true se o servidor embutido for `*.rustdesk.com`. Sem isso o app mostra "For faster connection, please set up your own server" e limita qualidade/FPS no relay |

Gerador das imagens: o "T" laranja (#f8a51c) em quadrado preto; versão 1024px em `res/icon.png`.

**Regra importante:** app com marca própria tem que sair do build com o executável chamado
`<APP_NAME>.exe` (`Tzada.exe`). Se ficar `rustdesk.exe`, o "Instalar" do app falha com
"não pode encontrar ...\Tzada.exe". O workflow faz esse `mv`.

Avisos legais (AGPL): manter o copyright do RustDesk e a licença na tela "Sobre" e manter o código
das modificações disponível (o repo público cumpre isso).

## 3. Builds no GitHub

Workflows ativos (os originais do RustDesk estão desativados no fork):

- **`tzada-windows.yml`** — build completo Windows x64 (app + portátil + msi + instalador).
  ~40–50 min com cache (o 1º build levou ~2h compilando ffmpeg/vcpkg).
  ```
  gh workflow run tzada-windows.yml -R Peffmb/tzada-suporte --ref master
  ```
  Saídas: artefato `tzada-suporte-windows-x64` e release `tzada` com
  `Tzada-Suporte-<versão>-x86_64.exe` (portátil), `.msi`, `Tzada-Suporte-Setup.exe`.
- **`tzada-setup-only.yml`** — só o instalador, reaproveitando o app de um build anterior (~3 min):
  ```
  gh workflow run tzada-setup-only.yml -R Peffmb/tzada-suporte --ref master -f run_id=<ID do run completo> -f version=1.5.3
  ```

Ver andamento: `gh run list -R Peffmb/tzada-suporte --limit 3`
(`gh run watch` não funciona nesse terminal — usar loop com `gh run view <id> --json status`).

**Atualizar para uma versão nova do RustDesk:** sincronizar o fork com o upstream
(`gh repo sync Peffmb/tzada-suporte` ou merge de `rustdesk/master`), resolver conflitos nos arquivos da
tabela da seção 2, regenerar `tzada-windows.yml` se o `flutter-build.yml` do upstream mudou muito
(o tzada-windows.yml é uma cópia enxuta do job Windows x64 dele), e rodar o build completo.

## 4. Instalador (Inno Setup)

`tzada/setup/tzada-setup.iss`:
- Extrai o app para `{tmp}` e roda `Tzada.exe --silent-install` → a instalação real é a do próprio app
  (serviço do Windows `Tzada`, atalhos, desinstalador, `Program Files\Tzada`).
- Antes de instalar: `sc stop Tzada` + `taskkill /F /IM Tzada.exe` (evita o conflito de canal descrito abaixo).
- Acha a pasta real pela chave `HKLM\...\Uninstall\Tzada` → `InstallLocation` (uma atualização reaproveita a
  pasta antiga, que pode não ser `Program Files\Tzada`).
- Imagens: `wizard-*.bmp` (geradas com Pillow a partir de `res/icon.png`).

## 5. Site desk.tzada.org

- VPS `/opt/tzada-desk`: `docker-compose.yml` (nginx:1.27-alpine, rede `mailcowdockerized_mailcow-network`,
  sem portas publicadas), `nginx.conf`, `site/index.html`, `site/assets/`, `site/download/`.
- Downloads publicados: `site/download/Tzada-Suporte-Setup.exe` (botão principal) e
  `site/download/Tzada-Suporte.exe` (link "versão sem instalação"). Se o Setup sumir, o botão cai sozinho
  na versão portátil; se os dois sumirem, mostra "Download em atualização".
- vhost: `/opt/mailcow-dockerized/data/conf/nginx/desk.tzada.org.conf` (proxy pro container `tzada-desk`).
- HTTPS: `desk.tzada.org` está em `ADDITIONAL_SAN` do `/opt/mailcow-dockerized/mailcow.conf`.

Publicar arquivos novos (do Windows, credenciais em `Desktop\vps.txt`):
```
pscp ... Tzada-Suporte-Setup.exe root@163.245.203.148:/opt/tzada-desk/site/download/Tzada-Suporte-Setup.exe
pscp ... Tzada-Suporte-<v>-x86_64.exe root@163.245.203.148:/opt/tzada-desk/site/download/Tzada-Suporte.exe
pscp ... index.html root@163.245.203.148:/opt/tzada-desk/site/index.html
```
Não precisa reiniciar nada pra trocar arquivos. Se mudar `nginx.conf`: `docker exec tzada-desk nginx -t && docker exec tzada-desk nginx -s reload`.
Se mudar o vhost do Mailcow: `docker compose exec -T nginx-mailcow nginx -t` antes de `nginx -s reload`.

**Cuidado com o certificado:** mexer no `ADDITIONAL_SAN` + `docker compose up -d acme-mailcow` faz o Mailcow
reiniciar dovecot/postfix (~1 min de IMAP fora — o gerador de e-mails dá `SSL: UNEXPECTED_EOF`). Avisar antes.

DNS (Spaceship), a partir da VPS: `cd /opt/tempmail-api && ./deploy/spaceship-dns.sh list tzada.org`
(`add-a tzada.org <nome> <ip> [ttl]`).

## 6. Problemas já vistos e solução

| Sintoma | Causa | Solução |
|---|---|---|
| "Instalar" do app: *não pode encontrar ...\Tzada.exe* | exe saiu do build como `rustdesk.exe` | build tem que gerar `Tzada.exe` (já corrigido no workflow) |
| Senha fica em **"Gerando..."** | outro processo com APP_NAME Tzada ocupa `\\.\pipe\Tzada\query` (ex.: versão antiga/portátil aberta, ou 2 instalações). Log do serviço: `Failed to start ipc ... Acesso negado` / `ipc is occupied` | fechar todos os Tzada (`taskkill /F /IM Tzada.exe`), desinstalar instalações duplicadas, `sc stop Tzada` + `sc start Tzada`. Ver pipes: `[IO.Directory]::GetFiles("\\.\pipe\") \| ? { $_ -match 'tzada' }` |
| Conectado mas **não dá pra clicar** / parece travado | UAC: app sem instalar (ou sem admin) não clica em janelas de administrador / pedido de permissão | instalar com o Setup (roda como serviço) ou "Executar como administrador" |
| "Windows protegeu seu PC" | app sem assinatura digital | "Mais informações" → "Executar assim mesmo"; só some com certificado de assinatura de código |
| Site sem animação | Windows com "Efeitos de animação" desligado (prefers-reduced-motion) | esperado; o site mantém só fades/pulsos nesse caso |

Logs do app no Windows:
- usuário: `%APPDATA%\Tzada\log\` (ex.: `silent-install\`, `tray\`)
- serviço/servidor (precisa admin): `C:\Windows\System32\config\systemprofile\AppData\Roaming\Tzada\log\{service,server}\`
