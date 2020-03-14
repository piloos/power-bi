require 'pry' # TODO remove in final product
require 'faraday'
require 'json'
require 'date'

module PowerBI
  BASE_URL = 'https://api.powerbi.com/v1.0/myorg'

  class Error < StandardError ; end
  class APIError < Error ; end
end

require_relative "power-bi/tenant"
require_relative "power-bi/array"
require_relative "power-bi/workspace"
require_relative "power-bi/report"
require_relative "power-bi/dataset"
require_relative "power-bi/datasource"
require_relative "power-bi/parameter"
require_relative "power-bi/refresh"
