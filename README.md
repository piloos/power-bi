# power-bi

Ruby wrapper around the Power BI API

# Initialization

The Power BI API does not handle the authorization part. It requires the user to pass a function where it can request tokens.

```
pbi = PowerBI::Tenant.new(->{token = get_token(client, token) ; token.token})
```

# Supported endpoints

Note: where possible we use _lazy evaluation_: we only call the REST API endpoint when really needed. For examples `pbi.workspaces` won't trigger a call, while `pbi.workspaces.count` will trigger a call.  And `pbi.workspace('123')` won't trigger a call, while `pbi.workspace('123').name` will trigger a call.

Note 2: to limit the number of API calls, it is best to directly use the _getters_ iso the _lists_.

## Workspaces (aka Groups)

* List workspaces: `pbi.workspaces`
* Get a specific workspace `pbi.workspace(id)`
* Create workspace: `pbi.workspaces.create`
* Upload PBIX to workspace: `ws.upload_pbix('./test.pbix', 'new_datasetname_in_the_service')`
* Delete workspace: `workspace.delete`
* Add a user to a wokspace: `workspace.add_user('company_0001@fabrikam.com')`
* Assign a workspace to a capacity: `workspace.assign_to_capacity(capacity)`
* Unassign a workspace from a capacity: `workspace.unassign_from_capacity`

## Reports

* List reports in a workspace: `workspace.reports`
* Get report in a workspace: `workspace.report(id)`
* Clone a report from one workspace to another: `report.clone(src_workspace, new_report_name)`
* Rebind report to another dataset: `report.rebind(dataset)`
* Export report to file: `report.export_to_file(filename, format: 'PDF')`
* Get embed token: `report.embed_token(access_level: 'View', lifetime_in_minutes: 60)`

## Pages

* List pages in a report: `report.pages`

## Users

* List users in a workspace: `workspace.pages`
* Delete a user from a workspace: `user.delete`
* Add a user to a workspace: `workspace.create(email_address, access_right: "Viewer")`

## Datasets

* List datasets in a workspace: `workspace.datasets`
* Get report in a workspace: `workspace.dataset(id)`
* Update parameter in a dataset: `dataset.update_parameter(parameter_name, new_value)`
* Get time of last refresh: `dataset.last_refresh`
* Refresh the dataset: `dataset.refresh`
* Delete the dataset: `dataset.delete`
* Bind dataset to a gateway datasource: `dataset.bind_to_gateway(gateway, gateway_datasource)`

## Gateways

* List gateways: `pbi.gateways`
* Get a specific gateway `pbi.gateway(id)`

## Gateway datasources

* List datasources in a gateway: `gateway.gateway_datasources`
* Update credentials of a gateway datasource: `gateway_datasource.update_credentials(new_credentials)`
* Create a new gateway datasource: `gateway.gateway_datasource.create(name, credentials, db_server, db_name)`
* Delete a new gateway datasource: `gateway_datasource.delete`

## Capacities

Note: Capacities are Azure creatures, you can't create them in Power BI.

* List capacities: `pbi.capacities`
* Get a capacity: `pbi.capacity(id)`

# Note about gateway credentials

Power BI uses an obscure mechanism to encrypt credential exchange between the service and the gateway.  The encryption must be done outside this module on a Windows machine based on th public key of the gateway.  This is an example C# script:

```
using System;
using Microsoft.PowerBI.Api.Models;
using Microsoft.PowerBI.Api.Models.Credentials;
using Microsoft.PowerBI.Api.Extensions;


namespace pbi_credentials
{
    class Program
    {
        static void Main(string[] args)
        {
            Console.WriteLine("Kicking off");

            var credentials = new BasicCredentials(username: "cdmuser", password: "cdmuserpw4879515365");

            var publicKey = new GatewayPublicKey("AQAB", "ru5gTdHbJ+8eC/uwERTOMz9Yktf/kCDWeRDCY1M5fPCB9+p4c8Uk54/NzT5ZWPQCp958bLcO8nSOSOpz4I8fW/AI4d+JxwW6VCsxzue2mKbJjeuSDXXmIiNUFqvjOIolfSIxJFNlfWkZUFlaD3dXgJkjJxrrc4OrYBDUt0FF14UsvdZymTbOl39sAhD4i9CqkXTqm6+JDxsEkPE3GAZ6ZslCsRUqu7lX73anAHkm889FR9NOMtsLV02JDMKCblJqnoszTzgExEEeoTJKxLiJdC8Mfbl96fKFS8JElJIzfTPzldGx5TxdjRmekQODWr7SNMSVJJQTJaANh9C2FZ85pQ==");
            var credentialsEncryptor = new AsymmetricKeyEncryptor(publicKey);

            var credentialDetails = new CredentialDetails(
                credentials,
                PrivacyLevel.Private,
                EncryptedConnection.Encrypted,
                credentialsEncryptor
            );
            Console.WriteLine(credentialDetails.Credentials);

            Console.WriteLine("Bye Bye");
        }
    }
}
```


