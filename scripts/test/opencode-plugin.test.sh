#!/usr/bin/env bash
# Tests for .opencode/plugins/mgkit.js.
source "$(dirname "$0")/lib.sh"
PLUGIN="$(cd "$SCRIPTS_DIR/.." && pwd)/.opencode/plugins/mgkit.js"
SKILLS_DIR="$(cd "$SCRIPTS_DIR/.." && pwd)/skills"

# node_eval <js> -> runs an ES module snippet with `plugin` bound to the imported module
node_eval() {
  run_capture node --input-type=module -e "
    import { pathToFileURL } from 'node:url';
    const plugin = await import(pathToFileURL(process.argv[1]).href);
    const hooks = await plugin.MgkitPlugin({});
    const register = async (cfg) => { await hooks.config(cfg); return cfg; };
    $1
  " "$PLUGIN"
}

test_registers_skills_path_on_empty_config() {
  node_eval "
    const cfg = await register({});
    if (cfg.skills.paths.length !== 1) throw new Error('expected one path');
    console.log(cfg.skills.paths[0]);
  "
  assert_status 0
  assert_contains "$SKILLS_DIR"
}

test_does_not_duplicate_path() {
  node_eval "
    const cfg = {};
    await register(cfg);
    await register(cfg);
    if (cfg.skills.paths.length !== 1) throw new Error('duplicated: ' + cfg.skills.paths.length);
  "
  assert_status 0
}

test_preserves_existing_paths() {
  node_eval "
    const cfg = { skills: { paths: ['/existing'] }, model: 'x' };
    await register(cfg);
    if (cfg.skills.paths[0] !== '/existing' || cfg.skills.paths.length !== 2) throw new Error(JSON.stringify(cfg));
    if (cfg.model !== 'x') throw new Error('other keys changed');
  "
  assert_status 0
}

test_exports_only_the_plugin() {
  node_eval "
    const names = Object.keys(plugin);
    if (names.length !== 1 || names[0] !== 'MgkitPlugin') throw new Error('exports: ' + names.join(','));
    if (typeof hooks.config !== 'function') throw new Error('no config hook');
  "
  assert_status 0
}

run_tests
