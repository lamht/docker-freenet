#!/bin/bash
service nginx start
nginx -v
service nginx status
rm -f /tmp/.wrapper*
chown -R fred:fred /conf /data /download /fred
exec gosu fred /fred/docker-run
