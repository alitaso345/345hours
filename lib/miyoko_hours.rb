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
    end

    def handle_friends(data)
      LOGGER.info "You are following %d users" % data["friends"].size
    end
  end
end
