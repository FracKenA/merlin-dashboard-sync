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
# along with this program.  if not, see <http://www.gnu.org/licenses/>.


# Files
merlin_log="/opt/monitor/var/merlin_dashboard_database_sync.log"
merlin_sql="/opt/monitor/var/merlin_database_sync.sql"

# Export local SQL tables
export_sql_tables() {
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
    > "$merlin_sql"
}

# Push SQL tables to remote peers
sync_and_import_sql_file_to_peers () {
    for node in $(mon node list --type=peer)
    do
        asmonitor \
        cat "$merlin_sql" | ssh "$node" 'mysql -u root merlin'
    done
}

# Get checksum of remote SQL tables
check_remote_checksum () {
    local checksum_remote
    checksum_remote=$(asmonitor \
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
}

# Get checksum of local SQL tables
check_local_checksum () {
    checksum_local=$(asmonitor \
    mysql -u root -e " \
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
    ")
}

# Compare local & remote merlin DB-tables then sync if needed
compare_remote_database_checksum_and_sync () {
    for node in $(mon node list --type=peer); \
    do
        check_remote_checksum
        check_local_checksum
        # Only push updates if data has changed
        if [[ "$checksum_local" == "$checksum_remote" ]]
            then
                echo "[$(date "+%F %T")] $node is in sync." >> "$merlin_log"
            else
                echo "[$(date "+%F %T")] $node not in sync." >> "$merlin_log"
                export_sql_tables
                sync_and_import_sql_file_to_peers
                check_remote_checksum
        fi
        
        # Log events
        if [[ "$checksum_local" == "$checksum_remote" ]]
            then
                echo "[$(date "+%F %T")] $node sync corrected." >> "$merlin_log"
            else
                echo "[$(date "+%F %T")] $node sync failed." >> "$merlin_log"    
        fi
        
    done
}

# Compare local & remote merlin DB-tables dry run
compare_remote_database_checksum () {
    for node in $(mon node list --type=peer)
    do
        check_remote_checksum
        check_local_checksum
        if [[ "$checksum_local" == "$checksum_remote" ]]
            then
                echo "[$(date "+%F %T")] $node is in sync."
            else
                echo "[$(date "+%F %T")] $node not in sync."
        fi
        
    done
}

# Logic to perform sync or dryrun
if [[ -z $1 ]]
    then
        compare_remote_database_checksum
    elif [[ $1 == sync]]
        compare_remote_database_checksum_and_sync
    else
        echo "Sync not set, performing dry run"
        echo "use \"sync-merlin-dashboard.sh\" sync to perform sync"
        compare_remote_database_checksum
fi
