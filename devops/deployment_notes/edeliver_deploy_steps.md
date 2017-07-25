# Deploying a single release with Edeliver

## Deploying a Phoenix Release

Make sure you have your AWS ssh key. If it's called `~/.ssh/aws_mbta`, you
can add it to your ssh agent with `ssh-add ~/.ssh/aws_mbta`

1. Increment the version number in `rel/config.exs` and make a release on github.

2. Build your release:

`DEPLOY_ENVIRONMENT=<environment> mix edeliver build release`

This will build your release from your local master. Reference the edeliver docs
to see how to build particular tags or branches.

3. Deploy release:

`mix edeliver deploy release to <environment>`

4. Run migration if needed

5. Restart server:

Make sure the release is the one in the beam process. Do the same with the other app server.

You can see if the nodes are responding with the following command:

`mix edeliver ping staging` (or production)

You'll see something like:

```
EDELIVER ALERT_PROCESSOR WITH PING COMMAND

-----> pinging staging servers



staging node: 1

  user    : ubuntu
  host    : xx.xx.xxx.xxx
  path    : /home/ubuntu/web
  response: pong

staging node: 0

  user    : ubuntu
  host    : xx.xx.xxx.xxx
  path    : /home/ubuntu/web
  response: pong
```

In the case that one of the servers does not respond with a pong, the best option is to restart manually.

## Running commands on the app server directly (if needed)

```
cd ~/web/alerts_concierge/releases/

<release>/alerts_concierge.sh stop
<release>/alerts_concierge.sh console
<release>/alerts_concierge.sh start
```

To confirm the app has started:

```
ps aux | grep beam
```
