"""lq-maintainer-agent -- skills/triage/scripts/uat-shoot.py

The UAT camera (rules/uat.md UA-07.4). Runs INSIDE the pinned Playwright
container that uat-run.sh starts on the sandbox's internal network; it is
never run on the maintainer's host. It is trusted code shipped with the
plugin and mounted read-only; everything it looks at is contributed code
running in the sandbox, and everything it records is contribution output
(UA-08) -- it records pixels and status codes, never page text.

Inputs (environment, set by uat-run.sh):
  UAT_BASE        http://<web-service>:<port>  (same-origin for every visit)
  UAT_PLAN        /plan/plan.json  (validated by uat-run.sh; re-validated here)
  UAT_OUT         /out             (the only writable mount)
  UAT_LOGIN       login route, or empty for no sign-in
  UAT_EMAIL / UAT_PASSWORD   throwaway admin credentials minted for this run

Output: one PNG per (expectation, viewport, scheme) and /out/manifest.json.
Exit 0 even when screens fail to render: a screen that did not render is a
`not-reached` observation (UA-09), not a runner error.
"""

import json
import os
import re
import sys

from playwright.sync_api import sync_playwright

ROUTE = re.compile(r"^/[A-Za-z0-9/_\-.~%+=&?]*$")
VIEWPORTS = {"desktop": (1440, 900), "phone": (390, 844)}
SCHEMES = ("light", "dark")


def safe_route(route):
    return isinstance(route, str) and bool(ROUTE.match(route)) and "//" not in route \
        and ".." not in route


def sign_in(page, base, login, email, password):
    page.goto(base + login, wait_until="networkidle", timeout=60000)
    page.fill("input[type=email], input[name=email]", email, timeout=15000)
    page.fill("input[type=password]", password, timeout=15000)
    page.press("input[type=password]", "Enter")
    page.wait_for_load_state("networkidle", timeout=60000)
    return login not in page.url


def main():
    base = os.environ["UAT_BASE"].rstrip("/")
    out = os.environ.get("UAT_OUT", "/out")
    plan = json.load(open(os.environ.get("UAT_PLAN", "/plan/plan.json")))
    login = os.environ.get("UAT_LOGIN", "")
    shots, signed_in = [], None

    with sync_playwright() as pw:
        browser = pw.chromium.launch()
        context = browser.new_context()
        page = context.new_page()
        if login and safe_route(login):
            try:
                signed_in = sign_in(page, base, login, os.environ.get("UAT_EMAIL", ""),
                                    os.environ.get("UAT_PASSWORD", ""))
            except Exception as exc:  # noqa: BLE001 -- recorded, not raised
                signed_in = False
                shots.append({"id": "sign-in", "status": "not-reached",
                              "reason": type(exc).__name__})
        for exp in plan.get("expectations", []):
            eid, route = str(exp.get("id", "")), exp.get("route")
            if not re.match(r"^[A-Za-z0-9_-]{1,32}$", eid) or not safe_route(route):
                shots.append({"id": eid[:32], "status": "refused", "reason": "invalid id or route"})
                continue
            for vp in exp.get("viewports") or list(VIEWPORTS):
                if vp not in VIEWPORTS:
                    continue
                for scheme in exp.get("schemes") or list(SCHEMES):
                    if scheme not in SCHEMES:
                        continue
                    w, h = VIEWPORTS[vp]
                    name = "%s-%s-%s.png" % (eid, vp, scheme)
                    rec = {"id": eid, "route": route, "viewport": vp, "scheme": scheme,
                           "file": name}
                    try:
                        page.set_viewport_size({"width": w, "height": h})
                        page.emulate_media(color_scheme=scheme)
                        resp = page.goto(base + route, wait_until="networkidle", timeout=60000)
                        rec["http"] = resp.status if resp else None
                        # Same-origin only: a redirect off the sandbox is not followed up.
                        rec["same_origin"] = page.url.startswith(base + "/")
                        page.screenshot(path=os.path.join(out, name), full_page=True)
                        rec["status"] = "captured" if rec["same_origin"] and \
                            (rec["http"] or 0) < 400 else "not-reached"
                    except Exception as exc:  # noqa: BLE001 -- recorded, not raised
                        rec["status"] = "not-reached"
                        rec["reason"] = type(exc).__name__
                    shots.append(rec)
        browser.close()

    json.dump({"signed_in": signed_in, "shots": shots},
              open(os.path.join(out, "manifest.json"), "w"), indent=2)
    return 0


if __name__ == "__main__":
    sys.exit(main())
