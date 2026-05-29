class Day < ApplicationRecord
  belongs_to :week

  enum :status, { upcoming: 0, completed: 1, skipped: 2 }

  validates :planned_vertical_distance, :status, presence: true

  def complete!(completed_date: Date.today)
    self.completed_date = completed_date
    completed!
    week.check_completion!
  end

  def skip!
    skipped!
    week.check_completion!
  end
end
