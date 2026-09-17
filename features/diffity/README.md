# diffity feature

Opt-in feature that builds [diffity](https://github.com/sdirix/diffity) — an
agent-driven, GitHub-style diff review UI — from a **pinned git commit**, inside
the agent image.

Install and enable it:

```bash
enclave features add sdirix/enclave-extensions --name diffity
enclave --features +diffity …
```

Viewing the UI needs the [vnc feature](../vnc) as well, see
[Using it in a session](#using-it-in-a-session).

## What it does

At image build time, `install.sh`:

1. clones diffity and checks out a pinned commit SHA (verifying `git rev-parse
   HEAD` matches), so the build uses exactly the reviewed source rather than the
   mutable npm registry package;
2. runs `npm ci --ignore-scripts` (exact, hash-checked dependency tree, no
   arbitrary lifecycle scripts), then rebuilds `esbuild` (the bundler, whose own
   install step `--ignore-scripts` skips);
3. runs `npm run build` and installs a `diffity` launcher on `PATH`.

Every build step and the installed launcher use the **private agent Node
runtime** (`/opt/enclave/node`), not the session's user-facing `node` — the same
convention every bundled agent tool follows. The user-facing node can be
repointed (the `node-dev` feature aliases its own nvm default; a project `.nvmrc`
selects a version), so pinning keeps diffity on a runtime that meets its declared
Node floor (`>=22.13`) regardless. diffity has no native modules, so this is a
stable-runtime guarantee rather than an ABI requirement. Because the build happens
in this image, **sessions need no npm/registry access at runtime**.

## Using it in a session

`diffity` is on `PATH` for the agent and serves on **container-local**
port 5391 — no host port is published, so the agent-served UI is never loaded
by the host browser. Viewing goes through the `vnc` feature instead: diffity
opens its own UI in the contained Chromium (see below), and the human watches
that display over VNC (see the [vnc feature](../vnc)):

```bash
enclave features add sdirix/enclave-extensions --name vnc
enclave --features +diffity,+vnc …
# on the host:
enclave vnc-viewer   # opens a viewer on the session's contained display
```

Inside the session, every diffity command that opens a view (`diffity`,
`diffity tree`, `diffity open`) drives the contained Chromium to the right
URL — **including the ref**, so the intended diff and its review session are
shown. This runs through the same `$BROWSER`/`xdg-open` path as any "open in
browser" flow. diffity sets `VNC_OPEN_LINKS=1`, which makes the vnc feature
route that path to the contained Chromium (see
[Opening links on the display](../vnc#opening-links-on-the-display)), so the
agent's "open in browser" behavior works unchanged, it just lands on the
streamed display instead of a host tab. That also applies to login flows such
as `gh auth login --web`, and whatever you enter in the contained browser is
readable by the agent. Open those URLs on the host instead. Until
the first diffity view opens, the display shows the vnc feature's waiting page.
The DB and settings live in the container's `~/.diffity`, not in the mounted
code.

PR review and syncing reviews with GitHub go through `gh` in the session, so
they need `--features +github-cli` for the CLI, its credentials, and the
GitHub allowlist.

> diffity intentionally opens its own ref-specific URL rather than having the
> vnc feature auto-forward to the server root. A ref-less load (`/`) resolves
> to the working-tree ("work") session and marks it the active session, which
> would clobber the session a skill just opened and hide its comments from the
> `diffity agent` CLI (which follows the active session).

## Bumping diffity

A commit SHA is immutable, so updates are deliberate: review the new commit
**and** its `package-lock.json`, update `DIFFITY_SHA` in `install.sh` (or pass
`DIFFITY_SHA=…` as a build arg), and rebuild.

## Skills

The feature also ships diffity's slash-command skills (`diffity-diff`,
`diffity-review`, `diffity-summarize`, `diffity-resolve`, `diffity-watch`,
`diffity-tree`, `diffity-resolve-tree`, `diffity-tour`, `diffity-learn`) under
`skills/`. When the feature is enabled, these are composed into the agent's
(read-only) skills mount on the host, so they are present only for sessions
that opted into `--features +diffity`.

The skills are **vendored** from the same diffity revision as `DIFFITY_SHA`,
with enclave adaptations, since diffity serves container-locally and is
watched over VNC:

- upstream's "check your browser / here is the URL" guidance points at the
  session's VNC viewer instead
- `open <url>` becomes `xdg-open <url>`, which `VNC_OPEN_LINKS` routes to the
  contained Chromium
- the `npm install -g diffity` hint tells the user to enable the feature

When you bump `DIFFITY_SHA`, refresh the skills and re-apply those
adaptations:

```bash
# from a checkout of diffity at the new SHA:
rm -rf <this-repo>/features/diffity/skills
cp -r skills <this-repo>/features/diffity/skills
# then re-apply the adaptations (see git log for the last one)
```
