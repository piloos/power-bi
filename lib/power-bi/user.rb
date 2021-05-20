module PowerBI
  class User
    attr_reader :email_address, :group_user_access_right

    def initialize(tenant, data)
      @email_address = data[:emailAddress]
      @group_user_access_right = data[:groupUserAccessRight]
      @workspace = data[:workspace]
      @tenant = tenant
    end

    def delete
      @tenant.delete("/groups/#{@workspace.id}/users/#{@email_address}")
      @workspace.users.reload
    end

  end

  class UserArray < Array

    def initialize(tenant, workspace)
      super(tenant)
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
      data = @tenant.get("/groups/#{@workspace.id}/users")[:value]
      data.each { |d| d[:workspace] = @workspace }
    end
  end
end