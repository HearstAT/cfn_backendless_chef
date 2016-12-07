#!/bin/bash -xev

################################
# USAGE:
#
# ./newrelic.sh license_key app_name db_endpoint db_user db_name
#
################################

LICENSE_KEY=${1}
APP_NAME=${2}
DBURL=${3}
DBUSER=${4}
DBNAME=${5}

echo 'deb http://apt.newrelic.com/debian/ newrelic non-free' >> /etc/apt/sources.list.d/newrelic.list || error_exit "Failed to add New Relic to sources"
wget -O- https://download.newrelic.com/548C16BF.gpg | apt-key add - || error_exit "Failes to add New Relic GPG Source Key"
apt-get update && apt-get install newrelic-sysmond || error_exit "Failed to install new relic system monitor"

nrsysmond-config --set license_key=${LICENSE_KEY} || error_exit "Failed to set New Relic License on System Monitor"

pip install newrelic-plugin-agent || error_exit "Failed to install newrelic plugin agent"

cat > '/etc/newrelic/newrelic-plugin-agent.cfg' << EOF
---
Application:
  license_key: ${LICENSE_KEY}
  poll_interval: 60

  elasticsearch:
    name: ${APP_NAME}
    host: 127.0.0.1
    port: 8080

  nginx:
    name: ${APP_NAME}
    host: 127.0.0.1
    port: 9999
    path: /nginx_status

  postgresql:
    host: ${DBURL}
    port: 5432
    user: ${DBUSER}
    dbname: ${DBNAME}
    superuser: True

  Daemon:
  user: newrelic
  pidfile: /var/run/newrelic/newrelic-plugin-agent.pid

  Logging:
  formatters:
    verbose:
      format: '%(levelname) -10s %(asctime)s %(process)-6d %(processName) -15s %(threadName)-10s %(name) -25s %(funcName) -25s L%(lineno)-6d: %(message)s'
  handlers:
    file:
      class : logging.handlers.RotatingFileHandler
      formatter: verbose
      filename: /var/log/newrelic/newrelic-plugin-agent.log
      maxBytes: 10485760
      backupCount: 3
  loggers:
    newrelic-plugin-agent:
      level: INFO
      propagate: True
      handlers: [console, file]
    requests:
      level: ERROR
      propagate: True
      handlers: [console, file]
EOF

pip install newrelic_plugin_agent[postgresql]

cat > '/lib/systemd/system/newrelic-plugin-agent.service' << EOF
[Unit]
Description=newrelic-plugin-agent

[Service]
Type=forking
PrivateTmp=yes
User=newrelic
Group=newrelic
PermissionsStartOnly=true
PIDFile=/var/run/newrelic/newrelic-plugin-agent.pid
ExecStartPre=/bin/mkdir -p /var/run/newrelic /var/log/newrelic
ExecStartPre=/bin/rm -f /var/run/newrelic/newrelic-plugin-agent.pid
ExecStartPre=/bin/chown -R newrelic:newrelic /var/run/newrelic
ExecStart=/usr/bin/newrelic-plugin-agent -c /etc/newrelic/newrelic-plugin-agent.cfg
ExecStop=/bin/kill -INT $MAINPID
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOF

cat > '/root/newrelic.yml' << EOF
production:
  license_key: ${LICENSE_KEY}
  app_name: ${NewRelicAppName}
  agent_enabled: true
  monitor_mode: true
EOF

cp -f /root/newrelic.yml /var/opt/chef-manage/etc/
cp -f /root/newrelic.yml /opt/opscode/embedded/service/oc_id/config/

systemctl enable newrelic-sysmond || error_exit "Failed to enable New Relic System Monitor"
systemctl enable newrelic-plugin-agent || error_exit "Failed to Enable New Relic Plugin Agent"

systemctl start newrelic-sysmond || error_exit "Failed to Restart New Relic System Monitor"
systemctl start newrelic-plugin-agent || error_exit "Failed to start New Relic Plugin Agent"
