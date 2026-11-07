#!/usr/bin/env bash
# Assemble and check mgkit plan HTML files. No dependencies beyond bash 3.2, grep, sed and awk.
# Usage:
#   assemble-plan.sh <out.html> <title>      wrap <out.html>.body in the shared head, check it,
#                                            write <out.html> and delete the .body file
#   assemble-plan.sh --check <file.html>...  check existing plan files or body fragments
#   assemble-plan.sh --classes               print the allowed class names, one per line
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HEAD_FILE="$DIR/../templates/_head.html"
ALLOWED_CLASSES="muted rule step task decision user-task files diff add del callout note warn out-of-scope diagram"

usage() {
  printf 'usage: %s <out.html> <title> | --check <file.html>... | --classes\n' "$(basename "$0")" >&2
  exit 2
}

# body_of <file>: the part after the line holding </head> when the file has one, else the whole file.
# Assembly rejects a body containing </head>, so a body file is always checked whole.
body_of() {
  if grep -q '</head>' "$1"; then sed '1,/<\/head>/d' "$1"; else cat "$1"; fi
}

# check_one <file>: prints one FAIL line per problem; returns 1 when there is any.
check_one() {
  local file="$1" body hits cls bad=0
  # Spaces around = are legal HTML; drop them so every check below sees attr="value".
  body="$(body_of "$file" | sed -E 's/[[:space:]]*=[[:space:]]*/=/g')"

  hits="$(printf '%s\n' "$body" | grep -n '{{' || true)"
  if [ -n "$hits" ]; then printf 'FAIL %s: placeholder left: %s\n' "$file" "$hits"; bad=1; fi

  hits="$(printf '%s\n' "$body" | grep -niE '<(style|script|link|iframe|object|embed)|<[a-z][^>]*[[:space:]](style|on[a-z]+)=|<[a-z][^>]*[[:space:]](src|poster|data)=["'"'"']?(https?:)?//|<(img|source|video|audio|track|image|use)[[:space:]/][^>]*(https?:)?//' || true)"
  if [ -n "$hits" ]; then printf 'FAIL %s: inline style, script or external resource: %s\n' "$file" "$hits"; bad=1; fi

  # Leftovers are checked in prose only: a code sample can quote these markers on purpose.
  hits="$(printf '%s\n' "$body" | awk '
    {
      rest = $0; prose = ""
      while (rest != "") {
        if (inpre) {
          if (match(rest, /<\/pre>/)) { rest = substr(rest, RSTART + RLENGTH); inpre = 0 } else rest = ""
        } else if (match(rest, /<pre[ >]/)) {
          prose = prose substr(rest, 1, RSTART - 1); rest = substr(rest, RSTART); inpre = 1
        } else { prose = prose rest; rest = "" }
      }
      if (tolower(prose) ~ /:contentreference\[|oaicite:|xx%|\[insert /) print NR ": " $0
    }' || true)"
  if [ -n "$hits" ]; then printf 'FAIL %s: generation leftover (citation marker or placeholder): %s\n' "$file" "$hits"; bad=1; fi

  # A diff line that is only an elision ("…", "// ...", "# …") hides real lines; split the hunk instead.
  # A bare "..." is left alone: it is real code in Python stubs, R and YAML.
  hits="$(printf '%s\n' "$body" | awk '
    /<pre[^>]*class="([^"]* )?diff( [^"]*)?"/ { indiff = 1 }
    indiff {
      line = $0; gsub(/<[^>]*>/, "", line)
      # Decode only the ellipsis entities; "&amp;hellip;" is literal source text and stays as it is.
      gsub(/&hellip;|&#8230;|&#x2026;/, "…", line)
      if (line ~ /^[[:space:]+-]*(\/\/|#|--)[[:space:]]*(\.\.\.|…)[[:space:]]*$/ || line ~ /^[[:space:]+-]*…[[:space:]]*$/) print NR ": " $0
    }
    /<\/pre>/ { indiff = 0 }' || true)"
  if [ -n "$hits" ]; then printf 'FAIL %s: elision inside a diff; split it into separate hunks: %s\n' "$file" "$hits"; bad=1; fi

  hits="$(printf '%s\n' "$body" | grep -nE "<[a-zA-Z][^>]*[[:space:]]class='" || true)"
  if [ -n "$hits" ]; then printf 'FAIL %s: write class values in double quotes: %s\n' "$file" "$hits"; bad=1; fi

  for cls in $(printf '%s\n' "$body" | grep -oE '<[a-zA-Z][^>]*class="[^"]*"' | sed -E 's/.*class="([^"]*)"/\1/'); do
    case " $ALLOWED_CLASSES " in
      *" $cls "*) ;;
      *) printf 'FAIL %s: class "%s" is not in the component catalog\n' "$file" "$cls"; bad=1 ;;
    esac
  done

  hits="$(printf '%s\n' "$body" | awk -v f="$file" '
    /<section[ >]/ && /class="([^"]* )?(step|task)( [^"]*)?"/ {
      inside = 1; text = ""
      labels = "Files:|Test first:|Do:|Acceptance:"
      if ($0 ~ /class="([^"]* )?step( [^"]*)?"/) labels = labels "|Gate:"
      id = "(no id)"
      if (match($0, /id="[^"]*"/)) id = substr($0, RSTART + 4, RLENGTH - 5)
    }
    inside { text = text $0 "\n" }
    inside && /<\/section>/ {
      n = split(labels, want, "|")
      for (i = 1; i <= n; i++) if (index(text, "<strong>" want[i] "</strong>") == 0) print "FAIL " f ": " id " is missing " want[i]
      inside = 0
    }
    END { if (inside) print "FAIL " f ": " id " has no closing </section>" }' || true)"
  if [ -n "$hits" ]; then printf '%s\n' "$hits"; bad=1; fi

  return "$bad"
}

[ "$#" -ge 1 ] || usage
case "$1" in
  --classes)
    printf '%s\n' $ALLOWED_CLASSES
    ;;
  --check)
    shift
    [ "$#" -ge 1 ] || usage
    status=0
    for f in "$@"; do
      if [ ! -f "$f" ] || [ ! -r "$f" ]; then printf 'FAIL %s: no such readable file\n' "$f"; status=1; continue; fi
      if check_one "$f"; then printf 'ok   %s\n' "$f"; else status=1; fi
    done
    exit "$status"
    ;;
  -*)
    usage
    ;;
  *)
    [ "$#" -eq 2 ] || usage
    out="$1"; title="$2"; body_file="$out.body"
    if [ ! -f "$body_file" ]; then printf 'FAIL %s: body file not found\n' "$body_file"; exit 1; fi
    if ! grep -q '[^[:space:]]' "$body_file"; then printf 'FAIL %s: body file is empty\n' "$body_file"; exit 1; fi
    case "$title" in *'{{'*) printf 'FAIL: title still has a placeholder: %s\n' "$title"; exit 1 ;; esac
    if [ -e "$out" ]; then printf 'FAIL %s: already exists; never overwrite a plan\n' "$out"; exit 1; fi
    if grep -qiE '<!doctype|</?(html|head|body)[ >]' "$body_file"; then
      printf 'FAIL %s: write only the body; the script adds doctype, html, head and body\n' "$body_file"; exit 1
    fi
    check_one "$body_file" || exit 1
    esc_title="$(printf '%s' "$title" | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g')"
    tmp="$out.tmp.$$"
    {
      printf '<!doctype html>\n<html lang="en">\n<head>\n'
      cat "$HEAD_FILE"
      printf '<title>%s</title>\n</head>\n<body>\n' "$esc_title"
      cat "$body_file"
      printf '</body>\n</html>\n'
    } > "$tmp"
    mv "$tmp" "$out"
    rm "$body_file"
    printf 'ok   %s\n' "$out"
    ;;
esac
