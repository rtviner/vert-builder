require "csv"

class PlanCsvExporter
  FORMATS = %i[full weeks days].freeze

  def initialize(plan)
    @plan = plan
  end

  def call(format: :full)
    case format
    when :full  then full_csv
    when :weeks then weeks_csv
    when :days  then days_csv
    else
      raise ArgumentError, "format must be one of: full, weeks, days"
    end
  end

  private

  attr_reader :plan

  def full_csv
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

  def weeks_csv
    CSV.generate(headers: true) do |csv|
      csv << [ "start", "type", "mi", "planned gain", "gain", "IL", "hours", "planned hours" ]

      plan.weeks.each do |week|
        csv << [
          format_date(week.start_date),
          week.category.to_s.titleize,
          nil,
          week.planned_vertical_distance,
          nil,
          nil,
          nil,
          format_duration(week.planned_duration)
        ]
      end
    end
  end

  def days_csv
    CSV.generate(headers: true) do |csv|
      csv << [ "day", "date", "notes", "Y", "R", "S", "B", "body", "planned gain", "%run", "\"run" ]

      plan.weeks.each do |week|
        week.days.each do |day|
          day_date = week.start_date && week.start_date + day.position

          csv << [
            day_date&.strftime("%a"),
            format_date(day_date),
            nil, nil, nil, nil, nil, nil,
            day.planned_vertical_distance,
            nil, nil
          ]
        end
      end
    end
  end

  def format_date(date)
    return "" unless date
    date.strftime("%-m/%-d")
  end

  def format_date_range(start_date, end_date)
    return "" unless start_date && end_date
    if start_date.strftime("%b") == end_date.strftime("%b")
      "#{start_date.strftime('%b %-d')}–#{end_date.strftime('%-d')}"
    else
      "#{start_date.strftime('%b %-d')}–#{end_date.strftime('%b %-d')}"
    end
  end

  def format_duration(minutes)
    return "" unless minutes
    hours = minutes / 60
    mins = minutes % 60
    "#{hours}h #{mins.to_s.rjust(2, '0')}m"
  end
end
