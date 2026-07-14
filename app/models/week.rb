class Week < ApplicationRecord
  belongs_to :plan
  has_many :days, dependent: :destroy

  CATEGORY_OPTIONS = %w[progression recovery taper goal].freeze

  enum :status, { planned: 0, upcoming: 1, in_progress: 2, completed: 3 }

  validates :planned_vertical_distance, :week_number, :status, :category, presence: true
  validates :planned_duration, presence: true, unless: -> { category == "goal" }
  validates :start_date, :end_date, presence: true, unless: -> { planned? }
  validates :week_number, numericality: { greater_than: 0 }, uniqueness: { scope: :plan_id }
  validates :completed_vertical_distance, presence: true, numericality: { greater_than_or_equal_to: 0 }, if: -> { completed? }
  validates :completed_duration, presence: true, numericality: { greater_than_or_equal_to: 0 }, if: -> { completed? }
  validate :end_date_after_start_date, if: -> { start_date.present? && end_date.present? }
  validates :category, inclusion: { in: CATEGORY_OPTIONS }
  validates :recovery_reduction_percentage,
            presence: true,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: 40,
              less_than_or_equal_to: 60
            },
            if: -> { category.in?(%w[recovery taper]) }
  validates :recovery_reduction_percentage,
            presence: true,
            numericality: { equal_to: 60 },
            if: -> { category == "goal" }
  validates :vertical_build_percentage,
            presence: true,
            numericality: {
              greater_than_or_equal_to: 5,
              less_than: Plan::MAX_PROGRESSION_PERCENTAGE
            },
            if: -> { category == "progression" }
  # completed here is redundant because Week.completed? remove?
  scope :completed, -> { where(status: :completed) }
  scope :recovery, -> { where(category: %w[recovery taper]) }
  scope :progression, -> { where(category: %w[progression goal]) }

  def check_completion!
    if end_date.past?
      if days.where(status: :upcoming).exists?
        days.where(status: :upcoming).find_each { |d| d.skip! }
      end
      completed!
    end
  end

  private

  def end_date_after_start_date
    if start_date.present? && end_date.present? && end_date < start_date
      errors.add(:end_date, "must be after the start date")
    end
  end
end
