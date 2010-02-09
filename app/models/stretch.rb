class Stretch

  attr_accessor :timetable, :wait, :ride, :node

  def initialize(timetable, node, wait, ride)
    @timetable = timetable
    @wait = wait
    @ride = ride
    @node = node
  end

  def stop
    timetable.stop
  end

  def line
    timetable.line
  end

  # time we wait plus time we ride in seconds
  def duration
    (@wait + @ride) * 60
  end
end