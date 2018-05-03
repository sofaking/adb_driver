module AdbDriver
  module Finder
    include Wait

    FIND_ELEMENT_TIMEOUT = 1
    PAGE_SOURCE_TIMEOUT = 15
    MIN_TIME_BETWEEN_FIND_ATTEMPTS = 0.250

    def find_element(locator)
      wait(FIND_ELEMENT_TIMEOUT) { find_elements(locator).first }
    rescue Wait::Error
      logger.info "Element with locator '#{locator}' has not been found"
      logger.debug "Current hierarchy: #{@last_view_hierarchy}"
      raise Error::NoSuchElementError
    end

    def find_elements(locator)
      logger.info "Searching for element by: #{locator}"

      locator_type = locator.first.first
      locator_value = locator.first.last

      case locator_type
      when :xpath        then find_elements_by_xpath(locator_value)
      when :id           then find_elements_by_xpath("//*[contains(@resource-id,'#{locator_value}')]")
      when :class_name   then find_elements_by_xpath("//*[@class='#{locator_value}']")
      when :content_desc then find_elements_by_xpath("//*[@content-desc='#{locator_value}']")
      end
    end

    def find_elements_by_xpath(xpath)
      sleep 0.05 until Time.now >= (@last_find_attempt_time ||= Time.now) + MIN_TIME_BETWEEN_FIND_ATTEMPTS

      view_hierarchy = REXML::Document.new(page_source)
      @last_view_hierarchy = view_hierarchy

      result = view_hierarchy.get_elements(xpath).map { |element| Element.new(element) }
      @last_find_attempt_time = Time.now
      logger.debug "Returning element(s): #{result}"
      result
    end

    def page_source
      adb_command = Adb.android_7? ? 'exec-out uiautomator dump /dev/tty' : 'shell uiautomator dump /dev/tty'
      logger.info "Getting view hierarchy"
      result = Adb.execute_command(adb_command, PAGE_SOURCE_TIMEOUT)

      if result.empty? || result.strip == 'Killed'
        logger.info "Result is empty or 'Killed'. Restarting adb..."
        Adb.restart_adb
        logger.info "Adb restarted. Getting result..."
        result = Adb.execute_command(adb_command, PAGE_SOURCE_TIMEOUT)
      end

      logger.debug "Result received: #{result}"
      result
    rescue Wait::Error
      raise TimeOutError, "Couldn't get page_source in reasonable time (#{PAGE_SOURCE_TIMEOUT} seconds)"
    end
  end
end
