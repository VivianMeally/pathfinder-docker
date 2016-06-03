#!/bin/bash

set -e
#set -x

if [ ! -d "/var/lib/mysql/" ]; then
	
	echo 'Running mysql_install_db ...'
	mysql_install_db --datadir=/var/lib/mysql
	echo 'Finished mysql_install_db'
	
fi
/usr/sbin/mysqld &
mysql_pid=$!

until mysqladmin ping &>/dev/null; do
  echo -n "."; sleep 0.2
done


if [ -d /var/lib/mysql/pathfinder ]; then
#exec "$@"
exec /usr/bin/supervisord --nodaemon
else

   		if [ "$MYSQL_PASS" = "**Random**" ]; then
        unset MYSQL_PASS
    fi
    PASS=${MYSQL_PASS:-$(pwgen -s 12 1)}
    _word=$( [ ${MYSQL_PASS} ] && echo "preset" || echo "random" )
    echo "=> Creating MySQL user ${MYSQL_USER} with ${_word} password"

    mysql -uroot -punused -e "CREATE USER '${MYSQL_USER}'@'%' IDENTIFIED BY '$PASS'"
    mysql -uroot -punused -e "create database \`$MYSQL_DATABASE\` CHARACTER SET utf8 COLLATE utf8_general_ci"
    mysql -uroot -punused $MYSQL_DATABASE < /pathfinder.sql
    mysql -uroot -punused -e "GRANT ALL PRIVILEGES ON *.* TO '${MYSQL_USER}'@'%' WITH GRANT OPTION"
    echo "=> Done!"
    echo "========================================================================"
    echo "You can now connect to this MySQL Server using:"
    echo ""
    echo "    mysql -u$MYSQL_USER -p$PASS -h<host> -P<port>"
    echo ""
    echo "Please remember to change the above password as soon as possible!"
    echo "========================================================================"

git clone https://github.com/exodus4d/pathfinder.git /var/www
chown -R www-data:www-data /var/www
wget https://github.com/exodus4d/pathfinder/raw/master/export/sql/eve_citadel_min.sql.zip &&  unzip eve_citadel_min.sql.zip &&  mysql -u$MYSQL_USER -p$PASS -e "create database sde CHARACTER SET utf8 COLLATE utf8_general_ci" &&  mysql -u$MYSQL_USER -p$PASS sde < eve_citadel_min.sql
echo "* * * * * curl -kv http://localhost/cron >/dev/null 2>&1" > /etc/crontab  


echo @a
set -- mysqld "$@"
chown -R mysql:mysql /var/lib/mysql
chown -R mysql:mysql /var/run/mysqld
echo "Checking to upgrade the schema"
echo "A failed upgrade is ok when there was no upgrade"
# mysql_upgrade || true
if grep -q "mysqld" /etc/supervisor/conf.d/supervisord.conf 
then
  echo "already in place, skip it..."
else
  echo "place mysqld in supervisord.conf ..."
  echo "$@" >> /etc/supervisor/conf.d/supervisord.conf
fi
echo "fastcgi_param   PF-ENV-URL                '$HOSTNAME';" >> /var/www/develop-pathfinder.conf
echo "fastcgi_param   PF-ENV-DEBUG                3;" >> /var/www/develop-pathfinder.conf



echo "fastcgi_param   PF-ENV-DB_DNS  				      'mysql:host=localhost;port=3306;dbname=';" >> /var/www/develop-pathfinder.conf
echo "fastcgi_param   PF-ENV-DB_NAME                '$MYSQL_DATABASE';" >> /var/www/develop-pathfinder.conf
echo "fastcgi_param   PF-ENV-DB_USER                'admin';" >> /var/www/develop-pathfinder.conf
echo "fastcgi_param   PF-ENV-DB_PASS                '$PASS';" >> /var/www/develop-pathfinder.conf


echo "fastcgi_param   PF-ENV-DB_CCP_DNS  			    'mysql:host=localhost;port=3306;dbname=';" >> /var/www/develop-pathfinder.conf
echo "fastcgi_param   PF-ENV-DB_CCP_NAME                'sde';" >> /var/www/develop-pathfinder.conf
echo "fastcgi_param   PF-ENV-DB_CCP_USER                'admin';" >> /var/www/develop-pathfinder.conf
echo "fastcgi_param   PF-ENV-DB_CCP_PASS                '$PASS';" >> /var/www/develop-pathfinder.conf

echo "fastcgi_param   PF-ENV-BASE                 '';" >> /var/www/develop-pathfinder.conf

echo "fastcgi_param   PF-ENV-SSO_CCP_CLIENT_ID                '$SSO_CCP_CLIENT_ID';" >> /var/www/develop-pathfinder.conf
echo "fastcgi_param   PF-ENV-SSO_CCP_SECRET_KEY                '$SSO_CCP_SECRET_KEY';" >> /var/www/develop-pathfinder.conf

echo "fastcgi_param   PF-ENV-CCP_CREST_URL                'https://crest-tq.eveonline.com';" >> /var/www/develop-pathfinder.conf
echo "fastcgi_param   PF-ENV-SSO_CCP_URL                'https://login.eveonline.com';" >> /var/www/develop-pathfinder.conf
echo "fastcgi_param   PF-ENV-CCP_XML                'https://api.eveonline.com';" >> /var/www/develop-pathfinder.conf
sed -i 's/GET @setup:/;GET @setup:/' /var/www/app/routes.ini

exec /usr/bin/supervisord --nodaemon
fi
