require_relative '../lib/power-bi'

require 'pry'
require 'oauth2'

AUTHORITY_HOST = 'login.microsoftonline.com'
TENANT = "xxx"
RESOURCE = 'https://analysis.windows.net/powerbi/api'

# Authentication using a 'master user'
# CLIENT_ID = 'xxx'
# CLIENT_SECRET = 'xxx
# USERNAME = 'xxx@xxx.com'
# PASSWORD = 'xxxx'

# Authentication using a 'service principal'
CLIENT_ID = 'xxx'
CLIENT_SECRET = 'xxx'
OBJECT_ID = 'xxx'

client = OAuth2::Client.new(CLIENT_ID, CLIENT_SECRET, site: 'https://login.microsoftonline.com', token_url: "#{TENANT}/oauth2/token", auth_scheme: :request_body)

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

# create profile
puts "create or recycle profile"
begin
  pbi.profiles.create('testprofile')
rescue PowerBI::APIError => e
  raise e unless e&.message.to_s.include?('PowerBIEntityAlreadyExistsException')
end
profile = pbi.profiles.find { |p| p.display_name == 'testprofile' }

# set profile
pbi.profile = profile.id  # comment this line if you want to do the flow using 'service principal' iso 'service principal profile'
puts "current profile in use: #{pbi.profile_id}"

# create workspace
puts "delete & create workspace"
ws = pbi.workspaces.find { |ws| ws.name == "testworkspace" }
ws.delete if ws

ws = pbi.workspaces.create('testworkspace')

# move workspace to dedicated capacity
puts "move workspace to dedicated capacity"
capacity = pbi.capacities.find { |c| c.display_name == 'bictestcapacity' }
ws.assign_to_capacity(capacity)

# upload PBIX
puts "upload PBIX"
ws.upload_pbix('/home/lode/power-bi/master.pbix', "report", timeout: 300)
dataset = ws.datasets.first

# update parameters
puts "update parameters"
dataset.update_parameter('db_name', 'lodenl_cdm_234')
hostname_for_gateway = 'bic-dev-cdm-database.cwfpciudco5r.eu-central-1.rds.amazonaws.com'
dataset.update_parameter('db_server', hostname_for_gateway)

# create gateway datasource
puts "create gateway datasource"
gw = pbi.gateways.first
credentials_for_gateway = "dpEz8wV2bDFSZD5Y7C+UI5rSgM9KuwMjBQeGT0gwpA9IsjzrDCtFAA6xlltJKqk0Cem4MhrQF32WTsNCgICPn/GYcEQzm8Ujbh9q4XLKNKut5A7RnSYbznXWPVt6kjpAufdQsUpNzWnTr/EYTnDdpuAG7DQ++gpehZO3y+06RSeel4nZ2dUJgImyPibpHIGNflkBgFTAKWYWqQ7HLpJsOKqNcJOLPDkOLfEyh9iLoCulbWYzVO6dEKCYULEzYqalPTT95cePK+E6U1qsUUs7dZ/RqLaOFZ5tyaRAS85ViQHXbeKVBBxNhvMXek2cnE4/CI5lz2gB9utrdjI7Yud2vA==AAAQ+Ladf21U5iQUWz27S8Bw1uEj7+/vl4E1PzCa+VgmCZyYIX9vHh5lnk2m9qmQVSVQ6AnnC+94mRXk4ydYIw6LoEjvOvbEAfXRYnvCfe2nCcVT/tdMbMrWXE8WJ/olMbWoLHnHkxpfUz9HZCFVR5gnHRpl2Y6Ra/K9Ov7Rui5dFyBlEIBQIOLxdFzIRhVmvhzXWGthZ0GLgJXsu3ieG0rz"
gateway_datasource_name = 'ds_lodenl_234'
existing_gateway_datasource = gw.gateway_datasources.find{ |ws| ws.datasource_name == gateway_datasource_name }
existing_gateway_datasource.delete if existing_gateway_datasource
gateway_datasource = gw.gateway_datasources.create(gateway_datasource_name, credentials_for_gateway, hostname_for_gateway, 'lodenl_cdm_234')

if pbi.profile_id
  puts "Add SPP to gateway datasource"
  gateway_datasource.gateway_datasource_users.add_service_principal_profile_user(profile.id, OBJECT_ID)
end

# bind gateway datasource to dataset
puts "bind gateway datasource to dataset"
dataset.bind_to_gateway(gw, gateway_datasource)

# refresh dataset
puts "refresh dataset"
dataset.refresh

# poll refresh completion
puts "poll refresh completion"
done = false
counter = 0
while !done && counter < 10
  sleep 10
  counter += 1
  last_refresh = dataset.last_refresh
  if last_refresh
    if last_refresh.status == 'Completed'
      puts " --> refresh done OK!"
      done = true
    elsif last_refresh.status == 'Unknown'
      puts " --> status still unknown"
    else
      puts " --> refresh failed"
      binding.pry
      done = true
    end
  end
end

puts "end of story"
