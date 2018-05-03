unless defined?(Selenium)
  module Selenium
    module WebDriver
      module Error
        class NoSuchElementError < StandardError; end
      end
    end
  end
end

module AdbDriver
  module Error
    class NoSuchElementError < Selenium::WebDriver::Error::NoSuchElementError; end
    class TimeOutError < StandardError; end
  end
end
