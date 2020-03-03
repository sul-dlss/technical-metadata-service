# frozen_string_literal: true

# Base controller for API controllers
class ApiController < ActionController::API
  before_action :check_auth_token

  TOKEN_HEADER = 'Authorization'

  private

  # Ensure a valid token is present, or renders "401: Not Authorized"
  def check_auth_token
    token = decoded_auth_token
    return render json: { error: 'Not Authorized' }, status: :unauthorized unless token
  end

  def decoded_auth_token
    @decoded_auth_token ||= begin
      body = JWT.decode(http_auth_header, Settings.hmac_secret, true, algorithm: 'HS256').first
      HashWithIndifferentAccess.new body
                            rescue StandardError
                              nil
    end
  end

  def http_auth_header
    return if request.headers[TOKEN_HEADER].blank?

    field = request.headers[TOKEN_HEADER]
    field.split(' ').last
  end
end
