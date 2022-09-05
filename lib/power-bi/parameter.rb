module PowerBI
  class Parameter < Object
    attr_reader :dataset

    def initialize(tenant, parent, id = nil)
      super(tenant, id)
      @dataset = parent
    end

    def data_to_attributes(data)
      {
        name: data[:name],
        type: data[:type],
        is_required: data[:isRequired],
        current_value: data[:currentValue],
      }
    end

  end

  class ParameterArray < Array

    def initialize(tenant, dataset)
      super(tenant, dataset)
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