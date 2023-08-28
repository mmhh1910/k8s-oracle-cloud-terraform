# Docs
https://javiermugueta.blog/2023/03/17/velero-backups-in-oracle-cloud-kubernetes-engine-clusters-powered-by-verrazzano/
https://velero.io/docs/v1.12/contributions/oracle-config/
https://velero.io/docs/v1.12/customize-installation/#default-pod-volume-backup-to-file-system-backup

https://docs.oracle.com/en-us/iaas/Content/Identity/Tasks/managingcredentials.htm#create-secret-key

# File credentials-velero:
[default]
aws_access_key_id=...
aws_secret_access_key=...


# get home region
oci iam region-subscription list | jq -r '.data[0]."region-name"'

# get storage namespace name
oci os ns get | jq -r .data

# Complete install with node-agent daemon set and default pv backup with every backup:

region=$(oci iam region-subscription list | jq -r '.data[0]."region-name"')
object_storage_ns=$(oci os ns get | jq -r .data) 

velero install --provider aws --plugins velero/velero-plugin-for-aws:v1.7.1 --bucket velero --prefix velerobackup --use-volume-snapshots=false --secret-file ./credentials-velero --backup-location-config region=$region,s3ForcePathStyle="true",s3Url=https://$object_storage_ns.compat.objectstorage.$region.oraclecloud.com --use-node-agent --default-volumes-to-fs-backup

velero backup create backup-name

velero backup get 

velero backup describe backup-name --details

velero schedule create backup-schedule --schedule="0 3 * * *" --ttl 168h0m0s
