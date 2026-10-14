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
    const v1Hooks = async () => (await plugin.default.server());
    const register = async (cfg) => { const hooks = await v1Hooks(); await hooks.config(cfg); return cfg; };
    const setupV2 = async () => {
      const added = [];
      const ctx = {
        skill: {
          transform: async (callback) => {
            callback({ add: (skill) => added.push(skill) });
          },
        },
      };
      await plugin.default.setup(ctx);
      return added;
    };
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

test_exports_only_the_dual_plugin() {
  node_eval "
    const names = Object.keys(plugin);
    if (names.length !== 1 || names[0] !== 'default') throw new Error('exports: ' + names.join(','));
    const definition = plugin.default;
    if (definition.id !== 'mgkit') throw new Error('id: ' + definition.id);
    if (typeof definition.setup !== 'function') throw new Error('no setup for OpenCode 2');
    if (typeof definition.server !== 'function') throw new Error('no server for OpenCode 1');
    const hooks = await v1Hooks();
    if (typeof hooks.config !== 'function') throw new Error('no config hook');
  "
  assert_status 0
}

test_v2_setup_registers_every_skill() {
  node_eval "
    import { readdirSync, readFileSync } from 'node:fs';
    import path from 'node:path';
    const added = await setupV2();
    const expected = readdirSync('$SKILLS_DIR', { withFileTypes: true })
      .filter((entry) => entry.isDirectory())
      .map((entry) => entry.name)
      .sort();
    const ids = added.map((skill) => skill.id).sort();
    if (JSON.stringify(ids) !== JSON.stringify(expected)) {
      throw new Error('ids: ' + ids.join(',') + ' expected: ' + expected.join(','));
    }
    for (const skill of added) {
      if (!skill.name) throw new Error(skill.id + ': no name');
      if (!skill.description) throw new Error(skill.id + ': no description');
      if (skill.path !== path.join('$SKILLS_DIR', skill.id, 'SKILL.md')) throw new Error(skill.id + ': wrong path');
      if (skill.content !== readFileSync(skill.path, 'utf8')) throw new Error(skill.id + ': content mismatch');
      if (!skill.content.startsWith('---')) throw new Error(skill.id + ': content is not the SKILL.md file');
    }
  "
  assert_status 0
}

test_v2_skill_names_match_frontmatter() {
  node_eval "
    const added = await setupV2();
    const build = added.find((skill) => skill.id === 'build');
    if (!build) throw new Error('build skill missing');
    if (build.name !== 'build') throw new Error('name: ' + build.name);
    if (!build.description.includes('mgkit pipeline')) throw new Error('description: ' + build.description);
  "
  assert_status 0
}

run_tests
