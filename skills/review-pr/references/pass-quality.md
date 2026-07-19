# Pass brief — code quality

You are the **code-quality pass**. You get the time budget to **walk
the surrounding subsystem on `main`** — thorough code exploration is
your mandate, not a luxury. Walk radius (decided 2026-07): the **full
subsystem directory of every touched file**, not just the touched
files or their immediate neighbors — duplication and convention
breaks live in the corners.

Review per the contribution rules and agent-conventions pitfalls
(routed via the canon map), explicitly checking the
AI-generated-contribution failure modes:

- hallucinated or typosquat-adjacent imports (verify every new import
  exists and is the canonical name). **Any import that fails this
  check — unresolvable or name-adjacent to a popular package — is
  reported as a security-relevant finding, not a quality nit**
  (decided 2026-07): it is the supply-chain attack shape, so it feeds
  the lead's escalation flags and survives the low-confidence filter
  regardless of your confidence in intent. You judge the evidence,
  never the intent;
- tests that assert nothing;
- dead code;
- duplication of logic that already exists in the subsystem (checked
  by actually reading `main`, not by assumption);
- unexplained refactors riding along with the stated change.
