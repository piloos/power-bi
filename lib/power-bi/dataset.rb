module PowerBI
  class Dataset
    attr_reader :id, :name, :add_rows_API_enabled, :configured_by, :is_refreshable, :is_effective_identity_required,
      :is_effective_identity_roles_required, :is_on_prem_gateway_required, :target_storage_mode, :workspace, :datasources,
      :parameters

    def initialize(tenant, data)
      @id = data[:id]
      @name = data[:name]
      @add_rows_API_enabled = data[:addRowsAPIEnabled]
      @configured_by = data[:configuredBy]
      @is_refreshable = data[:isRefreshable]
      @is_effective_identity_required = data[:isEffectiveIdentityRequired]
      @is_effective_identity_roles_required = data[:isEffectiveIdentityRolesRequired]
      @is_on_prem_gateway_required = data[:isOnPremGatewayRequired]
      @target_storage_mode = data[:targetStorageMode]
      @workspace = data[:workspace]
      @tenant = tenant
      @datasources = DatasourceArray.new(@tenant, self)
      @parameters = ParameterArray.new(@tenant, self)
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


    def refresh
      @tenant.post("/groups/#{workspace.id}/datasets/#{id}/refreshes") do |req|
        req.body = {
          notifyOption: "NoNotification"
        }.to_json
      end
      true
    end

  end

  class DatasetArray < Array

    def initialize(tenant, workspace)
      super(tenant)
      @workspace = workspace
    end

    def self.get_class
      Dataset
    end

    def get_data
      data = @tenant.get("/groups/#{@workspace.id}/datasets")[:value]
      data.each { |d| d[:workspace] = @workspace }
    end
  end
end