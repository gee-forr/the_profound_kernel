require "rubygems"
require "bundler/setup"
Bundler.require(:default)

require 'pry'

module ProfoundKernel
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  class Configuration
    attr_accessor :consumer_key, :consumer_secret, :oauth_token, :oauth_token_secret
    attr_accessor :right_phrase, :wrong_phrase
    attr_accessor :right_phrase_regex, :wrong_phrase_regex
    attr_accessor :dry_run
  end

  class Processor
    def initialize
      Twitter.configure do |config|
        config.consumer_key       = ProfoundKernel.configuration.consumer_key
        config.consumer_secret    = ProfoundKernel.configuration.consumer_secret
        config.oauth_token        = ProfoundKernel.configuration.oauth_token
        config.oauth_token_secret = ProfoundKernel.configuration.oauth_token_secret
      end

      @redis = Redis.new
    end

    def run_search
      Twitter.search(ProfoundKernel.configuration.wrong_phrase, :count => 32, :result_type => "recent").results
    end

    def sanitize_search(search_results)
      search_results
        .reverse                                                                            # Reverse cos we want the oldest tweets first
        .select { |status| status.text =~ ProfoundKernel.configuration.wrong_phrase_regex } # Keep tweets that have deep seeded only
        .reject { |status| status.text =~ ProfoundKernel.configuration.right_phrase_regex } # Reject tweets that also mention deep seated, it might be a correction already
    end

    def validate_tweet(tweet)
      # Should return yay if we can correct or nay if we shouldnt, based on validity
      return false if tweet.text =~ /^RT\s/
      puts "This is not an RT : [#{tweet.text}]"

      return false if recent_offender?(tweet.from_user)
      puts "This is not a recent offender [#{tweet.from_user}]"

      tweet.user_mentions.each do |mentioned| 
        if recent_offender?(mentioned.screen_name)  # Test for mentioner abuse
          puts "this mentioned is a recent offender, moving on  [#{mentioned.screen_name}]"
          return false
        else
          puts "[#{mentioned.screen_name}] is not a recent offender"
        end
      end

      puts "This is a valid tweet:"
      true
    end

    def tweet_correction(tweet)
      # construct message
      msg = "@#{tweet.from_user} I think you mean #{ProfoundKernel.configuration.right_phrase}."

      # send message
      if ProfoundKernel.configuration.dry_run
        puts "Replying to [#{tweet.id}] [#{tweet.text}] - [#{msg}]"
        
      else
        Twitter.update(msg, {in_reply_to_status_id: tweet.id})
      end

      update_offenders_list(tweet.from_user)
    end

    def recent_offender?(user)
      3.weeks.ago < offender_time(user)
    end

    def offender_time(user)
      time = @redis.get(user)
      
      time.nil? ? 1.year.ago: time.to_time
    end

    def update_offenders_list(user)
      @redis.set user, Time.now
    end
  end
end
