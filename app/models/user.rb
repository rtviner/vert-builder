class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
     has_many :plans, foreign_key: :user_id, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  validates :email_address, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }

  # Returns the average weekly vertical distance for the last 4 completed weeks across all plans
  def average_weekly_vertical_distance
    # Implementation to be completed after Week model exists
    nil
  end

  # Returns the average weekly duration for the last 4 completed weeks across all plans
  def average_weekly_duration
    # Implementation to be completed after Week model exists
    nil
  end
end
