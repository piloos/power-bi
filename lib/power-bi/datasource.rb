module PowerBI
  class Datasource
    attr_reader :gateway_id, :datasource_id, :datasource_type, :connection_details

    def initialize(tenant, data)
      @gateway_id = data[:gatewayId]
      @datasource_type = data[:datasourceType]
      @connection_details = data[:connectionDetails]
      @datasource_id = data[:datasourceId]
      @tenant = tenant
    end

  end

  class DatasourceArray < Array

    def initialize(tenant, dataset)
      super(tenant)
      @dataset = dataset
    end

    def self.get_class
      Datasource
    end

    def get_data
      @tenant.get("/groups/#{@dataset.workspace.id}/datasets/#{@dataset.id}/datasources")[:value]
    end
  end
end