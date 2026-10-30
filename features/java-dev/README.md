# java-dev

OpenJDK and Gradle, with Gradle's caches persisted per project. Opt-in
(disabled by default).

**Priority**: 70

```bash
enclave features add sdirix/enclave-extensions --name java-dev
enclave --features +java-dev
```

## Installation

| Component | Source | Provides |
|-----------|--------|----------|
| `default-jdk-headless` | apt | `java`, `javac`, `jar`, `jshell`, `keytool`. Java 21 on Enclave's Debian trixie base |
| Gradle `9.8.2` | `install.sh` | `gradle` in `~/.local/bin` |

`install.sh` downloads the Gradle binary distribution from
[gradle/gradle-distributions](https://github.com/gradle/gradle-distributions/releases)
and verifies it against a pinned SHA-256. Bump `GRADLE_VERSION` and
`GRADLE_SHA256` together. Gradle publishes the checksum at
`https://services.gradle.org/distributions/gradle-<version>-bin.zip.sha256`.

Use `./gradlew` in projects that have a wrapper. It runs the Gradle version the
project pins. The installed `gradle` covers projects without one, plus
`gradle init` and `gradle wrapper`.

`JAVA_HOME` is `/usr/lib/jvm/default-java`, the arch-independent symlink
`default-jre-headless` ships. It is container environment, so `docker exec`
processes see it too. The build fails if the symlink is missing.

## Network

| Domain | Used by |
|--------|---------|
| `gradle.org` and subdomains | Wrapper distributions, the plugin portal, and their download hosts |
| `repo.maven.apache.org`, `repo1.maven.org` | `mavenCentral()` |
| `api.foojay.io` | Toolchain resolution by `org.gradle.toolchains.foojay-resolver-convention` |

Toolchain JDKs download from the vendor's host. Temurin's come from GitHub,
which Enclave's base allowlist covers. Other vendors, `google()`
(`maven.google.com`, `dl.google.com`), and private repositories need
`--allow-domain` or `allow_domains` in config.

## Credentials

None declared. Repository credentials in `~/.gradle/gradle.properties` or
`ORG_GRADLE_PROJECT_*` variables are plain values the agent can read. The
gateway does not inject them.

## Persistence

Per project and tool, under `~/.cache/enclave/<tool>/<project-hash>/` on the
host:

| Cache | Container path | Contents |
|-------|----------------|----------|
| `gradle-caches` | `~/.gradle/caches` | Dependencies, plugins, transforms, local build cache |
| `gradle-wrapper` | `~/.gradle/wrapper` | Distributions downloaded by `./gradlew` |
| `gradle-jdks` | `~/.gradle/jdks` | Provisioned toolchain JDKs |

The rest of `~/.gradle`, including `gradle.properties` and `init.d/`, starts
fresh each session. `--no-cache` disables the caches. `enclave cleanup`
removes them unless `--keep cache` is set.

## Limitations

- Java ignores `SSL_CERT_FILE` and does not trust the gateway CA. Where the
  gateway terminates TLS, with `--network-log=requests` or for a host it
  injects a credential into, Gradle fails with `PKIX path building failed`.
  The default `coarse` mode works.
- Concurrent sessions of the same project and tool share the caches. Gradle
  asks the owner of a cache lock to release it over loopback, which does not
  cross containers, so a build can wait on the other session's idle daemon
  and time out. Run `./gradlew --stop` in the other session.
- Gradle 9 needs Java 17 or newer. On a custom base image whose
  `default-jdk-headless` is older, `gradle` does not start.
