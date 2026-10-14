// mgkit plugin for OpenCode: registers mgkit's skills/ folder so OpenCode discovers its skills.
// One file serves both host generations: OpenCode 2 reads the default export's
// id and setup() and registers each skill through the skill transform; OpenCode
// 1 (1.18.29+) calls server() for its config hook. OpenCode 1 treats every
// export of a plugin module as a plugin, so this file still exports exactly one
// thing — the default object.
import { readdirSync, readFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const skillsDir = path.resolve(here, "../../skills");

// loadSkills reads every skills/<name>/SKILL.md once, up front: OpenCode 2
// transforms are synchronous and replayable, so external data must be captured
// before registration. Frontmatter is parsed minimally — name and description
// are single-line scalars in mgkit's skills.
function loadSkills() {
  const skills = [];
  for (const entry of readdirSync(skillsDir, { withFileTypes: true })) {
    if (!entry.isDirectory()) continue;
    const skillPath = path.join(skillsDir, entry.name, "SKILL.md");
    let content;
    try {
      content = readFileSync(skillPath, "utf8");
    } catch {
      continue;
    }
    skills.push({ id: entry.name, path: skillPath, content, ...parseFrontmatter(content, entry.name) });
  }
  return skills;
}

function parseFrontmatter(content, fallbackName) {
  const fields = {};
  const match = content.match(/^---\r?\n([\s\S]*?)\r?\n---/);
  if (match) {
    for (const line of match[1].split(/\r?\n/)) {
      const field = line.match(/^(name|description):\s*(.*)$/);
      if (!field) continue;
      let value = field[2].trim();
      if (
        (value.startsWith('"') && value.endsWith('"')) ||
        (value.startsWith("'") && value.endsWith("'"))
      ) {
        value = value.slice(1, -1);
      }
      fields[field[1]] = value;
    }
  }
  return { name: fields.name || fallbackName, description: fields.description || "" };
}

export default {
  id: "mgkit",

  // OpenCode 2: add each mgkit skill to the skill registry. The skill id is
  // the directory name, the same id OpenCode 1 derived from skills.paths.
  async setup(ctx) {
    const skills = loadSkills();
    await ctx.skill.transform((editor) => {
      for (const skill of skills) {
        editor.add({
          id: skill.id,
          name: skill.name,
          description: skill.description,
          path: skill.path,
          content: skill.content,
        });
      }
    });
  },

  // OpenCode 1 (1.18.29+): append the absolute path of skills/ to
  // config.skills.paths (a documented config key, scanned recursively for
  // **/SKILL.md).
  async server() {
    return {
      config: async (config) => {
        config.skills = config.skills || {};
        config.skills.paths = config.skills.paths || [];
        if (!config.skills.paths.includes(skillsDir)) config.skills.paths.push(skillsDir);
      },
    };
  },
};
