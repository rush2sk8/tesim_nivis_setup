
#this script is called on release_one_time.sh, modules are stopped

# TAKE CARE: use relative paths. Will only work from ${NIVIS_FIRMWARE}
db_path=${NIVIS_ACTIVITY_FILES}
db_file=${db_path}/Monitor_Host.db3
# The scripts inside must be named exactly updateDB_to_${sql_script_version}.sql
sql_script_path=DbUpdate/

echo "path to db is -> $db_path"

if [ ! -f ${db_file} ]; then
	echo "Not found DB file [${db_file}]. Update cannot continue"
	return
fi

db_schema_version=$(echo "select Value from Properties where Key = 'SchemaVersion';" | sqlite3 $db_file)
if [ $? != 0 ]; then
    echo "Cannot retreive installed database schema. "
    exit 1
fi

echo "current db version is '${db_schema_version}'"
echo "delete  from DeviceChannelsHistory;"
echo "delete  from DeviceChannelsHistory;" | sqlite3 $db_file

# db_schema_version is el with the version of MH that needs that change in db

#Version of initial DB (released with the initial image)
PREV_DB_VERSION="1.0.00"

#List with all successive DB versions, in the order to be applied
DB_VERSION_LIST="1.0.06 1.0.07 1.0.08 1.0.09 1.0.10 1.0.11 1.0.12 1.0.14c 1.0.16 1.0.17 1.0.18 1.0.19"

for crt_ver in $DB_VERSION_LIST; do
	if [ "$db_schema_version" == "$PREV_DB_VERSION" ]; then
		sql_script_version=$crt_ver
		sql_script_file=${sql_script_path}/updateDB_to_${sql_script_version}.sql
		echo "Upgrading DB ver $PREV_DB_VERSION -> $sql_script_version ..."
		sqlite3 $db_file < $sql_script_file
		if [ $? != 0 ]; then
			echo      "ERROR upgrading DB to version $sql_script_version"
			log2flash "ERROR upgrading DB to version $sql_script_version"
		else
			echo      "DB upgrade OK to version $sql_script_version"
			log2flash "DB upgrade OK to version $sql_script_version"
		fi
		#next schema version for cascaded upgrade
		db_schema_version=$sql_script_version
	fi
	PREV_DB_VERSION=$crt_ver
done
