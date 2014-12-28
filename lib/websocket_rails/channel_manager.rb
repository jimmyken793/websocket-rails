require 'redis-objects'

module WebsocketRails

  class << self
    def private_channel_patterns
      @patterns ||= []
    end

    def add_private_channel_pattern(pattern)
      @patterns ||= []
      @patterns << pattern
    end

    def channel_manager
      @channel_manager ||= ChannelManager.new
    end

    def [](channel)
      channel_manager[channel]
    end

    def channel_tokens
      channel_manager.channel_tokens
    end

    def filtered_channels
      channel_manager.filtered_channels
    end

  end

  class ChannelManager

    attr_reader :channels, :filtered_channels

    def initialize
      @channels = {}.with_indifferent_access
      @filtered_channels = {}.with_indifferent_access
    end

    def channel_tokens
      @channel_tokens ||= begin
        if WebsocketRails.synchronize?
          ::Redis::HashKey.new('websocket_rails.channel_tokens', Synchronization.redis)
        else
          {}
        end
      end
    end

    def [](channel)
      c = @channels[channel]
      if c.nil?
        c = Channel.new channel
        WebsocketRails.private_channel_patterns.each{|pattern|
          if channel =~ pattern
            c.make_private
          end
        }
        @channels[channel] = c
        return c
      end
      return c
    end

    def unsubscribe(connection)
      @channels.each do |channel_name, channel|
        channel.unsubscribe(connection)
      end
    end

  end
end
