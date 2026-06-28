# Release Notes

This folder is the source of truth for the body of every GitHub Release.

## Contract

- One file per release tag: `ReleaseNotes/<tag>.md`, e.g. `ReleaseNotes/v1.7.md`.
- The file is read verbatim as the body of the GitHub Release.
- If the file is missing or empty, the release CI fails before any signing or
  notarization happens.
- Notes are public-facing and shown to anyone landing on the release page —
  write them in English.

## Conventions

A typical entry follows this skeleton:

```markdown
## What's new

- Headline change one.
- Headline change two.

## Migration notes

- Anything users must know before/after upgrading. Omit the section if not applicable.

## Internals

(Optional) Pointers to deeper docs in `Documentations/` for the curious.
```

Keep it skimmable — the first line of each bullet should be enough for a reader
who never opens the linked details.
