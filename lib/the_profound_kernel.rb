require "rubygems"
require 'activesupport/all'
require "bundler/setup"
Bundler.require(:default)

module ProfoundKernel
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  class Configuration
    attr_accessor :consumer_key, :consumer_secret, :oauth_token, :ouath_token_secret
    attr_accessor :right_phrase, :wrong_phrase
    attr_accessor :right_phrase_regex, :wrong_phrase_regex
  end

  class Processor
    def initialise
      Twitter.configure do |config|
        config.consumer_key       = ProfoundKernel.configuration.consumer_key
        config.consumer_secret    = ProfoundKernel.configuration.consumer_secret
        config.oauth_token        = ProfoundKernel.configuration.oauth_token
        config.oauth_token_secret = ProfoundKernel.configuration.oauth_token_secret
      end

      @redis = Redis.new
    end

    def run_search
      Twitter.search(ProfoundKernel.configuration.wrong_phrase, :count => 22, :result_type => "recent").results
        .reverse                                                # Reverse cos we want the oldest tweets first
        .select { |status| status.text =~ ProfoundKernel.configuration.wrong_phrase_regex } # Keep tweets that have deep seeded only
        .reject { |status| status.text =~ ProfoundKernel.configuration.right_phrase_regex } # Reject tweets that also mention deep seated, it might be a correction already
    end

    def validate_tweet

    end

    def recent_offender?(tweet)
      offender_time = @redis.get tweet.user.screen_name
      return true if offender_time.to_datetime < 1.week.ago

      # Test for mentioner abuse
      tweet.user_mentions.each do |user|
        mention_offender_time = @redis.get user.screen_name

        return true if mention_offender_time < 1.week.ago
      end

      false
    end
  end
end
