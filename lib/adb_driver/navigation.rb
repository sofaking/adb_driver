module AdbDriver
  class Navigation
    def back
      `adb shell input keyevent KEYCODE_BACK`
    end
  end
end
