#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  Interactive Process Finder & Killer                       ║
# ║  Type to filter · k:kill (confirm) · Tab/Shift+Tab:nav     ║
# ╚══════════════════════════════════════════════════════════════╝

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

WORK_DIR=$(mktemp -d)
LIST_SH="$WORK_DIR/list.sh"
KILL_SH="$WORK_DIR/kill.sh"
PORT_MAP="$WORK_DIR/ports"
trap 'rm -rf "$WORK_DIR"' EXIT

# Standalone list generator — also called by fzf reload
# Fields: PID | PORT | USER | CMD | ARGS (args hidden in display, still searchable)
cat > "$LIST_SH" << 'LIST_EOF'
#!/usr/bin/env bash
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
PORT_MAP="$1"
lsof -i -nP -sTCP:LISTEN 2>/dev/null \
  | awk 'NR>1 { p[$2] = p[$2] ? p[$2] "," $9 : $9 }
         END  { for (pid in p) printf "%s %s\n", pid, p[pid] }' \
  > "$PORT_MAP"
if [[ "$(uname)" == "Darwin" ]]; then
  ps -axm -o pid,user,comm,args
else
  ps -eo pid,user,comm,args --sort=-%mem
fi | awk -v pf="$PORT_MAP" '
  BEGIN {
    while ((getline line < pf) > 0) {
      pid = line+0
      ports[pid] = substr(line, index(line, " ") + 1)
    }
    close(pf)
  }
  NR > 1 {
    pid = $1; user = $2; comm = $3
    args = substr($0, index($0, $4))
    port = (pid in ports) ? ports[pid] : "—"
    printf "%s|%s|%s|%s|%s\n", pid, port, user, comm, args
  }
'
LIST_EOF
chmod +x "$LIST_SH"

# Kill helper — prompts for confirmation, stays visible briefly after
cat > "$KILL_SH" << 'KILL_EOF'
#!/usr/bin/env bash
pid="$1"
[[ -z "$pid" ]] && exit 0
name=$(ps -p "$pid" -o comm= 2>/dev/null || echo "unknown")
printf "\n  Kill PID %s (%s)? [y/N]: " "$pid" "$name"
read -r c < /dev/tty
if [[ "$c" == [yY] ]]; then
  kill -9 "$pid" 2>/dev/null && echo "  Killed." || echo "  Process already gone."
else
  echo "  Cancelled."
fi
sleep 0.4
KILL_EOF
chmod +x "$KILL_SH"

bash "$LIST_SH" "$PORT_MAP" | fzf \
  --header='PID | PORT | USER | CMD        [k] kill  [Tab/Shift+Tab] nav  [Esc] exit' \
  --with-nth=1,2,3,4 \
  --delimiter='|' \
  --preview='ps -p {1} -o pid,user,comm,args 2>/dev/null' \
  --preview-window='bottom:5:wrap' \
  --bind "k:execute($KILL_SH {1})+reload(bash $LIST_SH $PORT_MAP)" \
  --bind 'tab:down,btab:up' \
  --bind 'enter:abort' \
  --prompt='🔍 Process: ' \
  --height=100% --border \
  --color='bg+:#313244,fg+:#CDD6F4,hl:#89B4FA,hl+:#89B4FA,pointer:#89B4FA,prompt:#89B4FA,header:#585B70,info:#585B70'
