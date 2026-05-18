module Api
  module V1
    class SessionsController < ApplicationController
      allow_unauthenticated_access only: [ :create ]

      def create
        if user = User.authenticate_by(session_params)
          session = start_new_session_for(user)
          render json: { token: session.auth_token }, status: :created
        else
          render_invalid_credentials
        end
      end

      def destroy
        terminate_session
        render json: { message: "logged out" }, status: :ok
      end

      private

      def session_params
        params.permit(:email_address, :password)
      end

      def render_invalid_credentials
        render json: { error: "Invalid email address or password" }, status: :unauthorized
      end
    end
  end
end
