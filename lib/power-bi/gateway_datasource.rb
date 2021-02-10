module PowerBI
  class GatewayDatasource
    attr_reader :id, :gateway_id, :datasource_type, :connection_details, :credential_type, :datasource_name

    def initialize(tenant, data)
      @gateway_id = data[:gatewayId]
      @datasource_type = data[:datasourceType]
      @datasource_name = data[:datasourceName]
      @connection_details = data[:connectionDetails]
      @id = data[:id]
      @credential_type = data[:credentialType]
      @tenant = tenant
    end

  end

  class GatewayDatasourceArray < Array

    def initialize(tenant, gateway)
      super(tenant)
      @gateway = gateway
    end

    def self.get_class
      GatewayDatasource
    end

    def get_data
      @tenant.get("/gateways/#{@gateway.id}/datasources")[:value]
    end
  end
end