#!/usr/bin/env bash
# Test fonctionnel : lance MariaDB + l'appli, appelle / et vérifie la réponse.
set -euo pipefail

EXPECTED="Database Connection Status: Connected"
DB_NAME=appdb
# mot de passe généré au moment du test, rien n'est stocké dans le dépôt
DB_PASSWORD="$(openssl rand -hex 16)"

cleanup() {
  echo "--- logs de l'appli ---"
  docker logs app 2>&1 || true
  docker rm -f app db >/dev/null 2>&1 || true
  docker network rm test-net >/dev/null 2>&1 || true
}
trap cleanup EXIT

docker network create test-net

echo "Démarrage de MariaDB..."
docker run -d --name db --network test-net \
  -e MARIADB_ROOT_PASSWORD="$DB_PASSWORD" \
  -e MARIADB_DATABASE="$DB_NAME" \
  --health-cmd="healthcheck.sh --connect --innodb_initialized" \
  --health-interval=3s --health-retries=20 \
  mariadb:11.4

# on attend que la base soit prête
for i in $(seq 1 40); do
  status=$(docker inspect -f '{{.State.Health.Status}}' db)
  if [ "$status" = "healthy" ]; then break; fi
  sleep 3
done
if [ "$status" != "healthy" ]; then
  echo "MariaDB ne démarre pas"
  docker logs db
  exit 1
fi

echo "Build et démarrage de l'appli..."
docker build -t app-test .
docker run -d --name app --network test-net -p 5000:5000 \
  -e DB_HOST=db -e DB_USER=root \
  -e DB_PASSWORD="$DB_PASSWORD" -e DB_NAME="$DB_NAME" \
  app-test

# on attend que Flask réponde
body=""
for i in $(seq 1 20); do
  body=$(curl -fsS http://localhost:5000/ || true)
  if [ -n "$body" ]; then break; fi
  sleep 2
done

echo "Réponse : $body"

# comparaison exacte (un grep "Connected" accepterait aussi "Disconnected")
if [ "$body" != "$EXPECTED" ]; then
  echo "ECHEC : réponse attendue = $EXPECTED"
  exit 1
fi
echo "OK"