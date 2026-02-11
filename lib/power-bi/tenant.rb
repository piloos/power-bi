module PowerBI
  class Tenant
    attr_reader :workspaces, :gateways, :capacities, :profiles, :profile_id, :admin

    def initialize(token_generator, retries: 5, logger: nil)
      @token_generator = token_generator
      @workspaces = WorkspaceArray.new(self)
      @gateways = GatewayArray.new(self)
      @capacities = CapacityArray.new(self)
      @profiles = ProfileArray.new(self)
      @logger = logger
      @profile_id = nil
      @admin = Admin.new(self)

      ## WHY RETRIES? ##
      # It is noticed that once in a while (~0.1% API calls), the Power BI server returns a 500 (internal server error) without apparent reason, just retrying works :-)
      ##################
      @retry_options = {
        max: retries,
        exceptions: [Errno::ETIMEDOUT, Timeout::Error, Faraday::TimeoutError, Faraday::RetriableResponse, Faraday::ConnectionFailed],
        methods: [:get, :post, :patch, :delete],
        retry_statuses: [500], # internal server error
        interval: 0.2,
        interval_randomness: 0,
        backoff_factor: 4,
        retry_block: -> (env, options, retries, exc) { self.log "retrying...!! exception: #{exc.to_s} ---- #{exc.message}, request URL: #{env.url}" },
      }
    end

    def log(message, level: :info)
      if @logger
        @logger.send(level, message) # hence, the logger needs to implement the 'level' methods
      end
    end

    def workspace(id)
      Workspace.new(self, nil, id)
    end

    def gateway(id)
      Gateway.new(self, nil, id)
    end

    def capacity(id)
      Capacity.new(self, nil, id)
    end

    def profile(id)
      Profile.new(self, nil, id)
    end

    def profile=(profile)
      @profile_id = profile.is_a?(String) ? profile : profile&.id
      @workspaces.reload # we need to reload the workspaces because we look through the eyes of the profile
    end

    def get(url, params = {}, use_profile: true)
      t0 = Time.now
      conn = Faraday.new do |f|
        f.request :retry, @retry_options
      end
      response = conn.get(PowerBI::BASE_URL + url) do |req|
        req.params = params
        req.headers['Accept'] = 'application/json'
        req.headers['authorization'] = "Bearer #{token}"
        if use_profile
          add_spp_header(req)
        end
        yield req if block_given?
      end
      if response.status == 400
        raise NotFoundError
      end
      unless [200, 202].include? response.status
        raise APIError.new("Error calling Power BI API (status #{response.status}): #{response.body}")
      end
      log "Calling (GET) #{response.env.url.to_s} - took #{((Time.now - t0) * 1000).to_i} ms - status: #{response.status}"
      unless response.body.empty?
        JSON.parse(response.body, symbolize_names: true)
      end
    end

    def get_raw(url, params = {}, use_profile: true)
      t0 = Time.now
      conn = Faraday.new do |f|
        f.request :retry, @retry_options
      end
      response = conn.get(PowerBI::BASE_URL + url) do |req|
        req.params = params
        req.headers['authorization'] = "Bearer #{token}"
        if use_profile
          add_spp_header(req)
        end
        yield req if block_given?
      end
      log "Calling (GET - raw) #{response.env.url.to_s} - took #{((Time.now - t0) * 1000).to_i} ms - status: #{response.status}"
      unless [200, 202].include? response.status
        raise APIError.new("Error calling Power BI API (status #{response.status}): #{response.body}")
      end
      response.body
    end

    def post(url, params = {}, use_profile: true)
      t0 = Time.now
      conn = Faraday.new do |f|
        f.request :retry, @retry_options
      end
      response = conn.post(PowerBI::BASE_URL + url) do |req|
        req.params = params
        req.headers['Accept'] = 'application/json'
        req.headers['Content-Type'] = 'application/json'
        req.headers['authorization'] = "Bearer #{token}"
        if use_profile
          add_spp_header(req)
        end
        yield req if block_given?
      end
      log "Calling (POST) #{response.env.url.to_s} - took #{((Time.now - t0) * 1000).to_i} ms - status: #{response.status}"
      unless [200, 201, 202].include? response.status
        raise APIError.new("Error calling Power BI API (status #{response.status}): #{response.body}")
      end
      unless response.body.empty?
        JSON.parse(response.body, symbolize_names: true)
      end
    end

    def patch(url, params = {}, use_profile: true)
      t0 = Time.now
      conn = Faraday.new do |f|
        f.request :retry, @retry_options
      end
      response = conn.patch(PowerBI::BASE_URL + url) do |req|
        req.params = params
        req.headers['Accept'] = 'application/json'
        req.headers['Content-Type'] = 'application/json'
        req.headers['authorization'] = "Bearer #{token}"
        if use_profile
          add_spp_header(req)
        end
        yield req if block_given?
      end
      log "Calling (PATCH) #{response.env.url.to_s} - took #{((Time.now - t0) * 1000).to_i} ms - status: #{response.status}"
      unless [200, 202].include? response.status
        raise APIError.new("Error calling Power BI API (status #{response.status}): #{response.body}")
      end
      unless response.body.empty?
        JSON.parse(response.body, symbolize_names: true)
      end
    end

    def delete(url, params = {}, use_profile: true)
      t0 = Time.now
      conn = Faraday.new do |f|
        f.request :retry, @retry_options
      end
      response = conn.delete(PowerBI::BASE_URL + url) do |req|
        req.params = params
        req.headers['Accept'] = 'application/json'
        req.headers['authorization'] = "Bearer #{token}"
        if use_profile
          add_spp_header(req)
        end
        yield req if block_given?
      end
      log "Calling (DELETE) #{response.env.url.to_s} - took #{((Time.now - t0) * 1000).to_i} ms - status: #{response.status}"
      if [400, 401, 404].include? response.status
        raise NotFoundError
      end
      unless [200, 202].include? response.status
        raise APIError.new("Error calling Power BI API (status #{response.status}): #{response.body}")
      end
      unless response.body.empty?
        JSON.parse(response.body, symbolize_names: true)
      end
    end

    def post_file(url, file, params = {}, use_profile: true)
      t0 = Time.now
      conn = Faraday.new do |f|
        f.request :multipart
        f.request :retry, @retry_options
      end
      response = conn.post(PowerBI::BASE_URL + url) do |req|
        req.params = params
        req.headers['Accept'] = 'application/json'
        req.headers['Content-Type'] = 'multipart/form-data'
        req.headers['authorization'] = "Bearer #{token}"
        if use_profile
          add_spp_header(req)
        end
        req.body = {value: Faraday::UploadIO.new(file, 'application/octet-stream')}
        req.options.timeout = 120  # default is 60 seconds Net::ReadTimeout
      end
      log "Calling (POST - file) #{response.env.url.to_s} - took #{((Time.now - t0) * 1000).to_i} ms - status: #{response.status}"
      if response.status != 202
        raise APIError.new("Error calling Power BI API (status #{response.status}): #{response.body}")
      end
      JSON.parse(response.body, symbolize_names: true)
    end

    # Fetches paginated data from the Power BI API using OData-style pagination.
    #
    # Power BI API has a documented limit of 5000 records per request.
    # This method handles pagination automatically by:
    # 1. Requesting 5000 records at a time using $top and $skip
    # 2. If exactly 5000 records are returned, fetching the next page
    # 3. Accumulating all results across pages
    # 4. Deduplicating records by ID (to handle insertions between requests)
    #
    # Note: $skip-based pagination is not fully protected against deletions
    # between requests (a deleted record may cause a subsequent record to go
    # unseen). This risk is acceptable given the short pagination window.
    MAX_PAGE_SIZE = 5000
    MAX_ITERATIONS = 100
    def get_paginated(url, page_size: MAX_PAGE_SIZE, base_params: {}, use_profile: true, max_iterations: MAX_ITERATIONS)
      page_size = [page_size, MAX_PAGE_SIZE].min

      skip = 0
      all_data = []
      iteration = 0

      loop do
        iteration += 1
        if iteration > max_iterations
          log "WARNING: Reached maximum iteration limit (#{max_iterations}). " \
              "Fetched #{all_data.size} records so far. This may indicate an API issue or " \
              "an extremely large dataset. Consider using API filters to reduce the result set.",
              level: :warn
          break
        end

        params = base_params.merge({
          '$top' => page_size,
          '$skip' => skip
        })

        log "Fetching paginated data from #{url} (skip: #{skip}, top: #{page_size}, iteration: #{iteration})"

        resp = get(url, params, use_profile: use_profile)
        batch = resp[:value] || []
        all_data += batch
        batch_count = batch.size

        log "Received #{batch_count} records (total so far: #{all_data.size})"

        # If we got fewer records than requested, we've reached the last page
        break if batch_count < page_size

        skip += batch_count
      end

      # Deduplicate by ID to handle any records that were inserted between requests.
      # Insertions before the current $skip position shift items right, which can
      # cause duplicates across pages.
      deduplicated_data = all_data.uniq{|r| r[:id]}

      if deduplicated_data.size < all_data.size
        log "Removed #{all_data.size - deduplicated_data.size} duplicate records during deduplication"
      end

      deduplicated_data
    end

    private

    def add_spp_header(req)
      if @profile_id
        req.headers['X-PowerBI-Profile-Id'] = @profile_id
      end
    end

    def token
      @token_generator.call
    end

  end
end