require_relative '../lib/power-bi'

require 'pry'
require 'pry-byebug'
require 'oauth2'

AUTHORITY_HOST = 'login.microsoftonline.com'
TENANT = "xxx"
RESOURCE = 'https://analysis.windows.net/powerbi/api'

# Authentication using a 'master user'
# CLIENT_ID = 'xxx'
# CLIENT_SECRET = 'xxx'
# USERNAME = 'xxx@xxx.com'
# PASSWORD = 'xxx'

# Authentication using a 'service principal'
CLIENT_ID = 'xxx'
CLIENT_SECRET = 'xxx'
OBJECT_ID = 'xxx'


DATABASE = 'xxx'

DB_SERVER = 'xxx'

CREDENTIALS_FOR_GATEWAY = 'xxx'
USERNAME = 'xxx'
PASSWORD = 'xxx'

client = OAuth2::Client.new(CLIENT_ID, CLIENT_SECRET, site: 'https://login.microsoftonline.com', token_url: "#{TENANT}/oauth2/token", auth_scheme: :request_body)


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

class MyLogger
  def method_missing(method, *args, &block)
    puts "#{method}: #{args[0]}"
  end
end

token = nil
pbi = PowerBI::Tenant.new(->{token = get_token_service_principal(client, token1) ; token.token}, logger: MyLogger.new)

def create_stack(pbi, workspace_name, skip_if_exists: true, use_spp: false, spp_object_id: nil, use_gateway: false)
  if use_spp
    # create profile
    puts "create or recycle profile"
    begin
      pbi.profiles.create(workspace_name)
    rescue PowerBI::APIError => e
      raise e unless e&.message.to_s.include?('PowerBIEntityAlreadyExistsException')
    end
    profile = pbi.profiles.find { |p| p.display_name == workspace_name }

    # set profile
    pbi.profile = profile.id
    puts "current profile in use: #{pbi.profile_id}"
  end

  # # create workspace
  ws = pbi.workspaces.find { |ws| ws.name == workspace_name }
  if skip_if_exists && ws
    puts "#{workspace_name}: skip workspace because it already exists"
    return
  end
  if ws
    ws.delete
    puts "#{workspace_name}: delete workspace"
  end
  puts "#{workspace_name}: create workspace"
  ws = pbi.workspaces.create(workspace_name)

  # move workspace to dedicated capacity
  puts "#{workspace_name}: move workspace to dedicated capacity"
  capacity = pbi.capacities.find { |c| c.display_name == 'bictestcapacity' }
  ws.assign_to_capacity(capacity)

  # upload PBIX
  puts "#{workspace_name}: upload PBIX"
  ws.upload_pbix('/home/lode/power-bi/master.pbix', "report", timeout: 300)
  dataset = ws.datasets.first

  # update parameters
  puts "#{workspace_name}: update parameters"
  dataset.update_parameter('db_name', DATABASE)
  dataset.update_parameter('db_server', DB_SERVER)

  if use_gateway
    # create gateway datasource
    gw = pbi.gateways.find { |gw| gw.name == 'gateway-debug' }
    gateway_datasource_name = 'ds_' + workspace_name
    existing_gateway_datasource = gw.gateway_datasources.find{ |ws| ws.datasource_name == gateway_datasource_name }
    existing_gateway_datasource.delete if existing_gateway_datasource
    gateway_datasource = gw.gateway_datasources.create(gateway_datasource_name, CREDENTIALS_FOR_GATEWAY, DB_SERVER, DATABASE)

    if use_spp
      puts "Add SPP to gateway datasource"
      gateway_datasource.gateway_datasource_users.add_service_principal_profile_user(profile.id, spp_object_id)
      puts "Remove service principal from gateway datasource"
      gateway_datasource.gateway_datasource_users.first.delete
    end

    # bind gateway datasource to dataset
    puts "#{workspace_name}: bind gateway datasource to dataset"
    dataset.bind_to_gateway(gw, gateway_datasource)
  else
    # set credentials on datasource
    puts "Set credentials on datasource"
    dataset.datasources.first.update_credentials(USERNAME, PASSWORD)
  end
end

create_stack(pbi, "ws_debug_1", use_spp: true, spp_object_id: OBJECT_ID, use_gateway: true)

puts "end of story"
