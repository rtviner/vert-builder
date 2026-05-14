class ApplicationController < ActionController::API
  include Authentication
  include ActionController::HttpAuthentication::Token::ControllerMethods
end
