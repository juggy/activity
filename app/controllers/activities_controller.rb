require "net/http"
require "uri"

class ActivitiesController < ApplicationController
  layout 'application'
  def index
    redis = Activity.configuration.redis
    @activities = redis.lrange("activities", 0, 99).map do |user|
      # get the last activity for this user
      last_activity = redis.lrange("#{user}_activities", 0, 1)
      parse_json_and_symbolize(last_activity.first)
    end
    @activity_graph = week_graph @activities
    @day_graph = weekday_graph @activities
  end

  def show
    redis = Activity.configuration.redis
    @user = params[:id].gsub(/\ /, ".")
    @properties = redis.hgetall("#{@user}_properties")
    @properties[:location] = location(@properties["ip"])
    @activities = redis.lrange("#{@user}_activities", 0, 19).map do |a|
      parse_json_and_symbolize(a)
    end
  end

  protected

  def weekday_graph(activities)
    activities.inject([0,0,0,0,0,0,0]) do |days, a|
      if a[:time]
        time = Time.zone.parse(a[:time])
        days[0] = days[0] + 1 if time.monday?
        days[1] = days[1] + 1 if time.tuesday?
        days[2] = days[2] + 1 if time.wednesday?
        days[3] = days[3] + 1 if time.thursday?
        days[4] = days[4] + 1 if time.friday?
        days[5] = days[5] + 1 if time.saturday?
        days[6] = days[6] + 1 if time.sunday?
      end
      days
    end
  end

  def week_graph(activities)
    week1 = week2 = other = 0
    activities.each do |a|
      if a[:time]
        time = Time.zone.parse(a[:time])
        if time.to_i > 1.week.ago.to_i
          week1 = week1 + 1
        elsif time.to_i > 2.week.ago.to_i
          week2 = week2 + 1
        end  
        other = Activity.configuration.user_class.count - week1 + week2
      end
    end
    [week1, week2, other]
  end

  def location(ip)
    uri = URI.parse("http://api.hostip.info/get_html.php?ip=#{ip}")
    Net::HTTP.get_response(uri).body
  end

  def parse_json_and_symbolize(h)
    return {} if h.nil?
    JSON.parse(h).inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
  end
end
