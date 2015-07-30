#!/bin/sh
#handle uploading of rule_file.cfg

log2flash "AN Rule file updated"

mv rule_file.cfg ${NIVIS_PROFILE}rule_file.cfg
rule_file_mgr ${NIVIS_PROFILE}rule_file.cfg
