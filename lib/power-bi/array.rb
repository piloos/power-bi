module PowerBI

  class Array

    def initialize(tenant, parent = nil)
      @fulfilled = false
      @content = nil
      @tenant = tenant
      @parent = parent
    end

    def reload
      @fulfilled = false
      @content = nil
      self
    end

    private

    def get_content
      unless @fulfilled
        klass = self.class.get_class
        @content = get_data.map { |d| klass.instantiate_from_data(@tenant, @parent, d) }
        @fulfilled = true
      end
      @content
    end

    def method_missing(method, *args, &block)
      get_content.send(method, *args, &block)
    end
  end

end