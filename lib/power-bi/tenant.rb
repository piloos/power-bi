module PowerBI
  class Tenant
    attr_reader :workspaces, :gateways

    def initialize(token_generator, retries: 5)
      @token_generator = token_generator
      @workspaces = WorkspaceArray.new(self)
      @gateways = GatewayArray.new(self)

      ## WHY RETRIES? ##
      # It is noticed that once in a while (~0.1% API calls), the Power BI server returns a 500 (internal server error) withou apparent reason, just retrying works :-)
      ##################
      @retry_options = {
        max: retries,
        exceptions: [Errno::ETIMEDOUT, Timeout::Error, Faraday::TimeoutError, Faraday::RetriableResponse],
        methods: [:get, :post, :patch, :delete],
        retry_statuses: [500], # internal server error
        interval: 0.2,
        interval_randomness: 0,
        backoff_factor: 4,
        retry_block: -> (env, options, retries, exc) { puts "retrying...!! (@ #{Time.now.to_s}), exception: #{exc.to_s} ---- #{exc.message}" },
      }
    end

    def get(url, params = {})
      conn = Faraday.new do |f|
        f.request :retry, @retry_options
      end
      response = conn.get(PowerBI::BASE_URL + url) do |req|
        req.params = params
        req.headers['Accept'] = 'application/json'
        req.headers['authorization'] = "Bearer #{token}"
        yield req if block_given?
      end
      unless [200, 202].include? response.status
        raise APIError.new("Error calling Power BI API (status #{response.status}): #{response.body}")
      end
      unless response.body.empty?
        JSON.parse(response.body, symbolize_names: true)
      end
    end

    def get_raw(url, params = {})
      conn = Faraday.new do |f|
        f.request :retry, @retry_options
      end
      response = conn.get(PowerBI::BASE_URL + url) do |req|
        req.params = params
        req.headers['authorization'] = "Bearer #{token}"
        yield req if block_given?
      end
      unless [200, 202].include? response.status
        raise APIError.new("Error calling Power BI API (status #{response.status}): #{response.body}")
      end
      response.body
    end

    def post(url, params = {})
      conn = Faraday.new do |f|
        f.request :retry, @retry_options
      end
      response = conn.post(PowerBI::BASE_URL + url) do |req|
        req.params = params
        req.headers['Accept'] = 'application/json'
        req.headers['Content-Type'] = 'application/json'
        req.headers['authorization'] = "Bearer #{token}"
        yield req if block_given?
      end
      unless [200, 201, 202].include? response.status
        raise APIError.new("Error calling Power BI API (status #{response.status}): #{response.body}")
      end
      unless response.body.empty?
        JSON.parse(response.body, symbolize_names: true)
      end
    end

    def patch(url, params = {})
      conn = Faraday.new do |f|
        f.request :retry, @retry_options
      end
      response = conn.patch(PowerBI::BASE_URL + url) do |req|
        req.params = params
        req.headers['Accept'] = 'application/json'
        req.headers['Content-Type'] = 'application/json'
        req.headers['authorization'] = "Bearer #{token}"
        yield req if block_given?
      end
      unless [200, 202].include? response.status
        raise APIError.new("Error calling Power BI API (status #{response.status}): #{response.body}")
      end
      unless response.body.empty?
        JSON.parse(response.body, symbolize_names: true)
      end
    end

    def delete(url, params = {})
      conn = Faraday.new do |f|
        f.request :retry, @retry_options
      end
      response = conn.delete(PowerBI::BASE_URL + url) do |req|
        req.params = params
        req.headers['Accept'] = 'application/json'
        req.headers['authorization'] = "Bearer #{token}"
        yield req if block_given?
      end
      unless [200, 202].include? response.status
        raise APIError.new("Error calling Power BI API (status #{response.status}): #{response.body}")
      end
      unless response.body.empty?
        JSON.parse(response.body, symbolize_names: true)
      end
    end

    def post_file(url, file, params = {})
      conn = Faraday.new do |f|
        f.request :multipart
        f.request :retry, @retry_options
      end
      response = conn.post(PowerBI::BASE_URL + url) do |req|
        req.params = params
        req.headers['Accept'] = 'application/json'
        req.headers['Content-Type'] = 'multipart/form-data'
        req.headers['authorization'] = "Bearer #{token}"
        req.body = {value: Faraday::UploadIO.new(file, 'application/octet-stream')}
        req.options.timeout = 120  # default is 60 seconds Net::ReadTimeout
      end
      if response.status != 202
        raise APIError.new("Error calling Power BI API (status #{response.status}): #{response.body}")
      end
      JSON.parse(response.body, symbolize_names: true)
    end

    private

    def token
      @token_generator.call
    end

  end
end