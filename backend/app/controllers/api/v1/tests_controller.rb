class Api::V1::TestsController < Api::BaseController
  def whoami
    render json: current_user, status: :ok
  end
end