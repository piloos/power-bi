module PowerBI
  class Page < Object
    attr_reader :report

    def initialize(tenant, parent, id = nil)
      super(tenant, id)
      @report = parent
    end

    def data_to_attributes(data)
      {
        name: data[:name],
        display_name: data[:displayName],
        order: data[:order],
      }
    end

  end

  class PageArray < Array

    def initialize(tenant, report)
      super(tenant, report)
      @report = report
    end

    def self.get_class
      Page
    end

    def get_data
      @tenant.get("/groups/#{@report.workspace.id}/reports/#{@report.id}/pages")[:value]
    end
  end
end