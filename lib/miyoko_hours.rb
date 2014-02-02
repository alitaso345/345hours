# -*- coding: utf-8 -*-
require "logger"

LOGGER = Logger.new(STDOUT)
LOGGER.formatter = proc{|severity,datetime,progname,msg|
  "#{msg}\n"
}

STDOUT.sync = true

class MiyokoHours
  def initialize(settings)
    LOGGER.info status 

    twitter = settings["twitter"]

    @streamer = Streamer.new(twitter["my_screen_name"],{
      consumer_key:   twitter["consumer_key"],
      consumer_secret:twitter["consumer_secret"],
      access_key:     twitter["access_key"],
      access_secret:  twitter["access_secret"],
    })
  end

  def watch
    @streamer.start
  end

  def status
    result = "MiyokoHours:\n"

    result.gsub("MiyokoHours::","")
  end

  class Streamer
    def initialize(me,oauth)
      @me = me
      @options = {
        host: "userstream.twitter.com",
        path: "/2/user.json",
        ssl:  true,
        oauth:oauth
      }

    end

    def start
      EventMachine::run{
        EventMachine::defer{
          @stream = Twitter::JSONStream.connect(@options)
          
          @stream.each_item do |item|
            data = Yajl::Parser.parse(item)
            handle(data)
          end

          @stream.on_error do |message|
            LOGGER.error "On error:#{message}"
          end
        }
      }
    end

    private
    def handle(data)
      if data["friends"]
        handle_friends(data)
        return
      end

      if data["text"]
        if data["retweeted_status"]
          handle_retweet(data)
        else
          handle_tweet(data)
        end
        return
      end
    end

    def handle_friends(data)
      LOGGER.info "You are following %d users" % data["friends"].size
    end

    def handle_retweet(data)
      text = data["text"]
      user = data["user"]
      name = user["screen_name"]

      LOGGER.info "@%s (♺) %s" % [name, expand_url(text, data["entities"]["urls"])]
    end

    def handle_tweet(data)
      text = data["text"]
      user = data["user"]
      name = user["screen_name"]

      LOGGER.info "@%s: %s" % [name,expand_url(text,data["entities"]["urls"])]
      `echo '#{expand_url(text,data["entities"]["urls"])}' | say -v 'Alex'`
    end

    def expand_url(text,urls)
      return text if urls.empty?

      urls.inject(text) do |result,entry|
        url = entry["url"]
        expanded = entry["expanded_url"]

        result.sub(url,expanded)
      end
    end
  end
end
