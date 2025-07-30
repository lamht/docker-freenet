#!/bin/bash
service nginx start
nginx -v
service nginx status
exec gosu fred /fred/docker-run