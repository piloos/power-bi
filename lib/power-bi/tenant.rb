module PowerBI
  class Tenant
    attr_reader :workspaces

    def initialize(token_generator)
      @token_generator = token_generator
      @workspaces = WorkspaceArray.new(self)
    end

    def get(url, params = {})
      response = Faraday.get(PowerBI::BASE_URL + url) do |req|
        req.params = params
        req.headers['Accept'] = 'application/json'
        req.headers['authorization'] = "Bearer #{token}"
        yield req if block_given?
      end
      if response.status != 200
        raise APIError.new("Error calling Power BI API (status #{response.status}): #{response.body}")
      end
      unless response.body.empty?
        JSON.parse(response.body, symbolize_names: true)
      end
    end

    def post(url, params = {})
      response = Faraday.post(PowerBI::BASE_URL + url) do |req|
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

    def post_file(url, file, params = {})
      conn = Faraday.new do |f|
        f.request :multipart
      end
      response = conn.post(PowerBI::BASE_URL + url) do |req|
        req.params = params
        req.headers['Accept'] = 'application/json'
        req.headers['Content-Type'] = 'multipart/form-data'
        req.headers['authorization'] = "Bearer #{token}"
        req.body = {value: Faraday::UploadIO.new(file, 'application/octet-stream')}
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