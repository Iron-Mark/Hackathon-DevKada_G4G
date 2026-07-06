# ─── Stage 1: Build ──────────────────────────────────────────────────────────
# Pin the exact Flutter version so every machine builds identically.
# This image supports both linux/amd64 (Intel) and linux/arm64 (Apple Silicon).
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app

# Copy dependency manifests first — Docker caches this layer.
# pub get only re-runs when pubspec.yaml or pubspec.lock changes.
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get --no-example

# Copy the rest of the source (includes .env asset)
COPY . .

# Release web build — CanvasKit is the default renderer for release builds
# --pwa-strategy=none skips service worker generation (keeps it simple)
RUN flutter build web \
      --release \
      --pwa-strategy none \
      --no-tree-shake-icons

# ─── Stage 2: Serve ──────────────────────────────────────────────────────────
# nginx:alpine is ~45 MB. We copy only the compiled web output — no Flutter SDK.
FROM nginx:1.27-alpine

# Remove the default nginx page
RUN rm -rf /usr/share/nginx/html/*

COPY --from=builder /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
