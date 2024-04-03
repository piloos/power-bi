require_relative '../lib/power-bi'

require 'pry'
require 'oauth2'

AUTHORITY_HOST = 'login.microsoftonline.com'
TENANT = "53c835d6-6841-4d58-948a-55117409e1d8"
RESOURCE = 'https://analysis.windows.net/powerbi/api'

# Authentication using a 'master user'
# CLIENT_ID = '6fc64675-bee3-49a7-80d8-b3301a51a88d'
# CLIENT_SECRET = 'sI/@ncYe=eVt7.XfZ7ssPU1aPbxm0V_H'
# USERNAME = 'company_0001@bizzcontrol.com'
# PASSWORD = 'mLXv5A1jrIb8dHopur7y'

# Authentication using a 'service principal'
CLIENT_ID = 'xxx'
CLIENT_SECRET = 'xxx'

client = OAuth2::Client.new(CLIENT_ID, CLIENT_SECRET, site: 'https://login.microsoftonline.com', token_url: "#{TENANT}/oauth2/token")

token = nil

def get_token_master_user(client, token)
  if token.nil? || token.expired?
    token = client.password.get_token(USERNAME, PASSWORD, scope: 'openid', resource: 'https://analysis.windows.net/powerbi/api')
  end
  token
end

def get_token_service_principal(client, token)
  if token.nil? || token.expired?
    token = client.client_credentials.get_token(resource: 'https://analysis.windows.net/powerbi/api')
  end
  token
end


pbi = PowerBI::Tenant.new(->{token = get_token_service_principal(client, token) ; token.token})

workspaces = pbi.workspaces

puts "# workspaces: #{workspaces.length}"

profiles = pbi.profiles

puts "# profiles: #{profiles.length}"

puts "end of story"
