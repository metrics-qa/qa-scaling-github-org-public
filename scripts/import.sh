#!/usr/bin/env bash

# trigger the import main with forced overwrite
IMPORT_MAIN=$(curl -X POST -H "PRIVATE-TOKEN: $API_TOKEN" --form "path=qa-scaling-project" --form "file=@qa-scaling-project.tar.gz" --form "overwrite=true" https://gitlab.$CLUSTER.metrics.ca/api/v4/projects/import) 
IMPORT_MAIN_ID=$(echo $IMPORT_MAIN | jq -r .id)
echo $IMPORT_MAIN
# trigger the import submodule with forced overwrite
IMPORT_SUB=$(curl -X POST -H "PRIVATE-TOKEN: $API_TOKEN" --form "path=submod-test" --form "file=@submodule.tar.gz" --form "overwrite=true" https://gitlab.$CLUSTER.metrics.ca/api/v4/projects/import) 
IMPORT_SUB_ID=$(echo $IMPORT_SUB | jq -r .id)
echo $IMPORT_SUB

# get the status of the main import
STATUS=$(curl -H "PRIVATE-TOKEN: $API_TOKEN" https://gitlab.$CLUSTER.metrics.ca/api/v4/projects/$IMPORT_MAIN_ID/import | jq -r .import_status)
echo "The import of qa-scaling-project has status: $STATUS"
# wait for import status to be 'finished'
while [ $STATUS != "finished" ] && [ $STATUS != "failed" ]; do 
    sleep 10; 
    echo "waiting for import to complete"; 
    # get the status of the import
    STATUS=$(curl -H "PRIVATE-TOKEN: $API_TOKEN" https://gitlab.$CLUSTER.metrics.ca/api/v4/projects/$IMPORT_MAIN_ID/import | jq -r .import_status)
    echo $STATUS
done
if [ $STATUS == "failed" ]; then
    curl -H "PRIVATE-TOKEN: $API_TOKEN" https://gitlab.$CLUSTER.metrics.ca/api/v4/projects/$IMPORT_MAIN_ID/import
    exit 1
fi
curl -X POST -H "PRIVATE-TOKEN: $API_TOKEN" "https://gitlab.$CLUSTER.metrics.ca/api/v4/projects/$IMPORT_MAIN_ID/repository/tags?tag_name=qa_latest&ref=master"


# get the status of the submodule import
STATUS=$(curl -H "PRIVATE-TOKEN: $API_TOKEN" https://gitlab.$CLUSTER.metrics.ca/api/v4/projects/$IMPORT_SUB_ID/import | jq -r .import_status)
echo "The import of submod-test has status: $STATUS"
# wait for import status to be 'finished'
while [ $STATUS != "finished" ] && [ $STATUS != "failed" ]; do 
    sleep 10; 
    echo "waiting for import to complete"; 
    # get the status of the import
    STATUS=$(curl -H "PRIVATE-TOKEN: $API_TOKEN" https://gitlab.$CLUSTER.metrics.ca/api/v4/projects/$IMPORT_SUB_ID/import | jq -r .import_status)
    echo $STATUS
done
if [ $STATUS == "failed" ]; then
    curl -H "PRIVATE-TOKEN: $API_TOKEN" https://gitlab.$CLUSTER.metrics.ca/api/v4/projects/$IMPORT_MAIN_ID/import
    exit 1
fi
