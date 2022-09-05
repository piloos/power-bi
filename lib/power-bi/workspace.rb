module PowerBI
  class Workspace < Object
    attr_reader :reports, :datasets, :users

    class UploadError < PowerBI::Error ; end

    def initialize(tenant, parent, id = nil)
      super(tenant, id)
      @reports = ReportArray.new(@tenant, self)
      @datasets = DatasetArray.new(@tenant, self)
      @users = UserArray.new(@tenant, self)
    end

    def get_data(id)
      @tenant.get("/groups", {'$filter': "id eq #{id}"})[:value].first
    end

    def data_to_attributes(data)
      {
        id: data[:id],
        is_read_only: data[:isReadOnly],
        is_on_dedicated_capacity: data[:isOnDedicatedCapacity],
        name: data[:name],
      }
    end

    def upload_pbix(file, dataset_name, timeout: 30)
      data = @tenant.post_file("/groups/#{@id}/imports", file, {datasetDisplayName: dataset_name})
      import_id = data[:id]
      success = false
      iterations = 0
      status_history = ''
      old_status = ''
      while !success
        sleep 0.5
        iterations += 1
        raise UploadError.new("Upload did not succeed after #{timeout} seconds. Status history:#{status_history}") if iterations > (2 * timeout)
        new_status = @tenant.get("/groups/#{@id}/imports/#{import_id}")[:importState].to_s
        success = (new_status == "Succeeded")
        if new_status != old_status
          status_history += "\nStatus change after #{iterations/2}s: '#{old_status}' --> '#{new_status}'"
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

    def report(id)
      Report.new(@tenant, self, id)
    end

    def dataset(id)
      Dataset.new(@tenant, self, id)
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
      Workspace.instantiate_from_data(@tenant, nil, data)
    end

    def get_data
      @tenant.get("/groups")[:value]
    end
  end
end