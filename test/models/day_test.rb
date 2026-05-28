require "test_helper"
 class DayTest < ActiveSupport::TestCase
  setup do
    @week = weeks(:one)
    @day = Day.new(
      week: @week,
      planned_vertical_distance: 1000,
      completed_vertical_distance: 0,
      status: :upcoming
    )
  end

  test "valid day" do
    assert @day.valid?
  end

  test "invalid without planned_vertical_distance" do
    @day.planned_vertical_distance = nil
    assert_not @day.valid?
    assert_includes @day.errors[:planned_vertical_distance], "can't be blank"
  end

  test "invalid without status" do
    @day.status = nil
    assert_not @day.valid?
    assert_includes @day.errors[:status], "can't be blank"
  end

  test "complete! sets status and completed_date" do
    travel_to Time.zone.local(2026, 5, 28, 12, 0, 0) do
      @day.complete!
      assert_equal "completed", @day.status
      assert_equal Date.today, @day.completed_date
    end
  end

  test "skip! sets status to skipped and updates updated_at" do
    travel_to Time.zone.local(2026, 5, 28, 12, 0, 0) do
      @day.skip!
      assert_equal "skipped", @day.status
      assert_equal Time.zone.local(2026, 5, 28, 12, 0, 0), @day.updated_at
    end
  end
 end
