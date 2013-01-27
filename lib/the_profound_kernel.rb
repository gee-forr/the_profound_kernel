require "rubygems"
require "bundler/setup"
Bundler.require(:default)

require "pry"

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
    LAST_TWEET_KEY = 'last_corrected_tweet'

    def initialize
      Twitter.configure do |config|
        config.consumer_key       = ProfoundKernel.configuration.consumer_key
        config.consumer_secret    = ProfoundKernel.configuration.consumer_secret
        config.oauth_token        = ProfoundKernel.configuration.oauth_token
        config.oauth_token_secret = ProfoundKernel.configuration.oauth_token_secret
      end

      @redis = Redis.new
    end

    def process!
      search_results = run_search
      clean_search   = sanitize_search(search_results)

      clean_search.each do |tweet|
        tweet_correction(tweet) if should_correct?(tweet)
      end
    end

    def run_search
      Twitter.search(ProfoundKernel.configuration.wrong_phrase, :result_type => "recent").results
    end

    def sanitize_search(search_results)
      search_results
        .reverse                                                                            # Reverse cos we want the oldest tweets first
        .select { |status| status.text =~ ProfoundKernel.configuration.wrong_phrase_regex } # Keep tweets that have deep seeded only
        .reject { |status| status.text =~ ProfoundKernel.configuration.right_phrase_regex } # Reject tweets that also mention deep seated, it might be a correction already
    end

    def should_correct?(tweet) # This needs refactoring
      return false if last_known_correction >= tweet.id # No, if this is an old tweet we've already processed
      return false if tweet.text =~ /^RT\s/             # No, if this is an old school retweet
      return false if tweet.retweet?                    # No, if this is a new school retweet
      return false if recent_offender?(tweet.from_user)

      tweet.user_mentions.each do |mentioned| 
        return false if recent_offender?(mentioned.screen_name)  # Test for mentioner abuse
      end

      true # Passes all checks
    end

    def tweet_correction(tweet)
      msg = "@#{tweet.from_user} I think you mean #{ProfoundKernel.configuration.right_phrase}."

      if ProfoundKernel.configuration.dry_run
        puts "Replying to [#{tweet.id}] [#{tweet.text}] - [#{msg}]"
      else
        Twitter.update(msg, {in_reply_to_status_id: tweet.id})
      end

      update_offenders_list(tweet.from_user)
      update_last_known_correction(tweet.id)
    end

    private

    def recent_offender?(user)
      3.weeks.ago < offender_time(user)
    end

    def key_for(key) # Just a namespacing utility to separate redis data
      "#{ProfoundKernel.configuration.right_phrase}:#{key}"
    end

    def offender_time(user)
      time = @redis.get(key_for(user))

      time.nil? ? 1.year.ago: time.to_time
    end

    def update_offenders_list(user)
      @redis.set key_for(user), Time.now
    end

    def update_last_known_correction(id)
      @redis.set key_for(LAST_TWEET_KEY), id
    end

    def last_known_correction
      @redis.get(key_for(LAST_TWEET_KEY)).to_i or 1
    end
  end
end
