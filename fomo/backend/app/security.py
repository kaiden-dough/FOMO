import hashlib
import secrets


def hash_password(password: str, salt: str | None = None) -> str:
    use_salt = salt or secrets.token_hex(16)
    digest = hashlib.sha256(f"{use_salt}:{password}".encode("utf-8")).hexdigest()
    return f"{use_salt}${digest}"


def verify_password(password: str, password_hash: str) -> bool:
    try:
        salt, _ = password_hash.split("$", maxsplit=1)
    except ValueError:
        return False
    return hash_password(password, salt) == password_hash
