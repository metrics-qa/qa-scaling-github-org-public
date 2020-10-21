#!/usr/bin/env bash

# Schedule the export
set -x
EXPORT_SCHEDULE_MAIN=$(curl -X POST -H "PRIVATE-TOKEN: $GITLAB_METRICS_API_TOKEN" https://gitlab.metrics.ca/api/v4/projects/232/export)
set +x

echo $EXPORT_SCHEDULE_MAIN
EXPORT_MESSAGE_MAIN=$(echo $EXPORT_SCHEDULE_MAIN | jq -r .message)
# exit if the message wasn't successful
if [[ $EXPORT_MESSAGE_MAIN != "202 Accepted" ]]; then 
    echo "export main was not scheduled"; 
    exit 1; 
fi

# gather the status of the export
EXPORT_STATUS_MAIN=$(curl -H "PRIVATE-TOKEN: $GITLAB_METRICS_API_TOKEN" https://gitlab.metrics.ca/api/v4/projects/232/export | jq -r .export_status)
echo $EXPORT_STATUS_MAIN
# wait for the status to be finished
while [ $EXPORT_STATUS_MAIN != "finished" ] && [ $EXPORT_STATUS_MAIN != "failed" ]; do 
    sleep 10; 
    echo "waiting for export to complete"; 
    # gather the status of the export
    EXPORT=$(curl -H "PRIVATE-TOKEN: $GITLAB_METRICS_API_TOKEN" https://gitlab.metrics.ca/api/v4/projects/232/export)
    EXPORT_STATUS_MAIN=$(echo $EXPORT | jq -r .export_status)
done

# download the export tar ball
curl -H "PRIVATE-TOKEN: $GITLAB_METRICS_API_TOKEN" https://gitlab.metrics.ca/api/v4/projects/232/export/download --output qa-scaling-project.tar.gz

###### SUBMODULE ######

# Schedule the submodule export
set -x
EXPORT_SCHEDULE_SUBMODULE=$(curl -X POST -H "PRIVATE-TOKEN: $GITLAB_METRICS_API_TOKEN" https://gitlab.metrics.ca/api/v4/projects/177/export)
set +x

echo $EXPORT_SCHEDULE_SUBMODULE
EXPORT_MESSAGE_SUBMODULE=$(echo $EXPORT_SCHEDULE_SUBMODULE | jq -r .message)
# exit if the message wasn't successful
if [[ $EXPORT_MESSAGE_SUBMODULE != "202 Accepted" ]]; then 
    echo "export submodule was not scheduled"; 
    exit 1; 
fi

# gather the status of the export
EXPORT_STATUS_SUBMOD=$(curl -H "PRIVATE-TOKEN: $GITLAB_METRICS_API_TOKEN" https://gitlab.metrics.ca/api/v4/projects/177/export | jq -r .export_status)
echo $EXPORT_STATUS_SUBMOD
# wait for the status to be finished
while [ $EXPORT_STATUS_SUBMOD != "finished" ] && [ $EXPORT_STATUS_SUBMOD != "failed" ]; do 
    sleep 10; 
    echo "waiting for export to complete"; 
    # gather the status of the export
    EXPORT_STATUS_SUBMOD=$(curl -H "PRIVATE-TOKEN: $GITLAB_METRICS_API_TOKEN" https://gitlab.metrics.ca/api/v4/projects/177/export | jq -r .export_status)
done

# download the tar ball
curl -H "PRIVATE-TOKEN: $GITLAB_METRICS_API_TOKEN" https://gitlab.metrics.ca/api/v4/projects/177/export/download --output submodule.tar.gz