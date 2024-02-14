#!/bin/bash

if [ $1 -gt 90 ]; then
    echo "red"
elif [ $1 -gt 75 ]; then
    echo "orange"
else
    echo "green"
fi
