module PowerBI
  class Workspace
    attr_reader :name, :is_read_only, :is_on_dedicated_capacity, :id, :reports, :datasets

    class UploadError < PowerBI::Error ; end

    def initialize(tenant, data)
      @id = data[:id]
      @is_read_only = data[:isReadOnly]
      @is_on_dedicated_capacity = data[:isOnDedicatedCapacity]
      @name = data[:name]
      @tenant = tenant
      @reports = ReportArray.new(@tenant, self)
      @datasets = DatasetArray.new(@tenant, self)
    end

    def upload_pbix(file, dataset_name)
      data = @tenant.post_file("/groups/#{@id}/imports", file, {datasetDisplayName: dataset_name})
      import_id = data[:id]
      success = false
      iterations = 0
      while !success
        sleep 0.1
        iterations += 1
        raise UploadError if iterations > 300 # 30 seconds
        status = @tenant.get("/groups/#{@id}/imports/#{import_id}")
        success = (status[:importState] == "Succeeded")
      end
      @reports.reload
      @datasets.reload
      true
    end

    # TODO LATER: the 'Viewer' acces right is currently not settable throught the API. Fix that later
    def add_user(email_address, access_right = 'Member')
      @tenant.post("/groups/#{id}/users") do |req|
        req.body = {
          emailAddress: email_address,
          groupUserAccessRight: access_right
        }.to_json
      end
      true
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