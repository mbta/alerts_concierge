#!/bin/bash
set -e -x -u

# bash script should be called with aws environment (dev / dev-green / prod)
# other required configuration:
# * APP
# * DOCKER_REPO

awsenv=$1
appenv=$APP-$awsenv

githash=$(git rev-parse --short HEAD)
gitmsg=$(git log -1 --pretty=%s)

# debugging: output AWS CLI version
aws --version

# ensure the image exists on AWS. This command will fail if it does not.
aws ecr describe-images --region us-east-1 --repository-name $APP --image-ids "imageTag=git-$githash"

# get JSON describing task definition currently running on AWS
# use it as basis for new revision, but replace image with the one built above
current_task=$(aws ecs describe-task-definition --region us-east-1 --task-definition $appenv)
task_role=$(echo $current_task | jq -r '.taskDefinition.taskRoleArn')
task_execution_role=$(echo $current_task | jq -r '.taskDefinition.executionRoleArn')
task_volumes=$(echo $current_task | jq '.taskDefinition.volumes')
task_network_mode=$(echo $current_task | jq -r '.taskDefinition.networkMode')
task_compatibilities=$(echo $current_task | jq -r '.taskDefinition.requiresCompatibilities')
task_cpu=$(echo $current_task | jq -r '.taskDefinition.cpu')
task_memory=$(echo $current_task | jq -r '.taskDefinition.memory')
task_containers=$(echo $current_task | \
  jq '.taskDefinition.containerDefinitions' | \
  jq --arg gh "$githash" --arg dr "$DOCKER_REPO" 'map(.image="\($dr):git-\($gh)")' | \
  jq --arg gm "$gitmsg" 'map(.environment=(
    .environment |
    map(select(.name != "LAST_COMMIT_MESSAGE")) |
    . + [{name: "LAST_COMMIT_MESSAGE", value: "\($gm)"}]
  ))')

# safeguard against a known issue where the retrieved container definition is
# missing the `secrets` key, causing the new version of the app to be missing
# all its secrets and unable to start. this command will exit non-zero if the
# `secrets` key is not present, aborting the script.
! echo $task_containers | jq '.[0] | .secrets' | grep '^null$'

aws ecs register-task-definition \
  --family $appenv \
  --region us-east-1 \
  --task-role-arn $task_role \
  --execution-role-arn $task_execution_role \
  --volumes "$task_volumes" \
  --network-mode $task_network_mode \
  --requires-compatibilities "$task_compatibilities" \
  --cpu $task_cpu \
  --memory $task_memory \
  --container-definitions "$task_containers"

newrevision=$(aws ecs describe-task-definition --region us-east-1 --task-definition $appenv | jq '.taskDefinition.revision')

expected_count=$(aws ecs list-tasks --region us-east-1 --cluster $APP --service $appenv-a| jq '.taskArns | length')

if  [[ $expected_count = "0" ]]; then
    aws ecs update-service --region us-east-1 --cluster $APP --service $appenv-a --task-definition $appenv:$newrevision
    echo Environment $APP:$appenv is not running!
    echo
    echo We updated the definition: you can manually set the desired instances to 1.
    exit 1
fi

function task_count_eq {
    local task_count
    task_count=$(aws ecs list-tasks --region us-east-1 --cluster $APP --service $appenv-a | jq '.taskArns | length')
    [[ $task_count = "$1" ]]
}

function exit_if_too_many_checks {
  if [[ $checks -ge 50 ]]; then exit 1; fi
  sleep 5
  checks=$((checks+1))
}

# by setting the desired count to 0, ECS will kill the task that the ECS service is running
# allowing us to update it and start the new one. Check every 5 seconds to see if it's dead
# yet (AWS issues `docker stop` and it could take a moment to spin down). If it's still running
# after several checks, something is wrong and the script should die.
aws ecs update-service --region us-east-1 --cluster $APP --service $appenv-a --desired-count 0
checks=0
while task_count_eq $expected_count; do
    echo Shutting down old task...
    exit_if_too_many_checks
done

# Update the ECS service to use the new revision of the task definition. Then update the desired
# count back to 1, so the container instance starts up the task. Check periodically to see if the
# task is running yet, and signal deploy failure if it doesn't start up in a reasonable time.
aws ecs update-service --region us-east-1 --cluster $APP --service $appenv-a --task-definition $appenv:$newrevision
aws ecs update-service --region us-east-1 --cluster $APP --service $appenv-a --desired-count 1

checks=0
until task_count_eq $expected_count; do
    echo Starting up new task...
    exit_if_too_many_checks
done
