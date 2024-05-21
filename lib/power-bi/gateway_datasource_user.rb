module PowerBI
  class GatewayDatasourceUser < Object
    attr_reader :gateway_datasource

    def initialize(tenant, parent, id = nil)
      super(tenant, id)
      @gateway_datasource = parent
    end

    def data_to_attributes(data)
      {
        datasource_access_right: data[:datasourceAccessRight],
        display_name: data[:displayName],
        email_address: data[:emailAddress],
        identifier: data[:identifier],
        principal_type: data[:principalType],
        profile: data[:profile],
      }
    end

  end

  class GatewayDatasourceUserArray < Array

    def initialize(tenant, gateway_datasource)
      super(tenant, gateway_datasource)
      @gateway_datasource = gateway_datasource
    end

    def self.get_class
      GatewayDatasourceUser
    end

    # service principal object ID: https://learn.microsoft.com/en-us/power-bi/developer/embedded/embedded-troubleshoot#what-is-the-difference-between-application-object-id-and-principal-object-id
    def add_service_principal_profile_user(profile_id, principal_object_id, datasource_access_right: "Read")
      @tenant.post("/gateways/#{@gateway_datasource.gateway.id}/datasources/#{@gateway_datasource.id}/users", use_profile: false) do |req|
        req.body = {
          datasourceAccessRight: datasource_access_right,
          identifier: principal_object_id,
          principalType: "App",
          profile: {id: profile_id},
        }.to_json
      end
      self.reload
    end

    def get_data
      @tenant.get("/gateways/#{@gateway_datasource.gateway.id}/datasources/#{@gateway_datasource.id}/users", use_profile: false)[:value]
    end
  end
end