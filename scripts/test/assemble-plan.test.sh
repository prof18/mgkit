#!/usr/bin/env bash
# Tests for skills/plan/scripts/assemble-plan.sh and the plan component catalog.
source "$(dirname "$0")/lib.sh"
SKILLS="$SCRIPTS_DIR/../skills"
ASSEMBLE="$SKILLS/plan/scripts/assemble-plan.sh"
CATALOG="$SKILLS/plan/templates/components.html"
HEAD_FILE="$SKILLS/plan/templates/_head.html"

# One root registered at top level: new_dir runs in $(...), where _tmp_dirs+= would be lost.
TMP_ROOT="$(mktemp -d)"
_tmp_dirs+=("$TMP_ROOT")
new_dir() { mktemp -d "$TMP_ROOT/t.XXXXXX"; }

STEP_OK='<section class="step" id="S1">
<h3>☐ 1. A</h3>
<p><strong>Files:</strong> a</p>
<p><strong>Test first:</strong> a</p>
<p><strong>Do:</strong> a</p>
<p><strong>Gate:</strong> a</p>
<p><strong>Acceptance:</strong> a</p>
</section>'

test_assembles_valid_body() {
  local d; d="$(new_dir)"
  printf '<h1>T</h1>\n%s\n' "$STEP_OK" > "$d/p.html.body"
  run_capture bash "$ASSEMBLE" "$d/p.html" 'Fish & <Chips>'
  assert_status 0
  [ ! -e "$d/p.html.body" ] || fail "body file was not deleted"
  assert_file_contains "$d/p.html" '<!doctype html>'
  assert_file_contains "$d/p.html" '<title>Fish &amp; &lt;Chips&gt;</title>'
  assert_file_contains "$d/p.html" "$(head -n 1 "$HEAD_FILE")"
  assert_file_contains "$d/p.html" '</html>'
}

test_refuses_to_overwrite() {
  local d; d="$(new_dir)"
  printf '<h1>T</h1>\n' > "$d/p.html.body"; printf 'old\n' > "$d/p.html"
  run_capture bash "$ASSEMBLE" "$d/p.html" T
  assert_status 1
  assert_contains "already exists"
}

test_rejects_document_shell_in_body() {
  local d; d="$(new_dir)"
  printf '<!doctype html>\n<h1>T</h1>\n' > "$d/p.html.body"
  run_capture bash "$ASSEMBLE" "$d/p.html" T
  assert_status 1
  assert_contains "write only the body"
}

test_rejects_placeholder() {
  local d; d="$(new_dir)"
  printf '<h1>{{title}}</h1>\n' > "$d/p.html.body"
  run_capture bash "$ASSEMBLE" "$d/p.html" T
  assert_status 1
  assert_contains "placeholder left"
  [ ! -e "$d/p.html" ] || fail "plan written despite FAIL"
}

test_rejects_inline_style_and_script() {
  local d; d="$(new_dir)"
  printf '<p style="color:red">x</p>\n<script>1</script>\n' > "$d/a.html"
  run_capture bash "$ASSEMBLE" --check "$d/a.html"
  assert_status 1
  assert_contains "inline style, script or external resource"
}

test_allows_escaped_markup_in_code() {
  local d; d="$(new_dir)"
  printf '<pre><code>&lt;p style="x" class="nope"&gt;</code></pre>\n' > "$d/a.html"
  run_capture bash "$ASSEMBLE" --check "$d/a.html"
  assert_status 0
}

test_rejects_unknown_class() {
  local d; d="$(new_dir)"
  printf '<p class="muted fancy">x</p>\n' > "$d/a.html"
  run_capture bash "$ASSEMBLE" --check "$d/a.html"
  assert_status 1
  assert_contains 'class "fancy"'
}

test_step_needs_gate_and_task_does_not() {
  local d; d="$(new_dir)"
  printf '%s\n' "$STEP_OK" | grep -v 'Gate:' > "$d/a.html"
  run_capture bash "$ASSEMBLE" --check "$d/a.html"
  assert_status 1
  assert_contains "S1 is missing Gate:"
  printf '%s\n' "$STEP_OK" | grep -v 'Gate:' | sed 's/class="step" id="S1"/class="task" id="T1.1"/' > "$d/b.html"
  run_capture bash "$ASSEMBLE" --check "$d/b.html"
  assert_status 0
}

test_task_missing_acceptance() {
  local d; d="$(new_dir)"
  printf '%s\n' "$STEP_OK" | grep -v 'Acceptance:' | sed 's/class="step" id="S1"/class="task" id="T2.3"/' > "$d/a.html"
  run_capture bash "$ASSEMBLE" --check "$d/a.html"
  assert_status 1
  assert_contains "T2.3 is missing Acceptance:"
}

test_rejects_closing_head_in_body() {
  local d; d="$(new_dir)"
  printf '<script>1</script>\n</head>\n<p>x</p>\n' > "$d/p.html.body"
  run_capture bash "$ASSEMBLE" "$d/p.html" T
  assert_status 1
  assert_contains "write only the body"
}

test_rejects_remote_image_and_single_quoted_class() {
  local d; d="$(new_dir)"
  printf '<img src="https://example.com/t.png" alt="">\n' > "$d/a.html"
  run_capture bash "$ASSEMBLE" --check "$d/a.html"
  assert_status 1
  assert_contains "external resource"
  printf "<p class='fancy'>x</p>\n" > "$d/b.html"
  run_capture bash "$ASSEMBLE" --check "$d/b.html"
  assert_status 1
  assert_contains "double quotes"
}

test_section_check_ignores_attribute_order() {
  local d; d="$(new_dir)"
  printf '<section id="S2" class="step">\n<p><strong>Files:</strong> a</p>\n</section>\n' > "$d/a.html"
  run_capture bash "$ASSEMBLE" --check "$d/a.html"
  assert_status 1
  assert_contains "S2 is missing Do:"
}

test_spaced_attributes_are_still_checked() {
  local d; d="$(new_dir)"
  printf '<p class = "fancy">x</p>\n' > "$d/a.html"
  run_capture bash "$ASSEMBLE" --check "$d/a.html"
  assert_status 1
  assert_contains 'class "fancy"'
  printf '<section class = "step" id="S3">\n</section>\n' > "$d/b.html"
  run_capture bash "$ASSEMBLE" --check "$d/b.html"
  assert_status 1
  assert_contains "S3 is missing Files:"
}

test_rejects_remote_srcset_and_svg_image() {
  local d; d="$(new_dir)"
  printf '<img srcset="a.png 1x, https://example.com/t.png 2x" alt="">\n' > "$d/a.html"
  run_capture bash "$ASSEMBLE" --check "$d/a.html"
  assert_status 1
  assert_contains "external resource"
  printf '<svg viewBox="0 0 1 1"><image/href="https://example.com/t.png"/></svg>\n' > "$d/b.html"
  run_capture bash "$ASSEMBLE" --check "$d/b.html"
  assert_status 1
  assert_contains "external resource"
}

test_rejects_placeholder_title() {
  local d; d="$(new_dir)"
  printf '<h1>T</h1>\n' > "$d/p.html.body"
  run_capture bash "$ASSEMBLE" "$d/p.html" '{{title}}'
  assert_status 1
  assert_contains "title still has a placeholder"
  [ -e "$d/p.html.body" ] || fail "body file was deleted"
  [ ! -e "$d/p.html" ] || fail "plan written despite FAIL"
}

test_rejects_empty_body() {
  local d; d="$(new_dir)"
  printf '  \n' > "$d/p.html.body"
  run_capture bash "$ASSEMBLE" "$d/p.html" T
  assert_status 1
  assert_contains "body file is empty"
  [ -e "$d/p.html.body" ] || fail "body file was deleted"
  [ ! -e "$d/p.html" ] || fail "plan written despite FAIL"
}

test_check_ignores_head_of_full_file() {
  local d; d="$(new_dir)"
  printf '<!doctype html>\n<html>\n<head>\n<style>.x{}</style>\n</head>\n<body>\n<p class="muted">x</p>\n</body>\n</html>\n' > "$d/a.html"
  run_capture bash "$ASSEMBLE" --check "$d/a.html"
  assert_status 0
}

test_rejects_generation_leftovers() {
  local d; d="$(new_dir)"
  printf '<p>Fast :contentReference[oaicite:1]{index=1}.</p>\n' > "$d/a.html"
  run_capture bash "$ASSEMBLE" --check "$d/a.html"
  assert_status 1
  assert_contains "generation leftover"
  printf '<p>Cuts load time by XX%%.</p>\n' > "$d/b.html"
  run_capture bash "$ASSEMBLE" --check "$d/b.html"
  assert_status 1
  assert_contains "generation leftover"
  printf '<p>Owner: [Insert name].</p>\n' > "$d/c.html"
  run_capture bash "$ASSEMBLE" --check "$d/c.html"
  assert_status 1
  assert_contains "generation leftover"
}

test_rejects_elision_inside_diff() {
  local d; d="$(new_dir)"
  printf '<pre class="diff"><code>  a\n  // ...\n<span class="add">+ b</span></code></pre>\n' > "$d/a.html"
  run_capture bash "$ASSEMBLE" --check "$d/a.html"
  assert_status 1
  assert_contains "elision inside a diff"
  printf '<pre class="diff"><code>  a\n<span class="del">- // …</span>\n</code></pre>\n' > "$d/b.html"
  run_capture bash "$ASSEMBLE" --check "$d/b.html"
  assert_status 1
  assert_contains "elision inside a diff"
  printf '<pre class="diff"><code>  a\n  &#8230;\n</code></pre>\n' > "$d/c.html"
  run_capture bash "$ASSEMBLE" --check "$d/c.html"
  assert_status 1
  assert_contains "elision inside a diff"
}

test_allows_real_code_dots_and_elision_outside_diff() {
  local d; d="$(new_dir)"
  printf '<pre class="diff"><code><span class="add">+ f(...args)</span>\n<span class="add">+     ...</span>\n</code></pre>\n<pre><code>a\n...\n</code></pre>\n<p>Wait...</p>\n' > "$d/a.html"
  run_capture bash "$ASSEMBLE" --check "$d/a.html"
  assert_status 0
}

test_allows_leftover_words_in_code_and_as_identifiers() {
  local d; d="$(new_dir)"
  printf '<p>Set <code>contentReference</code> to the record id.</p>\n<pre><code>grep -E ":contentReference\\[oaicite:" | grep "XX%%"\n</code></pre>\n<pre class="diff"><code><span class="add">+ &amp;hellip; &amp;#8230;</span>\n</code></pre>\n' > "$d/a.html"
  run_capture bash "$ASSEMBLE" --check "$d/a.html"
  assert_status 0
}

test_rejects_leftover_on_a_code_boundary_line() {
  local d; d="$(new_dir)"
  printf '<pre><code>ok</code></pre><p>Owner: [Insert name].</p>\n' > "$d/a.html"
  run_capture bash "$ASSEMBLE" --check "$d/a.html"
  assert_status 1
  assert_contains "generation leftover"
  printf '<p>Cuts XX%% of time.</p><pre><code>a\n</code></pre>\n' > "$d/b.html"
  run_capture bash "$ASSEMBLE" --check "$d/b.html"
  assert_status 1
  assert_contains "generation leftover"
}

test_catalog_passes_and_stays_small() {
  run_capture bash "$ASSEMBLE" --check "$CATALOG"
  assert_status 0
  local size; size="$(wc -c < "$CATALOG" | tr -d ' ')"
  [ "$size" -le 3072 ] || fail "catalog is $size bytes (max 3072)"
}

test_every_allowed_class_is_styled_and_in_catalog() {
  local c
  for c in $(bash "$ASSEMBLE" --classes); do
    grep -qE "\.$c([^a-z-]|$)" "$HEAD_FILE" || fail "class $c has no rule in _head.html"
    grep -qE "class=\"([^\"]* )?$c( [^\"]*)?\"" "$CATALOG" || fail "class $c missing from the catalog"
  done
}

test_templates_pass_with_placeholders_filled() {
  local d t; d="$(new_dir)"
  for t in "$SKILLS/plan/templates/plan.html" "$SKILLS"/plan-max/templates/*.html; do
    if grep -qiE '<!doctype|<head[ >]' "$t"; then fail "$t still has a document shell"; fi
    sed 's/{{[^}]*}}/x/g' "$t" > "$d/$(basename "$t")"
    run_capture bash "$ASSEMBLE" --check "$d/$(basename "$t")"
    assert_status 0
  done
}

run_tests
