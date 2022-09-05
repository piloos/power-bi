module PowerBI

  class Object
    attr_reader :id

    class UnkownAttributeError < PowerBI::Error ; end
    class UnspecifiedIdError < PowerBI::Error ; end

    def initialize(tenant, id = nil)
      @id = id
      @fulfilled = false
      @not_found = nil
      @attributes = nil
      @tenant = tenant
    end

    def set_attributes(data)
      @fulfilled = true
      @not_found = false
      @id = data[:id]
      @attributes = data_to_attributes(data)
    end

    def reload
      @fulfilled = false
      @attributes = nil
      self
    end

    def self.instantiate_from_data(tenant, parent, data)
      o = new(tenant, parent)
      o.set_attributes(data)
      o
    end

    private

    def get_attributes
      unless @fulfilled
        raise UnspecifiedIdError unless @id
        begin
          set_attributes(get_data(@id))
        rescue PowerBI::NotFoundError
          @not_found = true
          raise PowerBI::NotFoundError
        end
      end
      @attributes
    end

    def method_missing(method, *args, &block)
      get_attributes.fetch(method.to_sym) do
        raise UnkownAttributeError.new "Unknown attribute #{method}"
      end
    end

  end

end