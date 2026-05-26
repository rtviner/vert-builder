class Week < ApplicationRecord
  belongs_to :plan
  has_many :days, dependent: :destroy

  enum status: { upcoming: 0, in_progress: 1, completed: 2, skipped: 3 }

  validates :planned_vertical_distance, :planned_duration, :start_date, :end_date, :week_number, :status, presence: true
  validates :week_number, numericality: { greater_than: 0 }, uniqueness: { scope: :plan_id }
  validates :completed_vertical_distance, numericality: { greater_than_or_equal_to: 0 }, if: -> { status == "completed" }
  validates :completed_duration, numericality: { greater_than_or_equal_to: 0 }, if: -> { status == "completed" }
  validate :end_date_after_start_date

  # Scopes
  scope :completed_weeks, -> { where(status: :completed) }

  # Methods
  def complete!(completed_date: Date.today)
    update!(status: :completed)
    # TODO: check if any days in week are not marked completed and set them to 'skipped'
  end

  def log_week_progress(vertical_distance:, duration:)
    self.completed_vertical_distance = vertical_distance
    self.completed_duration = duration
    if !completed? && end_date < Date.today
      complete!
    else
      save!
    end
  end

  private

  def end_date_after_start_date
    if start_date.present? && end_date.present? && end_date < start_date
      errors.add(:end_date, "must be after start date")
    end
  end
end
