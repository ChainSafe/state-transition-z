#!/bin/sh
grep -rlZ $1 . | xargs sed -i "" -e 's/$1/$2/g'
