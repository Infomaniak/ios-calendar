# AGENTS.md

## Project Summary

Infomaniak Calendar — a production iOS Calendar client supporting iPhone, iPad, and Mac Catalyst (iOS 16.4+).

- **Language:** Swift 6
- **UI:** SwiftUI (primary) with UIKit integration
- **Build system:** Tuist (project generation + SPM dependency management)
- **Linting:** SwiftLint, SwiftFormat
- **CI/CD:** GitHub Actions + Xcode Cloud
- **Commit style:** Conventional Commits
- **Tool version manager:** Mise (https://mise.jdx.dev/)

## Local Norms

### Command Patterns

```bash
# Install mise if it's not yet installed
curl https://mise.run | sh

# Bootstrap environment (required before build/lint/test)
mise install
eval "$(mise activate bash --shims)"

# Install SPM dependencies
tuist install

# Generate Xcode project
tuist generate --no-open

# Build
tuist build

# Lint and format (run before every PR)
swiftformat .
swiftlint --config .swiftlint.yml

# Run tests
tuist test # Or via Xcode Test Navigator
```

### Code Style

- **Naming:** Swift standard — `camelCase` for variables/functions, `PascalCase` for types.
- **SwiftUI property wrappers must be private:** `@State`, `@StateObject`, `@ModalState`, `@Environment`, `@EnvironmentObject` — enforced by custom SwiftLint rules.
- **Design System tokens — never use raw values:**
  - Spacing: `IKPadding.micro`, `.small`, `.medium`, etc. — not literal numbers.
  - Radii: `IKRadius.small`, `.medium`, `.large` — not literal numbers.
  - Icon sizes: `IKIconSize` constants.
  - Example: `.padding(value: .medium)` not `.padding(16)`.
- **Localized strings:** Always use `CalendarResourcesStrings.Localizable.<key>`, never raw string literals.
- **DI:** Use `@LazyInjectService` or `@InjectService` for dependency injection; register via target assembly classes.
- **Concurrency:** Use `async/await` and structured concurrency. `RefreshActor` for background sync.
- **Formatting:** SwiftFormat excludes `DerivedData`, `Derived`, `Tuist`, `Project.swift`.


### PR Checklist

- Run `scripts/lint.sh` — no lint errors.
- Use Conventional Commits for commit messages.
- Use Design System tokens (IKPadding, IKRadius, IKIconSize) — no raw numeric values.
- Localize all user-facing strings.
- Never use `ci_scripts/` locally.

When writing code, always check that it compiles correctly with:
`tuist build`

Always format code with `swiftformat .` and lint with `swiftlint --config .swiftlint.yml`.

If files are missing from workspace, always use `tuist generate --no-open` to regenerate the Xcode project.
When adding dependencies, add them to `Project.swift and Package.swift` and run `tuist install` to fetch them.

### Learned Preferences

## Self-correction

> This section is for you, the future agent.
>
> 1. **New Norms:** If the user corrects you (e.g., "Don't use X, use Y"), add that rule to the "Local norms" section immediately so you don't make the mistake again.
> 2. **Refinement:** If you find this file is too verbose, prune it. Keep it high-signal.
