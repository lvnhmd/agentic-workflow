---
name: run
description: Start (or reuse) the local app and drive it with the Playwright MCP to verify a change visually — screenshots, flows, before/after. Use whenever a UI or end-to-end behaviour change needs checking in the running app.
---

# Run — launch and verify the app

## 1. Read the configuration — never assume a port

```bash
for k in DEV_CMD APP_URL HEALTH_URL TEST_USER_VAR TEST_PASSWORD_VAR; do echo "$k=$(aw-config $k)"; done
```

If `APP_URL` or `DEV_CMD` is empty, ask the user for them (and suggest adding them to
`.claude/workflow.env`). Every URL below is built from these values.

## 2. Is it already running?

One check, no polling loop:

```bash
curl -s -o /dev/null -w '%{http_code}' "<HEALTH_URL or APP_URL>"
```

`000` = not running. Any other code (200, 302, 401, 503...) = the server is up → skip to step 4.

## 3. Start it

Run `DEV_CMD` with the Bash tool's `run_in_background: true` — without it the session hangs waiting for
the server to exit. Wait ~10 s, check once more. If it still isn't up, read the background output for
the error, report it, and stop.

## 4. Open it

Use the Playwright MCP (`mcp__playwright__browser_navigate`) to open `APP_URL`.

## 5. Log in, if needed

If you land on a login page and `TEST_USER_VAR` / `TEST_PASSWORD_VAR` are set, read just those two
variables from `.env` (`grep "^$TEST_USER_VAR=" .env`) and fill in the form. Never print other `.env`
values. If no test credentials are configured, ask the user to log in or to add them.

## 6. Verify

- Take an accessibility snapshot to find element refs before clicking.
- Exercise the exact flow the ticket describes, including the edge cases from the acceptance criteria.
- Take screenshots for before/after comparisons and for the PR's test evidence. They are saved in the
  repo root; `/pr` deletes untracked root screenshots before committing.
- Check the browser console for errors (`browser_console_messages`).
- For UI work with a design, compare against the Figma frame via the `figma` MCP.

Report what you checked, what you saw, and attach the screenshots that prove it.
