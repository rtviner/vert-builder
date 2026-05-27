class Week < ApplicationRecord
  belongs_to :plan

  enum :status, { upcoming: 0, in_progress: 1, completed: 2 }

  validates :planned_vertical_distance, :planned_duration, :start_date, :end_date, :week_number, :status, presence: true
  validates :week_number, numericality: { greater_than: 0 }, uniqueness: { scope: :plan_id }
  validates :completed_vertical_distance, presence: true, numericality: { greater_than_or_equal_to: 0 }, if: -> { status == "completed" }
  validates :completed_duration, presence: true, numericality: { greater_than_or_equal_to: 0 }, if: -> { status == "completed" }
  validate :end_date_after_start_date

  scope :completed_weeks, -> { where(status: :completed) }

  private

  def end_date_after_start_date
    if start_date.present? && end_date.present? && end_date < start_date
      errors.add(:end_date, "must be after the start date")
    end
  end
end
