#!/bin/sh
# Automated smoke test for the nginx container.
# Builds the image, runs it with no special env (the entrypoint auto-generates
# a self-signed cert + default index.html), waits for nginx to come up and
# asserts that the config is valid and that nginx actually serves HTTP + HTTPS.
set -e

IMG=nginx-test
CN=nginx-test-run

cleanup() { docker rm -f "$CN" >/dev/null 2>&1 || true; }
trap cleanup EXIT

fail() { echo "FAIL: $1"; exit 1; }

echo ">> building image"
docker build -t "$IMG" .

echo ">> starting container"
docker rm -f "$CN" >/dev/null 2>&1 || true
docker run -d --name "$CN" "$IMG" >/dev/null

echo ">> waiting for nginx to listen on 80 (up to 120s)"
up=0
for _ in $(seq 1 60); do
  if docker exec "$CN" bash -c 'exec 3<>/dev/tcp/127.0.0.1/80' 2>/dev/null; then up=1; break; fi
  sleep 2
done
[ "$up" = 1 ] || fail "nginx did not start listening on 80 in time"

echo ">> assert: container is running"
[ "$(docker inspect -f '{{.State.Running}}' "$CN")" = true ] || fail "container not running"
echo "ok - container running"

echo ">> assert: nginx master process present"
docker exec "$CN" sh -c "ps aux | grep -q '[n]ginx: master'" || fail "nginx master not running"
echo "ok - nginx master running"

echo ">> assert: nginx -t reports config OK"
docker exec "$CN" nginx -t || fail "nginx -t reported config problems"
echo "ok - nginx -t passed"

echo ">> assert: HTTP request to localhost returns content"
body=$(docker exec "$CN" wget -qO- http://localhost) || fail "HTTP request failed"
echo "$body" | grep -qi 'ServerContainers' || fail "unexpected HTTP body (got: $body)"
echo "ok - HTTP served: $(echo "$body" | head -c 80)..."

echo ">> assert: HTTPS request to localhost returns content"
sbody=$(docker exec "$CN" wget --no-check-certificate -qO- https://localhost) || fail "HTTPS request failed"
echo "$sbody" | grep -qi 'ServerContainers' || fail "unexpected HTTPS body (got: $sbody)"
echo "ok - HTTPS served: $(echo "$sbody" | head -c 80)..."

echo ""
echo "ALL TESTS PASSED"
