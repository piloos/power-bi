require 'faraday'
require 'json'
require 'date'

module PowerBI
  BASE_URL = 'https://api.powerbi.com/v1.0/myorg'

  class Error < StandardError ; end
  class APIError < Error ; end
  class NotFoundError < Error; end
end

require_relative "power-bi/tenant"
require_relative "power-bi/object"
require_relative "power-bi/array"
require_relative "power-bi/workspace"
require_relative "power-bi/report"
require_relative "power-bi/dataset"
require_relative "power-bi/datasource"
require_relative "power-bi/parameter"
require_relative "power-bi/refresh"
require_relative "power-bi/gateway"
require_relative "power-bi/gateway_datasource"
require_relative "power-bi/gateway_datasource_user"
require_relative "power-bi/page"
require_relative "power-bi/user"
require_relative "power-bi/capacity"
require_relative "power-bi/profile"
require_relative "power-bi/admin"