#!/usr/bin/env bash
#
# Sync db and assets from local to prod
#
# SSH-keys is mandatory
# Example usage `scripts/sync/local_to_prod.sh`

read -p "This will replace the LIVE database - Are you sure? [y/n]" -n 1 -r
echo # nl
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1
fi

cd $(git rev-parse --show-toplevel)

source scripts/sync/STAGES

docker-compose run web bash -c "cd /app; wp --allow-root db export db-dumps/latest.sql"

scp docker/files/db-dumps/latest.sql $LIVE_USERNAME@$LIVE_HOSTNAME:/tmp/latest.sql
ssh $LIVE_USERNAME@$LIVE_HOSTNAME "cd $LIVE_SRC_PATH;
    wp --allow-root db import /tmp/latest.sql;
    wp --allow-root search-replace $LOCAL_DOMAIN $LIVE_DOMAIN;
    wp --allow-root option set ep_host http://localhost:9200;
    wp --allow-root cache flush;
    wp --allow-root elasticpress index;"

rsync -re ssh src/app/uploads/ $LIVE_USERNAME@$LIVE_HOSTNAME:$LIVE_UPLOAD_PATH

cd -