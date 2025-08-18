import sqlite3
from collections.abc import Generator
from contextlib import contextmanager

from libs.configs import DB_FILE

# SQLite table schemas
CREATE_TABLES_SQL = """
CREATE TABLE IF NOT EXISTS indexing_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    uri TEXT NOT NULL,
    content_hash TEXT NOT NULL,
    status TEXT NOT NULL,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    error_message TEXT,
    document_id TEXT,
    metadata TEXT
);

CREATE INDEX IF NOT EXISTS idx_uri ON indexing_history(uri);
CREATE INDEX IF NOT EXISTS idx_document_id ON indexing_history(document_id);
CREATE INDEX IF NOT EXISTS idx_content_hash ON indexing_history(content_hash);

CREATE TABLE IF NOT EXISTS resources (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    uri TEXT NOT NULL UNIQUE,
    type TEXT NOT NULL,  -- 'path' or 'https'
    status TEXT NOT NULL DEFAULT 'active',  -- 'active' or 'inactive'
    indexing_status TEXT NOT NULL DEFAULT 'pending',  -- 'pending', 'indexing', 'indexed', 'failed'
    indexing_status_message TEXT,
    indexing_started_at DATETIME,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_indexed_at DATETIME,
    last_error TEXT
);

CREATE INDEX IF NOT EXISTS idx_resources_name ON resources(name);
CREATE INDEX IF NOT EXISTS idx_resources_uri ON resources(uri);
CREATE INDEX IF NOT EXISTS idx_resources_status ON resources(status);
CREATE INDEX IF NOT EXISTS idx_status ON indexing_history(status);
"""


@contextmanager
def get_db_connection() -> Generator[sqlite3.Connection, None, None]:
    """Get a database connection."""
    conn = sqlite3.connect(DB_FILE)
    conn.row_factory = sqlite3.Row
    try:
        yield conn
    finally:
        conn.close()


def init_db() -> None:
    """Initialize the SQLite database."""
    with get_db_connection() as conn:
        conn.executescript(CREATE_TABLES_SQL)
        conn.commit()
