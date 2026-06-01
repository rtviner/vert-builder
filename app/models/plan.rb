class Plan < ApplicationRecord
  belongs_to :user
  has_many :weeks, dependent: :destroy
  MAX_BUILD_PERCENTAGE = 15.freeze

  enum :recovery_pattern, { every_other: 0, every_third: 1, every_fourth: 2 }
  enum :status, { planned: 0, active: 1, completed: 2, abandoned: 3 }

  validates :baseline_vertical_distance, :baseline_duration, :goal_vertical_distance, :recovery_pattern, :vertical_build_percentage, :status, presence: true
  validates :vertical_build_percentage, numericality: { greater_than_or_equal_to: 5, less_than_or_equal_to: MAX_BUILD_PERCENTAGE }
  validates :goal_vertical_distance, numericality: { greater_than: :baseline_vertical_distance }
  validate :end_date_after_start_date, if: -> { start_date.present? && end_date.present? }

  scope :current_week, -> { joins(:weeks).merge(Week.in_progress).first }

  def progress_percentage
    return 0 if weeks.count == 0
    ((weeks.completed.count.to_f / weeks.count) * 100).round
  end

  private

  def end_date_after_start_date
    if end_date < start_date
      errors.add(:end_date, "must be after the start date")
    end
  end
end
