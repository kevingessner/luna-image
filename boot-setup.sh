#!/usr/bin/env bash

# Run at first boot on the rpi.

# Host the config server at port 80.
iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8000
