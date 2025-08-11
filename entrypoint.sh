#!/bin/bash
service nginx start
nginx -v
service nginx status
rm -f /tmp/.wrapper*
exec gosu fred /fred/docker-run
