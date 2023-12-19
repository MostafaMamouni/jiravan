#!/bin/bash
cp ./.env.example ./.env

# Export for tr error in mac
export LC_ALL=C
export LC_CTYPE=C

cp ./web/.env.example ./web/.env
cp ./apiserver/.env.example ./apiserver/.env

