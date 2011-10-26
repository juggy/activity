require "redis"
require "redis-namespace"

module Activity

  class Configuration
    attr_accessor :redis    

    def redis
      Redis::Namespace.new(:activity, :redis => @redis)
    end

    def initilize
      redis = Redis.new
    end
  end

  class << self
    attr_accessor :configuration

    def configure(silent = false)
      yield(configuration)
    end

    def configuration
      @configuration ||= Configuration.new
    end

  end


  module ApplicationController
    def activity(user, custom = {})
      load = {user: user,
              time: Time.now,
              current_url: request.fullpath, 
              referer: request.referer,
              custom: custom}.to_json
      # save as a queue
      Activity.configuration.redis.lpush "activities", load
      Activity.configuration.redis.ltrim "activities", 0, 255

      # optionaly push it to the client
      Pusher['activity'].trigger!('new', load) if Module::const_defined?("Pusher")
      
    end
  end

  class Engine < Rails::Engine
    # engine_name "activity"
    # paths["app/controllers"] = "app/controllers"
    # paths["app/views"] = "app/views"

    ActionController::Base.send(:include, Activity::ApplicationController)
  end

end
