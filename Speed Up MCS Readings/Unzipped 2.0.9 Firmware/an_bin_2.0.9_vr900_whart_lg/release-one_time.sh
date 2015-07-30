#! /bin/sh

#only if there is in archive and not already updated
if [ -f an_sys_patch/mini_httpd ]; then
	rm -f /access_node/bin/mini_httpd
	mv an_sys_patch/mini_httpd /usr/bin/mini_httpd
	chmod +x /usr/bin/mini_httpd
fi

if [ -f an_sys_patch/Monitor_Host.db3 -a ! -f activity_files/Monitor_Host.db3 ]; then
	mv an_sys_patch/Monitor_Host.db3 /access_node/activity_files/Monitor_Host.db3
fi

[ -x updateDB.sh ] && updateDB.sh

[ -f /access_node/profile/gw_ini_cmds.ini ] && \
		mv -f /access_node/profile/gw_ini_cmds.ini /access_node/profile/gw_ini_cmds.ini_sav