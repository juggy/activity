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

  def location(ip)
    uri = URI.parse("http://api.hostip.info/get_html.php?ip=#{ip}")
    Net::HTTP.get_response(uri).body
  end

  def parse_json_and_symbolize(h)
    return {} if h.nil?
    JSON.parse(h).inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
  end
end
