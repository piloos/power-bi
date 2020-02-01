module PowerBI
  class Report
    attr_reader :name, :id, :report_type, :web_url, :embed_url, :is_from_pbix, :is_owned_by_me, :dataset_id

    def initialize(tenant, data)
      @id = data[:id]
      @report_type = data[:reportType]
      @name = data[:name]
      @web_url = data[:webUrl]
      @embed_url = data[:embedUrl]
      @is_from_pbix = data[:isFromPbix]
      @is_owned_by_me = data[:isOwnedByMe]
      @dataset_id = data[:datasetId]
      @workspace = data[:workspace]
      @tenant = tenant
    end

  end

  class ReportArray < Array

    def initialize(tenant, workspace)
      super(tenant)
      @workspace = workspace
    end

    def self.get_class
      Report
    end

    def get_data
      data = @tenant.get("/groups/#{@workspace.id}/reports")[:value]
      data.each { |d| d[:workspace] = @workspace }
    end
  end
end