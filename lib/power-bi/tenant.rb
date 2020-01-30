module PowerBI
  class Tenant

    def initialize(token_generator)
      @token_generator = token_generator
    end

    def workspaces
      @workspaces ||= WorkspaceArray.new(self)
    end

    def get(url, params = {})
      response = Faraday.get(url) do |req|
        req.params = params
        req.headers['Accept'] = 'application/json'
        req.headers['authorization'] = "Bearer #{token}"
        yield req if block_given?
      end
      JSON.parse(response.body, symbolize_names: true)[:value]
    end

    private

    def token
      @token_generator.call
    end

  end
end