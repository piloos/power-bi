module PowerBI
  class Dataset < Object
    attr_reader :workspace, :datasources, :parameters

    def initialize(tenant, parent, id = nil)
      super(tenant, id)
      @workspace = parent
      @datasources = DatasourceArray.new(@tenant, self)
      @parameters = ParameterArray.new(@tenant, self)
      @refresh_history = RefreshArray.new(@tenant, self)
    end

    def get_data(id)
      @tenant.get("/groups/#{@workspace.id}/datasets/#{id}")
    end

    def data_to_attributes(data)
      {
        id: data[:id],
        name: data[:name],
        add_rows_API_enabled: data[:addRowsAPIEnabled],
        configured_by: data[:configuredBy],
        is_refreshable: data[:isRefreshable],
        is_effective_identity_required: data[:isEffectiveIdentityRequired],
        is_effective_identity_roles_required: data[:isEffectiveIdentityRolesRequired],
        is_on_prem_gateway_required: data[:isOnPremGatewayRequired],
        target_storage_mode: data[:targetStorageMode],
      }
    end

    def update_parameter(name, value)
      @tenant.post("/groups/#{workspace.id}/datasets/#{id}/Default.UpdateParameters") do |req|
        req.body = {
          updateDetails: [{name: name, newValue: value.to_s}]
        }.to_json
      end
      @parameters.reload
      true
    end

    def refresh_history(entries_to_load = 1)
      @refresh_history.entries_to_load = entries_to_load
      @refresh_history
    end

    def last_refresh
      @refresh_history.first
    end

    def refresh
      @tenant.post("/groups/#{workspace.id}/datasets/#{id}/refreshes") do |req|
        req.body = {
          notifyOption: "NoNotification"
        }.to_json
      end
      @refresh_history.reload
      true
    end

    def delete
      @tenant.delete("/groups/#{workspace.id}/datasets/#{id}")
      @workspace.datasets.reload
      true
    end

    def bind_to_gateway(gateway, gateway_datasource)
      @tenant.post("/groups/#{workspace.id}/datasets/#{id}/Default.BindToGateway") do |req|
        req.body = {
          gatewayObjectId: gateway.id,
          datasourceObjectIds: [gateway_datasource.id]
        }.to_json
      end
      true
    end

  end

  class DatasetArray < Array

    def initialize(tenant, workspace)
      super(tenant, workspace)
      @workspace = workspace
    end

    def self.get_class
      Dataset
    end

    def get_data
      @tenant.get("/groups/#{@workspace.id}/datasets")[:value]
    end
  end
end