#!/bin/bash
nc -z -w10 addr port 2>&1 | grep ldap
echo "${PIPESTATUS[0]}"