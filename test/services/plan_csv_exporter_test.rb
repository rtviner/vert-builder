require "test_helper"
require "csv"

class PlanCsvExporterTest < ActiveSupport::TestCase
  setup do
    @user = users(:two)
    @plan = plans(:user_two_active)
    @exporter = PlanCsvExporter.new(@plan)
  end

  test "includes the header row" do
    csv = CSV.parse(@exporter.call)

    assert_equal [ "Week", "Dates", "Type", "Weekly Vert (ft)", "Time Cap", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun" ], csv.first
  end

  test "writes one row per week with correct attributes" do
    week = weeks(:week_one_user_two_active)
    hours = (week.planned_duration/60)
    mins = (week.planned_duration%60)
    day = days(:day_one_week_one_user_two_active)

    csv = CSV.parse(@exporter.call)
    row = csv[1]

    assert_equal "1", row[0]
    assert_equal "Progression", row[2]
    assert_equal week.planned_vertical_distance.to_s, row[3]
    assert_equal "#{hours}h #{mins.to_s.rjust(2, '0')}m", row[4]
    assert_equal day.planned_vertical_distance.to_s, row[5]
  end

  test "writes a blank separator row after each week" do
    csv = CSV.parse(@exporter.call)

    assert_equal [], csv[2] # row 0 = header, row 1 = week, row 2 = blank separator
  end

  test "formats dates as a range when start_date and end_date are present" do
    @plan.weeks.first.update!(week_number: 1, category: :progression, start_date: Date.new(2026, 11, 10), end_date: Date.new(2026, 11, 16))

    csv = CSV.parse(@exporter.call)

    assert_equal "Nov 10–Nov 16", csv[1][1]
  end

  test "renders blank dates when a week has no start_date or end_date" do
    @plan.weeks.first.update!(start_date: nil, end_date: nil, status: :planned)

    csv = CSV.parse(@exporter.call)

    assert_equal "", csv[1][1]
  end

  test "titleizes week category for the Type column" do
    @plan.weeks.first.update!(category: :taper, recovery_reduction_percentage: 40)

    csv = CSV.parse(@exporter.call)

    assert_equal "Taper", csv[1][2]
  end

  test "orders days Mon through Sun by position" do
    week = @plan.weeks.first
    [ 90, 228, 241, 320, 120, 170, 120 ].each_with_index do |vert, i|
      week.days[i].update!(position: i, planned_vertical_distance: vert)
    end

    csv = CSV.parse(@exporter.call)

    assert_equal %w[90 228 241 320 120 170 120], csv[1][5..11]
  end

  test "outputs weeks in week_number order" do
    csv = CSV.parse(@exporter.call)

    assert_equal "1", csv[1][0]
    assert_equal "2", csv[3][0] # row 2 is the blank separator after week 1
  end

  # --- format: :weeks ---

  test "weeks format includes the header row" do
    csv = CSV.parse(@exporter.call(format: :weeks))

    assert_equal [ "start", "type", "mi", "planned gain", "gain", "IL", "hours", "planned hours" ], csv.first
  end

  test "weeks format writes one row per week with start date, type, planned gain, and planned hours and leaves manual-fill columns blank" do
    @plan.weeks.first.update!(
      planned_vertical_distance: 1624, planned_duration: 351,
      start_date: Date.new(2026, 11, 10), end_date: Date.new(2026, 11, 16))

    csv = CSV.parse(@exporter.call(format: :weeks))
    row = csv[1]

    assert_equal "11/10", row[0] # start date
    assert_equal "Progression", row[1]  # type
    assert_nil row[2]  # mi
    assert_equal "1624", row[3] # planned gain
    assert_nil row[4]  # gain
    assert_nil row[5]  # IL
    assert_nil row[6]  # hours
    assert_equal "5h 51m", row[7] # planned hours
  end

  # --- format: :days ---

  test "days format includes the header row" do
    csv = csv = CSV.parse(@exporter.call(format: :days))

    assert_equal [ "day", "date", "notes", "Y", "R", "S", "B", "body", "planned gain", "%run", "\"run" ], csv.first
  end

  test "days format writes day label, date, and planned gain when week has a start_date and leaves manual-fill columns blank" do
    week = @plan.weeks.first
    week.update!(start_date: Date.new(2026, 11, 10), end_date: Date.new(2026, 11, 16))
    week.days.each { |day| day.update!(planned_vertical_distance: 90) }

    csv = csv = CSV.parse(@exporter.call(format: :days))
    row = csv[1]

    assert_equal "Tue", row[0]
    assert_equal "11/10", row[1]
    assert_nil row[2] # notes
    assert_nil row[3] # Y
    assert_nil row[4] # R
    assert_nil row[5] # S
    assert_nil row[6] # B
    assert_nil row[7] # body
    assert_equal "90", row[8]
    assert_nil row[9] # %run
    assert_nil row[10] # "run
  end

  test "days format writes rows for every day across all weeks in order" do
    days_count = @plan.weeks.sum { |week| week.days.count }

    csv = csv = CSV.parse(@exporter.call(format: :days))

    assert_equal days_count, csv.size - 1 # minus header
  end

  # --- invalid format ---

  test "raises ArgumentError for an unrecognized format" do
    assert_raises(ArgumentError) { PlanCsvExporter.new(@plan).call(format: :bogus) }
  end

  private

  def week_attrs(overrides = {})
    {
      week_number: 1,
      category: :progression,
      planned_duration: 100,
      planned_vertical_distance: 1000,
      start_date: nil,
      end_date: nil,
      status: :planned,
      vertical_build_percentage: @plan.vertical_build_percentage,
      recovery_reduction_percentage: nil
    }.merge(overrides)
  end

  def day_attrs(overrides = {})
    {
      position: 0,
      planned_vertical_distance: 100,
      status: :upcoming
    }.merge(overrides)
  end
end
