"""Validate the deliberately public Flutter configuration before Pages upload."""

import argparse
import base64
import json
from pathlib import Path
import re
from urllib.parse import urlsplit


def validate_bundle(root: Path, app_subdir: str = "app") -> None:
    root = root.resolve(strict=True)
    app = (root / app_subdir).resolve()
    if not app.is_relative_to(root):
        raise ValueError("App directory must remain inside the public bundle")
    env_path = app / "assets" / ".env"
    if not env_path.is_file():
        raise ValueError("Required public Flutter runtime asset is missing")

    allowed_hidden = {env_path, app / ".last_build_id", root / ".nojekyll"}
    for entry in root.rglob("*"):
        if entry.is_symlink():
            raise ValueError("Symlinks are not permitted in the public bundle")
        if any(part.startswith(".") for part in entry.relative_to(root).parts):
            if entry not in allowed_hidden or not entry.is_file():
                raise ValueError("Unexpected hidden entry in the public bundle")
    marker = app / ".last_build_id"
    if marker.exists():
        build_id = marker.read_text(encoding="utf-8").strip()
        if not build_id or len(build_id) > 128 or any(
            char not in "0123456789abcdefABCDEF" for char in build_id
        ):
            raise ValueError("Unexpected Flutter build metadata")
    if (root / ".nojekyll").exists() and (root / ".nojekyll").stat().st_size:
        raise ValueError("The nojekyll marker must be empty")

    allowed_keys = {"SUPABASE_URL", "SUPABASE_ANON_KEY", "HUGGINGFACE_TOKEN"}
    values = {}
    for line in env_path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line:
            continue
        if line.startswith("#"):
            raise ValueError("Comments must not be copied into public runtime configuration")
        key, separator, value = line.partition("=")
        if not separator or key not in allowed_keys or key in values:
            raise ValueError("Unexpected or duplicated client configuration key")
        values[key] = value.strip().strip("\"'")
    if not {"SUPABASE_URL", "SUPABASE_ANON_KEY"}.issubset(values):
        raise ValueError("Required client configuration names are missing")
    if bool(values["SUPABASE_URL"]) != bool(values["SUPABASE_ANON_KEY"]):
        raise ValueError("Client URL and anonymous key must be configured together")
    if values.get("HUGGINGFACE_TOKEN"):
        raise ValueError("Private model tokens must not be published in Pages assets")
    if values["SUPABASE_URL"]:
        try:
            url = urlsplit(values["SUPABASE_URL"])
            valid_url = (
                url.scheme == "https" and bool(url.hostname)
                and url.username is None and url.password is None
                and not url.query and not url.fragment and url.path in ("", "/")
                and not re.search(r"\s|\\", values["SUPABASE_URL"])
                and (url.port is None or 0 < url.port <= 65535)
            )
        except ValueError:
            valid_url = False
        if not valid_url:
            raise ValueError("Only a public HTTPS origin belongs in client configuration")
    anon = values["SUPABASE_ANON_KEY"]
    if anon and not re.fullmatch(r"sb_publishable_[A-Za-z0-9_-]+", anon):
        if not re.fullmatch(r"[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+", anon):
            raise ValueError("Unknown client key format; public-key review is required")
        try:
            payload = anon.split(".")[1]
            claims = json.loads(base64.urlsafe_b64decode(payload + "=" * (-len(payload) % 4)))
        except (ValueError, UnicodeDecodeError):
            raise ValueError("Invalid anonymous-key payload") from None
        if not isinstance(claims, dict) or claims.get("role") != "anon":
            raise ValueError("Only anonymous public keys belong in this bundle")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path("build/web"))
    parser.add_argument("--app-subdir", default="app")
    arguments = parser.parse_args()
    try:
        validate_bundle(arguments.root, arguments.app_subdir)
    except (ValueError, OSError) as error:
        # Validation messages never include configuration values.
        parser.exit(1, f"Public bundle validation failed: {error}\n")
    print("Public bundle validated; only approved client assets may be uploaded.")
