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

aws ecs update-service --region us-east-1 --cluster $APP --service $appenv --task-definition $appenv:$newrevision --force-new-deployment
