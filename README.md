# Enclave Extensions

Fork of [eclipse-enclave/enclave-extensions](https://github.com/eclipse-enclave/enclave-extensions)
carrying feature extensions for [Eclipse Enclave](https://github.com/eclipse-enclave/enclave),
the Docker sandbox for agentic coding tools.

The bundled tools from upstream are not kept here. Install those from upstream.

## Install

Enclave installs extensions straight from a git repository.

```bash
enclave features add sdirix/enclave-extensions --name diffity
enclave --features +diffity …
```

Before writing anything, `add` prints what the extension can do: root install
steps, install and startup scripts, network changes, declared credentials,
files seeded into your project, host commands. Read that summary. An extension
is code that runs at container build and start time, and a host command runs
outside the sandbox with your own privileges. Proceed at your own risk, this
fork is not signed and is not reviewed or tested by the Eclipse Enclave core
team.

Afterwards:

```bash
enclave features list                  # built-in and installed, with provenance
enclave features update <name>         # refresh from the recorded source
enclave features remove <name>
```

If `enclave features --help` has no `add` subcommand, your Enclave predates the
installer. Update from the
[rolling release](https://github.com/eclipse-enclave/enclave/releases/tag/rolling).

Alternatively, you can skip the installer entirely: clone this repository and
copy the `features/<name>/` directories you want into
`~/.config/enclave/extensions/features/`. This gets you the same extensions
without provenance tracking or update checks. See Enclave's [extension
docs](https://github.com/eclipse-enclave/enclave/tree/main/docs/extensions)
for more information.

## What is in here

| Feature | Status | What it is |
|---------|--------|------------|
| [diffity](features/diffity) | Experimental | [diffity](https://github.com/sdirix/diffity) agent-driven diff review UI, built from a pinned commit in the image |
| [vnc](features/vnc) | Experimental | Contained GUI: a virtual X display with a fullscreened Chromium, served over VNC, plus an `enclave vnc-viewer` host command |

Experimental means what it says: each one pins a fast-moving upstream, gets
thinner testing than a built-in feature, and has rough edges written down in
its own README. Read that README before the first session, the security notes
above all.

diffity serves on container-local loopback only, so watching its UI needs vnc
alongside it.

`vnc` is carried here only until it lands in upstream enclave-extensions
([the pending contribution](https://github.com/eclipse-enclave/enclave-extensions)).
Install it from upstream once it is there.

## Questions & Support

Got a question, an idea, or ran into trouble? Head over to
[Enclave's discussions](https://github.com/eclipse-enclave/enclave/discussions)
and start a thread. It's the best place for support, feature requests, and
just chatting about what you're building.

## License

MIT. See [LICENSE](LICENSE).
