module PowerBI
  class Refresh
    attr_reader :refresh_type, :start_time, :end_time, :service_exception_json, :status, :request_id

    def initialize(tenant, data)
      @id = data[:id]
      @refresh_type = data[:refreshType]
      @start_time = DateTime.iso8601(data[:startTime])
      @end_time = DateTime.iso8601(data[:endTime])
      @service_exception_json = data[:serviceExceptionJson]
      @status = data[:status]
      @request_id = data[:requestId]
    end

  end

  class RefreshArray < Array

    def initialize(tenant, dataset)
      super(tenant)
      @dataset = dataset
    end

    def self.get_class
      Refresh
    end

    def get_data
      @tenant.get("/groups/#{@dataset.workspace.id}/datasets/#{@dataset.id}/refreshes", {'$top': '3'})[:value]
    end
  end
end