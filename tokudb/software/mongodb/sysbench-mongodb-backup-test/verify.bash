#!/bin/bash

if [ -z "$VERIFY_LOG_NAME" ]; then
    echo "Need to set VERIFY_LOG_NAME"
    exit 1
fi
if [ -z "$NUM_COLLECTIONS" ]; then
    echo "Need to set NUM_COLLECTIONS"
    exit 1
fi
if [ -z "$DB_NAME" ]; then
    echo "Need to set DB_NAME"
    exit 1
fi


ant validate | tee -a $VERIFY_LOG_NAME
