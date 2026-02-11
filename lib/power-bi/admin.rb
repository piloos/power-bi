module PowerBI
  class Admin

    def initialize(tenant)
      @tenant = tenant
    end

    def get_user_artifact_access(user_id, artifact_types: nil)
      if artifact_types
        params = {artifactTypes: artifact_types.join(',')}
      else
        params = {}
      end

      url = "/admin/users/#{user_id}/artifactAccess"

      resp = @tenant.get(url, params)
      data = resp[:ArtifactAccessEntities]

      continuation_token = resp[:continuationToken]

      while continuation_token
        params = {continuationToken: "'#{continuation_token}'"}
        resp = @tenant.get(url, params)
        data += resp[:ArtifactAccessEntities]
        continuation_token = resp[:continuationToken] ? URI::decode_uri_component(resp[:continuationToken]) : nil
      end

      data
    end

    def get_workspaces(filter: nil, expand: nil)
      base_params = {}
      base_params[:$filter] = filter if filter
      base_params[:$expand] = expand if expand

      @tenant.get_paginated('/admin/groups', base_params: base_params)
    end

    def force_delete_workspace_by_workspace_name(user_email, workspace_name)
      workspace = get_workspaces(filter: "name eq '#{workspace_name}' and state eq 'Active'").first
      add_user(user_email, workspace[:id], access_right: "Admin")
      @tenant.workspace(workspace[:id]).delete
    end

    def force_delete_workspace_by_workspace_id(user_email, workspace_id)
      add_user(user_email, workspace_id, access_right: "Admin")
      @tenant.workspace(workspace_id).delete
    end

    private

    def add_user(user_email, workspace_id, access_right: "Admin")
      @tenant.post("/admin/groups/#{workspace_id}/users") do |req|
        req.body = {
          emailAddress: user_email,
          groupUserAccessRight: access_right,
        }.to_json
      end
    end

  end
end