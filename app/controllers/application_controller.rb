class ApplicationController < ActionController::API
  include Authentication
  include ActionController::HttpAuthentication::Token::ControllerMethods

  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
  rescue_from ActionController::ParameterMissing, with: :bad_request

  private

  def not_found(exception)
    render json: {
      error: {
        status: 404,
        message: "Resource not found",
        detail: exception.message
      }
    }, status: :not_found
  end

  def unprocessable_entity(exception)
    render json: {
      error: {
        status: 422,
        message: "Validation failed",
        errors: exception.record.errors.full_messages
      }
    }, status: :unprocessable_entity
  end

  def bad_request(exception)
    render json: {
      error: {
        status: 400,
        message: "Bad request",
        detail: exception.message
      }
    }, status: :bad_request
  end
end
