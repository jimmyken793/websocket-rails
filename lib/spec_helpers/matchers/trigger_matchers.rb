# require 'rspec-partial-hash'

module WebsocketRails

  module SpecHelpers

    def self.compare_trigger_data(event, data)
      return true if data.nil?
      return true if data == :any and event.data
      return true if data == :nil and event.data.nil?
      data.eql? event.data
    end

    def self.expected_data_for_spec_message(data)
      case data
        when nil
          ''
        when :nil
          ' with no data'
        when :any
          ' with some data'
        else
          " with data #{data}"
      end
    end

    def self.actual_data_for_spec_message(data)
      data ? "with data #{data}": 'with no data'
    end

    def self.actual_for_spec_message(event, success)
      if event.triggered?
        if success.nil?
          "triggered message #{actual_data_for_spec_message(event.data)}"
        else
          "triggered #{event.success ? 'a success' : 'a failure' } message #{actual_data_for_spec_message(event.data)}"
        end
      else
        'did not trigger any message'
      end
    end

    def self.verify_trigger(event, data, success)
      return false unless event.triggered?
      return false unless compare_trigger_data(event, data)
      success.nil? || success == event.success
    end

  end

end

def partial_match?(expected, actual)
  actual_slice = actual.slice(*expected.keys)
  if actual_slice.keys == expected.keys
    actual_slice.each do |key, value|
      if expected[key].is_a?(Hash)
        return partial_match?(expected[key], value)
      elsif  expected[key].is_a?(Array)
        v=Hash[value.each_with_index.map { |value, index| [index, value] }]
        e=Hash[expected[key].each_with_index.map { |value, index| [index, value] }]
        return partial_match?(e,v)
      else
        return false unless value == expected[key]
      end
    end
    true
  else
    false
  end
end

RSpec::Matchers.define :json_include do |expected|

  match do |actual|
    actual_data =  JSON.parse actual.to_json
    expected_data = JSON.parse expected.to_json
    begin
      expect(actual_data.class).to eq(expected_data.class)
      if expected_data.class == Hash
        expect(partial_match?(expected_data, actual_data)).to eq(true)
      end
      true
    rescue
      false
    end
  end
end
RSpec::Matchers.define :trigger_success do |expected|
  match do |event|
    if expected.nil?
      expect(event).to receive(:triggered_with).with(have_attributes(:success => true))
    else
      expect(event).to receive(:triggered_with).with(have_attributes(:data => json_include(expected), :success => true))
    end
  end
  failure_message do |event|
    "expected that Event would trigger success, but it triggered failure with #{event.data}"
  end
end

RSpec::Matchers.define :trigger_failure do |expected|
  match do |event|
    if expected.nil?
      expect(event).to receive(:triggered_with).with(have_attributes(:success => false))
    else
      expect(event).to receive(:triggered_with).with(have_attributes(:data => json_include(expected), :success => false))
    end
  end
  failure_message do |event|
    "expected that Event would trigger failure, but it triggered success with #{event.data}"
  end
end


RSpec::Matchers.define :trigger_channel do |expected_event_name, &block|
  match do |event|

  end
end

RSpec::Matchers.define :trigger_message do |data|

  match do |event|
    WebsocketRails::SpecHelpers.verify_trigger event, data, nil
  end

  failure_message do |event|
    "expected #{event.encoded_name} to trigger message#{WebsocketRails::SpecHelpers.expected_data_for_spec_message data}, " +
        "instead it #{WebsocketRails::SpecHelpers.actual_for_spec_message event, nil}"
  end

  failure_message_when_negated do |event|
    "expected #{event.encoded_name} not to trigger message#{WebsocketRails::SpecHelpers.expected_data_for_spec_message data}"
  end

  description do
    "trigger message#{WebsocketRails::SpecHelpers.expected_data_for_spec_message data}"
  end

end

RSpec::Matchers.define :trigger_success_message do |data|

  match do |event|
    WebsocketRails::SpecHelpers.verify_trigger event, data, true
  end

  failure_message do |event|
    "expected #{event.encoded_name} to trigger success message#{WebsocketRails::SpecHelpers.expected_data_for_spec_message data}, "+
        "instead it #{WebsocketRails::SpecHelpers.actual_for_spec_message event, true}"
  end

  failure_message_when_negated do |event|
    "expected #{event.encoded_name} not to trigger success message#{WebsocketRails::SpecHelpers.expected_data_for_spec_message data}"
  end

  description do
    "trigger success message#{WebsocketRails::SpecHelpers.expected_data_for_spec_message data}"
  end

end

RSpec::Matchers.define :trigger_failure_message do |data|

  match do |event|
    WebsocketRails::SpecHelpers.verify_trigger event, data, false
  end

  failure_message do |event|
    "expected #{event.encoded_name} to trigger failure message#{WebsocketRails::SpecHelpers.expected_data_for_spec_message data}, " +
        "instead it #{WebsocketRails::SpecHelpers.actual_for_spec_message event, true}"
  end

  failure_message_when_negated do |event|
    "expected #{event.encoded_name} not to trigger failure message#{WebsocketRails::SpecHelpers.expected_data_for_spec_message data}"
  end

  description do
    "trigger failure message#{WebsocketRails::SpecHelpers.expected_data_for_spec_message data}"
  end

end
