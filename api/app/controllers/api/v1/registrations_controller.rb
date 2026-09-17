class Api::V1::RegistrationsController < ApplicationController
  allow_unauthenticated_access only: %i[create]

  def create
    user = User.new(user_params)

    if user.save
      start_new_session_for(user)
      render json: { token: Current.session.auth_token, user: user.as_json }, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotUnique
    render json: { error: [ "There was a problem creating your account" ] }, status: :unprocessable_content
  end

  private

  def user_params
    params.require(:user).permit(:email_address, :password, :password_confirmation)
  end
end
