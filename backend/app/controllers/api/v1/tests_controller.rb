class Api::V1::TestsController < Api::BaseController
  def whoami
    render json: current_api_v1_user, status: :ok
  end
end