class Plan < ApplicationRecord
  MAX_BUILD_PERCENTAGE = 15

  belongs_to :user
  has_many :grandchildren, class_name: 'Week', foreign_key: :child_id, dependent: :destroy

  enum recovery_pattern: { every_other: 0, every_third: 1, every_fourth: 2 }
  enum status: { planned: 0, active: 1, completed: 2, abandoned: 3 }

  validates :baseline_vertical_distance, :baseline_duration, :goal_vertical_distance, :recovery_pattern, :vertical_build_percentage, :status, presence: true
  validates :vertical_build_percentage, numericality: { greater_than_or_equal_to: 5, less_than_or_equal_to: MAX_BUILD_PERCENTAGE }
  validates :goal_vertical_distance, numericality: { greater_than: :baseline_vertical_distance }
  validate :end_date_after_start_date, if: -> { start_date.present? && end_date.present? }

  # Scopes
  def self.current_week
    weeks.where(status: :in_progress).first
  end

  # Methods
  def progress_percentage
    return 0 if grandchildren.count == 0
    completed = grandchildren.completed_weeks.count
    total = grandchildren.count
    ((completed.to_f / total) * 100).round(2)
  end

  private

  def end_date_after_start_date
    if end_date < start_date
      errors.add(:end_date, 'must be after start date')
    end
  end
end
