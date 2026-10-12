"""Writes the demo home's shell and CLI settings: a quiet prompt, and every CLI set up to start without a login.

Claude Code never sends a prompt during the demo. Codex, OpenCode, and Pi talk only to the canned model server.
"""
import json

from claude_transcript import CLAUDE_VERSION
from demo_paths import CLAUDE_DIRECTORY, HOME, MODEL_SERVER

MODEL = "gpt-5.5"
# The helper only stops Claude Code's "Not logged in" notice; the demo never sends a prompt to the API.
CLAUDE_SETTINGS = {"theme": "light", "spinnerTipsEnabled": False, "env": {"DISABLE_AUTOUPDATER": "1"},
                   "apiKeyHelper": "echo demo-key-not-used"}


def write_shell_config():
    HOME.mkdir(parents=True, exist_ok=True)
    (HOME / ".zshrc").write_text("PROMPT='%F{244}%1~%f %F{208}❯%f '\nexport CLICOLOR=1\n")
    (HOME / ".zprofile").write_text("")
    (HOME / ".gitconfig").write_text("[user]\n\tname = Demo\n\temail = demo@example.invalid\n"
                                     "[core]\n\tpager = cat\n[color]\n\tui = always\n[init]\n\tdefaultBranch = main\n")


def claude_config(project_paths, startups):
    return {"theme": "light", "hasCompletedOnboarding": True, "numStartups": startups,
            "lastReleaseNotesSeen": CLAUDE_VERSION, "hasSeenAutoDefaultNotice": True, "tipsHistory": {},
            "autoUpdates": False,
            "projects": {str(path): {"hasTrustDialogAccepted": True, "hasCompletedProjectOnboarding": True,
                                     "projectOnboardingSeenCount": 4, "allowedTools": []}
                         for path in project_paths}}


def write_claude_config(project_paths):
    CLAUDE_DIRECTORY.mkdir(parents=True, exist_ok=True)
    (CLAUDE_DIRECTORY / ".claude.json").write_text(json.dumps(claude_config(project_paths, 12), indent=2))
    (CLAUDE_DIRECTORY / "settings.json").write_text(json.dumps(CLAUDE_SETTINGS, indent=2))


def write_codex_config(project_paths):
    # Codex checks trust by the folder's real path, which differs when DEMO_HOME goes through a symlink.
    trusted_paths = dict.fromkeys(str(form) for path in project_paths for form in (path, path.resolve()))
    trusted = "".join(f'\n[projects."{path}"]\ntrust_level = "trusted"\n' for path in trusted_paths)
    (HOME / ".codex").mkdir(parents=True, exist_ok=True)
    (HOME / ".codex/config.toml").write_text(f'''model = "{MODEL}"
model_provider = "demo"
check_for_update_on_startup = false

[model_providers.demo]
name = "OpenAI"
base_url = "{MODEL_SERVER}"
wire_api = "responses"
requires_openai_auth = false
{trusted}
[notice]
hide_full_access_warning = true

# Notices Codex 0.162 shows on a first start, marked as seen so typed prompts reach the composer.
[notice.model_migrations]
"{MODEL}" = "gpt-6-sol"

[tui]
screen_reader_detection_done = true

[tui.model_availability_nux]
"gpt-6.1-sol" = 4
''')


def write_opencode_config():
    folder = HOME / ".config/opencode"
    folder.mkdir(parents=True, exist_ok=True)
    (folder / "opencode.json").write_text(json.dumps({
        "$schema": "https://opencode.ai/config.json", "autoupdate": False, "share": "disabled",
        "model": f"openai/{MODEL}",
        "provider": {"openai": {"npm": "@ai-sdk/openai-compatible", "name": "OpenAI",
                                "options": {"baseURL": MODEL_SERVER, "apiKey": "unused-local-demo"},
                                "models": {MODEL: {"name": "GPT-5.5"}}}},
    }, indent=2) + "\n")


def write_pi_config():
    folder = HOME / ".pi/agent"
    folder.mkdir(parents=True, exist_ok=True)
    (folder / "models.json").write_text(json.dumps({"providers": {"openai-demo": {
        "baseUrl": MODEL_SERVER, "api": "openai-completions", "apiKey": "unused-local-demo",
        "models": [{"id": MODEL, "name": "GPT-5.5", "reasoning": False, "input": ["text"], "contextWindow": 200000,
                    "maxTokens": 16000, "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}}],
    }}}, indent=2) + "\n")
    (folder / "settings.json").write_text(json.dumps(
        {"defaultProvider": "openai-demo", "defaultModel": MODEL, "quietStartup": False}) + "\n")
    (folder / "auth.json").write_text("{}\n")


def main():
    from sample_projects import ORBIT_API, ORBIT_WEB
    write_codex_config([ORBIT_WEB, ORBIT_API])
    write_opencode_config()
    write_pi_config()
    print(f"wrote Codex, OpenCode, and Pi settings in {HOME}")


if __name__ == "__main__":
    main()
