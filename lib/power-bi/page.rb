module PowerBI
  class Page
    attr_reader :display_name, :name, :order, :report

    def initialize(tenant, data)
      @name = data[:Name]
      @display_name = data[:displayName]
      @order = data[:order]
      @report = data[:report]
      @tenant = tenant
    end
  end

  class PageArray < Array

    def initialize(tenant, report)
      super(tenant)
      @report = report
    end

    def self.get_class
      Page
    end

    def get_data
      data = @tenant.get("/groups/#{@report.workspace.id}/reports/#{@report.id}/pages")[:value]
      data.each { |d| d[:report] = @report }
    end
  end
end