variable "auth_type" {
  type        = string
  description = <<DESCRIPTION
The method of authentication. Valid options include:
"AAD","AccessKey","AccountKey","ApiKey","CustomKeys", "ManagedIdentity", "None", 
"OAuth2", "PAT", "SAS", "ServicePrincipal", "UsernamePassword"
DESCRIPTION
  nullable    = false

  validation {
    condition = contains(["AAD", "AccessKey", "AccountKey", "ApiKey", "CustomKeys", "ManagedIdentity", "None",
    "OAuth2", "PAT", "SAS", "ServicePrincipal", "UsernamePassword"], var.auth_type)
    error_message = "value"
  }
}

variable "category" {
  type        = string
  description = <<DESCRIPTION
The type of resource or service to be connected. Valid options include:
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
DESCRIPTION
  nullable    = false

  validation {
    condition = contains(["ADLSGen2", "AIServices", "AmazonMws", "AmazonRdsForOracle", "AmazonRdsForSqlServer", "AmazonRedshift",
      "AmazonS3Compatible", "ApiKey", "AzureBlob", "AzureDatabricksDeltaLake", "AzureDataExplorer", "AzureMariaDb",
      "AzureMySqlDb", "AzureOneLake", "AzureOpenAI", "AzurePostgresDb", "AzureSqlDb", "AzureSqlMi", "AzureSynapseAnalytics",
      "AzureTableStorage", "BingLLMSearch", "Cassandra", "CognitiveSearch", "CognitiveService", "Concur", "ContainerRegistry",
      "CosmosDb", "CosmosDbMongoDbApi", "Couchbase", "CustomKeys", "Db2", "Drill", "Dynamics", "DynamicsAx", "DynamicsCrm",
      "Elasticsearch", "Eloqua", "FileServer", "FtpServer", "GenericContainerRegistry", "GenericHttp", "GenericRest", "Git",
      "GoogleAdWords", "GoogleBigQuery", "GoogleCloudStorage", "Greenplum", "Hbase", "Hdfs", "Hive", "Hubspot", "Impala", "Informix",
      "Jira", "Magento", "ManagedOnlineEndpoint", "MariaDb", "Marketo", "MicrosoftAccess", "MongoDbAtlas", "MongoDbV2", "MySql",
      "Netezza", "ODataRest", "Odbc", "Office365", "OpenAI", "Oracle", "OracleCloudStorage", "OracleServiceCloud", "PayPal", "Phoenix",
      "Pinecone", "PostgreSql", "Presto", "PythonFeed", "QuickBooks", "Redis", "Responsys", "S3", "Salesforce", "SalesforceMarketingCloud",
      "SalesforceServiceCloud", "SapBw", "SapCloudForCustomer", "SapEcc", "SapHana", "SapOpenHub", "SapTable", "Serp", "Serverless", "ServiceNow",
    "Sftp", "SharePointOnlineList", "Shopify", "Snowflake", "Spark", "SqlServer", "Square", "Sybase", "Teradata", "Vertica", "WebTable", "Xero", "Zoho"], var.category)
    error_message = "One of the valid connection categories"
  }
}

variable "name" {
  type        = string
  description = <<DESCRIPTION
The name of the connection.
DESCRIPTION
  nullable    = false
}

variable "target" {
  type        = string
  description = <<DESCRIPTION
The target endpoint to connect to.
DESCRIPTION
  nullable    = false
}

variable "workspace_id" {
  type        = string
  description = <<DESCRIPTION
The id of the AML Workspace, AI Foundry Hub or AI Foundry Project for which to create the connection.
DESCRIPTION
  nullable    = false
}

variable "credentials" {
  type = object({
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
  default     = null
  description = <<DESCRIPTION
The specific details required for authentication. This object is dependent on `var.auth_type`.

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
DESCRIPTION

  validation {
    condition     = !contains(["AAD", "None"], var.auth_type) || var.credentials == null
    error_message = <<DESCRIPTION
`var.credentials` must be null when `var.auth_type` is "AAD" or "None"
DESCRIPTION
  }
  validation {
    condition     = var.auth_type != "PAT" || can(length(var.credentials.pat) > 0)
    error_message = <<DESCRIPTION
`credentials.pat` is required when `auth_type` is "PAT".
DESCRIPTION
  }
  validation {
    condition     = var.auth_type != "SAS" || can(length(var.credentials.sas) > 0)
    error_message = <<DESCRIPTION
`credentials.sas` is required when `auth_type` is "SAS".
DESCRIPTION
  }
  validation {
    condition     = var.auth_type != "CustomKeys" || can(length(var.credentials.keys) > 0)
    error_message = <<DESCRIPTION
`credentials.keys` must contain at least one key when `auth_type` is "CustomKeys".
DESCRIPTION
  }
  validation {
    condition     = !contains(["AccountKey", "ApiKey"], var.auth_type) || can(length(var.credentials.key) > 0)
    error_message = <<DESCRIPTION
`credentials.key` is required when `auth_type` is "AccountKey" or "ApiKey".
DESCRIPTION
  }
  validation {
    condition     = var.auth_type != "AccessKey" || can(length(var.credentials.access_key_id) > 0 && length(var.credentials.secret_access_key) > 0)
    error_message = <<DESCRIPTION
`credentials.access_key_id` and `credentials.secret_access_key` are required when `auth_type` is "AccessKey".
DESCRIPTION
  }
  validation {
    condition     = var.auth_type != "UsernamePassword" || can(length(var.credentials.username) > 0 && length(var.credentials.password) > 0 && length(var.credentials.security_token) > 0)
    error_message = <<DESCRIPTION
`credentials.password`, `credentials.username` and `credentials.security_token` are required when `auth_type` is "UsernamePassword".
DESCRIPTION
  }
  validation {
    condition     = var.auth_type != "ServicePrincipal" || can(length(var.credentials.client_id) > 0 && length(var.credentials.client_secret) > 0 && length(var.credentials.tenant_id) > 0)
    error_message = <<DESCRIPTION
`credentials.client_id`, `credentials.client_secret` and `credentials.tenant_id` are required when `auth_type` is "ServicePrincipal".
DESCRIPTION
  }
  validation {
    condition     = var.auth_type != "ManagedIdentity" || can(length(var.credentials.client_id) > 0 && length(var.credentials.resource_id) > 0)
    error_message = <<DESCRIPTION
`credentials.client_id` and `credentials.resource_id` are required when `auth_type` is "ManagedIdentity".
DESCRIPTION
  }
}

variable "expiry_time" {
  type        = string
  default     = null
  description = <<DESCRIPTION
The connection's time of expiration.
DESCRIPTION
}

variable "metadata" {
  type        = map(string)
  default     = {}
  description = <<DESCRIPTION
Additional details about the connection.

When connecting to an Azure service, this object must, at minimum, look like:
```hcl
{
  ApiType = "Azure"
  ResourceId = <resource id for connected service>
}
```
DESCRIPTION

  validation {
    condition     = contains(["ADLSGen2", "AIServices", "AzureBlob", "AzureDatabricksDeltaLake", "AzureDataExplorer", "AzureMariaDb", "AzureMySqlDb", "AzureOneLake", "AzureOpenAI", "AzurePostgresDb", "AzureSqlDb", "AzureSqlMi", "AzureSynapseAnalytics", "AzureTableStorage", "BingLLMSearch", "CognitiveSearch", "CognitiveService", "ContainerRegistry", "CosmosDb", "CosmosDbMongoDbApi"], var.category) == false || length(var.metadata) > 0
    error_message = <<DESCRIPTION
`metadata` is required when connecting to Azure services. `APIType` = "Azure" and `ResourceId` = <the resource id>
DESCRIPTION
  }
}

variable "shared_by_all" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
Indicates whether the connection is shared to all users of the workspace.
DESCRIPTION
}

variable "shared_user_list" {
  type        = set(string)
  default     = []
  description = <<DESCRIPTION
The list of users who can use the connection. **Required if `var.shared_by_all` is `false`.
DESCRIPTION

  validation {
    condition     = var.shared_by_all || length(var.shared_user_list) > 0
    error_message = <<DESCRIPTION
If `var.shared_by_all` is false, `var.shared_user_list` must contain at least 1 value.
DESCRIPTION
  }
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) Tags for the resource."
}
