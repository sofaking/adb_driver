require 'logger'

module AdbDriver
  class Driver
    include Finder
    include Wait

    SCREENSHOT_TIMEOUT = 5

    attr_reader :logger

    def initialize
      @logger = Logger.new('adb_driver.log')
      @logger.level = Logger::DEBUG
      @logger.info 'Initializing Adb driver'
    end

    def save_screenshot(filepath)
      if Adb.android_5_or_greater?
        wait(SCREENSHOT_TIMEOUT) { `adb exec-out screencap -p > #{filepath}` }
      else
        wait(SCREENSHOT_TIMEOUT) { `adb shell screencap -p /sdcard/screenshot.png; adb pull /sdcard/screenshot.png #{filepath}` }
      end
    rescue Wait::Error => e
      raise e.class, 'Cannot take a screenshot'
    end

    def navigate
      @navigation ||= Navigation.new
    end

    def quit
    end
  end
end
