module DSL
  def active?
    new.active?
  end

  def button(name, options)
    define_active_method(name) if options.delete(:distinctive)
    define_scroll_to_bottom_method(name) if options.delete(:bottom)
    wait_for_class = options.delete(:wait_for_class)
    wait_for_class_timeout = options.delete(:wait_for_class_timeout)
    index = options.delete(:index)

    locator = options
    define_name_method(name, wait_for_class, wait_for_class_timeout)
    define_query_method(name, locator, index)
    define_button_method(name, locator, index)
  end

  def buttons(locator, &block)
    ButtonsBuilder.new(locator, &block)
  end

  def radio_buttons(locator, &block)
    ButtonsBuilder.new(locator, &block)
    define_selected_method
  end

  def text_field(name, options)
    define_active_method(name) if options.delete(:distinctive)

    locator = options
    define_text_field_method(name, locator)
    define_query_method(name, locator)
    define_setter(name, locator)
    define_getter(name, locator)
  end

  def switch(name, options)
    define_active_method(name) if options.delete(:distinctive)
    wait_for_class = options.delete(:wait_for_class)

    locator = options
    define_query_method(name, locator)
    define_switch_methods(name, locator, wait_for_class)
  end
  alias checkbox switch

  def view(name, options)
    define_active_method(name) if options.delete(:distinctive)

    locator = options
    define_query_method(name, locator)
    define_view_method(name, locator)
  end

  private

  def define_active_method(name)
    define_method(:active?) do
      send("#{name}?")
    end
  end

  def define_scroll_to_bottom_method(name)
    define_method(:scroll_to_bottom) do
      start = Time.now
      until send("#{name}?")
        fling_down
        sleep 0.1
        fail "Unable to scroll to the bottom (#{name} button)" if Time.now > start + 60
      end
    end
  end

  def define_name_method(name, wait_for_class, wait_for_class_timeout)
    wait_for_class_timeout = 10 unless wait_for_class_timeout

    define_method(name) do
      send("#{name}_button").click
      if wait_for_class
        wait(wait_for_class_timeout, "Screen #{wait_for_class} hasn't became active") do
          self.class.const_get(wait_for_class).active?
        end
      end
    end
  end

  def define_text_field_method(name, locator)
    define_method("#{name}_text_field") do
      begin
        find_element(locator)
      rescue Selenium::WebDriver::Error::NoSuchElementError => e
        fail e.class, "'#{name}' text field cannot be found using #{locator}", caller.reject { |line| line =~ /#{__FILE__}/ }
      end
    end
  end

  def define_query_method(name, locator, index = nil)
    define_method("#{name}?") do
      if index
        !!find_elements(locator)[index] || false
      else
        begin
          !!find_element(locator)
        rescue Selenium::WebDriver::Error::NoSuchElementError
          false
        end
      end
    end
  end

  def define_button_method(name, locator, index)
    define_method("#{name}_button") do
      if index
        button = find_elements(locator)[index]
        unless button
          fail Selenium::WebDriver::Error::NoSuchElementError,
               "'#{name}' button cannot be found using #{locator} with index #{index}",
               caller.reject { |line| line =~ /#{__FILE__}/ }
        end
        button
      else
        begin
          find_element(locator)
        rescue Selenium::WebDriver::Error::NoSuchElementError => e
          fail e.class, "'#{name}' button cannot be found using #{locator}", caller.reject { |line| line =~ /#{__FILE__}/ }
        end
      end
    end
  end

  def define_view_method(name, locator)
    define_method("#{name}_view") do
      begin
        find_element(locator)
      rescue Selenium::WebDriver::Error::NoSuchElementError
        fail %(Element "#{name}" with locator "#{locator}" wasn't found)
      end
    end
  end

  def define_setter(name, locator)
    define_method("#{name}=") do |text|
      find_element(locator).send_keys text
    end
  end

  def define_getter(name, locator, index = nil)
    define_method(name) do
      if index
        find_elements(locator)[index].name
      else
        find_element(locator).name
      end
    end
  end

  def define_switch_methods(name, locator, wait_for_class)
    define_method("#{name}_switch") do
      find_element(locator)
    end

    define_method("toggle_#{name}") do
      find_element(locator).click
    end

    define_method("#{name}_on?") do
      find_element(locator).attribute(:checked) == 'true'
    end
    alias_method "#{name}_selected?".to_sym, "#{name}_on?".to_sym

    define_method("turn_on_#{name}") do
      unless send("#{name}_on?")
        send("toggle_#{name}")
        if wait_for_class
          wait(5, "Screen #{wait_for_class} hasn't became active") do
            Module.const_get(wait_for_class).active?
          end
        end
      end
    end

    define_method("turn_off_#{name}") do
      if send("#{name}_on?")
        send("toggle_#{name}")
        if wait_for_class
          wait(5, "Screen #{wait_for_class} hasn't became active") do
            Module.const_get(wait_for_class).active?
          end
        end
      end
    end
  end

  def define_selected_method
    button_methods = instance_methods.grep(/_button/)
    define_method(:selected) do
      result = button_methods.map do |button_method|
        send(button_method).checked? && button_method.to_s.sub(/_button/, '').to_sym
      end
      result.grep_v(false).first
    end
  end

  class ButtonsBuilder
    def initialize(locator, &block)
      @locator = locator
      @block = block
      @index = 0
      instance_exec(&block)
    end

    def method_missing(method, *args)
      button_name = args[0]
      button_params = args[1] || {}

      unless button_params.key?(:index)
        button_params[:index] = @index
        @index += 1
      end

      @block.binding.receiver.button button_name, @locator.merge(button_params)
    end
  end
end
