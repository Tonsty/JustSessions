"""The two sample projects in the demo home, each a git repository, and the file contents their sessions quote."""
import shutil
import subprocess

from demo_paths import PROJECTS

RATE_LIMIT_BEFORE = """import { Router } from "express";
import { storeUpload } from "./storage.js";

export const uploads = Router();

uploads.post("/upload", async (request, response) => {
  const file = await storeUpload(request);
  response.status(201).json(file);
});
"""

CHECKOUT_TEST = """import { test, expect } from "vitest";
import { renderCheckout } from "./checkout.js";

test("shows the total after a coupon", async () => {
  const page = renderCheckout({ coupon: "SPRING" });
  expect(page.total()).toBe("$42.00");
});
"""

ORBIT_WEB = PROJECTS / "orbit-web"
ORBIT_API = PROJECTS / "orbit-api"


def git(project, *arguments):
    subprocess.run(["git", "-C", str(project), "-c", "user.name=Demo", "-c", "user.email=demo@example.invalid",
                    *arguments], check=True, capture_output=True)


def write_project(project, files, uncommitted=None):
    if project.exists():
        shutil.rmtree(project)
    for relative_path, text in files.items():
        path = project / relative_path
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text)
    subprocess.run(["git", "init", "-q", "-b", "main", str(project)], check=True)
    git(project, "add", ".")
    git(project, "commit", "-qm", "Initial commit")
    for relative_path, text in (uncommitted or {}).items():
        (project / relative_path).write_text(text)


def write_sample_projects():
    write_project(ORBIT_WEB, {
        "package.json": '{ "name": "orbit-web", "version": "3.1.0" }\n',
        "src/checkout.test.ts": CHECKOUT_TEST,
        "src/theme.ts": 'export const theme = {\n  accent: "#2f6bff",\n  radius: 8,\n};\n',
    }, uncommitted={"src/theme.ts": 'export const theme = {\n  accent: "#2f6bff",\n  radius: 8,\n  darkMode: "system",\n};\n'})
    write_project(ORBIT_API, {
        "package.json": '{ "name": "orbit-api", "version": "2.4.0" }\n',
        "src/routes/uploads.ts": RATE_LIMIT_BEFORE,
    })
    return [ORBIT_WEB, ORBIT_API]
