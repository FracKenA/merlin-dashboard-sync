#!/usr/bin/env bash
#
# OP5 Script to sync dashboards to peered master
#
# License: GPL
# Copyright (c) 2018 Ken Dobbins
# Author: Ken Dobbins <kdobbins@op5.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 3 as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

export_sql_tables()
{
asmonitor \
    mysqldump -u root --add-drop-table merlin \
        dashboards \
        dashboard_widgets \
        ninja_report_comments \
        custom_vars \
        ninja_saved_filters \
        ninja_settings \
        permission_quarks \
        saved_reports \
        saved_reports_objects \
        saved_reports_options \
    > /opt/monitor/var/merlin_database_sync.sql
}

sync_sql_file_to_peers ()
{
for node in $(mon node list --type=peer); \
    do asmonitor \
        scp /opt/monitor/var/merlin_database_sync.sql \
            "$node":/opt/monitor/var/merlin_database_sync.sql;
    done;
}

import_sql_file_on_peers ()
{
for node in $(mon node list --type=peer); \
    do asmonitor \
        ssh "$node" 'mysql -u root merlin < /opt/monitor/var/merlin_database_sync.sql';
    done;
}

##
# Removed to test checksum alternative
##
# dump_remote_database_tables ()
# {
# for node in $(mon node list --type=peer); \
#     do asmonitor \
#         mysqldump -u root --add-drop-table merlin \
#             dashboards \
#             dashboard_widgets \
#             ninja_report_comments \
#             custom_vars \
#             ninja_saved_filters \
#             ninja_settings \
#             permission_quarks \
#             saved_reports \
#             saved_reports_objects \
#             saved_reports_options \
#         > /opt/monitor/var/merlin_database_sync_verify.sql;
#     done;
# }

compare_remote_database ()
{
for node in $(mon node list --type=peer); \
    do
        ##
        #Removed to test checksum alternative
        ##
        # local OUTPUT
        # OUTPUT=$(asmonitor ssh "$node" 'cmp -s /opt/monitor/var/merlin_database_sync.sql /opt/monitor/var/merlin_database_sync_verify.sql')
        # IF [[ "$OUTPUT" -eq "0" ]]; 
        #     then
        #         echo "$node sync succeeded" >> /opt/monitor/var/merlin_database_sync.log
        #     else
        #         echo "$node sync failed" >> /opt/monitor/var/merlin_database_sync.log
        # FI
        local CHECKSUM_REMOTE
        CHECKSUM_REMOTE=$(asmonitor \
            ssh "$node" \
            'mysql -u root -e "\
            checksum table \
            merlin.dashboards, \
            merlin.dashboard_widgets, \
            merlin.ninja_report_comments, \
            merlin.custom_vars, \
            merlin.ninja_saved_filters, \
            merlin.ninja_settings, \
            merlin.permission_quarks, \
            merlin.saved_reports, \
            merlin.saved_reports_objects, \
            merlin.saved_reports_options \
            "')
        CHECKSUM_LOCAL=$(asmonitor \
            mysql -u root -e " \
            checksum table merlin.dashboards, \
            merlin.dashboard_widgets, \
            merlin.ninja_report_comments, \
            merlin.custom_vars, \
            merlin.ninja_saved_filters, \
            merlin.ninja_settings, \
            merlin.permission_quarks, \
            merlin.saved_reports, \
            merlin.saved_reports_objects, \
            merlin.saved_reports_options \
            ")
        IF [[ "$CHECKSUM_LOCAL" == "$CHECKSUM_REMOTE" ]]; 
            then
                echo "$node sync succeeded" >> /opt/monitor/var/merlin_database_sync.log
            else
                echo "$node sync failed" >> /opt/monitor/var/merlin_database_sync.log
        FI
    done;
}


export_sql_tables
sync_sql_file_to_peers
import_sql_file_on_peers
dump_remote_database_tables
compare_remote_database