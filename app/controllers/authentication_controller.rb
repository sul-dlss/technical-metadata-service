# frozen_string_literal: true

# AuthenticationController validates the email password and returns a JWT token
class AuthenticationController < ApplicationController
  before_action :authorize_request, except: :login

  # POST /v1/auth/login
  def login
    @user = User.find_by(email: params[:email])

    if @user&.authenticate(params[:password])
      exp = Time.zone.now + 24.hours.to_i
      token = JsonWebToken.encode({ user_id: @user.id }, exp)
      render json: { token: token, exp: exp.strftime('%m-%d-%Y %H:%M') }, status: :ok
    else
      render json: { error: 'unauthorized' }, status: :unauthorized
    end
  end

  private

  def login_params
    params.permit(:email, :password)
  end
end
