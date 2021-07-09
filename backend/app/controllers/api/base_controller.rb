class Api::BaseController < ApplicationController
  before_action :split_tokens
  before_action :authenticate_api_v1_user!, unless: :devise_controller?

  private
    def split_tokens
      return if request.headers['Authorization'].nil?

      token = JSON.parse(Base64.decode64(CGI.unescape(request.headers['Authorization'].match(/Bearer /).post_match)))
      request.headers['access-token'] = token['access-token']
      request.headers['client'] = token['client']
      request.headers['uid'] = token['uid']
    end
end
