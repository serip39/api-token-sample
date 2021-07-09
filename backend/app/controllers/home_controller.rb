class HomeController < ApplicationController
  def index
    render json: { 'message': 'API server is running...' }, status: :ok
  end
end
