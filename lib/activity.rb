require "redis"
require "redis-namespace"

module Activity

  class Configuration
    attr_accessor :user_class
    attr_accessor :redis    

    def redis
      Redis::Namespace.new(:activity, :redis => @redis)
    end

    def user_class
      Object.const_get(@user_class)
    end

    def initilize
      redis = Redis.new
      user_class = "User"
    end
  end

  class << self
    attr_writer :configuration

    def configure(silent = false)
      yield(configuration)
    end

    def configuration
      @configuration ||= Configuration.new
    end

  end

  module Routes
    def activity_routes(options={})
      resources :activities, options
    end
  end


  module ApplicationController
    def activity(user, custom = {})
      redis = Activity.configuration.redis
      load = {user: user,
              time: Time.now,
              current_url: request.fullpath, 
              referer: request.referer,
              custom: custom}.to_json
      # save in a queue for the user
      redis.lpush "#{user}_activities", load
      redis.ltrim "#{user}_activities", 0, 19

      # save user properties
      redis.hset "#{user}_properties", "ip", request.remote_ip

      # remove the previous occurence from the global queue
      redis.lrem "activities", 1, user
      # push it back
      redis.lpush "activities", user
      redis.ltrim "activities", 0, 99

      # optionaly push it to the client
      if Module::const_defined?("Pusher")
        Pusher['activities'].trigger_async('new', load) 
        # Pusher["#{user}_activities"].trigger_async('new', load) 
      end  
      
    end
  end

  class Engine < Rails::Engine
    ActionController::Base.send(:include, Activity::ApplicationController)
    ActionDispatch::Routing::Mapper.send(:include, Activity::Routes)
  end

end
