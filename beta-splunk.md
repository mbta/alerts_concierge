# Splunk Integration

#### CloudWatch Permissions

The `alerts-concierge` role requires the following inline-policy:

```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams"
    ],
      "Resource": [
        "arn:aws:logs:*:*:*"
    ]
  }
 ]
}
```

#### Increase Erlang Log Rotation Settings

By default, Erlang's log rotation file size is very small, change it to 100MB:

```
RUN_ERL_LOG_MAXSIZE=100000000
```

#### Install CloudWatch Agent

```
curl https://s3.amazonaws.com/aws-cloudwatch/downloads/latest/awslogs-agent-setup.py | sudo python ./awslogs-agent-setup.py --region us-east-1
```

#### Cloudwatch Local Configuration

Put the following in `/var/awslogs/etc/awslogs.conf`:

```
[general]
state_file = /var/awslogs/state/agent-state

[erlang.log]
datetime_format = %Y-%m-%d %H:%M:%S
file = /home/ubuntu/app/concierge_site/var/log/erlang.log*
buffer_duration = 5000
log_stream_name = {instance_id}
initial_position = start_of_file
log_group_name = /home/ubuntu/app/concierge_site/application.log
```

#### Configure CloudWatch Agent to Start on Boot

Put the following in `/etc/systemd/system/awslogs.service`:

```
[Unit]
Description=Service for CloudWatch Logs agent
After=rc-local.service

[Service]
Type=simple
Restart=always
KillMode=process
TimeoutSec=infinity
PIDFile=/var/awslogs/state/awslogs.pid
ExecStart=/var/awslogs/bin/awslogs-agent-launcher.sh --start --background --pidfile $PIDFILE --user awslogs --chuid awslogs &amp;

[Install]
WantedBy=multi-user.target
```

#### Start the Service

```
systemctl start awslogs.service
```

#### Connect to Splunk

Follow directions from the Wiki: https://github.com/mbta/wiki/blob/master/website/logs/splunk.md
