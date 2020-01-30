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
  end
end