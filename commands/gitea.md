---
description: Privater Git-Mirror auf Gitea. Repo-Management — push, list, create, delete, clone, status.
allowed-tools: ["Bash", "AskUserQuestion", "Read", "Write", "Edit"]
---

# Gitea — Privater Git-Mirror

Manage Repos auf dem selbst-gehosteten Gitea-Server fuer Privacy-relevante Projekte.

**Usage:** `/cwe:gitea <subcommand> [args]`

## Konfiguration

Lies die Gitea-Config aus der Datei `$HOME/.claude/cwe.local.md`.
Suche nach dem `gitea:` Block im YAML-Frontmatter ODER als Markdown-Abschnitt.

Falls die Datei nicht existiert oder kein `gitea:` Block vorhanden:

1. Frage mit AskUserQuestion nach URL, User und Passwort
2. Speichere die Config in `$HOME/.claude/cwe.local.md` (erstelle oder ergaenze die Datei)

Config-Format (in `$HOME/.claude/cwe.local.md`):

```yaml
gitea:
  url: https://<your-gitea-host>
  user: <your-user>
  token: <access-token>        # bevorzugt — in Gitea unter Settings → Applications
  # password: <your-password>  # Fallback; ein Token ist sicherer
```

Setze die Variablen und exportiere sie in die Umgebung (NICHT in die Remote-URL schreiben):
- `GITEA_URL` — Server-URL (ohne trailing slash)
- `GITEA_USER` — User
- `GITEA_TOKEN` — Access-Token (bevorzugt), sonst `GITEA_PASS`

```bash
GITEA_CRED="${GITEA_TOKEN:-$GITEA_PASS}"     # Token bevorzugt, Passwort als Fallback
export GITEA_URL GITEA_USER GITEA_TOKEN GITEA_PASS GITEA_CRED
```

## Subcommands

### `push` (Default wenn kein Subcommand)

Pushed das aktuelle Git-Repo auf Gitea.

**Ablauf:**

1. Pruefe ob aktuelles Verzeichnis ein Git-Repo ist (`git rev-parse --is-inside-work-tree`)
2. Bestimme Repo-Name:
   - Aus `$ARGUMENTS` falls angegeben (z.B. `/cwe:gitea push my-repo`)
   - Sonst aus dem Verzeichnisnamen (`basename $(git rev-parse --show-toplevel)`)
3. Pruefe ob Repo auf Gitea existiert:
   ```bash
   curl -s -u "$GITEA_USER:$GITEA_CRED" "$GITEA_URL/api/v1/repos/$GITEA_USER/<repo-name>"
   ```
4. Falls Repo NICHT existiert → erstelle es:
   ```bash
   curl -s -u "$GITEA_USER:$GITEA_CRED" -X POST "$GITEA_URL/api/v1/user/repos" \
     -H "Content-Type: application/json" \
     -d '{"name": "<repo-name>", "private": true, "description": "Mirror from local"}'
   ```
5. Pruefe ob `gitea` Remote existiert:
   ```bash
   git remote get-url gitea 2>/dev/null
   ```
   Die Remote-URL enthaelt **keine** Credentials:
   ```bash
   git remote add gitea "$GITEA_URL/$GITEA_USER/<repo>.git"      # neu
   git remote set-url gitea "$GITEA_URL/$GITEA_USER/<repo>.git"  # aktualisieren
   ```
6. Push — Credentials kommen ueber einen ephemeren Credential-Helper aus der
   Umgebung, nicht aus der URL (landen so nicht in `.git/config` oder `git remote -v`):
   ```bash
   GIT_CRED='!f() { echo "username=${GITEA_USER}"; echo "password=${GITEA_CRED}"; }; f'
   git -c credential.helper="$GIT_CRED" push gitea --all
   git -c credential.helper="$GIT_CRED" push gitea --tags
   ```
7. Zeige Erfolg: Repo-URL und Anzahl gepushter Branches/Tags

**Sicherheit:** Credentials werden ueber einen ephemeren Git-Credential-Helper aus der Umgebung gelesen und landen **nicht** in der Remote-URL, in `.git/config` oder in `git remote -v`. Verwende bevorzugt einen Access-Token statt des Passworts.

### `list`

Listet alle Repos des Users auf Gitea auf.

```bash
curl -s -u "$GITEA_USER:$GITEA_CRED" "$GITEA_URL/api/v1/user/repos?limit=50"
```

Zeige als Tabelle:
| Name | Beschreibung | Privat | Aktualisiert |
|------|-------------|--------|-------------|

### `create <name>`

Erstellt ein leeres Repo auf Gitea.

```bash
curl -s -u "$GITEA_USER:$GITEA_CRED" -X POST "$GITEA_URL/api/v1/user/repos" \
  -H "Content-Type: application/json" \
  -d '{"name": "<name>", "private": true}'
```

Frage mit AskUserQuestion:
- Beschreibung (optional, kann leer sein)
- Privat oder Public (Default: privat)

### `delete <name>`

Loescht ein Repo auf Gitea. **IMMER** vorher mit AskUserQuestion bestaetigen lassen!

```bash
curl -s -u "$GITEA_USER:$GITEA_CRED" -X DELETE "$GITEA_URL/api/v1/repos/$GITEA_USER/<name>"
```

### `clone <name>`

Klont ein Repo von Gitea.

```bash
GIT_CRED='!f() { echo "username=${GITEA_USER}"; echo "password=${GITEA_CRED}"; }; f'
git -c credential.helper="$GIT_CRED" clone "$GITEA_URL/$GITEA_USER/<name>.git"
```

### `ssh-push` (für große Repos / LFS)

Pushed das aktuelle Git-Repo ueber SSH statt HTTPS. Ideal fuer grosse Repos oder wenn Git LFS verwendet wird.

**Voraussetzung:** SSH-Key muss auf dem Gitea-Server hinterlegt sein.

**Zusaetzliche Config** (optional, in `$HOME/.claude/cwe.local.md`):

```yaml
gitea:
  url: https://<your-gitea-host>
  user: <your-user>
  password: <your-password>
  ssh_host: <your-gitea-host>   # Hostname fuer SSH (ohne https://)
  ssh_port: 22                  # SSH-Port (Default: 22)
```

**Ablauf:**

1. Pruefe ob aktuelles Verzeichnis ein Git-Repo ist
2. Bestimme Repo-Name (aus `$ARGUMENTS` oder Verzeichnisname)
3. Pruefe ob SSH-Key vorhanden ist:
   ```bash
   ssh-keygen -l -f ~/.ssh/id_rsa 2>/dev/null || ssh-keygen -l -f ~/.ssh/id_ed25519 2>/dev/null
   ```
   Falls kein Key: Zeige Hinweis "Kein SSH-Key gefunden. Erstelle einen mit: ssh-keygen -t ed25519"
4. Teste SSH-Verbindung zum Gitea-Server:
   ```bash
   ssh -p <ssh_port> -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new git@<ssh_host> 2>&1
   ```
5. Pruefe ob Repo auf Gitea existiert (via API wie bei `push`), erstelle es falls nicht
6. Pruefe ob `gitea-ssh` Remote existiert:
   ```bash
   git remote get-url gitea-ssh 2>/dev/null
   ```
   Falls nicht → hinzufuegen:
   ```bash
   git remote add gitea-ssh "ssh://git@<ssh_host>:<ssh_port>/<user>/<repo>.git"
   ```
   Falls URL nicht stimmt → aktualisieren:
   ```bash
   git remote set-url gitea-ssh "ssh://git@<ssh_host>:<ssh_port>/<user>/<repo>.git"
   ```
7. Push:
   ```bash
   git push gitea-ssh --all
   git push gitea-ssh --tags
   ```
8. Falls LFS vorhanden:
   ```bash
   git lfs push gitea-ssh --all 2>/dev/null
   ```
9. Zeige Erfolg: Remote-URL, Branches, Tags, LFS-Objekte (falls vorhanden)

**Fehlerbehandlung SSH:**
- **Permission denied:** "SSH-Key nicht auf Gitea-Server hinterlegt. Gehe zu: $GITEA_URL/user/settings/keys"
- **Connection refused:** "SSH-Verbindung fehlgeschlagen. Pruefe ssh_host und ssh_port in $HOME/.claude/cwe.local.md"
- **Host key verification failed:** Passiert beim ersten Verbinden — wird automatisch mit `StrictHostKeyChecking=accept-new` akzeptiert

### `status`

Zeigt ob das aktuelle Repo einen `gitea` Remote hat und ob es aktuell ist.

1. Pruefe `git remote get-url gitea`
2. Falls vorhanden → `git fetch gitea` und vergleiche Branches
3. Zeige: Remote-URL, lokale vs. remote Commits, ob Push noetig

## Ausgabe-Stil

Halte die Ausgabe kompakt und informativ:
- Erfolgreich: "Repo `name` auf Gitea gepushed (3 Branches, 2 Tags) → URL"
- Fehler: Klare Fehlermeldung mit Loesungsvorschlag
- Liste: Kompakte Tabelle

## Fehlerbehandlung

- **Kein Git-Repo:** "Das aktuelle Verzeichnis ist kein Git-Repo."
- **Gitea nicht erreichbar:** "Gitea-Server nicht erreichbar unter URL. Pruefe die Verbindung."
- **Auth-Fehler (401/403):** "Authentifizierung fehlgeschlagen. Pruefe User/Passwort in $HOME/.claude/cwe.local.md"
- **Repo existiert schon (create):** "Repo existiert bereits. Nutze `/cwe:gitea push` um es zu aktualisieren."
- **Push-Fehler:** Zeige git-Fehlermeldung und schlage Loesung vor (force-push nur nach Bestaetigung)
