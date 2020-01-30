require 'minitest/autorun'
require 'webmock/minitest'
require 'power-bi'

# disable all outside world requests in testing
WebMock.disable_net_connect!(allow_localhost: true)

def dummy_token
  'dummy_token'
end
