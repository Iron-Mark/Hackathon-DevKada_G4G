#!/bin/bash
set -e

if ! command -v flutter >/dev/null 2>&1; then
  if [ ! -d "$HOME/flutter" ]; then
    git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$HOME/flutter"
  fi
  export PATH="$PATH:$HOME/flutter/bin"
fi

PUBLIC_SITE_URL="${PUBLIC_SITE_URL:-${CF_PAGES_URL:-https://example.com}}"
PUBLIC_SITE_URL="${PUBLIC_SITE_URL%/}"
APP_BASE_PATH="${APP_BASE_PATH:-/app/}"

if [[ "$APP_BASE_PATH" != /* || "$APP_BASE_PATH" != */ ]]; then
  echo "APP_BASE_PATH must start and end with '/'. Current value: $APP_BASE_PATH" >&2
  exit 1
fi

if [ -n "${SUPABASE_URL:-}" ] || [ -n "${SUPABASE_ANON_KEY:-}" ] || [ -n "${GEMINI_API_KEY:-}" ] || [ -n "${HUGGINGFACE_TOKEN:-}" ]; then
  # Write .env from CI environment variables so flutter_dotenv can load it.
  # All variables must be set as secrets in the CI environment.
  cat > .env <<EOF
SUPABASE_URL=${SUPABASE_URL}
SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}
GEMINI_API_KEY=${GEMINI_API_KEY}
HUGGINGFACE_TOKEN=${HUGGINGFACE_TOKEN:-}
EOF
elif [ ! -f .env ]; then
  cat > .env <<EOF
SUPABASE_URL=
SUPABASE_ANON_KEY=
GEMINI_API_KEY=
HUGGINGFACE_TOKEN=
EOF
fi

flutter config --enable-web
flutter pub get
export MSYS_NO_PATHCONV=1
flutter build web --release --base-href "$APP_BASE_PATH"

rm -rf .seo-build
mkdir -p .seo-build/app
cp -R build/web/. .seo-build/app/

rm -rf build/web
mkdir -p build/web

python - <<PY
import json
from pathlib import Path
from urllib.parse import urlsplit, urlunsplit

site_url = "$PUBLIC_SITE_URL"
app_base_path = "$APP_BASE_PATH"
root = Path("build/web")

parts = urlsplit(site_url)
site_path = parts.path.rstrip("/")
app_path = app_base_path if app_base_path.startswith("/") else f"/{app_base_path}"

if site_path and app_path.startswith(f"{site_path}/"):
    final_app_path = app_path
else:
    final_app_path = f"{site_path}/{app_path.lstrip('/')}"
final_app_path = "/" + final_app_path.strip("/") + "/"
app_url = urlunsplit((parts.scheme, parts.netloc, final_app_path, "", ""))

template = Path("web/landing/index.html").read_text(encoding="utf-8")
template = template.replace("__PUBLIC_SITE_URL__", site_url)
template = template.replace("__APP_URL__", app_url)
(root / "index.html").write_text(template, encoding="utf-8")

robots = f"""User-agent: *
Allow: /

Sitemap: {site_url}/sitemap.xml
"""
(root / "robots.txt").write_text(robots, encoding="utf-8")

sitemap = f"""<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>{site_url}/</loc>
    <priority>1.0</priority>
  </url>
  <url>
    <loc>{app_url}</loc>
    <priority>0.7</priority>
  </url>
</urlset>
"""
(root / "sitemap.xml").write_text(sitemap, encoding="utf-8")

manifest = json.loads(Path("web/manifest.json").read_text(encoding="utf-8"))
manifest["start_url"] = app_url
manifest["scope"] = final_app_path
(root / "manifest.json").write_text(
    json.dumps(manifest, indent=2, ensure_ascii=False) + "\n",
    encoding="utf-8",
)
PY

cp -R .seo-build/app build/web/app
rm -rf build/web/app/landing build/web/app/social build/web/app/screenshots
cp -R web/icons build/web/icons
cp web/favicon.png build/web/favicon.png
cp -R web/social build/web/social
cp -R web/screenshots build/web/screenshots

rm -rf .seo-build
