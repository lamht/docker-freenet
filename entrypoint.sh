#!/bin/bash
service nginx start
exec gosu fred /fred/docker-run