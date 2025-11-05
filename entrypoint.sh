#!/bin/bash
service nginx start
nginx -v
service nginx status
rm -f /tmp/.wrapper*
chown -R 1000:1000 /conf /data /download /fred
exec gosu 1000:1000 /fred/docker-run
