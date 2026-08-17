---
name: harmony-release-testing
description: Release-focused testing workflow for the money-tracker-harmony HarmonyOS/ArkTS bookkeeping app. Use when the user asks to test, check bugs, verify release readiness, validate decimal amount inputs, audit app store review risks, or run automated checks before publishing this HarmonyOS project.
---

# Harmony Release Testing

## Overview

Use this skill to test the HarmonyOS bookkeeping app before release. Prioritize practical blockers: build-breaking ArkTS issues, decimal amount input regressions, app-store-sensitive pages or text, route registration mistakes, file export problems, and dirty git state.

## Quick Start

From the repository root, run:

```powershell
powershell -ExecutionPolicy Bypass -File .codex\skills\harmony-release-testing\scripts\run_release_tests.ps1
```

Always report:

- Whether the workspace is clean.
- Whether `tools\release-check.ps1` passed.
- Whether `hvigor`, `ohpm`, or `hdc` are available locally.
- Any concrete bug found and the file(s) changed.
- Whether the user still needs DevEco Studio for build/install testing.

## Workflow

1. Run `git status --short`.
2. Run the skill script above.
3. If the script finds a concrete fixable bug, patch it, rerun the script, then commit.
4. If the script cannot run a true Harmony build because `hvigor`, `ohpm`, or `hdc` are missing, say so clearly and ask the user to run DevEco Studio build/install.
5. Do not add privacy pages, notification/SMS/OCR/auto-recognition release features, or new sensitive permissions while testing.

## Manual Checks To Mention

When command-line build tools are unavailable, ask the user to verify these on device:

- Record edit amount accepts decimal input and saves at most two decimal places.
- Account management current balance and initial balance accept decimal input.
- Budget total and category budget inputs accept decimal input.
- Data export saves CSV for month, recent 1000 records, and custom date range.
- Search exports the currently filtered result list to CSV.
- Calendar can add a record for the selected date and refresh normally.
