require 'pry' # TODO remove in final product
require 'faraday'
require 'json'

module PowerBI
  BASE_URL = 'https://api.powerbi.com/v1.0/myorg'
end

require_relative "power-bi/tenant"
require_relative "power-bi/array"
require_relative "power-bi/workspace"