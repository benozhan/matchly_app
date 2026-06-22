"""
Match Search API — KuponBot VPS companion
==========================================
Runs independently alongside the Telegram bot process.

Deploy:
  pip install fastapi uvicorn
  uvicorn api_server:app --host 0.0.0.0 --port 8001 &

Or via systemd — see matchly-api.service in this directory.

Environment variables:
  KUPONBOT_DB   Path to SQLite database (default: matches.db)
  API_PORT      Port to listen on     (default: 8001)
"""

from __future__ import annotations

import os
import sqlite3
from functools import lru_cache
from typing import Optional

from fastapi import FastAPI, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from social_router import router as social_router

# ── Config ────────────────────────────────────────────────────────────────────

DB_PATH = os.environ.get("KUPONBOT_DB", "matches.db")

# ── Turkish alias map ─────────────────────────────────────────────────────────
# Each key (lowercase, normalized) maps to all DB-searchable variants.

ALIASES: dict[str, list[str]] = {
    # ── National teams (TR → EN + variants) ──────────────────────────────────
    "türkiye":                    ["turkey", "türkiye", "turkiye"],
    "turkiye":                    ["turkey", "türkiye", "turkiye"],
    "turkey":                     ["turkey", "türkiye", "turkiye"],
    "united states":              ["united states", "usa"],
    "usa":                        ["united states", "usa"],
    "amerika":                    ["united states", "usa"],
    "abd":                        ["united states", "usa"],
    "amerika birleşik devletleri":["united states", "usa"],
    "amerika birlesiK devletleri":["united states", "usa", "us"],
    "amerika":                    ["united states", "usa", "us"],
    "abd":                        ["united states", "usa", "us"],
    "united states":              ["united states", "usa", "us"],
    "usa":                        ["united states", "usa", "us"],
    "ingiltere":                  ["england", "ingiltere"],
    "İngiltere":                  ["england", "ingiltere"],
    "england":                    ["england"],
    "almanya":                    ["germany", "deutschland", "almanya"],
    "germany":                    ["germany", "deutschland"],
    "fransa":                     ["france", "fransa"],
    "france":                     ["france"],
    "ispanya":                    ["spain", "españa", "espana", "ispanya"],
    "spain":                      ["spain", "españa", "espana"],
    "italya":                     ["italy", "italia", "italya"],
    "italy":                      ["italy", "italia"],
    "hollanda":                   ["netherlands", "holland", "hollanda"],
    "netherlands":                ["netherlands", "holland"],
    "belçika":                    ["belgium", "belçika", "belcika"],
    "belcika":                    ["belgium", "belçika", "belcika"],
    "belgium":                    ["belgium"],
    "portekiz":                   ["portugal", "portekiz"],
    "portugal":                   ["portugal"],
    "brezilya":                   ["brazil", "brasil", "brezilya"],
    "brazil":                     ["brazil", "brasil"],
    "arjantin":                   ["argentina", "arjantin"],
    "argentina":                  ["argentina"],
    "avustralya":                 ["australia", "avustralya"],
    "australia":                  ["australia"],
    "kanada":                     ["canada", "kanada"],
    "canada":                     ["canada"],
    "isviçre":                    ["switzerland", "isviçre", "isvicre"],
    "isvicre":                    ["switzerland", "isviçre", "isvicre"],
    "switzerland":                ["switzerland"],
    "norveç":                     ["norway", "norveç", "norvec"],
    "norvec":                     ["norway", "norveç", "norvec"],
    "norway":                     ["norway"],
    "isveç":                      ["sweden", "isveç", "isvec"],
    "isvec":                      ["sweden", "isveç", "isvec"],
    "sweden":                     ["sweden"],
    "japonya":                    ["japan", "japonya"],
    "japan":                      ["japan"],
    "güney kore":                 ["south korea", "güney kore", "guney kore"],
    "guney kore":                 ["south korea", "güney kore", "guney kore"],
    "kore":                       ["korea", "south korea"],
    "south korea":                ["south korea"],
    "meksika":                    ["mexico", "meksika"],
    "mexico":                     ["mexico"],
    "fas":                        ["morocco", "fas"],
    "morocco":                    ["morocco"],
    "iskoçya":                    ["scotland", "iskoçya", "iskocya"],
    "iskocya":                    ["scotland", "iskoçya", "iskocya"],
    "scotland":                   ["scotland"],
    "uruguay":                    ["uruguay"],
    "kolombiya":                  ["colombia", "kolombiya"],
    "colombia":                   ["colombia"],
    "hırvatistan":                ["croatia", "hrvatska", "hırvatistan", "hirvatistan"],
    "hirvatistan":                ["croatia", "hrvatska", "hırvatistan", "hirvatistan"],
    "croatia":                    ["croatia", "hrvatska"],
    "gana":                       ["ghana", "gana"],
    "ghana":                      ["ghana"],
    "panama":                     ["panama"],
    "avusturya":                  ["austria", "avusturya"],
    "austria":                    ["austria"],
    "cezayir":                    ["algeria", "cezayir"],
    "algeria":                    ["algeria"],
    "ürdün":                      ["jordan", "ürdün", "urdun"],
    "urdun":                      ["jordan", "ürdün", "urdun"],
    "jordan":                     ["jordan"],
    "ırak":                       ["iraq", "ırak", "irak"],
    "irak":                       ["iraq", "ırak", "irak"],
    "iraq":                       ["iraq"],
    "senegal":                    ["senegal"],
    "tunus":                      ["tunisia", "tunus"],
    "tunisia":                    ["tunisia"],
    "mısır":                      ["egypt", "mısır", "misir"],
    "misir":                      ["egypt", "mısır", "misir"],
    "egypt":                      ["egypt"],
    "iran":                       ["iran"],
    "yeni zelanda":               ["new zealand", "yeni zelanda"],
    "new zealand":                ["new zealand"],
    "katar":                      ["qatar", "katar"],
    "qatar":                      ["qatar"],
    "suudi arabistan":            ["saudi arabia", "suudi arabistan"],
    "saudi arabia":               ["saudi arabia"],
    "çekya":                      ["czechia", "czech", "çekya", "cekya"],
    "cekya":                      ["czechia", "czech", "çekya", "cekya"],
    "czechia":                    ["czechia", "czech"],
    "güney afrika":               ["south africa", "güney afrika", "guney afrika"],
    "guney afrika":               ["south africa", "güney afrika", "guney afrika"],
    "south africa":               ["south africa"],
    "bosna hersek":               ["bosnia", "bosnia-herzegovina", "bosnia and herzegovina"],
    "bosna-hersek":               ["bosnia", "bosnia-herzegovina", "bosnia and herzegovina"],
    "bosnia-herzegovina":         ["bosnia", "bosnia-herzegovina", "bosnia and herzegovina"],
    "fildişi sahili":             ["ivory coast", "côte d'ivoire", "cote d'ivoire"],
    "fildisi sahili":             ["ivory coast", "côte d'ivoire", "cote d'ivoire"],
    "ivory coast":                ["ivory coast", "côte d'ivoire"],
    "ekvador":                    ["ecuador", "ekvador"],
    "ecuador":                    ["ecuador"],
    "curaçao":                    ["curaçao", "curacao"],
    "curacao":                    ["curaçao", "curacao"],
    "demokratik kongo":           ["congo dr", "dr congo", "democratic congo"],
    "congo dr":                   ["congo dr", "dr congo"],
    "dr congo":                   ["congo dr", "dr congo"],
    "özbekistan":                 ["uzbekistan", "özbekistan", "ozbekistan"],
    "ozbekistan":                 ["uzbekistan", "özbekistan", "ozbekistan"],
    "uzbekistan":                 ["uzbekistan"],
    "yeşil burun adaları":        ["cape verde", "yeşil burun adaları"],
    "yesil burun adalari":        ["cape verde", "yeşil burun adaları"],
    "cape verde":                 ["cape verde"],
    "haiti":                      ["haiti"],
    "paraguay":                   ["paraguay"],
    # ── Turkish clubs ─────────────────────────────────────────────────────────
    "galatasaray":                ["galatasaray"],
    "gs":                         ["galatasaray"],
    "fenerbahce":                 ["fenerbahce", "fenerbahçe"],
    "fenerbahçe":                 ["fenerbahce", "fenerbahçe"],
    "fb":                         ["fenerbahce", "fenerbahçe"],
    "besiktas":                   ["besiktas", "beşiktaş"],
    "beşiktaş":                   ["besiktas", "beşiktaş"],
    "bjk":                        ["besiktas", "beşiktaş"],
    "trabzonspor":                ["trabzonspor"],
    "trabzon":                    ["trabzonspor"],
    "trb":                        ["trabzonspor"],
    "basaksehir":                 ["basaksehir", "başakşehir", "istanbul basaksehir"],
    "başakşehir":                 ["basaksehir", "başakşehir", "istanbul basaksehir"],
    "antalyaspor":                ["antalyaspor"],
    "sivasspor":                  ["sivasspor"],
    "kasimpasa":                  ["kasimpasa", "kasımpaşa"],
    "kasımpaşa":                  ["kasimpasa", "kasımpaşa"],
    # ── Leagues ───────────────────────────────────────────────────────────────
    "sampiyonlar ligi":           ["champions league", "şampiyonlar ligi", "ucl"],
    "şampiyonlar ligi":           ["champions league", "şampiyonlar ligi", "ucl"],
    "ucl":                        ["champions league", "şampiyonlar ligi"],
    "premier lig":                ["premier league"],
    "premier league":             ["premier league"],
    "la liga":                    ["la liga", "laliga"],
    "laliga":                     ["la liga", "laliga"],
    "seri a":                     ["serie a"],
    "serie a":                    ["serie a"],
    "bundesliga":                 ["bundesliga"],
    "ligue 1":                    ["ligue 1"],
    "super lig":                  ["super lig", "süper lig"],
    "süper lig":                  ["super lig", "süper lig"],
    "europa league":              ["europa league", "uel"],
    "uel":                        ["europa league", "uel"],
    "dunya kupasi":               ["world cup", "dünya kupası", "fifa world cup"],
    "dünya kupası":               ["world cup", "dünya kupası", "fifa world cup"],
    "world cup":                  ["world cup", "dünya kupası", "fifa world cup"],
}


# Fold Turkish diacritics to ASCII after lowercasing.
# ü→u  ö→o  ı→i  ş→s  ç→c  ğ→g
_TR_MAP = str.maketrans("üöışçğ", "uoiscg")

def normalize(s: str) -> str:
    """Lowercase, fold Turkish diacritics to ASCII, collapse whitespace."""
    # Replace İ (U+0130) before lower() — Python lower() yields 'i̇' not 'i'
    s = s.replace("İ", "i")
    return " ".join(s.lower().translate(_TR_MAP).strip().split())


def _build_country_aliases() -> None:
    """Extend ALIASES with EN↔TR country pairs from country_names.py.

    Called after normalize() is defined. Safe to call multiple times (idempotent).
    Silently skips if country_names.py is not present (e.g. during tests).
    """
    try:
        from country_names import EN_TO_TR  # type: ignore
    except ImportError:
        return

    for en, tr in EN_TO_TR.items():
        en_low  = en.lower()
        tr_norm = normalize(tr)
        en_norm = normalize(en)

        # TR search term → EN DB variants (e.g. "almanya" → ["germany", "almanya"])
        if tr_norm not in ALIASES:
            ALIASES[tr_norm] = list(dict.fromkeys([en_low, en_norm, tr_norm]))

        # EN search term → EN DB variants passthrough (helps prefix matching on EN input)
        if en_norm not in ALIASES:
            ALIASES[en_norm] = list(dict.fromkeys([en_low, en_norm]))


_build_country_aliases()


def expand_query(q: str) -> list[str]:
    """Return all DB search terms for a user query.

    Matching rules (in order):
    1. Exact alias key match.
    2. Prefix match: query starts with an alias key (e.g. "fransa" → key "fransa").
    3. Prefix match: alias key starts with query (e.g. "fran" → key "fransa").
    All matched alias lists are merged and deduplicated.
    Falls back to [query] if no alias matches.
    """
    key = normalize(q)
    seen: dict[str, None] = {}  # ordered set via insertion-ordered dict

    for alias_key, terms in ALIASES.items():
        if key == alias_key or key.startswith(alias_key) or alias_key.startswith(key):
            for t in terms:
                seen[t] = None

    if seen:
        return list(seen)
    return [key]


# ── Schema detection ──────────────────────────────────────────────────────────

@lru_cache(maxsize=1)
def detect_columns() -> dict[str, str]:
    """
    Read PRAGMA table_info(matches) once and return a mapping of
    logical names → actual column names.
    Falls back to sensible defaults if columns are missing.
    """
    with sqlite3.connect(DB_PATH) as conn:
        rows = conn.execute("PRAGMA table_info(matches)").fetchall()
    cols = {r[1].lower() for r in rows}  # r[1] = column name

    def pick(*candidates: str) -> str | None:
        for c in candidates:
            if c in cols:
                return c
        return None

    return {
        "id":     pick("id", "match_id", "fixture_id") or "rowid",
        "home":   pick("home_team", "home", "home_name") or "home_team",
        "away":   pick("away_team", "away", "away_name") or "away_team",
        "league": pick("league", "league_name", "competition") or "league",
        "time":   pick("match_time", "time", "datetime", "date", "kickoff") or "match_time",
    }


# ── App ───────────────────────────────────────────────────────────────────────

app = FastAPI(title="KuponBot API", version="2.0.0", docs_url="/api/docs")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["GET", "POST", "DELETE"],
    allow_headers=["*"],
)

app.include_router(social_router)


class MatchResult(BaseModel):
    id: str
    home: str
    away: str
    league: str
    time: str


def fmt_row(row: sqlite3.Row, cols: dict[str, str]) -> MatchResult:
    keys = row.keys()

    def get(logical: str) -> str:
        col = cols[logical]
        return str(row[col]) if col in keys else ""

    return MatchResult(
        id=get("id"),
        home=get("home"),
        away=get("away"),
        league=get("league"),
        time=get("time"),
    )


@app.get("/api/matches/search", response_model=list[MatchResult])
def search_matches(
    q: Optional[str] = Query(default=None, max_length=200, description="Search query"),
) -> list[MatchResult]:
    cols = detect_columns()
    time_col   = cols["time"]
    home_col   = cols["home"]
    away_col   = cols["away"]
    league_col = cols["league"]

    with sqlite3.connect(DB_PATH) as conn:
        conn.row_factory = sqlite3.Row

        # Cutoff: matches that started no more than 6 hours ago (still relevant)
        # or are in the future. Applied to both empty and query searches.
        cutoff_expr = f"{time_col} >= datetime('now', '-6 hours')"

        if not q or not q.strip():
            # No query → upcoming / in-progress matches
            try:
                rows = conn.execute(
                    f"""
                    SELECT * FROM matches
                    WHERE {cutoff_expr}
                    ORDER BY {time_col} ASC
                    LIMIT 20
                    """
                ).fetchall()
            except sqlite3.OperationalError:
                rows = conn.execute(
                    "SELECT * FROM matches ORDER BY rowid DESC LIMIT 20"
                ).fetchall()
        else:
            terms = expand_query(q.strip())
            clauses: list[str] = []
            params: list[str] = []

            for term in terms:
                like = f"%{term}%"
                clauses.append(
                    f"(LOWER({home_col}) LIKE ? "
                    f" OR LOWER({away_col}) LIKE ? "
                    f" OR LOWER({league_col}) LIKE ?)"
                )
                params.extend([like, like, like])

            text_where = " OR ".join(clauses)
            try:
                rows = conn.execute(
                    f"""
                    SELECT * FROM matches
                    WHERE ({text_where})
                      AND {cutoff_expr}
                    ORDER BY {time_col} ASC
                    LIMIT 20
                    """,
                    params,
                ).fetchall()
            except sqlite3.OperationalError:
                rows = conn.execute(
                    f"""
                    SELECT * FROM matches
                    WHERE ({text_where})
                      AND {cutoff_expr}
                    ORDER BY {time_col} ASC
                    LIMIT 20
                    """,
                    params,
                ).fetchall()

    return [fmt_row(r, cols) for r in rows]


@app.get("/health")
def health() -> dict:
    return {"status": "ok", "db": DB_PATH}
