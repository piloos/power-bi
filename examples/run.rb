require_relative '../lib/power-bi'

require 'pry'
require 'oauth2'

AUTHORITY_HOST = 'login.microsoftonline.com'
TENANT = "53c835d6-6841-4d58-948a-55117409e1d8"
CLIENT_ID = '5fac4af8-e2df-4d23-91f6-b8b67461632f'
CLIENT_SECRET = 'DtSh23EVw53KjORY.WTytN:BaBlnRH-['
RESOURCE = 'https://analysis.windows.net/powerbi/api'
USERNAME = 'pbiembed@bizzcontrol.com'
PASSWORD = 'Xafa0454'

client = OAuth2::Client.new(CLIENT_ID, CLIENT_SECRET, site: 'https://login.microsoftonline.com', token_url: "#{TENANT}/oauth2/token")

token = nil

def get_token(client, token)
  if token.nil? || token.expired?
    token = client.password.get_token(USERNAME, PASSWORD, scope: 'openid', resource: 'https://analysis.windows.net/powerbi/api')
  end
  token
end

pbi = PowerBI::Tenant.new(->{token = get_token(client, token) ; token.token})
workspaces = pbi.workspaces

ws = workspaces.create('val_cdm_45')
ws.upload_pbix('./cdmtest2.pbix', 'cdm_test')
ds = ws.datasets.first
ds.update_parameter('dbserver', 'db-val1.ctz7m0qmpwax.eu-central-1.rds.amazonaws.com')
ds.update_parameter('dbname', 'cdm_45')

gateways = pbi.gateways

# gateways.each do |gateway|
#   puts "gateway #{gateway.name} (#{gateway.id}) - type #{gateway.type}"

#   datasources = gateway.gateway_datasources

#   puts " * contains #{datasources.length} gateway_datasources"

#   datasources.each do |ds|
#     puts "   * datasource #{ds.id} - type #{ds.datasource_type} on gateway #{ds.gateway_id}"
#     puts "     name #{ds.datasource_name}, credential type #{ds.credential_type}"
#     puts "     connection details: #{ds.connection_details}"
#   end
# end

# these encrypted credentials represent username 'cdmuser' with password 'cdmuserpw4879515365'
encrypted_credentials = "amJxaoa18xAIO2lY3W27eVFXqH3NHA4RouUqUW5hjUefkgcOXX5gTeIu45zQAhrpu709LAB2Lh/ZQ5MnJQRjbcyEAkVOne3FOcCOKKsNEY78FSJxuKY9sXW6dJ98MSjrVCV911hnXClea8iDRp7kU26dZ80TWx1jnkLL/IPg6nTkrBd/8e68h8b5AOLOYP6Vb5QX3a7lG1B3gqARR1kA9d4SS0IpvQki4h1JMm2uqtJL1bTJjcdTx+SKlhjtDffbheqwUmWTpyEMnoHKsgPPorNA9Od+4qwwxND8QaeU6sV90j3uM29iloN5sDL4EpTeM5LQGl4Xj1H6KSCKVkHd9g==AADTz+4lSCGyMr4pwA99tIXNR7MTWDiLeXJqExDiByuoc1evshllxwPtinj+x2I9g1+YbNA/y7D5vqK0ntNc8xruF15Rlc+ITN6RHuesL9qan+XH5dD/Gj4WUPCFkZZM0xjmk0c4yIvaASNqJs7y2QcwnnQq2alSvNATJ7SD3y4UlmXxKKu8sGBkYQh1PxSUTtE0Oz0AUfw/IMelOwjHqUrg"

the_gateway = gateways[0]
gw_datasource = the_gateway.gateway_datasources.create('cdm_45', encrypted_credentials, 'db-val1.ctz7m0qmpwax.eu-central-1.rds.amazonaws.com', 'cdm_45')

ds.bind_to_gateway(the_gateway, gw_datasource)

# the_gateway.gateway_datasources[0].update_credentials(encrypted_credentials)

# puts workspaces.length

# workspaces.create('Zoo7')

# reports = workspaces[0].reports

# datasets = workspaces[0].datasets

# zoo1 = workspaces.find{ |ws| ws.name == 'Zoo1'}
# zoo2 = workspaces.find{ |ws| ws.name == 'Zoo2'}
# zoo6 = workspaces.find{ |ws| ws.name == 'Zoo6'}
# zoo7 = workspaces.find{ |ws| ws.name == 'Zoo7'}

# ws = workspaces.find{ |ws| ws.name == 'cdmtest'}

# puts zoo1.reports.length

# original_report = zoo1.reports.find { |r| r.name == 'zoo_from_sharepoint'}
# cloned_report = original_report.clone(zoo2, 'zoo2_from_sharepoint')
# clone_report = zoo2.reports.find { |r| r.name == 'zoo2_from_sharepoint'}

# datasets = ws.datasets

# the_gateway = gateways[0]
# the_dataset = datasets.find { |ds| ds.name == 'cdmtest2' }
# the_dataset.bind_to_gateway(the_gateway, the_gateway.gateway_datasources.find{ |ds| ds.datasource_name == 'cdmtest2'})

# puts datasets.length

# datasets.each do |dataset|
#   puts "dataset #{dataset.name} (#{dataset.id})"

#   datasources = dataset.datasources

#   puts " * contains #{datasources.length} datasources"

#   datasources.each do |datasource|
#     puts "   * datasource #{datasource.datasource_id} - type #{datasource.datasource_type} on gateway #{datasource.gateway_id}"
#   end
# end

# zoo7.upload_pbix('./examples/zoo_from_sharepoint.pbix', 'uploaded_stuff')
# dataset = zoo3.datasets.first

# p dataset.parameters.map { |p| [p.name, p.current_value]}

# dataset.update_parameter('folder', 'zoo3')

# p dataset.parameters.map { |p| [p.name, p.current_value]}

# report = zoo1.reports.find { |r| r.name == 'zoo_from_sharepoint_report2' }
# target_dataset = zoo1.datasets.find { |d| d.name == 'zoo_from_sharepoint' }
# report.rebind(target_dataset)

# dataset.refresh

# zoo1.datasets.each { |d| d.refresh }

# zoo1.add_user('company_0001@bizzcontrol.com')

# zoo3.datasets.first.delete

# zoo6.delete

# dses = zoo7.datasets

# dses.each do |ds|
#   refreshes = ds.refresh_history
#   p refreshes.map { |r| [r.status, r.start_time, r.end_time] }
#   p ds.last_refresh
# end
# ds.refresh
# p refreshes.map { |r| [r.status, r.start_time, r.end_time] }

#report = ws.reports.first

#report.export_to_file 'myexport.pdf'

puts "end of story"
