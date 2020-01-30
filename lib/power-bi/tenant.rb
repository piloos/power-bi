module PowerBI
  class Tenant

    def initialize(token_generator)
      @token_generator = token_generator
    end

    def workspaces
      @workspaces ||= WorkspaceArray.new(self)
    end

    def get(url, params = {})
      response = Faraday.get(PowerBI::BASE_URL + url) do |req|
        req.params = params
        req.headers['Accept'] = 'application/json'
        req.headers['authorization'] = "Bearer #{token}"
        yield req if block_given?
      end
      if response.status != 200
        raise APIError.new("Error calling Power BI API: #{response.body}")
      end
      JSON.parse(response.body, symbolize_names: true)
    end

    def post(url, params = {})
      response = Faraday.post(PowerBI::BASE_URL + url) do |req|
        req.params = params
        req.headers['Accept'] = 'application/json'
        req.headers['Content-Type'] = 'application/json'
        req.headers['authorization'] = "Bearer #{token}"
        yield req if block_given?
      end
      if response.status != 200
        raise APIError.new("Error calling Power BI API: #{response.body}")
      end
      JSON.parse(response.body, symbolize_names: true)
    end

    private

    def token
      @token_generator.call
    end

  end
end