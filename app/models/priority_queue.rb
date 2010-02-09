class PriorityQueue
  def initialize
    @list = []
  end

  def add(priority, item)
    @list << [priority, @list.length, item]
#    begin
      @list = @list.sort_by{|x| x[0]}
#    rescue
#      raise [priority, @list.length, item].inspect
#    end

    self
  end

  def <<(pritem)
    add(*pritem)
  end

  def next
    @list.shift[2]
  end

  def empty?
    @list.empty?
  end
end