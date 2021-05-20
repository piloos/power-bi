module PowerBI
  class User
    attr_reader :email_address, :group_user_access_right, :display_name, :identifier, :principal_type

    def initialize(tenant, data)
      @email_address = data[:emailAddress]
      @group_user_access_right = data[:groupUserAccessRight]
      @display_name = data[:displayName]
      @identifier = data[:identifier]
      @principal_type = data[:principalType]
      @workspace = data[:workspace]
      @tenant = tenant
    end

    def delete_user
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

    def create(email_address, identifier, group_user_access_right, display_name, principal_type)
      @tenant.post("/groups/#{@workspace.id}/users") do |req|
        req.body = {
          displayName: display_name,
          emailAddress: email_address,
          identifier: identifier,
          groupUserAccessRight: group_user_access_right,
          principalType: principal_type
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