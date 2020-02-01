module PowerBI
  class Workspace
    attr_reader :name, :is_read_only, :is_on_dedicated_capacity, :id

    def initialize(tenant, data)
      @id = data[:id]
      @is_read_only = data[:isReadOnly]
      @is_on_dedicated_capacity = data[:isOnDedicatedCapacity]
      @name = data[:name]
      @tenant = tenant
    end

    def reports
      @reports ||= ReportArray.new(@tenant, self)
    end
  end

  class WorkspaceArray < Array
    def self.get_class
      Workspace
    end

    def create(name)
      data = @tenant.post("/groups", {workspaceV2: 'True'}) do |req|
        req.body = {name: name}.to_json
      end
      self.reload
      Workspace.new(@tenant, data)
    end

    def get_data
      @tenant.get("/groups")[:value]
    end
  end
end