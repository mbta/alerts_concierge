#!/bin/bash
set -e -u

# bash script should be called with aws environment (dev / dev-green / prod)
# other required configuration:
# * APP
# * DOCKER_REPO

awsenv=$1
appenv=$APP-$awsenv

githash=$(git rev-parse --short HEAD)
gitmsg=$(git log -1 --pretty=%s)

export AWS_DEFAULT_REGION="us-east-1"

echo "AWS CLI version: $(aws --version)"

echo "Ensuring image exists on ECR..."
aws ecr describe-images --repository-name $APP --image-ids "imageTag=git-$githash" && echo "Success."

echo "Creating new task definition..."
current_task=$(aws ecs describe-task-definition --task-definition $appenv)
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
# all its secrets and unable to start
if echo $task_containers | jq '.[0] | .secrets' | grep '^null$'; then
  echo "Aborting: new task definition is missing secrets. Try deploying again."
  exit 1
fi

echo "Registering new task definition..."
aws ecs register-task-definition \
  --family $appenv \
  --task-role-arn $task_role \
  --execution-role-arn $task_execution_role \
  --volumes "$task_volumes" \
  --network-mode $task_network_mode \
  --requires-compatibilities "$task_compatibilities" \
  --cpu $task_cpu \
  --memory $task_memory \
  --container-definitions "$task_containers"

function check_deployment_complete() {
  # extract task counts and test whether they match the desired state

  local deployment_details
  local desired_count
  local pending_count
  local running_count
  deployment_details="${1}"

  # get and print current task counts
  desired_count="$(echo "${deployment_details}" | jq -r '.desiredCount')"
  pending_count="$(echo "${deployment_details}" | jq -r '.pendingCount')"
  running_count="$(echo "${deployment_details}" | jq -r '.runningCount')"
  echo "Desired count: ${desired_count}"
  echo "Pending count: ${pending_count}"
  echo "Running count: ${running_count}"
  # if the number of running tasks equals the number of desired tasks, then we're all set
  [ "${pending_count}" -eq "0" ] && [ "${running_count}" -eq "${desired_count}" ]
}

echo "Updating service with new revision..."
new_revision=$(aws ecs describe-task-definition --task-definition $appenv | jq '.taskDefinition.revision')
aws ecs update-service --cluster $APP --service $appenv-a --task-definition $appenv:$new_revision

# monitor the cluster for status
while true; do
  # get the service details
  service_status="$(aws ecs describe-services --cluster="${APP}" --services="${appenv}-a")"
  # exctract the details for the new deployment (status PRIMARY)
  new_deployment="$(echo "${service_status}" | jq -r '.services[0].deployments[] | select(.status == "PRIMARY")')"

  # check whether the new deployment is complete
  if check_deployment_complete "${new_deployment}"; then
    echo "Deployment complete."
    break
  else
    # extract deployment id
    new_deployment_id="$(echo "${new_deployment}" | jq -r '.id')"
    # find any tasks that may have stopped unexpectedly
    stopped_tasks="$(aws ecs list-tasks --cluster "${APP}" --started-by "${new_deployment_id}" --desired-status "STOPPED" | jq -r '.taskArns')"
    stopped_task_count="$(echo "${stopped_tasks}" | jq -r 'length')"
    if [ "${stopped_task_count}" -gt "0" ]; then
      # if there are stopped tasks, print the reason they stopped and then exit
      stopped_task_list="$(echo "${stopped_tasks}" | jq -r 'join(",")')"
      stopped_reasons="$(aws ecs describe-tasks --cluster "${APP}" --tasks "${stopped_task_list}" | jq -r '.tasks[].stoppedReason')"
      echo "The deployment failed because one or more containers stopped running. The reasons given were:"
      echo "${stopped_reasons}"
      exit 1
    fi
    # wait, then loop
    echo "Waiting for new tasks to start..."
    sleep 5
  fi
done

# confirm that the old deployment is torn down
while true; do
  # get the service details
  service_status="$(aws ecs describe-services --cluster="${APP}" --services="${appenv}-a")"
  # extract the details for any old deployments (status ACTIVE)
  deployment="$(echo "${service_status}" | jq -r --compact-output '.services[0].deployments[] | select(.status == "ACTIVE")')"
  total_tasks=0

  # extract deployment id
  old_deployment_id="$(echo "${deployment}" | jq -r '.id')"
  # count tasks associated with the old deployment that are still running
  running_task_count="$(aws ecs list-tasks --cluster "${APP}" --started-by "${old_deployment_id}" --desired-status "RUNNING" | jq -r '.taskArns | length')"
  total_tasks=$((total_tasks+running_task_count))

  echo "Old tasks still running: ${total_tasks}"
  # if no running tasks, break
  if [ "$total_tasks" -eq "0" ]; then
    echo "Done."
    break
  else
    echo "Waiting for old tasks to be stopped..."
    sleep 5
  fi
done
