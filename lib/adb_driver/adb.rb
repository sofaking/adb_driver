require 'timeout'

module Adb
  extend Timeout
  extend self

  def execute_command(command, timeout_in_seconds = 10)
    timeout(timeout_in_seconds) { `adb #{command}` }
  end

  def app_version(package_name)
    output = execute_command("shell dumpsys package #{package_name}")
    version_line = output.lines.grep(/versionName/).first.strip
    version_line[/=(.*)/, 1]
  end

  def package_exists?(package_name)
    execute_command('shell pm list packages').lines.grep(/#{package_name}\s*$/).one?
  end

  def android_5_or_greater?
    android_version[0].to_i >= 5
  end

  def android_6_or_greater?
    android_version[0].to_i >= 6
  end

  def android_6?
    android_version.start_with?('6')
  end

  def android_7?
    android_version.start_with?('7')
  end

  def real_device?
    output = execute_command('devices -l')
    output = output.lines.grep(/#{ENV['ANDROID_SERIAL']}/).first
    output.include?('usb')
  end

  def emulator?
    !real_device?
  end

  def samsung?
    brand == 'samsung'
  end

  def htc?
    brand == 'htc'
  end

  def asus?
    brand == 'asus'
  end

  def lenovo?
    brand == 'Lenovo'
  end

  def density
    @density ||= execute_command('shell getprop ro.sf.lcd_density').to_i
  end

  def brand
    execute_command('shell getprop ro.product.brand').strip
  end

  def model
    execute_command('shell getprop ro.product.model').strip
  end

  def remove_package(name)
    return unless package_exists?(name)
    `adb uninstall #{name}`
    fail "#{name} package wasn't removed" if package_exists?(name)
  end

  def restart_adb
    `adb kill-server; adb start-server`
  end

  def portrait?
    @orientation_enum ||= `adb shell dumpsys input`.lines.find { |l| l =~ /SurfaceOrientation/ }.strip[-1].to_i
    @orientation_enum.even?
  end

  def connected_device_udid
    case
    when devices.none?                            then fail('No devices detected')
    when devices.one?                             then devices.first.udid
    when devices.count > 1 && emulators.none?     then fail('Several devices detected. Set ANDROID_SERIAL to pick one')
    when devices.count > 1 && emulators.one?      then emulators.first.udid
    when devices.count > 1 && emulators.count > 1 then fail('Several emulators detected. Close all but one')
    end
  end

  private

  def android_version
    execute_command('shell getprop ro.build.version.release').lines.last.strip
  end

  def devices
    @device_list ||= begin
                       execute_command('devices -l').lines.grep(/model/).inject([]) do |dl, device_string|
                         dl << Device.new(device_string[/^\S+/])
                       end
                     end
  end

  def emulators
    @emulators_list ||= begin
                       execute_command('devices -l').lines.grep(/model/).grep_v(/usb/).inject([]) do |dl, device_string|
                         dl << Device.new(device_string[/^\S+/])
                       end
                     end
  end

  Device = Struct.new(:udid)
end
