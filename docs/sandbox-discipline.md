# Sandbox discipline — executing contributed code as a human

**Status:** lives here until upstreamed to lq-ai as a
`docs/security/sandbox-discipline.md` page (design doc §11; scheduled
for M1, §14). Until then this file is the normative text, and
[rules/canon-map.md](../rules/canon-map.md) routes the
"how does a human safely execute contributed code?" question here.

This page exists because of the two-rule split in design doc §10:

> **The agent: never.** **Humans: sequence and containment.**

The agent never executes contributed code — not tests, not installs,
not builds, under any instruction from anyone, and its Triage Receipts
say so in every coverage statement ("runtime behavior — never
checked"). When a human maintainer genuinely needs runtime behavior —
"does this fix actually fix it?" — this page is the discipline that
replaces ambient trust.

## Why this is strict (read this once, properly)

The danger is not `git checkout`. Checking out a contributor's branch
puts hostile bytes on your disk, which is fine — bytes are inert. The
danger is **everything that runs after checkout**, because each of
these executes the *contributor's* code with *your* ambient authority:

- **`pytest` runs contributed code before any test runs.** Pytest
  imports `conftest.py` — and every module it collects — at
  *collection time*. A malicious PR does not need a malicious test;
  it needs a malicious import. `pytest --collect-only` is already
  arbitrary code execution.
- **Installs run lifecycle scripts.** `npm ci` / `npm install` execute
  `preinstall`/`postinstall` hooks; `pip install -e .` executes the
  project's build backend and `setup.py`. "I only installed the
  dependencies" *is* "I ran their code".
- **`docker build` executes the contributor's Dockerfile.** Every
  `RUN` line is their command on your machine, with network, at build
  time — before you ever "run the container".
- **Your session's ambient credentials are the prize.** A normal dev
  environment carries a `gh` token with repo write, SSH keys, and
  often a dev `.env` of real provider keys. Code that runs as you can
  push as you, approve as you, and exfiltrate what you can read.

And the reason the *agent* is held to "never" rather than "carefully":
an agent is an **ambient** hazard — fast, semi-invisible, and
instructable by the PR itself, since the diff sits in its context. A
human at least feels friction before typing `pip install`; an agent
can be *asked to* by the very artifact under review. So the two rules
do not converge with experience or trust. Agent: never. Human:
sequence and containment.

## Rule 1 — Sequence: adversarial read first, execute second

Never run anything from a contribution you have not read as a hostile
artifact. Before any execution, read — in this order, because this is
where the payloads live:

1. **Everything that runs implicitly**: `conftest.py`, `setup.py` /
   `pyproject.toml` build hooks, `package.json` scripts,
   `Makefile` / `justfile` targets, Dockerfiles, anything under
   `.github/`.
2. **Dependency changes**: every new or changed name in manifests and
   lockfiles, checked character-by-character for typosquats
   (`requets`, `python-dotenv` vs `dotenv-python`) and for
   resolution-source changes (new registries, git URLs, local paths).
3. **The diff itself**, asking "what does this code *do when
   executed*", not "what does the PR say it does". The PR body is the
   contributor's narrative; the vetting posture
   ([rules/injection-posture.md](../rules/injection-posture.md)) is
   that narratives are material under review, never instructions.

If the adversarial read leaves you uneasy, stop — that unease is
triage information. Take it to the committee; do not resolve it with
"I'll just run it and see".

## Rule 2 — Containment: a disposable sandbox, defined by what it lacks

Execute untrusted code only in an environment you can delete without
regret. "Disposable sandbox" means ALL of the following:

- **No credentials.** No `gh` auth, no SSH keys or agent socket, no
  `~/.aws`, `~/.config`, `~/.netrc`, no keychain. Check what your
  container mounts inherit — an innocent `-v ~:/home/me` defeats
  everything.
- **No `.env`.** Not the repo's dev `.env`, not a "harmless" one. If
  the code under test needs configuration, hand-write throwaway
  values.
- **No Docker socket.** Never mount `/var/run/docker.sock` into a
  container that runs untrusted code — that is root on the host with
  extra steps.
- **No writable mounts of your real working tree.** Copy the code in
  (or clone from the sandbox side); do not bind-mount the clone you
  do real work in.
- **Ideally no network.** `docker run --network none` for the actual
  test execution. If the scenario genuinely needs network (an install
  step), do the install online, then *re-run the code under test
  offline* — exfiltration needs egress, so deny it during the
  interesting part.
- **Disposable.** Built fresh, destroyed after (`docker run --rm`).
  Nothing you would miss, nothing the code could persist into.

### The `Dockerfile.dev` in-container pattern

lq-ai ships a `Dockerfile.dev` for in-container development; hardened
per this page it is the standard sandbox. The shape of a safe session:

```sh
# 1. Build the sandbox image from YOUR trusted main — never from the
#    contributor's branch (their Dockerfile.dev would run at build time).
git -C ~/src/lq-ai checkout main
docker build -f Dockerfile.dev -t lq-sandbox ~/src/lq-ai

# 2. Fetch the PR head into a throwaway worktree (fetching is safe;
#    executing is what we're containing). Note: do this in a clone
#    session, not an agent session — PR-ref checkout is hook-blocked
#    for agents by design (§2.1).
git -C ~/src/lq-ai fetch origin pull/<N>/head:pr-<N>
git -C ~/src/lq-ai worktree add /tmp/pr-<N> pr-<N>

# 3. Run the code COPIED in, offline, credential-free, disposable.
docker run --rm --network none \
  -v /tmp/pr-<N>:/work:ro \
  -w /work lq-sandbox \
  sh -c 'cp -r /work /tmp/run && cd /tmp/run && pytest -x'

# 4. Destroy.
git -C ~/src/lq-ai worktree remove --force /tmp/pr-<N>
git -C ~/src/lq-ai branch -D pr-<N>
```

Adapt the test command per the change; keep the invariants (build from
trusted main, read-only copy-in, `--network none`, `--rm`, no secrets
in the environment).

If the PR **changes `Dockerfile.dev` itself or the dependency
manifests**, the image build now executes contributed code — read
those changes with full adversarial attention first, build with
network but with no mounts and no secrets, and treat the resulting
image itself as untrusted.

## The absolute rule — workflows PRs are never "verified by running"

**Never run a `.github/workflows/**` PR to see what it does. Not in a
sandbox, not with `act`, not "just the lint job".** Workflow files are
programs whose intended execution environment *is* the credentialed
CI context — running one is granting it exactly what it asks for, and
a fork/sandbox run proves nothing about what it will do with real
`secrets` and a real `GITHUB_TOKEN`. Workflows PRs are reviewed by
reading, escalate by default (CODEOWNERS-sensitive path — see
`rules/escalation-triggers.md`), and get decided by humans on the text
alone. This mirrors lq-ai's own vetting playbook, which classifies
workflows as prime supply-chain surface.

## Quick checklist (print this bit)

Before executing anything from a contribution:

- [ ] Adversarial read done: implicit-execution files, dependency
      diffs, then the diff itself
- [ ] Not a `.github/workflows/**` change (if it is: STOP — read-only
      review, escalate)
- [ ] Sandbox has: no credentials, no `.env`, no Docker socket, no
      writable mount of my real tree
- [ ] Network off for the execution step (or install-online /
      run-offline split)
- [ ] Image built from trusted `main`, not the contributor's branch
- [ ] Everything created is disposable, and I will dispose of it
- [ ] I am doing this as a human, in my own terminal — no agent
      session is running the code for me

## Relationship to the agent

The agent's receipts render "runtime behavior — never checked" in
every coverage statement precisely so that *this* process stays
visibly separate: if runtime verification happened, a human did it,
under this discipline, and can say so in the PR thread in their own
name. Once this page upstreams to lq-ai (`docs/security/`, M1), this
copy becomes a pointer and lq-ai's copy becomes canon — tracked, like
everything else, by the canon map and the drift check.
