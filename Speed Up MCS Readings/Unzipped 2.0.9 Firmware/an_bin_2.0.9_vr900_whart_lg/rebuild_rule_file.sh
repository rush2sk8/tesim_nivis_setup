#!/bin/sh

#do not rm /tmp/rule_file if scheduler or node_connection is running

rule_file_mgr ${NIVIS_PROFILE}rule_file.cfg /access_node/one_time_cmd.cfg

