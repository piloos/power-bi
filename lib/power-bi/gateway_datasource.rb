module PowerBI
  class GatewayDatasource < Object
    attr_reader :gateway, :gateway_datasource_users

    def initialize(tenant, parent, id = nil)
      super(tenant, id)
      @gateway = parent
      @gateway_datasource_users = GatewayDatasourceUserArray.new(@tenant, self)
    end

    def get_data(id)
      @tenant.get("/gateways/#{@gateway.id}/datasources/#{id}", use_profile: false)
    end

    def data_to_attributes(data)
      {
        gateway_id: data[:gatewayId],
        datasource_type: data[:datasourceType],
        datasource_name: data[:datasourceName],
        connection_details: data[:connectionDetails],
        id: data[:id],
        credential_type: data[:credentialType],
        gateway: data[:gateway],
      }
    end

    def update_credentials(encrypted_credentials)
      @tenant.patch("/gateways/#{gateway.id}/datasources/#{id}", use_profile: false) do |req|
        req.body = {
          credentialDetails: {
            credentialType: "Basic",
            credentials: encrypted_credentials,
            encryptedConnection: "Encrypted",
            encryptionAlgorithm: "RSA-OAEP",
            privacyLevel: "Organizational",
            useCallerAADIdentity: false,
            useEndUserOAuth2Credentials: false,
          },
        }.to_json
      end
      true
    end

    def delete
      @tenant.delete("/gateways/#{gateway.id}/datasources/#{id}", use_profile: false)
      @gateway.gateway_datasources.reload
      true
    end

  end

  class GatewayDatasourceArray < Array

    def initialize(tenant, gateway)
      super(tenant, gateway)
      @gateway = gateway
    end

    def self.get_class
      GatewayDatasource
    end

    # only MySQL type is currently supported
    def create(name, encrypted_credentials, db_server, db_name)
      data = @tenant.post("/gateways/#{@gateway.id}/datasources", use_profile: false) do |req|
        req.body = {
          connectionDetails: {server: db_server, database: db_name}.to_json,
          credentialDetails: {
            credentialType: "Basic",
            credentials: encrypted_credentials,
            encryptedConnection: "Encrypted",
            encryptionAlgorithm: "RSA-OAEP",
            privacyLevel: "Organizational",
            useCallerAADIdentity: false,
            useEndUserOAuth2Credentials: false,
          },
          datasourceName: name,
          datasourceType: 'MySql',
        }.to_json
      end
      self.reload
      GatewayDatasource.instantiate_from_data(@tenant, @gateway, data)
    end

    def get_data
      @tenant.get("/gateways/#{@gateway.id}/datasources", use_profile: false)[:value]
    end
  end
end