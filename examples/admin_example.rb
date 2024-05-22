require_relative '../lib/power-bi'

require 'pry'
require 'oauth2'

AUTHORITY_HOST = 'login.microsoftonline.com'
TENANT = "xxx"
RESOURCE = 'https://analysis.windows.net/powerbi/api'

# Authentication using a 'master user'
CLIENT_ID = 'xxx'
CLIENT_SECRET = 'xxx'
USERNAME = 'xxx@xxx.com'
PASSWORD = 'xxx'


client = OAuth2::Client.new(CLIENT_ID, CLIENT_SECRET, site: 'https://login.microsoftonline.com', token_url: "#{TENANT}/oauth2/token", auth_scheme: :request_body)

token = nil

def get_token_master_user(client, token)
  if token.nil? || token.expired?
    token = client.password.get_token(USERNAME, PASSWORD, scope: 'openid', resource: 'https://analysis.windows.net/powerbi/api')
  end
  token
end

pbi = PowerBI::Tenant.new(->{token = get_token_master_user(client, token) ; token.token})

# artis = pbi.admin.get_user_artifact_access('309271de-d3a5-4105-ad6b-e2ac21c62218', artifact_types: ['Workspace', 'Capacity'])
# artis = pbi.admin.get_user_artifact_access('309271de-d3a5-4105-ad6b-e2ac21c62218')

# puts artis.map { |x| x[:artifactType] }.tally

# workspaces = pbi.admin.get_workspaces(expand: 'users')
# workspaces = pbi.admin.get_workspaces(filter: "name eq 'gaston_cdm_401' and state eq 'Active'", expand: 'users')
# pbi.admin.force_delete_workspace_by_workspace_name(USERNAME, 'gaston_cdm_401')
# workspaces = pbi.admin.get_workspaces(filter: "name eq 'gaston_cdm_401' and state eq 'Active'", expand: 'users')

# workspaces = pbi.admin.get_workspaces(filter: "contains(name, 'lodenl_cdm_') and state eq 'Active'", expand: 'users')

puts "end of story"
