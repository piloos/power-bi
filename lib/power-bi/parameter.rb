module PowerBI
  class Parameter
    attr_reader :name, :type, :is_required, :current_value

    def initialize(tenant, data)
      @name = data[:name]
      @type = data[:type]
      @is_required = data[:isRequired]
      @current_value = data[:currentValue]
    end

  end

  class ParameterArray < Array

    def initialize(tenant, dataset)
      super(tenant)
      @dataset = dataset
    end

    def self.get_class
      Parameter
    end

    def get_data
      @tenant.get("/groups/#{@dataset.workspace.id}/datasets/#{@dataset.id}/parameters")[:value]
    end
  end
end