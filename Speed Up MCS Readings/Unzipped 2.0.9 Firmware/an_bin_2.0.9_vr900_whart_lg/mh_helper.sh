#!/bin/sh




tmpDB="${NIVIS_TMP}/Monitor_Host.db3"
currentDB="${NIVIS_ACTIVITY_FILES}/Monitor_Host.db3"
fixtureDB="${NIVIS_FIRMWARE}/Monitor_Host.db3.fixture"

elog2flash() 
{
	log2flash "$@"
	echo $@
}

	

# $1 file to copy
# $2 file to copy to

safe_copy()
{
	local file_from=$1
	local file_to=$2
	local file_to_tmp=${file_to}.tmp

	echo "Copy $file_from -> $file_to ... start"
	cp $file_from $file_to_tmp	

	if [ $? -eq 0 ]; then
		
		mv $file_to_tmp $file_to
		
		if [ $? -eq 0 ]; then
			echo "Copy $file_from -> $file_to ... OK"
		else
			rm -f $file_to_tmp
			elog2flash "Copy $file_from -> $file_to ... stage2 FAILED"	
		fi
	else
		rm -f $file_to_tmp
		elog2flash "Copy $file_from -> $file_to ... stage1 FAILED"
	fi
	
}


# $1 db_file
# $2 sql query
exec_sql_with_err_2_flash() 
{
	local db_file=$1
	local sql=$2
	
	out_var_exec=`echo "$sql" | sqlite3 $db_file 2>&1`
	ret_code=$?
	if [ $ret_code -ne 0 ]; then
		 elog2flash "ERROR db_file=$db_file sql=$sql\n\t output=$out_var_exec"
	else
		echo "$out_var_exec"
	fi	

	return $ret_code
}


# $1 table name
# $2 tables list
is_table_in_list()
{
	local table_seek=$1
	local table_list=$2
	local result=1

	for db3_table in $table_list; do
		if  [ "$db3_table" == "$table_seek" ]; then
			#echo "table: $table_seek was found!"
			result=0
			break
		fi
	done

	return $result
}

# $1 db_file
validate_db_against_fixture()
{
	local db_file=$1
	local db_tables
	local db_fixture_tables
	local table_crt
	local count
	
	db_tables=`exec_sql_with_err_2_flash $db_file ".table "`
	[ $? -ne 0 ] && return 1

	db_fixture_tables=`exec_sql_with_err_2_flash $fixtureDB ".table "`
	[ $? -ne 0 ] && return 1

	count=0
	for table_crt in $db_fixture_tables; do
	
		#echo "table=$table_crt"
		is_table_in_list $table_crt "$db_tables"
		if [ $? -eq 1 ]; then
			elog2flash "table: $table_crt was not found! in $db_file"		
			count=$(expr $count + 1)
		fi
	done	
	
	if [ $count -gt 0 ]; then
		elog2flash "validate_db FAILED: $count tables missing"		
		return 1
	fi

	return 0	
}


# $1 -- db file name
validate_db()
{
	local file_db=$1

	#validate the copied DB
	out_var=`exec_sql_with_err_2_flash $file_db "PRAGMA integrity_check;"`
	ret_code=$?

	[ ! "$out_var" = "ok" ] && ret_code=1

	if [ $ret_code -eq 0 -a ! -f ${NIVIS_TMP}skip_db_struct_validate ]; then
		validate_db_against_fixture $file_db
		ret_code=$?
	fi
	
	return $ret_code
}

mh_putDBToTmp() 
{
	if [ ! -s "${currentDB}" -o -h "${currentDB}" ]; then
		elog2flash "No MH DB in ${NIVIS_ACTIVITY_FILES}. Copy ${fixtureDB} -> ${tmpDB}"
		rm -rf ${currentDB}
		safe_copy "${fixtureDB}" "${tmpDB}"
		return
	fi

	rm -rf "${tmpDB}"
	safe_copy "${currentDB}" "${tmpDB}"

	
	validate_db ${tmpDB}
	if [ $? -ne 0 ]; then
		safe_copy "${fixtureDB}" "${tmpDB}"
	fi

	out_var=`exec_sql_with_err_2_flash ${tmpDB} "VACUUM;"`
	if [ $? -ne 0 ]; then
		safe_copy "${fixtureDB}" "${tmpDB}"
	fi
}

mh_getDBFromTmp() 
{
	if [ ! -f "${tmpDB}" ]; then
		# This is normal flow for manual stop.sh or for web upgrade which does stop.sh twice:
		# one before activate.sh, and one at the end of activate.sh->start.sh->stop.sh
		return	# Be silent
	fi

	#validate the db before copying
	if [ -h "${tmpDB}" -o ! -f "${tmpDB}" -o "`du ${tmpDB}|cut -f1 -d' '`" == "0" ]; then
		elog2flash "Invalid MH DB in ${NIVIS_TMP}. Not changing ${currentDB}"
		return
	fi
	
	validate_db ${tmpDB}

	if [ "$?" != "0" ]; then
		elog2flash "MH DB ${tmpDB} validation check failed. Not changing ${currentDB}"
		return
	fi

	#vacuum DB
	out_var=`exec_sql_with_err_2_flash ${tmpDB} "VACUUM;"`
	if [ "$?" != "0" ]; then
		elog2flash "MH DB ${tmpDB} VACUUM failed. Not changing ${currentDB}"
		return
	fi

	#get the db from tmp
	safe_copy ${tmpDB} ${currentDB}

	# just for a while as debug help
	validate_db ${currentDB}

	 [ -f ${NIVIS_TMP}skip_db_struct_validate ] && rm -rf ${NIVIS_TMP}skip_db_struct_validate
}
