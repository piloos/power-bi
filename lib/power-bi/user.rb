module PowerBI
  class User < Object
    attr_reader :workspace

    def initialize(tenant, parent, id = nil)
      super(tenant, id)
      @workspace = parent
    end

    def data_to_attributes(data)
      {
        email_address: data[:emailAddress],
        group_user_access_right: data[:groupUserAccessRight],
        display_name: data[:displayName],
        identifier: data[:identifier],
        principal_type: data[:principalType],
      }
    end

    def delete
      @tenant.delete("/groups/#{@workspace.id}/users/#{email_address}")
      @workspace.users.reload
    end

  end

  class UserArray < Array

    def initialize(tenant, workspace)
      super(tenant, workspace)
      @workspace = workspace
    end

    def self.get_class
      User
    end

    def create(email_address, access_right: "Viewer")
      @tenant.post("/groups/#{@workspace.id}/users") do |req|
        req.body = {
          emailAddress: email_address,
          groupUserAccessRight: access_right
        }.to_json
      end
      self.reload
    end

    def get_data
      @tenant.get("/groups/#{@workspace.id}/users")[:value]
    end
  end
end