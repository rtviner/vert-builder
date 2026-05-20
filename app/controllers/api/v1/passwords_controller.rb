class Api::V1::PasswordsController < ApplicationController
  def update
    user = Current.user
    unless user&.authenticate(reset_password_params[:current_password])
      return render json: { error: "Current password is incorrect" }, status: :unauthorized
    end

    user.password = reset_password_params[:new_password]
    user.password_confirmation = reset_password_params[:new_password_confirmation]

    if user.save
      terminate_session
      render json: { message: "Password updated successfully" }, status: :ok
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def reset_password_params
    params.permit(:current_password, :new_password, :new_password_confirmation)
  end
end
