# SwiftFormat — dry-run report & integration notes (day 19)

Generated 2026-09-21 on branch `chore/swiftformat-setup`.
SwiftFormat 0.62.1, config: repo-root `.swiftformat`.

## Dry-run result (`--lint`, no files changed)

**26 of 50 files require formatting.** All rules are non-semantic except one
`redundantSelf` hit, which was inspected and is safe (see below).

Rule frequency across the project:

| count | rule | kind |
|------:|------|------|
| 49 | consecutiveSpaces | whitespace |
| 37 | docComments | `//` → `///` over declarations |
| 33 | indent | indentation |
| 12 | wrapPropertyBodies | wrapping |
|  7 | trailingCommas | commas |
|  6 | wrap | wrapping |
|  6 | redundantReturn | remove needless `return` |
|  3 | hoistPatternLet | pattern `let` |
|  2 | wrapIfStatementBodies | wrapping |
|  2 | sortImports | imports order |
|  2 | emptyBraces | `{ }` → `{}` |
|  2 | andOperator | `&&` → `,` in if/guard/while |
|  1 | spaceAroundOperators | whitespace |
|  1 | redundantSelf | **inspected — safe** |
|  1 | opaqueGenericParameters | generics sugar |
|  1 | blankLinesAtStartOfScope | blank lines |
|  1 | blankLinesAtEndOfScope | blank lines |

## The `--self remove` question (the only semantic risk)

`--self remove` is dangerous only inside `@escaping` closures, where explicit
`self` is required and signals a strong capture (retain-cycle reminder).

In this project the rule triggers **exactly once**:

`Views/Components/PhotoResource+SizeClass.swift:7`
```swift
func url(for sizeClass: UserInterfaceSizeClass?) -> URL {
    sizeClass == .regular ? self.url : self.urlMobile   // self. is redundant here
}
```

This is a plain method in an `extension` on a struct — no closure, no capture,
no escaping. Removing `self.` here changes nothing and compiles.

**Conclusion:** `--self remove` is safe to keep for this codebase. There is no
escaping-closure site where it would strip a required `self`. (The codebase is
SwiftUI / value types, so escaping-closure `self` capture essentially doesn't
occur.)

## Files-per-folder (where the changes land)

Run by folder if you want smaller reviewable commits. Suggested order — safest
first, then the rest:

1. `Models` (data types, no closures)
2. `Network`, `Utilities`, `ViewModels`
3. `Views/*` (Profile, Components, Vehicles, Trips, Settings, Points)
4. `App`

Format one folder, build in Xcode, eyeball the diff (watch `andOperator`
`&&`→`,` for readability), commit, next folder.

## Command to format a folder (run from repo root, on a machine with swiftformat)

```sh
swiftformat viadrouniki_ios_app/Models        # then build, review, commit
swiftformat viadrouniki_ios_app/Network
# ... etc, or `swiftformat viadrouniki_ios_app` for the whole tree at once
```

`--lint` first if you want to preview without writing:

```sh
swiftformat viadrouniki_ios_app --lint
```

## Run Script Build Phase (lint in CI/build, does NOT reformat)

Add a **Run Script Phase** to the app target (after Compile Sources is fine;
for lint it can be early). Uncheck "Based on dependency analysis". Script:

```sh
# SwiftFormat lint — warns, never rewrites files during a build.
if which swiftformat >/dev/null; then
  swiftformat "$SRCROOT/viadrouniki_ios_app" --lint --lenient
else
  echo "warning: SwiftFormat not installed — run `brew install swiftformat` or `mint bootstrap`"
fi
```

- `--lint` = check only, no rewriting on build (never format in a build phase).
- `--lenient` = report violations as warnings, don't fail the build. Drop
  `--lenient` later if you want lint failures to break the build.
- `if which` guard = no hard failure on a machine without the tool.

## Pin under arm64 (fixing yesterday's Mint/Rosetta failure)

Yesterday `mint bootstrap` failed: Intel Homebrew in `/usr/local` installed an
x86_64 Mint that forced an x86_64 target onto the arm64 toolchain
(`ld: symbol(s) not found for architecture x86_64`). The machine is native
arm64.

Pick one:

### Path B — native Homebrew (recommended)
Install arm64 Homebrew in `/opt/homebrew`, then Mint is native too:

```sh
# native brew lives in /opt/homebrew on Apple Silicon
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
# ensure /opt/homebrew/bin is first on PATH, then:
/opt/homebrew/bin/brew install mint
mint bootstrap        # now builds SwiftFormat 0.62.1 arm64 from Mintfile
```
Check which brew you're getting: `file $(which brew)` and `file $(which mint)`
should say arm64.

### Path C — prebuilt arm64 binary, no build
Skip Mint entirely; vendor the official arm64 binary:

```sh
# SwiftFormat 0.62.1 ships a macOS binary in swiftformat.zip
curl -L -o /tmp/sf.zip \
  https://github.com/nicklockwood/SwiftFormat/releases/download/0.62.1/swiftformat.zip
unzip -o /tmp/sf.zip -d Tools/swiftformat
# point the Run Script at Tools/swiftformat/swiftformat, or put it on PATH
```
Trade-off: no compile step, but you commit/track a binary (or fetch it in a
setup script). Keep it out of any Build Phase's file lists.

## Reminder from day 18
Config files (`.swiftformat`, `Mintfile`) must NOT be in any Build Phase — they
only need to exist in the repo. When adding files in Xcode, uncheck target
membership so they don't leak into the `.app` bundle.
