
class ActivitiesController < ApplicationController
  layout 'application'
  def index
    @activities = Activity.configuration.redis.lrange("activities", 0, 99).map do |a|
      Rails.logger.error a
      JSON.parse(a).inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
    end
  end
end
