#!/bin/sh

if [ -f "/data/production.sqlite3" ]
then
    echo "Skipping database creation"
else
    rails db:schema:load
fi

rails server -b 0.0.0.0