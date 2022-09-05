module PowerBI
  class Refresh < Object
    attr_reader :dataset

    def initialize(tenant, parent, id = nil)
      super(tenant, id)
      @dataset = parent
    end

    def data_to_attributes(data)
      {
        id: data[:id],
        refresh_type: data[:refreshType],
        start_time: DateTime.iso8601(data[:startTime]),
        end_time: data[:endTime] ? DateTime.iso8601(data[:endTime]) : nil,
        service_exception_json: data[:serviceExceptionJson],
        status: data[:status],
        request_id: data[:requestId],
      }
    end

  end

  class RefreshArray < Array

    def initialize(tenant, dataset)
      super(tenant, dataset)
      @dataset = dataset
    end

    def self.get_class
      Refresh
    end

    def get_data
      @tenant.get("/groups/#{@dataset.workspace.id}/datasets/#{@dataset.id}/refreshes", {'$top': '1'})[:value]
    end
  end
end