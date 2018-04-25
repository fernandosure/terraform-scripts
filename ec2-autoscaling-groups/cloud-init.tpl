#!/bin/bash
echo ECS_CLUSTER=${ecs_cluster} >> /etc/ecs/ecs.config
echo ECS_AVAILABLE_LOGGING_DRIVERS=[\"json-file\",\"syslog\",\"gelf\"] >> /etc/ecs/ecs.config
echo ECS_ENGINE_AUTH_TYPE=dockercfg >> /etc/ecs/ecs.config
echo ECS_ENGINE_AUTH_DATA={\"https://index.docker.io/v1/\":{\"auth\":\"${docker_auth_token}\"}} >> /etc/ecs/ecs.config
sudo stop ecs
sudo start ecs
