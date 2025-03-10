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

    # only MySQL type is currently supported
    def update_credentials(username, password)
      @tenant.patch("/gateways/#{gateway_id}/datasources/#{datasource_id}") do |req|
        req.body = {
          credentialDetails: {
            credentialType: "Basic",
            credentials: "{\"credentialData\":[{\"name\":\"username\", \"value\":\"#{username}\"},{\"name\":\"password\", \"value\":\"#{password}\"}]}",
            encryptedConnection: "Encrypted",
            encryptionAlgorithm: "None",
            privacyLevel: "None",
            useCallerAADIdentity: false,
            useEndUserOAuth2Credentials: false,
          },
        }.to_json
      end
      true
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