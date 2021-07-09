class Custom::SessionsController < DeviseTokenAuth::SessionsController
  prepend_after_action :join_tokens, only: [:create]

  private
    def join_tokens
      return if response.headers['access-token'].nil?

      auth_json = {
        'access-token' => response.headers['access-token'],
        'client' => response.headers['client'],
        'uid' => response.headers['uid'],
      }
      response.headers.delete_if{|key| auth_json.include? key}
      access_token = CGI.escape(Base64.encode64(JSON.dump(auth_json)))

      json_body = JSON.parse(response.body)
      new_json_body = {
        'user' => json_body['data'],
        'access_token' => access_token,
        'expiry' => response.headers['expiry']
      }
      response.body = JSON.dump(new_json_body)
    end
end
