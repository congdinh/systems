#!/bin/bash
# source http://stackoverflow.com/questions/23222616/copy-all-keys-from-one-db-to-another-in-redis
# https://github.com/sripathikrishnan/redis-rdb-tools
# https://github.com/redis-developer/riot

#set connection data accordingly
source_host=127.0.0.1
source_port=6379
source_db=1
target_host=localhost
target_port=7000
target_db=0

#copy all keys without preserving ttl!
redis-cli -h $source_host -p $source_port -n $source_db keys \* | while read key; do
    echo "Copying $key"
    redis-cli --raw -h $source_host -p $source_port -n $source_db DUMP "$key" | head -c -1 | redis-cli -x -h $target_host -p $target_port -n $target_db RESTORE "$key" 0
done
