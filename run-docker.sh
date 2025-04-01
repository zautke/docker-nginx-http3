#!/bin/sh
docker run --rm \
  -p 0.0.0.0:8888:80 \
  -p 0.0.0.0:8889:443/tcp \
  -p 0.0.0.0:8889:443/udp \
  -v "$PWD/tests":/static:ro \
  -v "$PWD/conf.d":/etc/nginx/conf.d:ro \
  -v ./ssl:/etc/nginx/ssl:ro \
  \
  -v "$PWD/tests/njs":/opt/njs:ro \
  \
  -v "$PWD/tests/localhost.crt":/etc/nginx/local/localhost.crt:ro \
  -v "$PWD/tests/localhost.key":/etc/nginx/local/localhost.key:ro \
  --name nginx \
  -t braisenly/nginx-h3:wip
∫
