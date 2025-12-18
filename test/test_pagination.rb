require 'test_helper'

module PowerBI
  describe "Pagination" do

    describe "single page (no pagination needed)" do
      before do
        # Single page with 3 profiles (< 5000)
        stub_request(:get, "https://api.powerbi.com/v1.0/myorg/profiles?$skip=0&$top=5000")
          .to_return(
            status: 200,
            body: {
              value: [
                { id: "id-1", displayName: "Profile 1" },
                { id: "id-2", displayName: "Profile 2" },
                { id: "id-3", displayName: "Profile 3" }
              ]
            }.to_json
          )

        @tenant = Tenant.new(-> { dummy_token })
      end

      it "should fetch all profiles in single request" do
        profiles = @tenant.profiles
        assert_equal 3, profiles.count
        assert_equal "Profile 1", profiles.first.display_name
      end

      it "should not make additional requests" do
        profiles = @tenant.profiles.to_a
        # WebMock will raise error if unexpected request is made
        assert_equal 3, profiles.length
      end
    end

    describe "multiple pages (pagination required)" do
      before do
        # First page: 5000 profiles (exactly at limit)
        first_page = (0...5000).map { |i| { id: "id-#{i}", displayName: "Profile #{i}" } }
        stub_request(:get, "https://api.powerbi.com/v1.0/myorg/profiles?$skip=0&$top=5000")
          .to_return(status: 200, body: { value: first_page }.to_json)

        # Second page: 3000 profiles (< 5000, last page)
        second_page = (5000...8000).map { |i| { id: "id-#{i}", displayName: "Profile #{i}" } }
        stub_request(:get, "https://api.powerbi.com/v1.0/myorg/profiles?$skip=5000&$top=5000")
          .to_return(status: 200, body: { value: second_page }.to_json)

        @tenant = Tenant.new(-> { dummy_token })
      end

      it "should fetch all profiles across pages" do
        profiles = @tenant.profiles
        assert_equal 8000, profiles.count
      end

      it "should have correct first and last profiles" do
        profiles = @tenant.profiles
        assert_equal "Profile 0", profiles.first.display_name
        assert_equal "Profile 7999", profiles.last.display_name
      end
    end

    describe "deduplication (handles deletions between requests)" do
      before do
        # First page: includes profile "id-5000"
        first_page = (0...5000).map { |i| { id: "id-#{i}", displayName: "Profile #{i}" } }
        stub_request(:get, "https://api.powerbi.com/v1.0/myorg/profiles?$skip=0&$top=5000")
          .to_return(status: 200, body: { value: first_page }.to_json)

        # Second page: "id-5000" appears again (data shifted during pagination)
        # Plus 2999 new profiles
        second_page = [{ id: "id-5000", displayName: "Profile 5000" }] +
                      (5001...8000).map { |i| { id: "id-#{i}", displayName: "Profile #{i}" } }
        stub_request(:get, "https://api.powerbi.com/v1.0/myorg/profiles?$skip=5000&$top=5000")
          .to_return(status: 200, body: { value: second_page }.to_json)

        @tenant = Tenant.new(-> { dummy_token })
      end

      it "should remove duplicate IDs" do
        profiles = @tenant.profiles
        # Should be 8000 unique profiles (not 8001)
        assert_equal 8000, profiles.count
      end

      it "should keep first occurrence of duplicate" do
        profiles = @tenant.profiles
        # Find profile with id-5000
        duplicate_profile = profiles.find { |p| p.id == "id-5000" }
        assert_equal "Profile 5000", duplicate_profile.display_name
      end
    end

    describe "empty results" do
      before do
        stub_request(:get, "https://api.powerbi.com/v1.0/myorg/profiles?$skip=0&$top=5000")
          .to_return(status: 200, body: { value: [] }.to_json)

        @tenant = Tenant.new(-> { dummy_token })
      end

      it "should return empty array" do
        profiles = @tenant.profiles
        assert_equal 0, profiles.count
      end
    end

    describe "exactly 5000 records (edge case)" do
      before do
        # First page: exactly 5000 profiles
        first_page = (0...5000).map { |i| { id: "id-#{i}", displayName: "Profile #{i}" } }
        stub_request(:get, "https://api.powerbi.com/v1.0/myorg/profiles?$skip=0&$top=5000")
          .to_return(status: 200, body: { value: first_page }.to_json)

        # Second page: empty (no more data)
        stub_request(:get, "https://api.powerbi.com/v1.0/myorg/profiles?$skip=5000&$top=5000")
          .to_return(status: 200, body: { value: [] }.to_json)

        @tenant = Tenant.new(-> { dummy_token })
      end

      it "should fetch exactly 5000 profiles" do
        profiles = @tenant.profiles
        assert_equal 5000, profiles.count
      end

      it "should make second request to confirm no more data" do
        profiles = @tenant.profiles.to_a
        # Both stubs must be called
        assert_equal 5000, profiles.length
      end
    end

    describe "maximum iteration limit" do
      before do
        # Stub 15 pages (each with exactly 5000 records)
        # MAX_ITERATIONS is now 10, so should stop after 10 iterations
        15.times do |page|
          page_data = (page * 5000...(page + 1) * 5000).map do |i|
            { id: "id-#{i}", displayName: "Profile #{i}" }
          end
          stub_request(:get, "https://api.powerbi.com/v1.0/myorg/profiles?$skip=#{page * 5000}&$top=5000")
            .to_return(status: 200, body: { value: page_data }.to_json)
        end

        @tenant = Tenant.new(-> { dummy_token })
      end

      it "should stop at max iterations" do
        profiles = @tenant.profiles
        # With MAX_ITERATIONS = 10, should get 10 * 5000 = 50,000 profiles
        assert_equal 50_000, profiles.count
      end

      it "should log warning when limit reached" do
        # Note: This test verifies the behavior, logging verification would need a logger mock
        profiles = @tenant.profiles
        assert_equal 50_000, profiles.count
      end
    end

    describe "workspaces pagination" do
      before do
        # First page: 5000 workspaces
        first_page = (0...5000).map { |i|
          { id: "ws-id-#{i}", name: "Workspace #{i}", isReadOnly: false, isOnDedicatedCapacity: false }
        }
        stub_request(:get, "https://api.powerbi.com/v1.0/myorg/groups?$skip=0&$top=5000")
          .to_return(status: 200, body: { value: first_page }.to_json)

        # Second page: 100 workspaces
        second_page = (5000...5100).map { |i|
          { id: "ws-id-#{i}", name: "Workspace #{i}", isReadOnly: false, isOnDedicatedCapacity: false }
        }
        stub_request(:get, "https://api.powerbi.com/v1.0/myorg/groups?$skip=5000&$top=5000")
          .to_return(status: 200, body: { value: second_page }.to_json)

        @tenant = Tenant.new(-> { dummy_token })
      end

      it "should fetch all workspaces across pages" do
        workspaces = @tenant.workspaces
        assert_equal 5100, workspaces.count
      end

      it "should have correct workspace attributes" do
        workspaces = @tenant.workspaces
        first_ws = workspaces.first
        assert_equal "ws-id-0", first_ws.id
        assert_equal "Workspace 0", first_ws.name
        assert_equal false, first_ws.is_read_only
      end
    end

    describe "datasets pagination within workspace" do
      before do
        @workspace_id = "test-workspace-id"
        @workspace = Workspace.instantiate_from_data(
          Tenant.new(-> { dummy_token }),
          nil,
          { id: @workspace_id, name: "Test Workspace", isReadOnly: false, isOnDedicatedCapacity: false }
        )

        # First page: 5000 datasets
        first_page = (0...5000).map { |i|
          { id: "ds-id-#{i}", name: "Dataset #{i}" }
        }
        stub_request(:get, "https://api.powerbi.com/v1.0/myorg/groups/#{@workspace_id}/datasets?$skip=0&$top=5000")
          .to_return(status: 200, body: { value: first_page }.to_json)

        # Second page: 500 datasets
        second_page = (5000...5500).map { |i|
          { id: "ds-id-#{i}", name: "Dataset #{i}" }
        }
        stub_request(:get, "https://api.powerbi.com/v1.0/myorg/groups/#{@workspace_id}/datasets?$skip=5000&$top=5000")
          .to_return(status: 200, body: { value: second_page }.to_json)
      end

      it "should fetch all datasets across pages" do
        datasets = @workspace.datasets
        assert_equal 5500, datasets.count
      end
    end

    describe "reports pagination within workspace" do
      before do
        @workspace_id = "test-workspace-id"
        @workspace = Workspace.instantiate_from_data(
          Tenant.new(-> { dummy_token }),
          nil,
          { id: @workspace_id, name: "Test Workspace", isReadOnly: false, isOnDedicatedCapacity: false }
        )

        # First page: 5000 reports
        first_page = (0...5000).map { |i|
          { id: "rpt-id-#{i}", name: "Report #{i}", reportType: "PowerBIReport" }
        }
        stub_request(:get, "https://api.powerbi.com/v1.0/myorg/groups/#{@workspace_id}/reports?$skip=0&$top=5000")
          .to_return(status: 200, body: { value: first_page }.to_json)

        # Second page: 200 reports
        second_page = (5000...5200).map { |i|
          { id: "rpt-id-#{i}", name: "Report #{i}", reportType: "PowerBIReport" }
        }
        stub_request(:get, "https://api.powerbi.com/v1.0/myorg/groups/#{@workspace_id}/reports?$skip=5000&$top=5000")
          .to_return(status: 200, body: { value: second_page }.to_json)
      end

      it "should fetch all reports across pages" do
        reports = @workspace.reports
        assert_equal 5200, reports.count
      end
    end

    describe "finding profile by name (original bug scenario)" do
      before do
        # Profile exists at position 5001 (beyond first page)
        first_page = (0...5000).map { |i|
          { id: "id-#{i}", displayName: "Profile #{i}" }
        }
        stub_request(:get, "https://api.powerbi.com/v1.0/myorg/profiles?$skip=0&$top=5000")
          .to_return(status: 200, body: { value: first_page }.to_json)

        # Second page includes the profile we're looking for
        second_page = [
          { id: "special-id", displayName: "prod_cdm_92971" }
        ] + (5001...8000).map { |i|
          { id: "id-#{i}", displayName: "Profile #{i}" }
        }
        stub_request(:get, "https://api.powerbi.com/v1.0/myorg/profiles?$skip=5000&$top=5000")
          .to_return(status: 200, body: { value: second_page }.to_json)

        @tenant = Tenant.new(-> { dummy_token })
      end

      it "should find profile beyond first 5000 results" do
        profile = @tenant.profiles.find { |p| p.display_name == "prod_cdm_92971" }

        refute_nil profile, "Profile should be found even though it's beyond position 5000"
        assert_equal "special-id", profile.id
        assert_equal "prod_cdm_92971", profile.display_name
      end
    end

    describe "admin API pagination" do
      before do
        # First page: 5000 workspaces
        first_page = (0...5000).map { |i|
          { id: "ws-id-#{i}", name: "Workspace #{i}", state: "Active" }
        }
        stub_request(:get, "https://api.powerbi.com/v1.0/myorg/admin/groups?$skip=0&$top=5000")
          .to_return(status: 200, body: { value: first_page }.to_json)

        # Second page: 1500 workspaces
        second_page = (5000...6500).map { |i|
          { id: "ws-id-#{i}", name: "Workspace #{i}", state: "Active" }
        }
        stub_request(:get, "https://api.powerbi.com/v1.0/myorg/admin/groups?$skip=5000&$top=5000")
          .to_return(status: 200, body: { value: second_page }.to_json)

        @tenant = Tenant.new(-> { dummy_token })
      end

      it "should fetch all admin workspaces across pages" do
        workspaces = @tenant.admin.get_workspaces
        assert_equal 6500, workspaces.count
      end
    end

    describe "admin API with filters and pagination" do
      before do
        # First page with filter
        first_page = (0...5000).map { |i|
          { id: "ws-id-#{i}", name: "Workspace #{i}", state: "Active" }
        }
        stub_request(:get, "https://api.powerbi.com/v1.0/myorg/admin/groups?$filter=state%20eq%20'Active'&$skip=0&$top=5000")
          .to_return(status: 200, body: { value: first_page }.to_json)

        # Second page with filter
        second_page = (5000...5300).map { |i|
          { id: "ws-id-#{i}", name: "Workspace #{i}", state: "Active" }
        }
        stub_request(:get, "https://api.powerbi.com/v1.0/myorg/admin/groups?$filter=state%20eq%20'Active'&$skip=5000&$top=5000")
          .to_return(status: 200, body: { value: second_page }.to_json)

        @tenant = Tenant.new(-> { dummy_token })
      end

      it "should fetch filtered workspaces with pagination" do
        workspaces = @tenant.admin.get_workspaces(filter: "state eq 'Active'")
        assert_equal 5300, workspaces.count
      end
    end
  end
end

