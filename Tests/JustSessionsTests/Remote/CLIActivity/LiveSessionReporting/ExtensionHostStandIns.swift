import Foundation

/// Stand-ins for Pi and OpenCode that run the app's real extension in `node`, as the CLIs run it, and drive it as the
/// CLI would: Pi through the events it fires, OpenCode through the state its TUI shows. Each takes the next step from
/// a file in the home folder that the test rewrites, one step a line, and runs the lines it has not run yet.
enum ExtensionHostStandIns {
    /// An installed `node`, or nil where none is, and tests that need one are skipped.
    static var installedNodePath: String? {
        ["/opt/homebrew/bin/node", "/usr/local/bin/node", "/usr/bin/node"].first(where: FileManager.default.isExecutableFile(atPath:))
    }

    /// The file a stand-in reads its steps from.
    static let stepsFileName = "cli-steps"

    /// `pi --extension <file>`. A step is an event's name, and for a prompt a tab and its title.
    static let pi = #"""
        import { copyFileSync, readFileSync } from "node:fs";
        import { join } from "node:path";
        import { pathToFileURL } from "node:url";

        // Copied to a name that tells node it is a module, as Pi needs no such name.
        const extensionFile = join(process.env.HOME, "extension.mjs");
        copyFileSync(process.argv[process.argv.indexOf("--extension") + 1], extensionFile);
        const { default: extension } = await import(pathToFileURL(extensionFile).href);
        const handlers = {};
        extension({ on: (name, handler) => { handlers[name] = handler; }, registerEntryRenderer() {} });
        const context = { sessionManager: { getSessionId: () => "abc", getSessionFile: () => undefined }, isIdle: () => true };
        handlers.session_start({}, context);

        let stepsRun = 0;
        setInterval(() => {
          let steps = [];
          try { steps = readFileSync(join(process.env.HOME, "\#(stepsFileName)"), "utf8").split("\n").filter(Boolean); } catch {}
          for (const step of steps.slice(stepsRun)) {
            const [name, title] = step.split("\t");
            handlers[name]?.({ kind: "confirm", title, reason: "quit" }, context);
          }
          stepsRun = steps.length;
        }, 100);
        """#

    /// `opencode` with `OPENCODE_TUI_CONFIG`, whose plugin it loads as OpenCode does. A step is the TUI's state as JSON:
    /// `session`, the session on screen or null, `status`, and `permissions`, how many are open.
    static let openCode = #"""
        import { copyFileSync, readFileSync } from "node:fs";
        import { dirname, join, resolve } from "node:path";
        import { pathToFileURL } from "node:url";

        const configuration = process.env.OPENCODE_TUI_CONFIG;
        // Copied to a name that tells node it is a module, as OpenCode needs no such name.
        const pluginFile = join(process.env.HOME, "plugin.mjs");
        copyFileSync(resolve(dirname(configuration), JSON.parse(readFileSync(configuration, "utf8")).plugin[0]), pluginFile);
        const { default: plugin } = await import(pathToFileURL(pluginFile).href);
        let state = { session: null, status: "idle", permissions: 0 };
        await plugin.tui({
          route: { get current() { return state.session ? { name: "session", params: { sessionID: state.session } } : { name: "home" }; } },
          state: {
            session: {
              get: () => ({}),
              status: () => ({ type: state.status }),
              permission: () => Array(state.permissions).fill({}),
              question: () => [],
            },
          },
          event: { on: () => () => {} },
          lifecycle: { onDispose: () => {} },
        });

        setInterval(() => {
          let steps = [];
          try { steps = readFileSync(join(process.env.HOME, "\#(stepsFileName)"), "utf8").split("\n").filter(Boolean); } catch {}
          if (steps.length > 0) state = JSON.parse(steps.at(-1));
        }, 100);
        """#
}
