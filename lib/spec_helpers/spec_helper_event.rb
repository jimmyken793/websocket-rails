module WebsocketRails
  module ConnectionAdapters

    class SpecHelperConnection < Base
      attr_accessor :data_store
      attr_reader :id
      attr_reader :dispatcher

      def initialize(id, request, dispatcher)
        # super(request, dispatcher)
        @delegate   = WebsocketRails::DelegationController.new
        @dispatcher = dispatcher
        @data_store = {}
        @id = id
        if request.nil?
          @env      = Rack::MockRequest.env_for('/websocket')
          @delegate.instance_variable_set(:@_env, @env)
        else
          @env      = request.env.nil? ? {} : request.env.dup
          @delegate.instance_variable_set(:@_env, request.env)
        end
        @request    = request
        @dispatcher = dispatcher
        @connected  = true
        @queue      = EventQueue.new
        @data_store = DataStore::Connection.new(self)
        @delegate.instance_variable_set(:@_request, request)
      end

      def send(message)

      end

      def new_event(event_name, data)
        SpecHelperEvent.new(self, event_name, {:data=>data, :connection=>self})
      end
    end
  end

  class SpecHelperConnectionManager
    attr_reader :connections, :dispatcher, :synchronization
    def initialize(request)
      @request = request
      @connections = {}
      @dispatcher  = Dispatcher.new(self)
      @connection_count = 1
    end

    def new_connection
      connection = ConnectionAdapters::SpecHelperConnection.new(@connection_count, @request, dispatcher)
      @connection_count = @connection_count + 1
      connection
    end
  end

  class SpecHelperEvent < Event

    attr_reader :triggered, :connection

    alias :triggered? :triggered

    def initialize(connection, event_name, options={})
      super(event_name, options)
      @triggered = false
      @connection = connection
    end

    def trigger
      @triggered = true
      triggered_with(self)
    end

    def triggered_with(arg)
    end

    def dispatcher
      @connection.dispatcher
    end

    def dispatch
      @connection.dispatcher.dispatch(self)
      self
    end

  end

end
def dispatcher
  connection_manager.dispatcher
end

def connection_manager
  if @conn_manager.nil?
    @conn_manager = WebsocketRails::SpecHelperConnectionManager.new(@request)
    WebsocketRails.dispatcher = @conn_manager.dispatcher
  end
  @conn_manager
end

def connection
  @connection ||= connection_manager.new_connection
end

def create_event(name, data={})
  connection.new_event(name, data)
end
