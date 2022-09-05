module PowerBI
  class Datasource < Object
    attr_reader :dataset

    def initialize(tenant, parent, id = nil)
      super(tenant, id)
      @dataset = parent
    end

    def data_to_attributes(data)
      {
        gateway_id: data[:gatewayId],
        datasource_type: data[:datasourceType],
        connection_details: data[:connectionDetails],
        datasource_id: data[:datasourceId],
      }
    end

  end

  class DatasourceArray < Array

    def initialize(tenant, dataset)
      super(tenant, dataset)
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