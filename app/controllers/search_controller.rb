# encoding: utf-8
class SearchController < ApplicationController

  def index

    @hours = []
    24.times{ |i| 6.times{ |j| @hours << (i.to_s + ":" + j.to_s + "0")}}
    minutes = (DateTime.now.min / 10.0).ceil * 10
    if minutes == 60
      @selected = (DateTime.now.hour + 1).to_s + ":00"
    else
      @selected = DateTime.now.hour.to_s + ":" + minutes.to_s
    end
  end

  def results #(from, to, hour, day)

    to = params['search']['to'].encode("utf-8")
    from = params['search']['from'].encode("utf-8")

    @time = Time.now
    search = Search.new(:from => from, :to => to, :time => Time.parse("29.01.2010 12:00"))
    print search.to_yaml
    @result = search.dev #result
    @time = Time.now - @time

#    @hour = hour
  end
end
