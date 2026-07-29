---
name: haruhancut-app-store-release
description: Prepare a Haruhancut App Store release from merged GitHub PR history. Use when asked to prepare an App Store submission, write or refresh release notes, or update Fastlane App Store metadata from PRs. Update `fastlane/metadata/ko/release_notes.txt`, `fastlane/metadata/ja/release_notes.txt`, `fastlane/metadata/en-US/release_notes.txt`, and `fastlane/metadata/review_information/notes.txt` while preserving the existing localized format.
---

# Haruhancut App Store Release

Prepare customer-facing App Store metadata from the release's PRs. Treat Korean release notes as the canonical source, then produce equivalent Japanese and US English notes.

## Establish the release scope

1. Work from the repository root. Start with `git branch --show-current` and `git status --short`; preserve unrelated local changes.
2. Use the PR or commit range supplied by the user. If no range is supplied, identify the last published release tag or GitHub release and compare it with the intended release commit or branch. If that boundary remains ambiguous, ask the user before editing metadata.
3. Collect each merged PR's number, title, body, labels, merged time, changed files, and commits. Prefer GitHub CLI data when available; otherwise inspect merge commits and diffs locally. The repository's `.github/release-drafter.yml` provides useful label categories, but labels alone do not establish user-visible behavior.
4. Read the relevant PR diffs before drafting. Include only features, user-visible UI/UX improvements, and direct bug fixes. Omit refactors, dependencies, CI, tests, admin-only changes, and implementation details unless the diff shows a customer-facing effect.
5. Before writing files, briefly state the proposed PR range plus the included and omitted changes. Do not invent a change from a PR title.

If the metadata directory is absent or the user asks to refresh it, run `bundle exec fastlane deliver download_metadata` before inspecting it. This directory is gitignored in this repository, so do not rely on `git diff` or `git status` to show its edits.

## Write localized release notes

Inspect the current files first; their layout is the source of truth. Update all three files in the same change:

| Locale | File |
| --- | --- |
| Korean | `fastlane/metadata/ko/release_notes.txt` |
| Japanese | `fastlane/metadata/ja/release_notes.txt` |
| US English | `fastlane/metadata/en-US/release_notes.txt` |

Use this format in every locale: a single `■` category heading followed by concise `- ` bullets. Keep one to four meaningful bullets. Select a category that matches the release, such as new features, feature improvements, bug fixes, or update information. Preserve the current app's concise, polished tone.

- Draft Korean first in natural customer-facing Korean, such as `- 가족 구성원의 생일을 등록하고 확인할 수 있는 기능 추가`.
- Translate the finalized Korean meaning—not its wording—into natural Japanese and US English. Use polite Japanese (`追加しました`, `改善しました`) and past-tense English (`Added`, `Improved`, `Fixed`).
- Do not mention PR numbers, branches, internal modules, data models, services, build systems, or unverified claims.
- Do not add generic stability or performance claims unless the PR evidence supports them.

## Update App Review notes

Update `fastlane/metadata/review_information/notes.txt` in the existing bilingual structure.

1. Preserve `[로그인 안내]` and `[Login Instructions]` verbatim unless the authentication flow, review credentials, or support contact has changed. Never invent test credentials; ask for the missing review information when needed.
2. Replace only the release-specific bullets under `[업데이트 내용 안내]` with the finalized Korean changes.
3. Make `[Update Information]` an accurate, natural English equivalent of those Korean bullets.
4. Preserve the headings, greeting and sign-off style, and the Haruhancut team name unless the user asks to change them.

## Validate and report

1. Ensure every file is UTF-8, non-empty, and ends with a newline.
2. Run:

   ```bash
   python3 .agents/skills/haruhancut-app-store-release/scripts/validate_metadata.py \
     --metadata-root fastlane/metadata
   ```

3. Re-read all four files and confirm the Korean bullets in `notes.txt` match the Korean release-note bullets.
4. Report the PR range used, the user-visible changes included, the files updated, and the validation result. Explicitly mention that Fastlane metadata is ignored by Git in this repository.
