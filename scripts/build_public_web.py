"""Run a web build with an allowlisted asset, restoring local .env bytes after it."""

import argparse
import os
from pathlib import Path
import shlex
import shutil
import subprocess
from typing import Mapping, Sequence

from check_public_bundle import validate_public_env


PUBLIC_KEYS = ("SUPABASE_URL", "SUPABASE_ANON_KEY")
PRIVATE_PROVIDER_KEYS = ("GEMINI_API_KEY", "HUGGINGFACE_TOKEN")


def public_env(contents: str, environment: Mapping[str, str]) -> str:
    """Copy only known public configuration; never copy arbitrary local lines."""
    values = {}
    for line in contents.splitlines():
        line = line.strip()
        if line.startswith("export "):
            line = line[len("export "):].lstrip()
        key, separator, value = line.partition("=")
        key = key.strip()
        if separator and key in PUBLIC_KEYS:
            if key in values:
                raise ValueError("Duplicated public configuration key")
            parts = shlex.split(value, comments=True, posix=True)
            if len(parts) > 1:
                raise ValueError("Invalid public configuration value")
            values[key] = parts[0] if parts else ""
    for key in PUBLIC_KEYS:
        if key in environment:
            values[key] = environment[key]
    result = "".join(f"{key}={values.get(key, '')}\n" for key in PUBLIC_KEYS)
    # The optional native-only token name stays compatible, but never its value.
    result += "HUGGINGFACE_TOKEN=\n"
    validate_public_env(result)
    return result


def run_public_build(
    command: Sequence[str],
    env_path: Path = Path(".env"),
    environment: Mapping[str, str] | None = None,
) -> int:
    if not command:
        raise ValueError("A build command is required")
    if env_path.is_symlink():
        raise ValueError("The local runtime file must not be a symlink")
    environment = dict(os.environ if environment is None else environment)
    original = env_path.read_bytes() if env_path.exists() else None
    sanitized = public_env((original or b"").decode("utf-8"), environment)
    for key in PRIVATE_PROVIDER_KEYS:
        environment.pop(key, None)
    # Keep the original only in memory, not in another secret-bearing disk file.
    try:
        env_path.write_text(sanitized, encoding="utf-8")
        executable = shutil.which(command[0]) or command[0]
        return subprocess.run([executable, *command[1:]], env=environment, check=False).returncode
    finally:
        if original is not None:
            env_path.write_bytes(original)
        # If no local file existed, leave only the safe generated public asset.


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", nargs=argparse.REMAINDER)
    arguments = parser.parse_args()
    command = arguments.command
    if command and command[0] == "--":
        command = command[1:]
    try:
        code = run_public_build(command)
    except (ValueError, OSError):
        # Never include local configuration values or raw subprocess output here.
        parser.exit(1, "Public web configuration/build startup failed; local configuration was preserved.\n")
    raise SystemExit(code)
