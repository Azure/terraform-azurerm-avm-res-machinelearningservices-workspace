<!-- BEGIN_TF_DOCS -->
# Azure Machine Learning Workspace Connection

This module provisions a connection between a service and an Azure Machine Learning Workspace / AI Foundry Hub / AI Foundry Project.

## Usage

### Example - AI Services

```hcl
module "connections" {
  source = "Azure/avm-res-machinelearningservices-workspace/azurerm//modules/connection"

  category      = "AIServices"
  credentials   = null
  shared_by_all = true
  target        = "<cog services endpoint>"
  auth_type     = "AAD"
  metadata = {
    apiType    = "Azure"
    resourceId = "<cog services account resource id>"
  }
  name         = "aiservicesaihub1"
  workspace_id = "<AI Foundry hub resource id>"
}
```

### Example - Azure OpenAI

```hcl
module "connections" {
  source = "Azure/avm-res-machinelearningservices-workspace/azurerm//modules/connection"

  category      = "AzureOpenAI"
  credentials   = null
  shared_by_all = true
  target        = "<cog services endpoint>"
  auth_type     = "AAD"
  metadata = {
    apiType    = "Azure"
    resourceId = "<cog services account resource id>"
  }
  name         = "aoiaml1"
  workspace_id = "<AML workspace resource id>"
}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.9, < 2.0)

- <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) (~> 2.0)

## Providers

The following providers are used by this module:

- <a name="provider_azapi"></a> [azapi](#provider\_azapi) (~> 2.0)

## Resources

The following resources are used by this module:

- [azapi_resource.connection](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_auth_type"></a> [auth\_type](#input\_auth\_type)

Description: The method of authentication. Valid options include:
"AAD","AccessKey","AccountKey","ApiKey","CustomKeys", "ManagedIdentity", "None",
"OAuth2", "PAT", "SAS", "ServicePrincipal", "UsernamePassword"

Type: `string`

### <a name="input_category"></a> [category](#input\_category)

Description: The type of resource or service to be connected. Valid options include:
"ADLSGen2", "AIServices", "AmazonMws", "AmazonRdsForOracle", "AmazonRdsForSqlServer", "AmazonRedshift",
"AmazonS3Compatible", "ApiKey", "AzureBlob", "AzureDatabricksDeltaLake", "AzureDataExplorer", "AzureMariaDb",
"AzureMySqlDb", "AzureOneLake", "AzureOpenAI", "AzurePostgresDb", "AzureSqlDb", "AzureSqlMi", "AzureSynapseAnalytics",
"AzureTableStorage", "BingLLMSearch", "Cassandra", "CognitiveSearch", "CognitiveService", "Concur", "ContainerRegistry",
"CosmosDb", "CosmosDbMongoDbApi", "Couchbase", "CustomKeys", "Db2", "Drill", "Dynamics", "DynamicsAx", "DynamicsCrm",
"Elasticsearch", "Eloqua", "FileServer", "FtpServer", "GenericContainerRegistry", "GenericHttp", "GenericRest", "Git",
"GoogleAdWords" , "GoogleBigQuery", "GoogleCloudStorage", "Greenplum", "Hbase", "Hdfs", "Hive", "Hubspot", "Impala", "Informix",
"Jira", "Magento", "ManagedOnlineEndpoint", "MariaDb", "Marketo", "MicrosoftAccess", "MongoDbAtlas", "MongoDbV2", "MySql",
"Netezza", "ODataRest", "Odbc", "Office365", "OpenAI", "Oracle", "OracleCloudStorage", "OracleServiceCloud", "PayPal", "Phoenix",
"Pinecone", "PostgreSql", "Presto", "PythonFeed", "QuickBooks", "Redis", "Responsys", "S3", "Salesforce", "SalesforceMarketingCloud",
"SalesforceServiceCloud", "SapBw", "SapCloudForCustomer", "SapEcc", "SapHana", "SapOpenHub", "SapTable", "Serp", "Serverless", "ServiceNow",
"Sftp", "SharePointOnlineList", "Shopify", "Snowflake", "Spark", "SqlServer", "Square", "Sybase", "Teradata", "Vertica", "WebTable", "Xero", "Zoho"

Type: `string`

### <a name="input_name"></a> [name](#input\_name)

Description: The name of the connection.

Type: `string`

### <a name="input_target"></a> [target](#input\_target)

Description: The target endpoint to connect to.

Type: `string`

### <a name="input_workspace_id"></a> [workspace\_id](#input\_workspace\_id)

Description: The id of the AML Workspace, AI Foundry Hub or AI Foundry Project for which to create the connection.

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_credentials"></a> [credentials](#input\_credentials)

Description: The specific details required for authentication. This object is dependent on `var.auth_type`.

### "AAD" and "None"

```hcl
{
  credentials = null
}
```

### "AccessKey"

```hcl
{
  credentials = {
    access_key_id = "<value>"
    secret_access_key = "<value>"
  }
}
```

### "AccountKey" and "ApiKey"

```hcl
{
  credentials = {
    key = "<value>"
  }
}
```

### "CustomKeys"

```hcl
{
  credentials = {
    keys = {
      {customized property} = "<value>"
    }
  }
}
```

### "ManagedIdentity"

```hcl
{
  credentials = {
    client_id = "<value>"
    resource_id = "<value>"
  }
}
```

### "OAuth2"

```hcl
{
  credentials = {
    auth_url = "<value>"
    client_secret = "<value>"
    dev_token = "<value>"
    password = "<value>"
    refresh_token = "<value>"
    username = "<value>"
    tenant_id = "<value>"
  }
}
```

- `auth_url` is required when `category` is "Concur".
- `dev_token` is required when `category` is "GoogleAdWords".
- `refresh_token` is required when `category` is "GoogleBigQuery", "GoogleAdWords", "Hubspot", "QuickBooks", "Square", "Xero", or "Zoho".
- `tenant_id` is required when `category` is "QuickBooks" or "Xero".
- `username` is required when `category` is "Concur" or "ServiceNow".

### "PAT"

```hcl
{
  credentials = {
    pat = "<value>"
  }
}
```

### "SAS"

```hcl
{
  credentials = {
    sas = "<value>"
  }
}
```

### "ServicePrincipal"

```hcl
{
  credentials = {
    client_id = "<value>"
    client_secret = "<value>"
    tenant_id = "<value>"
  }
}
```

### "UsernamePassword"

```hcl
{
  credentials = {
    password = "<value>"
    username = "<value>"
    security_token = "<value>"
  }
}
```

Type:

```hcl
object({
    access_key_id     = optional(string, null)
    secret_access_key = optional(string, null)
    key               = optional(string, null)
    keys              = optional(map(string), {})
    client_id         = optional(string, null)
    resource_id       = optional(string, null)
    auth_url          = optional(string, null)
    client_secret     = optional(string, null)
    dev_token         = optional(string, null)
    password          = optional(string, null)
    refresh_token     = optional(string, null)
    username          = optional(string, null)
    pat               = optional(string, null)
    sas               = optional(string, null)
    security_token    = optional(string, null)
    tenant_id         = optional(string, null)
  })
```

Default: `null`

### <a name="input_expiry_time"></a> [expiry\_time](#input\_expiry\_time)

Description: The connection's time of expiration.

Type: `string`

Default: `null`

### <a name="input_metadata"></a> [metadata](#input\_metadata)

Description: Additional details about the connection.

When connecting to an Azure service, this object must, at minimum, look like:
```hcl
{
  ApiType = "Azure"
  ResourceId = <resource id for connected service>
}
```

Type: `map(string)`

Default: `{}`

### <a name="input_shared_by_all"></a> [shared\_by\_all](#input\_shared\_by\_all)

Description: Indicates whether the connection is shared to all users of the workspace.

Type: `bool`

Default: `true`

### <a name="input_shared_user_list"></a> [shared\_user\_list](#input\_shared\_user\_list)

Description: The list of users who can use the connection. **Required if `var.shared_by_all` is `false`.

Type: `set(string)`

Default: `[]`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: (Optional) Tags for the resource.

Type: `map(string)`

Default: `null`

## Outputs

The following outputs are exported:

### <a name="output_name"></a> [name](#output\_name)

Description: The name of the created connection

### <a name="output_resource_id"></a> [resource\_id](#output\_resource\_id)

Description: The id of the created connection

## Modules

No modules.

<!-- markdownlint-disable-next-line MD041 -->

## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->