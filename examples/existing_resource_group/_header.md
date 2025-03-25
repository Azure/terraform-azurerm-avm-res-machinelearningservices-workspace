# Deploy to existing resource group

This example provisions a publicly-accessible AML workspace with basic configuration that is deployed to an existing resource group. It can be used to demonstrate how to force purge of deleted workspaces, in contrast to the default behavior of a "soft delete". The "soft delete" results in the inability to create a new workspace with the same name until the workspace is purged.

## Verify the change in behavior

### Default: purge protection

1. `terraform apply -var "resource_group_name=<resource group name>"`
2. `terraform destroy -var "resource_group_name=<resource group name>" -target="module.azureml"` Plan shows only 1 resource to delete. Destroy succeeds.
3. `terraform apply -var "resource_group_name=<resource group name>"`. Plan shows only 1 resource to create. Apply fails with message "Soft-deleted workspace exists. Please purge or recover it."

### Force purge

1. `terraform apply -var "resource_group_name=<resource group name>" -var "force_purge_on_delete=true"`
2. `terraform destroy -var "resource_group_name=<resource group name>" -var "force_purge_on_delete=true" -target="module.azureml"` Plan shows only 1 resource to delete. Destroy succeeds.
3. `terraform apply -var "resource_group_name=<resource group name>" -var "force_purge_on_delete=true"`. Plan shows only 1 resource to create. Apply succeeds.
