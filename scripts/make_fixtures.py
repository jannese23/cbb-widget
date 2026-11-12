"""Trim captured ESPN scoreboards to the games that matter and derive the hand-made live fixture.

Run from the repo root after re-capturing the raw scoreboards:
    python3 -I scripts/make_fixtures.py Tests/CBBCoreTests/Fixtures
"""
import copy
import json
import pathlib
import sys

fixtures = pathlib.Path(sys.argv[1])


def ranked_or_uconn(event):
    comps = event["competitions"][0]["competitors"]
    return any(c.get("curatedRank", {}).get("current", 99) <= 25 or c["team"]["id"] == "41" for c in comps)


def trim(name):
    path = fixtures / f"{name}.json"
    data = json.loads(path.read_text())
    keep = [e for e in data["events"] if ranked_or_uconn(e)]
    # keep one unranked-vs-unranked game so tests see that shape too
    keep += [e for e in data["events"] if not ranked_or_uconn(e)][:1]
    data = {"events": keep}
    path.write_text(json.dumps(data))
    return data


tue = trim("men_scoreboard_20261110")
trim("men_scoreboard_20261113")


def find(events, a, b):
    for e in events:
        ids = {c["team"]["id"] for c in e["competitions"][0]["competitors"]}
        if {a, b} <= ids:
            return copy.deepcopy(e)
    raise SystemExit(f"no game {a} vs {b}")


live = find(tue["events"], "150", "127")            # Duke vs Michigan State
comp = live["competitions"][0]
for status in (comp["status"], live["status"]):
    status.update({"period": 2, "displayClock": "4:20"})
    status["type"].update({"name": "STATUS_IN_PROGRESS", "state": "in", "completed": False,
                           "description": "In Progress", "detail": "4:20 - 2nd Half", "shortDetail": "2nd 4:20"})
for c in comp["competitors"]:
    c["score"] = "55" if c["team"]["id"] == "150" else "61"
    c.pop("winner", None)

postponed = find(tue["events"], "2305", "96")       # Kansas at Kentucky
postponed["id"] = "900000001"
pcomp = postponed["competitions"][0]
for status in (pcomp["status"], postponed["status"]):
    status["type"].update({"name": "STATUS_POSTPONED", "state": "post", "completed": False,
                           "description": "Postponed", "detail": "Postponed", "shortDetail": "Postponed"})
for c in pcomp["competitors"]:
    c.pop("score", None)
    c.pop("winner", None)

odd = find(tue["events"], "12", "2464")             # Arizona vs Northern Arizona
odd["id"] = "900000002"
ocomp = odd["competitions"][0]
ocomp.pop("venue", None)
away = next(c for c in ocomp["competitors"] if c["homeAway"] == "away")
away.pop("curatedRank", None)
away.pop("score", None)

(fixtures / "men_scoreboard_live.json").write_text(json.dumps({"events": [live, postponed, odd]}))
print("ok")
