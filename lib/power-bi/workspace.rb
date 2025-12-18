module PowerBI
  class Workspace < Object
    attr_reader :reports, :datasets, :users

    class UploadError < PowerBI::Error ; end
    class CapacityAssignmentError < PowerBI::Error ; end

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

    def assign_to_capacity(capacity, timeout: 30)
      _assign_to_capacity(capacity.id, timeout: timeout)
    end

    def unassign_from_capacity(timeout: 30)
      _assign_to_capacity('00000000-0000-0000-0000-000000000000', timeout: timeout)
    end

    private

    def _assign_to_capacity(capacity_id, timeout: 30)
      @tenant.post("/groups/#{@id}/AssignToCapacity") do |req|
        req.body = {
          capacityId: capacity_id,
        }.to_json
      end

      success = false
      iterations = 0
      status_history = ''
      old_status = ''
      while !success
        sleep 0.5
        iterations += 1
        raise CapacityAssignmentError.new("(Un)assignment did not succeed after #{timeout} seconds. Status history:#{status_history}") if iterations > (2 * timeout)
        new_status = @tenant.get("/groups/#{@id}/CapacityAssignmentStatus")[:status].to_s
        success = (new_status == "CompletedSuccessfully")
        if new_status != old_status
          status_history += "\nStatus change after #{iterations/2}s: '#{old_status}' --> '#{new_status}'"
          old_status = new_status
        end
      end
      self.reload
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
      @tenant.get_paginated("/groups")
    end
  end
end