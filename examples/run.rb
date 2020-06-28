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


puts workspaces.length

# workspaces.create('Zoo7')

# reports = workspaces[0].reports

# datasets = workspaces[0].datasets

# zoo1 = workspaces.find{ |ws| ws.name == 'Zoo1'}
# zoo2 = workspaces.find{ |ws| ws.name == 'Zoo2'}
# zoo6 = workspaces.find{ |ws| ws.name == 'Zoo6'}
zoo7 = workspaces.find{ |ws| ws.name == 'Zoo7'}

# puts zoo1.reports.length

# original_report = zoo1.reports.find { |r| r.name == 'zoo_from_sharepoint'}
# cloned_report = original_report.clone(zoo2, 'zoo2_from_sharepoint')
# clone_report = zoo2.reports.find { |r| r.name == 'zoo2_from_sharepoint'}

# ds1 = zoo1.datasets.first

# datasources = ds1.datasources

# puts datasources.length

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

report = zoo7.reports.first

report.export_to_file

puts "end of story"
