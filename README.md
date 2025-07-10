# power-bi

Ruby wrapper around the Power BI API

# Initialization

The Power BI API does not handle the authorization part. It requires the user to pass a function where it can request tokens.

```
pbi = PowerBI::Tenant.new(->{token = get_token(client, token) ; token.token})
```

## Authentication & authorization towards the Power BI API

Currently (april 2024), there are basically 3 ways to authenticate to the Power BI API.

### 1 - Master User

A master user is a classic Microsoft 365 user that you assign a Power BI Pro license.  In order to allow the user to execute actions on the Power BI API you need to create an app registration in Azure AD.  In the associated Enterprise application (gets created when you create the app registration), you need to add the permissions to use the Power BI service.

The resulting authentication looks like this:

```
TENANT = "53c835d6-6841-4d58-948a-55117409e1d8"
CLIENT_ID = '6fc64675-bee3-49a7-70d8-b3301a51a88d'
CLIENT_SECRET = 'sI/@ncYe=eVt7.XfZ7tsPU1aPbxm0V_H'
USERNAME = 'company_0001@example.com'
PASSWORD = 'mLXv5A1jrIb8dHopur7y'

client = OAuth2::Client.new(CLIENT_ID, CLIENT_SECRET, site: 'https://login.microsoftonline.com', token_url: "#{TENANT}/oauth2/token")

token = client.password.get_token(USERNAME, PASSWORD, scope: 'openid', resource: 'https://analysis.windows.net/powerbi/api')
```

Note that in this case the legacy (and slightly unsafe) Resource Owner Password Credentials (ROPC) OAuth flow is used.

### 2 - Service principal

A service principal is a fancy word for a machine user with a secret (eg. id + key) in Azure AD.  You create them by creating an app registration and adding a secret on it.  You need to allow service principals in your Power BI admin settings. But once you allow that, the setup is very easy.  No need to configure anything special in AD.

The resulting authentication looks like this:

```
TENANT = "53c835d6-6841-4d58-948a-55117409e1d8"
CLIENT_ID = '6fc64675-bee3-49a7-70d8-b3301a51a88d'
CLIENT_SECRET = 'sI/@ncYe=eVt7.XfZ7tsPU1aPbxm0V_H'

client = OAuth2::Client.new(CLIENT_ID, CLIENT_SECRET, site: 'https://login.microsoftonline.com', token_url: "#{TENANT}/oauth2/token")

token = client.client_credentials.get_token(resource: 'https://analysis.windows.net/powerbi/api')
```

Note that in this case the Client Credentials OAuth flow is used.

### 3 - Service principal profiles

Service principal profiles is a Power-BI-only concept.  Towards AD, it looks exactly the same as generic service principal.  Hence the authenication looks exactly as in way 2.

Once authenticated, you can set profiles like this:

```
pbi.profile = profile
```

Every action executed after setting the profile, will be executed _through the eyes of the profile_.  This way, you can create an isolated multi-tenant setup.  Using profiles, simplifies the internal organization of Power BI and allows faster interaction with Power BI.  This also lifts the 1000-workspaces limit that is imposed on Master Users and Service Principals

Note: when working with Service principal profiles (SPP), you need to add the SPP to the gateway datasource before binding the gateway datasource to the dataset.

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

## Datasources

* Update credentials of a datasource: `datasource.update_credentials(username, password)`

## Gateways

* List gateways: `pbi.gateways`
* Get a specific gateway `pbi.gateway(id)`

## Gateway datasources

* List datasources in a gateway: `gateway.gateway_datasources`
* Update credentials of a gateway datasource: `gateway_datasource.update_credentials(new_credentials)`
* Create a new gateway datasource: `gateway.gateway_datasource.create(name, credentials, db_server, db_name)`
* Delete a new gateway datasource: `gateway_datasource.delete`

## Gateway datasource users

* List datasource users in a gateway datasource: `gateway_datasource.gateway_datasource_users`
* Add a Service principal profile to a gateway datasource: `gateway_datasource.add_service_principal_profile_user(profile_id, principal_object_id)`

## Capacities

Note: Capacities are Azure creatures, you can't create them in Power BI.

* List capacities: `pbi.capacities`
* Get a capacity: `pbi.capacity(id)`

## Profiles

* List profiles: `pbi.profiles`
* Get a profile: `pbi.profile(id)`
* Create a profile: `pbi.profiles.create`
* Delete a profile: `profile.delete`

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


