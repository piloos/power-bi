module PowerBI
  class Gateway
    attr_reader :name, :id, :type, :gateway_datasources

    def initialize(tenant, data)
      @id = data[:id]
      @name = data[:name]
      @type = data[:type]
      @tenant = tenant
      @gateway_datasources = GatewayDatasourceArray.new(@tenant, self)
    end

  end

  class GatewayArray < Array
    def self.get_class
      Gateway
    end

    def get_data
      @tenant.get("/gateways")[:value]
    end
  end
end