"""Rebuilds the demo home's projects, Claude Code settings, and sample Claude Code sessions, with fresh times.

Run before every take (recording/reset_demo.sh), so the sessions' ages read the same in every recording.
"""
from datetime import datetime, timedelta, timezone

from claude_transcript import ClaudeTranscript, short_session
from cli_configs import write_claude_config, write_shell_config
from demo_paths import CLAUDE_DIRECTORY
from sample_projects import CHECKOUT_TEST, ORBIT_API, ORBIT_WEB, RATE_LIMIT_BEFORE, write_sample_projects

RATE_LIMIT_OLD = """uploads.post("/upload", async (request, response) => {"""
RATE_LIMIT_NEW = """uploads.post("/upload", rateLimit({ perMinute: 30 }), async (request, response) => {"""


def rate_limit_session(started_at):
    transcript = ClaudeTranscript(ORBIT_API, "6a1c0e52-3f7d-4d8e-9a51-2b7c4e0d1a01", started_at)
    transcript.user("Add rate limiting to the upload endpoint. Clients should get a 429 after 30 requests a minute.")
    transcript.text("I'll look at the upload route first.")
    transcript.read("src/routes/uploads.ts", RATE_LIMIT_BEFORE)
    transcript.text("There's no limiter yet. I'll add one per API key and return 429 with a Retry-After header.")
    transcript.edit("src/routes/uploads.ts", RATE_LIMIT_BEFORE, RATE_LIMIT_OLD, RATE_LIMIT_NEW)
    transcript.bash("npm test -- uploads", "Run the upload tests",
                    "> orbit-api@2.4.0 test\n> vitest run uploads\n\n ✓ uploads.test.ts (6 tests) 412ms\n\n"
                    " Test Files  1 passed (1)\n      Tests  6 passed (6)")
    transcript.text("Done. `/upload` now allows 30 requests per minute per API key. The 31st gets **429 Too Many "
                    "Requests** with `Retry-After`. All 6 upload tests pass.")
    return transcript


def checkout_session(started_at):
    transcript = ClaudeTranscript(ORBIT_WEB, "6a1c0e52-3f7d-4d8e-9a51-2b7c4e0d1a02", started_at)
    transcript.user("The checkout test is flaky on CI. Can you find out why?")
    transcript.read("src/checkout.test.ts", CHECKOUT_TEST)
    transcript.bash("npx vitest run checkout --repeat 20", "Repeat the checkout test",
                    " ✓ checkout.test.ts (1 test) 18/20 passed\n ✗ 2 runs failed: total was \"$0.00\"")
    transcript.text("The total is read before the coupon request resolves. I'll await the price update.")
    transcript.edit("src/checkout.test.ts", CHECKOUT_TEST, '  const page = renderCheckout({ coupon: "SPRING" });',
                    '  const page = await renderCheckout({ coupon: "SPRING" });\n  await page.pricesSettled();')
    transcript.bash("npx vitest run checkout --repeat 50", "Repeat the checkout test again",
                    " ✓ checkout.test.ts (1 test) 50/50 passed")
    transcript.text("Fixed. The test waited on nothing. It now waits for prices to settle; 50 runs in a row pass.")
    return transcript


def main():
    now = datetime.now(timezone.utc)
    write_shell_config()
    write_claude_config(write_sample_projects())
    sessions = [
        (checkout_session(now - timedelta(minutes=48)), "Fix flaky checkout test"),
        (short_session(ORBIT_WEB, "6a1c0e52-3f7d-4d8e-9a51-2b7c4e0d1a03", now - timedelta(hours=3),
                       "Add a dark mode toggle to settings.",
                       "Added a System / Light / Dark control to Settings. It follows the system by default."),
         "Dark mode toggle"),
        (rate_limit_session(now - timedelta(minutes=95)), "Rate-limit uploads"),
        (short_session(ORBIT_API, "6a1c0e52-3f7d-4d8e-9a51-2b7c4e0d1a04", now - timedelta(days=1, hours=2),
                       "Document the new billing endpoints.",
                       "Added docs for the three billing endpoints, with request and response examples."),
         "Billing endpoint docs"),
    ]
    for transcript, title in sessions:
        print(transcript.save(CLAUDE_DIRECTORY, title=title))


if __name__ == "__main__":
    main()
