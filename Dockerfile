# ── Stage 1 : Build Flutter Web ──────────────────────────────────────────────
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app

# Copier les fichiers de dépendances en premier (cache layer)
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copier le reste du projet
COPY . .

# URL du backend (passée au build, ex: https://mon-backend.railway.app/api)
ARG API_BASE_URL=https://backend-production.up.railway.app/api
RUN flutter build web --release --dart-define=API_BASE_URL=${API_BASE_URL}

# ── Stage 2 : Servir avec nginx ───────────────────────────────────────────────
FROM nginx:alpine

COPY --from=builder /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
