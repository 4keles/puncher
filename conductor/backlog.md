# Backlog

Findings accepted but deliberately not fixed inside the track that raised
them. Each row says what it is, where it came from, and what closing it looks
like. Reconciled at the start and the close of every track.

Nothing here is a reminder to be tidy. A row exists because someone decided
the work was real and the timing was wrong.

| # | Raised by | Finding | Closing it looks like |
| --- | --- | --- | --- |
| 1 | Security review, track 1 | The formatter binary is downloaded in the automated checks and installed without its contents being verified. The version is pinned, so it cannot silently move, but if that release were ever replaced the checks would run whatever arrived. The damage today is bounded: the run has read-only rights and holds no secrets. | The download is checked against a published hash for that exact release before it is installed, and the check fails rather than continuing if it does not match. |
| 2 | Security review, track 1 | The checkout step is pinned by tag rather than by commit. A tag can be moved by the account that owns it, which changes what runs without this repository's history changing. | Pinned to a commit, with the version it corresponds to written beside it. |
| 3 | Security review, track 1 | Frame count and distance flow into the sampler and the adapter unbounded. Not reachable today - the only caller is a fixed preset - but the first dialog that exposes these numbers makes a large value able to allocate frames until the editor stalls. | The track that introduces a parameter dialog bounds these inputs before they reach the core, with the limits stated in the preset documentation rather than buried at the call site. |
