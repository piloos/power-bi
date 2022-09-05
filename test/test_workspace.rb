require 'test_helper'

# class WorkspaceTest < Minitest::Test

#   def test_the_truth
#     assert true
#   end

# end

module PowerBI
  describe Workspace do

    describe "workspace" do

      before do
        @stub = stub_request(:get, "https://api.powerbi.com/v1.0/myorg/groups").to_return(status: 200, body: "{\r\n  \"@odata.context\":\"http://wabi-west-europe-d-primary-redirect.analysis.windows.net/v1.0/myorg/$metadata#groups\",\"@odata.count\":4,\"value\":[\r\n    {\r\n      \"id\":\"58fc01f1-461d-4cff-9f8c-88c5442cf7a5\",\"isReadOnly\":false,\"isOnDedicatedCapacity\":false,\"name\":\"ZooTest\"\r\n    },{\r\n      \"id\":\"b103bf93-fc39-496d-aa89-dd759f2d14f7\",\"isReadOnly\":false,\"isOnDedicatedCapacity\":false,\"name\":\"Bizzcontrol WS One2\"\r\n    },{\r\n      \"id\":\"c0d950cb-8f80-40e7-9bbe-8f8c8faeb20e\",\"isReadOnly\":false,\"isOnDedicatedCapacity\":false,\"name\":\"ProBuFisc\"\r\n    },{\r\n      \"id\":\"5fcce4f4-87db-4770-acd8-0aa57d205349\",\"isReadOnly\":false,\"isOnDedicatedCapacity\":false,\"name\":\"Zoo1\"\r\n    }\r\n  ]\r\n}", headers: {})
        @tenant = Tenant.new(->{dummy_token})
        @workspace = @tenant.workspaces.first
      end

      it "should have name, id, is_on_dedicated_capacity and is_read_only attributes" do
        assert_equal "58fc01f1-461d-4cff-9f8c-88c5442cf7a5", @workspace.id
        assert_equal "ZooTest", @workspace.name
        assert_equal false, @workspace.is_on_dedicated_capacity
        assert_equal false, @workspace.is_read_only
      end

    end

    describe "when getting workspaces" do

      before do
        @stub = stub_request(:get, "https://api.powerbi.com/v1.0/myorg/groups").to_return(status: 200, body: "{\r\n  \"@odata.context\":\"http://wabi-west-europe-d-primary-redirect.analysis.windows.net/v1.0/myorg/$metadata#groups\",\"@odata.count\":4,\"value\":[\r\n    {\r\n      \"id\":\"58fc01f1-461d-4cff-9f8c-88c5442cf7a5\",\"isReadOnly\":false,\"isOnDedicatedCapacity\":false,\"name\":\"ZooTest\"\r\n    },{\r\n      \"id\":\"b103bf93-fc39-496d-aa89-dd759f2d14f7\",\"isReadOnly\":false,\"isOnDedicatedCapacity\":false,\"name\":\"Bizzcontrol WS One2\"\r\n    },{\r\n      \"id\":\"c0d950cb-8f80-40e7-9bbe-8f8c8faeb20e\",\"isReadOnly\":false,\"isOnDedicatedCapacity\":false,\"name\":\"ProBuFisc\"\r\n    },{\r\n      \"id\":\"5fcce4f4-87db-4770-acd8-0aa57d205349\",\"isReadOnly\":false,\"isOnDedicatedCapacity\":false,\"name\":\"Zoo1\"\r\n    }\r\n  ]\r\n}", headers: {})
        @tenant = Tenant.new(->{dummy_token})
      end

      it 'should return a WorkspaceArray' do
        ws = @tenant.workspaces
        assert ws.is_a? WorkspaceArray
      end

      it 'should only query when we actually need the content' do
        remove_request_stub(@stub)
        @tenant.workspaces
      end

      it 'should be of length 4' do
        ws = @tenant.workspaces
        assert_equal 4, ws.length
      end

      it 'should cache the results' do
        @tenant.workspaces.length
        remove_request_stub(@stub)
        @tenant.workspaces.length
      end

      it 'should allow to reload the results' do
        ws = @tenant.workspaces
        assert_equal 4, ws.length
        @stub = stub_request(:get, "https://api.powerbi.com/v1.0/myorg/groups").to_return(status: 200, body: "{\r\n  \"@odata.context\":\"http://wabi-west-europe-d-primary-redirect.analysis.windows.net/v1.0/myorg/$metadata#groups\",\"@odata.count\":4,\"value\":[\r\n    {\r\n      \"id\":\"58fc01f1-461d-4cff-9f8c-88c5442cf7a5\",\"isReadOnly\":false,\"isOnDedicatedCapacity\":false,\"name\":\"ZooTest\"\r\n    },{\r\n      \"id\":\"b103bf93-fc39-496d-aa89-dd759f2d14f7\",\"isReadOnly\":false,\"isOnDedicatedCapacity\":false,\"name\":\"Bizzcontrol WS One2\"\r\n    },{\r\n      \"id\":\"c0d950cb-8f80-40e7-9bbe-8f8c8faeb20e\",\"isReadOnly\":false,\"isOnDedicatedCapacity\":false,\"name\":\"ProBuFisc\"\r\n    }\r\n  ]\r\n}", headers: {})
        ws = @tenant.workspaces
        assert_equal 4, ws.length
        assert_equal 3, ws.reload.length
      end

    end

    describe "creating workspaces" do

      before do
        @tenant = Tenant.new(->{dummy_token})
      end

      it "can create a workspace" do
        stub_request(:post, "https://api.powerbi.com/v1.0/myorg/groups?workspaceV2=True").
        with(body: "{\"name\":\"TheNewWS\"}").
        to_return(status: 200, body: "{\r\n  \"@odata.context\":\"http://wabi-west-europe-d-primary-redirect.analysis.windows.net/v1.0/myorg/$metadata#groups/$entity\",\"id\":\"9c8e8340-fe66-4dbb-865a-d4ca7ce205e6\",\"isReadOnly\":false,\"isOnDedicatedCapacity\":false,\"name\":\"TheNewWS\"\r\n}", headers: {})
        ws = @tenant.workspaces.create('TheNewWS')
        assert ws.is_a? Workspace
      end

      it "raise an error when creating an already existing workspace" do
        stub_request(:post, "https://api.powerbi.com/v1.0/myorg/groups?workspaceV2=True").
        with(body: "{\"name\":\"TheNewWS\"}").
        to_return(status: 400, body: "{\"error\":{\"code\":\"PowerBIEntityAlreadyExists\",\"pbi.error\":{\"code\":\"PowerBIEntityAlreadyExists\",\"parameters\":{},\"details\":[]}}}", headers: {})

        assert_raises APIError do
          @tenant.workspaces.create('TheNewWS')
        end
      end

    end

    describe "upload pbix" do

      before do
        @tenant = Tenant.new(->{dummy_token})
        @ws = Workspace.instantiate_from_data(@tenant, nil, {id: 7})
      end

      it "possible to upload pbix" do
        stub_request(:post, "https://api.powerbi.com/v1.0/myorg/groups/7/imports?datasetDisplayName=newstuff").to_return(status: 202, body: "{\"id\": \"d02b8896-e247-4d83-ae5a-014028cb0665\"}")
        stub_request(:get, "https://api.powerbi.com/v1.0/myorg/groups/7/imports/d02b8896-e247-4d83-ae5a-014028cb0665").
          to_return(status: 200, body: "{\r\n  \"@odata.context\":\"http://api.powerbi.com/v1.0/myorg/groups/ba4084ce-0fc6-47f1-864a-d5b1a0df970a/$metadata#imports/$entity\",\"id\":\"9442dde0-e1e2-477d-b7a3-a922684227d0\",\"importState\":\"Publishing\",\"createdDateTime\":\"2020-02-08T06:02:44.883Z\",\"updatedDateTime\":\"2020-02-08T06:02:44.883Z\",\"name\":\"uploaded_stuff\",\"connectionType\":\"import\",\"source\":\"Upload\",\"datasets\":[\r\n    \r\n  ],\"reports\":[\r\n    \r\n  ]\r\n}").
          to_return(status: 200, body: "{\r\n  \"@odata.context\":\"http://api.powerbi.com/v1.0/myorg/groups/ba4084ce-0fc6-47f1-864a-d5b1a0df970a/$metadata#imports/$entity\",\"id\":\"9442dde0-e1e2-477d-b7a3-a922684227d0\",\"importState\":\"Succeeded\",\"createdDateTime\":\"2020-02-08T06:02:44.883Z\",\"updatedDateTime\":\"2020-02-08T06:02:44.883Z\",\"name\":\"uploaded_stuff\",\"connectionType\":\"import\",\"source\":\"Upload\",\"datasets\":[\r\n    {\r\n      \"id\":\"ed063b93-15b6-4b54-b8aa-f2f2bfc5c83c\",\"name\":\"uploaded_stuff\",\"webUrl\":\"https://app.powerbi.com/groups/ba4084ce-0fc6-47f1-864a-d5b1a0df970a/datasets/ed063b93-15b6-4b54-b8aa-f2f2bfc5c83c\",\"targetStorageMode\":\"Unknown\"\r\n    }\r\n  ],\"reports\":[\r\n    {\r\n      \"id\":\"624fc545-c344-4146-bb82-f4d4d9a91a79\",\"reportType\":\"PowerBIReport\",\"name\":\"uploaded_stuff\",\"webUrl\":\"https://app.powerbi.com/groups/ba4084ce-0fc6-47f1-864a-d5b1a0df970a/reports/624fc545-c344-4146-bb82-f4d4d9a91a79\",\"embedUrl\":\"https://app.powerbi.com/reportEmbed?reportId=624fc545-c344-4146-bb82-f4d4d9a91a79&config=eyJjbHVzdGVyVXJsIjoiaHR0cHM6Ly9XQUJJLVdFU1QtRVVST1BFLUQtUFJJTUFSWS1yZWRpcmVjdC5hbmFseXNpcy53aW5kb3dzLm5ldCJ9\"\r\n    }\r\n  ]\r\n}")
        result = @ws.upload_pbix('./test/zoo_from_sharepoint.pbix', 'newstuff')
        assert result
      end

      it "meaningful error on upload pbix timeout" do
        stub_request(:post, "https://api.powerbi.com/v1.0/myorg/groups/7/imports?datasetDisplayName=newstuff").to_return(status: 202, body: "{\"id\": \"d02b8896-e247-4d83-ae5a-014028cb0665\"}")
        stub_request(:get, "https://api.powerbi.com/v1.0/myorg/groups/7/imports/d02b8896-e247-4d83-ae5a-014028cb0665").
          to_return(status: 200, body: "{\r\n  \"@odata.context\":\"http://api.powerbi.com/v1.0/myorg/groups/ba4084ce-0fc6-47f1-864a-d5b1a0df970a/$metadata#imports/$entity\",\"id\":\"9442dde0-e1e2-477d-b7a3-a922684227d0\",\"importState\":\"Publishing\",\"createdDateTime\":\"2020-02-08T06:02:44.883Z\",\"updatedDateTime\":\"2020-02-08T06:02:44.883Z\",\"name\":\"uploaded_stuff\",\"connectionType\":\"import\",\"source\":\"Upload\",\"datasets\":[\r\n    \r\n  ],\"reports\":[\r\n    \r\n  ]\r\n}")
        error = assert_raises PowerBI::Workspace::UploadError do
          @ws.upload_pbix('./test/zoo_from_sharepoint.pbix', 'newstuff', timeout: 1)
        end
        assert_equal "Upload did not succeed after 1 seconds. Status history:\nStatus change after 0s: '' --> 'Publishing'", error.message
      end

    end
  end
end