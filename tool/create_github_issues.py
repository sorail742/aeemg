#!/usr/bin/env python3
"""Crée les issues GitHub à partir des tickets de docs/tickets/*.md.

Chaque ticket commence par « ### ID — Titre » et doit contenir une ligne
« **Type** : … · **Priorité** : P? · … · **Composant** : … ».

Usage :
    python3 tool/create_github_issues.py --dry-run          # aperçu
    python3 tool/create_github_issues.py --only SEC,REL     # sous-ensemble
    python3 tool/create_github_issues.py                     # création (gh auth login requis)

Idempotent : un ticket dont l'ID figure déjà dans le titre d'une issue existante
n'est pas recréé.
"""
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TICKETS_DIR = ROOT / "docs" / "tickets"
HEADER = re.compile(r"^### ((SEC|REL|DEL|AMEL|FEAT|OPS)-\d{3}) — (.+)$")
META = re.compile(r"\*\*(Type|Priorité|Estimation|Composant)\*\* : ([^·\n]+)")

TYPE_LABELS = {
    "SEC": "type:securite",
    "REL": "type:fiabilite",
    "DEL": "type:suppression",
    "AMEL": "type:amelioration",
    "FEAT": "type:fonctionnalite",
    "OPS": "type:devops",
}
LABEL_COLORS = {
    "type:securite": "b60205", "type:fiabilite": "d93f0b", "type:suppression": "cccccc",
    "type:amelioration": "0e8a16", "type:fonctionnalite": "1d76db", "type:devops": "5319e7",
    "P0": "b60205", "P1": "d93f0b", "P2": "fbca04", "P3": "c2e0c6",
}
COMPONENT_LABELS = {
    "flutter": "comp:flutter", "supabase": "comp:supabase-db", "edge-functions": "comp:edge-functions",
    "ci": "comp:ci", "docs": "comp:docs", "android": "comp:android", "ios": "comp:ios",
    "web": "comp:web", "github": "comp:ci", "outillage": "comp:ci",
}


def parse_tickets() -> list[dict]:
    tickets = []
    for path in sorted(TICKETS_DIR.glob("0*.md")):
        lines = path.read_text(encoding="utf-8").splitlines()
        current = None
        for line in lines:
            m = HEADER.match(line)
            if m or line.startswith("## ") or line.strip() == "---":
                if current:
                    tickets.append(current)
                current = None
            if m:
                current = {"id": m.group(1), "prefix": m.group(2), "title": m.group(3).strip(),
                           "file": path.name, "body": []}
                continue
            if current is not None:
                current["body"].append(line)
        if current:
            tickets.append(current)

    result = []
    for t in tickets:
        body = "\n".join(t["body"]).strip()
        meta = {k: v.strip() for k, v in META.findall(body)}
        if "Type" not in meta:  # simple renvoi vers un autre ticket
            continue
        if "**Statut** : ✅ Livré" in body:  # déjà traité
            continue
        labels = [TYPE_LABELS[t["prefix"]]]
        prio = re.match(r"P[0-3]", meta.get("Priorité", ""))
        if prio:
            labels.append(prio.group(0))
        for key, label in COMPONENT_LABELS.items():
            if key in meta.get("Composant", "") and label not in labels:
                labels.append(label)
        footer = (f"\n\n---\nSource : `docs/tickets/{t['file']}` — règles globales : "
                  "[Definition of Done](../blob/main/docs/tickets/README.md#definition-of-done-dod-globale)")
        result.append({"id": t["id"], "title": f"{t['id']} — {t['title']}",
                       "body": body + footer, "labels": labels})
    return result


def gh(*args: str, input_text: str | None = None) -> str:
    proc = subprocess.run(["gh", *args], input=input_text, capture_output=True, text=True)
    if proc.returncode != 0:
        raise RuntimeError(proc.stderr.strip())
    return proc.stdout


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--dry-run", action="store_true", help="affiche sans créer")
    parser.add_argument("--only", help="préfixes ou IDs séparés par des virgules (ex. SEC,REL-001)")
    parser.add_argument("--repo", help="owner/repo (défaut : dépôt courant)")
    args = parser.parse_args()

    tickets = parse_tickets()
    if args.only:
        wanted = [w.strip() for w in args.only.split(",") if w.strip()]
        tickets = [t for t in tickets if any(t["id"] == w or t["id"].startswith(w + "-") for w in wanted)]

    if args.dry_run:
        for t in tickets:
            print(f"{t['title']}  [{', '.join(t['labels'])}]")
        print(f"\n{len(tickets)} ticket(s).")
        return 0

    repo_args = ["--repo", args.repo] if args.repo else []
    existing = json.loads(gh("issue", "list", *repo_args, "--state", "all", "--limit", "1000",
                             "--json", "title"))
    existing_ids = {m.group(0) for i in existing
                    for m in [re.match(r"(SEC|REL|DEL|AMEL|FEAT|OPS)-\d{3}", i["title"])] if m}

    for label in sorted({lbl for t in tickets for lbl in t["labels"]}):
        try:
            gh("label", "create", label, *repo_args, "--color", LABEL_COLORS.get(label, "ededed"), "--force")
        except RuntimeError as exc:
            print(f"label {label}: {exc}", file=sys.stderr)

    created = 0
    for t in tickets:
        if t["id"] in existing_ids:
            print(f"= {t['id']} existe déjà")
            continue
        label_args = [a for lbl in t["labels"] for a in ("--label", lbl)]
        url = gh("issue", "create", *repo_args, "--title", t["title"], "--body-file", "-", *label_args,
                 input_text=t["body"]).strip()
        print(f"+ {t['id']} {url}")
        created += 1
    print(f"\n{created} issue(s) créée(s).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
