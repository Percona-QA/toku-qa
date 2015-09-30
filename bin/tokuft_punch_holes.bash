#!/usr/bin/env bash

du -ch --apparent-size $1 | tail -n1
du -ch $1 | tail -n1

$DB_DIR/bin/tokuftdump --translation-table $1 | ~/bin/tokuftunused.py | xfs_punch_holes $1

du -ch --apparent-size $1 | tail -n1
du -ch $1 | tail -n1