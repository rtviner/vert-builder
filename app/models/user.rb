class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :plans, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  validates :email_address, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }

  def average_weekly_vertical_distance
    weeks = last_four_completed_build_weeks
    if weeks.count < 4
      return most_recent_plan&.baseline_vertical_distance || 0
    end

    (weeks.sum(:completed_vertical_distance) / 4).round
  end

  def average_weekly_duration
    weeks = last_four_completed_build_weeks
    if weeks.count < 4
      return most_recent_plan&.baseline_duration || 0
    end

    (weeks.sum(:completed_duration) / 4).round
  end

  private

  def most_recent_plan
    plans.order(created_at: :desc).first
  end

  def last_four_completed_build_weeks
    Week.joins(:plan)
    .where(plans: { user_id: id }, status: :completed, is_recovery: false)
    .order(end_date: :desc)
    .limit(4)
  end
end
