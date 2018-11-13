# Merlin Dashboard and Filter One Way Replication

**This script is provided with no expressed warranty or support.  For assistance please contact your OP5 Account manager to get in touch with OP5's Professional Services.**
** You can contact your account manager at the following link. [Contact us at OP5](https://www.op5.com/contact-us/)**

## Purpose
This script is designed to copy all the required mariadb tables required to have your dashboards, filters and reports duplicated on all peers.

## How to use
This script needs to be placed somewhere that the monitor users has access executable permissions similar to the below directions.

    # wget https://raw.githubusercontent.com/OP5-Employee/merlin-dashboard-sync/master/sync-merlin-dashboard.sh
    # cp ./sync-merlin-dashboard.sh /opt/monitor/
    # chown monitor:apache /opt/monitor/sync-merlin-dashboard.sh
    # chmod a+x /opt/monitor/sync-merlin-dashboard.sh
    # cat "15 */4 * * * monitor /opt/monitor/sync-merlin-dashboard.sh" > /etc/cron.d/merlin-database-sync.cron
## Known Issues
This script does not perform any verification of the tasks performed.
