#! /bin/bash

#TODO Create variables from hard coded names

az login

az group create --name iot-pareto --location westus

az extension add --name azure-iot
az extension add --upgrade --name webpubsub




az iot hub create --name iot-pareto-hub --resource-group iot-pareto --sku S1
az iot hub device-identity create --device-id iot-pareto-device --hub-name iot-pareto-hub
az iot hub device-identity connection-string show --device-id iot-pareto-device --hub-name iot-pareto-hub

# Event Hub-compatible endpoint
# Event Hub-compatible name
export hubname=$(az iot hub show  --name iot-pareto-hub | jq .name)
# Event Hub-compatible endpoint
export hubendpoint=$(az iot hub show  --name iot-pareto-hub | jq .properties.eventHubEndpoints.events.endpoint)

export namespaceName="aruba$RANDOM"
az eventhubs namespace create --name $namespaceName --resource-group  "iot-pareto" -l "WestUS"

export eventhubName="arubahub$RANDOM"
# Just defaulted partitions to 0..3
az eventhubs eventhub create --name $eventhubName --resource-group "iot-pareto" --namespace-name $namespaceName
# Added Listen and Send as rights
az eventhubs eventhub authorization-rule create --authorization-rule-name aruba-hub-rule --eventhub-name $eventhubName --namespace-name $namespaceName --resource-group "iot-pareto" --rights Listen Send

#export pubsubName="pubsub$RANDOM"
export pubsubName="pareto-anywhere"
az webpubsub create --name $pubsubName --resource-group "iot-pareto" --location "WestUS" --sku Free_F1

export psendpoint=$(az webpubsub key show  --name "pareto-anywhere"  --resource-group "iot-pareto" --query primaryConnectionString --output tsv)

az eventhubs eventhub authorization-rule keys list --resource-group "iot-pareto" --namespace-name $namespaceName --eventhub-name $eventhubName --name aruba-hub-rule

export saName="arubastorage$RANDOM"
az storage account create --name $saName --resource-group "iot-pareto" --sku Standard_LRS --kind BlobStorage --access-tier Hot

storageConnection=$(az storage account show-connection-string --name $saName --resource-group "iot-pareto" --output tsv)

sendAppSetting=$(az eventhubs eventhub authorization-rule keys list --resource-group "iot-pareto" --namespace-name $namespaceName --eventhub-name $eventhubName --name aruba-hub-rule | jq  .primaryConnectionString)

psendpoint=$(az webpubsub key show  --name "pareto-anywhere"  --resource-group "iot-pareto" --query primaryConnectionString --output tsv)

# Stitch together the resource file
cat <<EOF > ./local.settings.json
{
  "IsEncrypted": false,
  "Values": {
    "FUNCTIONS_WORKER_RUNTIME": "node",
    "AzureWebJobsStorage": "$storageConnection",
    "EventHubConnectionString": $hubendpoint,
    "EventHubSendAppSetting": $sendAppSetting,
    "WebPubSubConnectionString": "$psendpoint",
    "iot_hub_name": "$hubname",
    "event_hub_name": "$eventhubName",
    "web_pub_sub_hub_name": "$pubsubName"
  }
}
EOF
