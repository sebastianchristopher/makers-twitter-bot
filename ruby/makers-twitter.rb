# As a manager,
#   so that I can keep up to date with what is being said about the
#   company on social media
#   I would like to receive a text message of tweets with #mackersacademy in the hashtag
#   As a manager,
#   so that I can see just relevant details
#   I would only like to see original tweets with the text, user and creation time.
# cj - I'm assuming that original tweets means excluding retweets

# As a manager,
# so that I never miss a tweet
# I would like tweets to be texted on a regular schedule (every day or so)

require 'pry'
require 'twitter'
require 'dotenv/load'
require 'twilio-ruby'
require 'yaml'

class TwitterBot
  def initialize
# "client" gives us access to the whole Twitter API
    @twitter_client = Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV["TWITTER_CONSUMER_KEY"]
      config.consumer_secret     = ENV["TWITTER_CONSUMER_SECRET"]
      config.access_token        = ENV["TWITTER_ACCESS_TOKEN"]
      config.access_token_secret = ENV["TWITTER_ACCESS_TOKEN_SECRET"]
    end

    @twilio_client = Twilio::REST::Client.new(
        account_sid = ENV["TWILIO_ACCOUNT_SID"],
        auth_token = ENV["TWILIO_AUTH_TOKEN"]
      )
  end

  # def print_tweets
  #   all_tweets_with_hashtag("makersacademy").each { |tweet| puts tweet.full_text }
  # end

  def send_text(to = '+447795537261‬',from = '+441827232034')
    message = format_tweets
    # puts "#makersacademy was tagged in the following tweets:\n\n#{message.join("\n\n")}"
    # return
    @twilio_client.api.account.messages.create(
      to: to,
      from: from,
      body: "#makersacademy was tagged in the following tweets:\n\n#{message.join("\n\n")}"
     )
   end

   # def daily_update
   #   write_file
   #   tweets = format_tweets
   #   tweets
   # end

   private

   def all_tweets_with_hashtag(hashtag)
     # tweets with #mackersacademy (-rt part of twitter's search to remove retweets)
     @twitter_client.search("##{hashtag} -rt", count: 10, result_type: 'mixed', lang: 'en') # tweet_mode: "extended" # returns untruncated text when .attrs[:full_text] used, but resulting text is too long for a text
     # another way to remove retweets, using the Ruby twitter api
     # tweets = hashtag_makersacademy.select { |tweet| !tweet.retweeted_tweet? }
   end

  def organize_tweets
    tweets = all_tweets_with_hashtag("makersacademy")
    list_of_tweets = []
    tweets.each{ |tweet|
      list_of_tweets << {
      # tweet: tweet.attrs[:full_text], # : Unable to create record (Twilio::REST::RestError) # The concatenated message body exceeds the 1600 character limit. # https://www.twilio.com/docs/errors/21617
      tweet: tweet.full_text,
      user: tweet.user.screen_name,
      created: tweet.created_at,
      url: tweet.uri
      }
    }
    list_of_tweets
  end

  def format_tweets
    tweets = organize_tweets
    formatted_tweets = []
    tweets.each { |tweet|
      formatted_tweets << "posted by #{tweet[:user]} on #{tweet[:created]}: #{tweet[:tweet]} \nlink: #{tweet[:url]}"
    }
    formatted_tweets
  end

  def write_file
    File.write('tweets.yml', YAML.dump(organize_tweets))
  end

  def load_file
    YAML.load_file('tweets.yml')
  end
end

# in pry, ls Twitter::Tweets will list the methods for Tweet class
# binding.pry

bot = TwitterBot.new
bot.send_text
