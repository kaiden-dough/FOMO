"""Additive migration; run once before starting green. No user data rewritten."""
from sqlalchemy import text
from .db import engine
from .models import AuthIdentity


def migrate():
    with engine.begin() as connection:
        AuthIdentity.__table__.create(connection, checkfirst=True)
        if connection.dialect.name == "postgresql":
            # Only the trusted backend DB role accesses this mapping. No anon policies.
            connection.execute(text("ALTER TABLE auth_identities ENABLE ROW LEVEL SECURITY"))
            connection.execute(text("REVOKE ALL ON auth_identities FROM anon, authenticated"))


if __name__ == "__main__":
    migrate()
    print("Auth identity migration complete; existing accounts and sessions preserved.")
