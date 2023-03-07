module PowerBI
  class Report < Object
    attr_reader :workspace, :pages

    class ExportToFileError < PowerBI::Error ; end

    def initialize(tenant, parent, id = nil)
      super(tenant, id)
      @workspace = parent
      @pages = PageArray.new(@tenant, self)
    end

    def get_data(id)
      @tenant.get("/groups/#{@workspace.id}/reports/#{id}")
    end

    def data_to_attributes(data)
      {
        id: data[:id],
        report_type: data[:reportType],
        name: data[:name],
        web_url: data[:webUrl],
        embed_url: data[:embedUrl],
        is_from_pbix: data[:isFromPbix],
        is_owned_by_me: data[:isOwnedByMe],
        dataset_id: data[:datasetId],
      }
    end

    def clone(target_workspace, new_report_name)
      data = @tenant.post("/reports/#{@id}/Clone") do |req|
        req.body = {
          name: new_report_name,
          targetWorkspaceId: target_workspace.id
        }.to_json
      end
      target_workspace.reports.reload
      data[:workspace] = target_workspace
      Report.new(@tenant, data)
    end

    def rebind(target_dataset)
      @tenant.post("/groups/#{workspace.id}/reports/#{id}/Rebind") do |req|
        req.body = {
          datasetId: target_dataset.id
        }.to_json
      end
      true
    end

    def export_to_file(filename, format: 'PDF', timeout: 300)
      # post
      data = @tenant.post("/groups/#{workspace.id}/reports/#{id}/ExportTo") do |req|
        req.body = {
          format: format
        }.to_json
      end
      export_id = data[:id]

      # poll
      success = false
      iterations = 0
      status_history = ''
      old_status = ''
      while !success
        sleep 0.1
        iterations += 1
        raise ExportToFileError.new("Report export to file did not succeed after #{timeout} seconds. Status history:#{status_history}") if iterations > (10 * timeout)
        new_status = @tenant.get("/groups/#{workspace.id}/reports/#{id}/exports/#{export_id}")[:status].to_s
        success = (new_status == "Succeeded")
        if new_status != old_status
          status_history += "\nStatus change after #{iterations/10.0}s: '#{old_status}' --> '#{new_status}'"
          old_status = new_status
        end
      end

      # get and write file
      data = @tenant.get_raw("/groups/#{workspace.id}/reports/#{id}/exports/#{export_id}/file")
      File.open(filename, "wb") { |f| f.write(data) }
    end

    def embed_token(access_level: 'View', lifetime_in_minutes: 60)
      data = @tenant.post("/groups/#{workspace.id}/reports/#{id}/GenerateToken") do |req|
        req.body = {
          accessLevel: access_level,
          lifetimeInMinutes: lifetime_in_minutes
        }.to_json
      end
      {
        token: data[:token],
        expiration: Time.parse(data[:expiration])
      }
    end

  end

  class ReportArray < Array

    def initialize(tenant, workspace)
      super(tenant, workspace)
      @workspace = workspace
    end

    def self.get_class
      Report
    end

    def get_data
      @tenant.get("/groups/#{@workspace.id}/reports")[:value]
    end
  end
end