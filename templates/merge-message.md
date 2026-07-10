<!--
TEMPLATE: merge-message.md — drafted squash-merge message with the §8.5
audit trailer.

Fill conventions (remove this comment block from rendered output):
- {{placeholders}} filled at render time.
- The agent ONLY DRAFTS this message. The human maintainer owns it,
  edits it, performs the merge, and is the one whose Signed-off-by
  appears — the agent never merges (§2.1, §10). Drafting the full
  message including the sign-off line is deliberate: it smooths the
  GitHub-web-UI merge path, where adding trailers by hand is
  irritating.
- The trailer block is the ENTIRE committed audit surface (§8.5): no
  receipt files, no ledger. It must be the final lines of the commit
  body, formatted exactly as below (standard git trailer syntax) so
  `git log --grep` queries work.
- <maintainer> is the human who reviewed the human-only judgments and
  performs the merge — filled with their name/handle, never the
  agent's.
- Trailers cover merged work only; rejected items keep their record in
  receipt comments and committee packets.
-->

{{subject line: conventional, <=72 chars, describing the change — e.g.
"fix(parser): handle empty citation blocks (#123)"}}

{{body: one short paragraph on what changed and why, anchored to canon —
e.g. "Implements DE-041's citation-block handling. Regression test
added per CONTRIBUTING. Salvaged from a broader PR; remaining parts
tracked in #124 and #125."}}

{{optional: "Co-authored-by:" lines preserving contributor credit on a
squash, one per contributor}}

Triage: {{lane}} lane; receipt at {{receipt-comment-url}}
Reviewed-At: pr-head {{pr_head_sha}} / canon {{canon_sha}} / agent {{agent_version}}
Disposition: {{e.g. "3 findings resolved; human-only items reviewed by {{maintainer}}"}}
Signed-off-by: {{maintainer name}} <{{maintainer email}}>
