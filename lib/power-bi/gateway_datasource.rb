module PowerBI
  class GatewayDatasource
    attr_reader :id, :gateway_id, :datasource_type, :connection_details, :credential_type, :datasource_name, :gateway

    def initialize(tenant, data)
      @gateway_id = data[:gatewayId]
      @datasource_type = data[:datasourceType]
      @datasource_name = data[:datasourceName]
      @connection_details = data[:connectionDetails]
      @id = data[:id]
      @credential_type = data[:credentialType]
      @gateway = data[:gateway]
      @tenant = tenant
    end

    def update_credentials(encrypted_credentials)
      response = @tenant.patch("/gateways/#{gateway.id}/datasources/#{id}") do |req|
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
      @tenant.delete("/gateways/#{gateway.id}/datasources/#{id}")
      @gateway.gateway_datasources.reload
      true
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

    # only MySQL type is currently supported
    def create(name, encrypted_credentials, db_server, db_name)
      data = @tenant.post("/gateways/#{@gateway.id}/datasources",) do |req|
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
      GatewayDatasource.new(@tenant, data)
    end

    def get_data
      data = @tenant.get("/gateways/#{@gateway.id}/datasources")[:value]
      data.each { |d| d[:gateway] = @gateway }
    end
  end
end