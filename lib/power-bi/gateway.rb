module PowerBI
  class Gateway < Object
    attr_reader :gateway_datasources

    def initialize(tenant, parent, id = nil)
      super(tenant, id)
      @gateway_datasources = GatewayDatasourceArray.new(@tenant, self)
    end

    def get_data(id)
      @tenant.get("/gateways/#{id}", use_profile: false)
    end

    def data_to_attributes(data)
      {
        id: data[:id],
        name: data[:name],
        type: data[:type],
        public_key: data[:publicKey],
      }
    end

    def gateway_datasource(id)
      GatewayDatasource.new(@tenant, self, id)
    end

  end

  class GatewayArray < Array
    def self.get_class
      Gateway
    end

    def get_data
      @tenant.get("/gateways", use_profile: false)[:value]
    end
  end
end