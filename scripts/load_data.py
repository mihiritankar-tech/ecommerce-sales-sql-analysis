"""Build a SQLite database (ecommerce.db) from the schema and CSV files."""
import csv, sqlite3
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
db = sqlite3.connect(ROOT / "ecommerce.db")
db.executescript((ROOT / "sql" / "01_schema.sql").read_text())
for table in ["customers", "products", "orders", "order_items"]:
    with open(ROOT / "data" / f"{table}.csv") as f:
        rows = list(csv.DictReader(f))
    cols = rows[0].keys()
    db.executemany(f"INSERT INTO {table} ({','.join(cols)}) VALUES ({','.join('?'*len(cols))})",
                   [tuple(r.values()) for r in rows])
    print(f"Loaded {len(rows):>5} rows into {table}")
db.commit()
