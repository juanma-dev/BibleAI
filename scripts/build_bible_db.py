#!/usr/bin/env python3
"""
Santa Biblia - Bible Database Builder
======================================
Descarga versiones de dominio público y construye el SQLite pre-empaquetado.
Ejecutar UNA VEZ desde la raíz del proyecto:
    python scripts/build_bible_db.py

Resultado: santa_biblia/assets/db/santa_biblia.db  (~8 MB)
"""

import sqlite3
import csv
import urllib.request
import urllib.error
import io
import os
import time
import json
import sys
from pathlib import Path

# ── Configuración ─────────────────────────────────────────────────────────────

OUTPUT_DB = Path(__file__).parent.parent / "santa_biblia" / "assets" / "db" / "santa_biblia.db"

# Fuentes de dominio público
# scrollmapper/bible_databases: CSV con formato id,b,c,v,t
SCROLLMAPPER_BASE = "https://raw.githubusercontent.com/scrollmapper/bible_databases/master/csv"

SOURCES_CSV = {
    "kjv": f"{SCROLLMAPPER_BASE}/t_kjv.csv",
    "web": f"{SCROLLMAPPER_BASE}/t_web.csv",
    "asv": f"{SCROLLMAPPER_BASE}/t_asv.csv",
}

# Para español usamos bible-api.com (dominio público, soporta rv1909)
BIBLE_API_BASE = "https://bible-api.com"
SPANISH_VERSIONS = {
    "rv1909": "rv1909",
}

# Libros de la Biblia (nombre en inglés para la API, ID estándar 1-66)
BIBLE_BOOKS = [
    (1,  "genesis",          50),  (2,  "exodus",           40),
    (3,  "leviticus",        27),  (4,  "numbers",          36),
    (5,  "deuteronomy",      34),  (6,  "joshua",           24),
    (7,  "judges",           21),  (8,  "ruth",              4),
    (9,  "1+samuel",         31),  (10, "2+samuel",         24),
    (11, "1+kings",          22),  (12, "2+kings",          25),
    (13, "1+chronicles",     29),  (14, "2+chronicles",     36),
    (15, "ezra",             10),  (16, "nehemiah",         13),
    (17, "esther",           10),  (18, "job",              42),
    (19, "psalms",          150),  (20, "proverbs",         31),
    (21, "ecclesiastes",    12),   (22, "song+of+solomon",   8),
    (23, "isaiah",           66),  (24, "jeremiah",         52),
    (25, "lamentations",     5),   (26, "ezekiel",          48),
    (27, "daniel",           12),  (28, "hosea",            14),
    (29, "joel",              3),  (30, "amos",              9),
    (31, "obadiah",           1),  (32, "jonah",             4),
    (33, "micah",             7),  (34, "nahum",             3),
    (35, "habakkuk",          3),  (36, "zephaniah",         3),
    (37, "haggai",            2),  (38, "zechariah",        14),
    (39, "malachi",           4),  (40, "matthew",          28),
    (41, "mark",             16),  (42, "luke",             24),
    (43, "john",             21),  (44, "acts",             28),
    (45, "romans",           16),  (46, "1+corinthians",   16),
    (47, "2+corinthians",   13),   (48, "galatians",         6),
    (49, "ephesians",         6),  (50, "philippians",       4),
    (51, "colossians",        4),  (52, "1+thessalonians",   5),
    (53, "2+thessalonians",   3),  (54, "1+timothy",         6),
    (55, "2+timothy",         4),  (56, "titus",             3),
    (57, "philemon",          1),  (58, "hebrews",          13),
    (59, "james",             5),  (60, "1+peter",           5),
    (61, "2+peter",           3),  (62, "1+john",            5),
    (63, "2+john",            1),  (64, "3+john",            1),
    (65, "jude",              1),  (66, "revelation",       22),
]

# ── Helpers ───────────────────────────────────────────────────────────────────

def download(url: str, label: str = "", retries: int = 3) -> bytes:
    for attempt in range(retries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "BibleDbBuilder/1.0"})
            with urllib.request.urlopen(req, timeout=30) as r:
                data = r.read()
            return data
        except Exception as e:
            if attempt < retries - 1:
                print(f"    ↻ Reintentando ({attempt+2}/{retries})... {e}")
                time.sleep(2 ** attempt)
            else:
                raise RuntimeError(f"Error descargando {label}: {e}")

def progress(current: int, total: int, label: str):
    pct = int(current / total * 40)
    bar = "█" * pct + "░" * (40 - pct)
    print(f"\r  [{bar}] {current}/{total}  {label:<30}", end="", flush=True)

# ── Creación del schema ────────────────────────────────────────────────────────

def create_schema(conn: sqlite3.Connection):
    conn.executescript("""
        PRAGMA journal_mode=WAL;
        PRAGMA synchronous=NORMAL;
        PRAGMA page_size=4096;

        CREATE TABLE IF NOT EXISTS verses (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            version_id  TEXT    NOT NULL,
            book_id     INTEGER NOT NULL,
            chapter     INTEGER NOT NULL,
            verse       INTEGER NOT NULL,
            text        TEXT    NOT NULL
        );

        CREATE INDEX IF NOT EXISTS idx_verses_lookup
            ON verses(version_id, book_id, chapter);

        CREATE INDEX IF NOT EXISTS idx_verses_version
            ON verses(version_id);

        CREATE VIRTUAL TABLE IF NOT EXISTS verses_fts USING fts5(
            text,
            version_id  UNINDEXED,
            book_id     UNINDEXED,
            chapter     UNINDEXED,
            verse_num   UNINDEXED,
            row_id      UNINDEXED,
            content='verses',
            content_rowid='id'
        );

        CREATE TRIGGER IF NOT EXISTS verses_ai AFTER INSERT ON verses BEGIN
            INSERT INTO verses_fts(rowid, text, version_id, book_id, chapter, verse_num, row_id)
            VALUES (new.id, new.text, new.version_id, new.book_id, new.chapter, new.verse, new.id);
        END;
    """)
    conn.commit()

# ── Carga desde scrollmapper CSV ──────────────────────────────────────────────

def load_from_scrollmapper_csv(conn: sqlite3.Connection, version_id: str, url: str):
    print(f"\n  📥 Descargando {version_id.upper()} desde scrollmapper...", end=" ", flush=True)
    raw = download(url, version_id)
    print(f"✓ ({len(raw)//1024} KB)")

    reader = csv.reader(io.StringIO(raw.decode("utf-8")))
    next(reader)  # skip header: id,b,c,v,t

    rows = []
    for cols in reader:
        if len(cols) < 5:
            continue
        _, book_id, chapter, verse, text = cols[0], int(cols[1]), int(cols[2]), int(cols[3]), cols[4]
        rows.append((version_id, book_id, chapter, verse, text.strip()))

    print(f"  ✍️  Insertando {len(rows):,} versículos...", end=" ", flush=True)
    conn.executemany(
        "INSERT INTO verses(version_id, book_id, chapter, verse, text) VALUES (?,?,?,?,?)",
        rows
    )
    conn.commit()
    print(f"✓")

# ── Carga desde bible-api.com (libro por libro) ───────────────────────────────

def load_from_bible_api(conn: sqlite3.Connection, version_id: str, api_code: str):
    print(f"\n  📥 Descargando {version_id.upper()} desde bible-api.com (66 libros)...")

    total_verses = 0
    for i, (book_id, book_slug, _) in enumerate(BIBLE_BOOKS):
        progress(i + 1, 66, book_slug.replace("+", " ").title())

        url = f"{BIBLE_API_BASE}/{book_slug}?translation={api_code}"
        try:
            raw = download(url, f"{version_id}/{book_slug}")
            data = json.loads(raw)
            verses_raw = data.get("verses", [])
        except Exception as e:
            print(f"\n  ⚠️  Libro {book_id} ({book_slug}): {e} — omitido")
            time.sleep(1)
            continue

        rows = [
            (version_id, book_id, v["chapter"], v["verse"], v["text"].strip())
            for v in verses_raw
        ]
        if rows:
            conn.executemany(
                "INSERT INTO verses(version_id, book_id, chapter, verse, text) VALUES (?,?,?,?,?)",
                rows
            )
            total_verses += len(rows)

        # Commit cada libro para no perder progreso si se interrumpe
        conn.commit()
        time.sleep(0.3)  # respetar rate limit de la API

    print(f"\n  ✓ {total_verses:,} versículos insertados")

# ── Reconstruir FTS ───────────────────────────────────────────────────────────

def rebuild_fts(conn: sqlite3.Connection):
    print("\n  🔍 Reconstruyendo índice de búsqueda FTS5...", end=" ", flush=True)
    conn.execute("INSERT INTO verses_fts(verses_fts) VALUES('rebuild')")
    conn.commit()
    print("✓")

# ── Verificación ──────────────────────────────────────────────────────────────

def verify(conn: sqlite3.Connection):
    print("\n  📊 Verificación del contenido:")
    rows = conn.execute("""
        SELECT version_id, COUNT(*) as cnt
        FROM verses GROUP BY version_id ORDER BY version_id
    """).fetchall()
    for version_id, cnt in rows:
        print(f"    {version_id:<10} {cnt:>6,} versículos")

    # Prueba de búsqueda FTS
    test = conn.execute(
        "SELECT text FROM verses WHERE version_id='kjv' AND book_id=43 AND chapter=3 AND verse=16"
    ).fetchone()
    if test:
        print(f"\n  📖 Juan 3:16 (KJV): «{test[0][:80]}...»")

# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    print("=" * 60)
    print("  🕊️  Santa Biblia — Bible Database Builder")
    print("=" * 60)

    OUTPUT_DB.parent.mkdir(parents=True, exist_ok=True)

    if OUTPUT_DB.exists():
        print(f"\n  ⚠️  Ya existe: {OUTPUT_DB}")
        resp = input("  ¿Sobreescribir? (s/N): ").strip().lower()
        if resp != "s":
            print("  Cancelado.")
            return
        OUTPUT_DB.unlink()

    print(f"\n  💾 Creando base de datos en: {OUTPUT_DB}\n")

    conn = sqlite3.connect(str(OUTPUT_DB))

    try:
        create_schema(conn)

        # ── Inglés: KJV, WEB, ASV (scrollmapper, rápido) ─────────────────────
        print("\n┌─ INGLÉS (scrollmapper.com) ─────────────────────────────┐")
        for version_id, url in SOURCES_CSV.items():
            # Check if already loaded (permite reanudar si se interrumpió)
            count = conn.execute(
                "SELECT COUNT(*) FROM verses WHERE version_id=?", (version_id,)
            ).fetchone()[0]
            if count > 30000:
                print(f"\n  ✓ {version_id.upper()} ya cargado ({count:,} versículos), omitiendo")
                continue
            load_from_scrollmapper_csv(conn, version_id, url)

        # ── Español: RV1909, RV1865 (bible-api.com) ───────────────────────────
        print("\n┌─ ESPAÑOL (bible-api.com) ───────────────────────────────┐")
        for version_id, api_code in SPANISH_VERSIONS.items():
            count = conn.execute(
                "SELECT COUNT(*) FROM verses WHERE version_id=?", (version_id,)
            ).fetchone()[0]
            if count > 30000:
                print(f"\n  ✓ {version_id.upper()} ya cargado ({count:,} versículos), omitiendo")
                continue
            load_from_bible_api(conn, version_id, api_code)

        # ── Finalización ──────────────────────────────────────────────────────
        print("\n┌─ FINALIZANDO ───────────────────────────────────────────┐")
        rebuild_fts(conn)
        verify(conn)

        print("\n  🧹 Optimizando base de datos (VACUUM)...", end=" ", flush=True)
        conn.execute("VACUUM")
        print("✓")

        size_mb = OUTPUT_DB.stat().st_size / 1_048_576
        print(f"\n  ✅ Base de datos lista: {OUTPUT_DB.name} ({size_mb:.1f} MB)")
        print("\n  Próximo paso:")
        print("    cd santa_biblia && flutter run -d windows")
        print("=" * 60)

    except KeyboardInterrupt:
        conn.commit()  # guardar progreso
        print("\n\n  ⚠️  Interrumpido. El progreso se guardó. Re-ejecuta para continuar.")
    finally:
        conn.close()


if __name__ == "__main__":
    main()
