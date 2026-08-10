require "csv"

class PlanCsvExporter
  def initialize(plan)
    @plan = plan
  end

  def call
    CSV.generate(headers: true) do |csv|
      csv << [ "Week", "Dates", "Type", "Weekly Vert (ft)", "Time Cap", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun" ]
      plan.weeks.each do |week|
          csv << [
            week.week_number,
            format_date_range(week.start_date, week.end_date),
            week.category.to_s.titleize,
            week.planned_vertical_distance,
            format_duration(week.planned_duration),
            *week.days.map(&:planned_vertical_distance) ]
          csv << []
        end
    end
  end

  private

  attr_reader :plan

  def format_date_range(start_date, end_date)
    return "" unless start_date && end_date
    "#{start_date.strftime('%b %-d')}–#{end_date.strftime('%b %-d')}"
  end

  def format_duration(minutes)
    return "" unless minutes
    hours = minutes / 60
    mins = minutes % 60
    "#{hours}h #{mins.to_s.rjust(2, '0')}m"
  end
end
