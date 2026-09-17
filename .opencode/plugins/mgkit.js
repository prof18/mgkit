// mgkit plugin for OpenCode: registers mgkit's skills/ folder so OpenCode discovers its skills.
// OpenCode treats every export of a plugin module as a plugin, so this file exports only MgkitPlugin.
import path from "node:path";
import { fileURLToPath } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const skillsDir = path.resolve(here, "../../skills");

export const MgkitPlugin = async () => ({
  config: async (config) => {
    config.skills = config.skills || {};
    config.skills.paths = config.skills.paths || [];
    if (!config.skills.paths.includes(skillsDir)) config.skills.paths.push(skillsDir);
  },
});
