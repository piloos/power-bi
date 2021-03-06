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

    def upload_pbix(file, dataset_name, timeout: 30)
      data = @tenant.post_file("/groups/#{@id}/imports", file, {datasetDisplayName: dataset_name})
      import_id = data[:id]
      success = false
      iterations = 0
      status_history = ''
      old_status = ''
      while !success
        sleep 0.1
        iterations += 1
        raise UploadError.new("Upload did not succeed after #{timeout} seconds. Status history:#{status_history}") if iterations > (10 * timeout)
        new_status = @tenant.get("/groups/#{@id}/imports/#{import_id}")[:importState].to_s
        success = (new_status == "Succeeded")
        if new_status != old_status
          status_history += "\nStatus change after #{iterations/10.0}s: '#{old_status}' --> '#{new_status}'"
          old_status = new_status
        end
      end
      @reports.reload
      @datasets.reload
      true
    end

    def delete
      @tenant.delete("/groups/#{@id}")
      @tenant.workspaces.reload
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