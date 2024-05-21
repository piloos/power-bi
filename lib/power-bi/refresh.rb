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
    attr_reader :entries_to_load

    def initialize(tenant, dataset)
      super(tenant, dataset)
      @dataset = dataset
      @entries_to_load = 1
    end

    def self.get_class
      Refresh
    end

    def entries_to_load=(entries_to_load)
      if entries_to_load > @entries_to_load
        @entries_to_load = entries_to_load
        reload
      end
    end

    def get_data
      @tenant.get("/groups/#{@dataset.workspace.id}/datasets/#{@dataset.id}/refreshes", {'$top': @entries_to_load.to_s})[:value]
    end
  end
end