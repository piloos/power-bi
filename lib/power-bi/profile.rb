module PowerBI
  class Profile < Object

    def initialize(tenant, parent, id = nil)
      super(tenant, id)
    end

    def get_data(id)
      @tenant.get("/profiles/#{id}", use_profile: false)
    end

    def data_to_attributes(data)
      {
        id: data[:id],
        display_name: data[:displayName],
      }
    end

    def delete
      @tenant.delete("/profiles/#{@id}", use_profile: false)
      @tenant.profiles.reload
      true
    end

  end

  class ProfileArray < Array
    def self.get_class
      Profile
    end

    def create(name)
      data = @tenant.post("/profiles", use_profile: false) do |req|
        req.body = {displayName: name}.to_json
      end
      self.reload
      Profile.instantiate_from_data(@tenant, nil, data)
    end

    def get_data
      @tenant.get("/profiles", use_profile: false)[:value]
    end
  end
end