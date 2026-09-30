import { Plugin } from "@opencode/plugin"

// RTK OpenCode plugin — rewrites commands to use rtk for token savings.
// Requires: rtk >= 0.23.0 in PATH.

export default Plugin.define({
  id: "rtk",
  async setup(ctx) {
    if (!Bun.which("rtk")) {
      console.warn("[rtk] rtk binary not found in PATH — plugin disabled")
      return
    }

    await ctx.tool.hook("execute.before", async (event) => {
      const tool = String((event as { tool?: unknown }).tool ?? "").toLowerCase()
      if (tool !== "bash" && tool !== "shell") return

      const input = (event as { input: unknown }).input as { command?: unknown }
      const command = input.command
      if (typeof command !== "string" || !command) return

      try {
        const result = await Bun.$`rtk rewrite ${command}`.quiet().nothrow()
        const rewritten = String(result.stdout).trim()
        if (rewritten && rewritten !== command) {
          input.command = rewritten
        }
      } catch {
        // rtk rewrite failed — pass through unchanged
      }
    })
  },
})
