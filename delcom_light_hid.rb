#!/usr/bin/env ruby
#
# AUTHORS
#   Ian Leitch <ian@envato.com>, Copyright 2010 Envato
#     * Original single light RGY version
#   Gregory McIntyre <blue.puyo@gmail.com>
#     * RGY+RGB support
#     * Multiple light support
#     * Method to get current light color
#
# You'll need to install ruby-usb:
#
#   gem install ruby-usb
#
# Only pass :vendor_id, :product_id or :interface_id to DelcomLight.open if you
# need to override their defaults.

require 'rubygems' rescue nil
require 'usb'

class DelcomLight
  DEFAULT_VENDOR_ID = 0x0fc5
  DEFAULT_PRODUCT_ID = 0xb080
  DEFAULT_DEVICE_INDEX = 0
  DEFAULT_INTERFACE_ID = 0

  RGB = {
    'green' => 0x01,
    'red' => 0x02,
    'blue' => 0x04,
    'off' => 0x00,
  }
  RGB['yellow'] = RGB['green'] | RGB['red']
  RGB['cyan'] = RGB['green'] | RGB['blue']
  RGB['purple'] = RGB['red'] | RGB['blue']
  RGB['white'] = RGB['green'] | RGB['red'] | RGB['blue']

  RGY = {
    'green' => 0x01,
    'red' => 0x02,
    'yellow' => 0x04,
  }
  RGY['white'] = RGY['green'] | RGY['red'] | RGY['yellow']

  # Create a handler and ensure it gets closed after your block exits.
  def self.open(*args_to_new, &block)
    light = new(*args_to_new)
    begin
      block.call(light)
    ensure
      light.close
    end
  end

  attr_reader :device_index

  # Create a handler that can control the light. Options are:
  #
  # * <tt>:device_index</tt> - Zero-based index of the light to use, if you have multiple lights.
  def initialize(options = {})
    @vendor_id = options[:vendor_id] || DEFAULT_VENDOR_ID
    @product_id = options[:product_id] || DEFAULT_PRODUCT_ID
    @device_index = options[:device_index] || DEFAULT_DEVICE_INDEX
    @interface_id = options[:interface_id] || DEFAULT_INTERFACE_ID
    @device = USB.devices.select {|device| 
      device.idVendor == @vendor_id && device.idProduct == @product_id
    }[@device_index]
    raise 'Unable to find device' unless @device
  end

  def close
    handle.release_interface(@interface_id)
    handle.usb_close
    @handle = nil
  end

  def set_rgb(colour)
    set(RGB.fetch(colour))
  end

  def set_rgy(colour)
    set(RGY.fetch(colour))
  end

  def get_rgb
    case get_data
    when 0xfe then 'green'
    when 0xfd then 'red'
    when 0xfb then 'blue'
    when 0xfc then 'yellow'
    when 0xfa then 'cyan'
    when 0xf9 then 'purple'
    when 0xf8 then 'white'
    when 0x00, 0xfe then 'off'
    else 'unknown'
    end
  end

  def get_rgy
    case get_data
    when 0xfe then 'green'
    when 0xfd then 'red'
    when 0xfb then 'yellow'
    when 0xf8 then 'white'
    when 0x00, 0xfe then 'off'
    else 'unknown'
    end
  end

  private

  def set(data)
    handle.usb_control_msg(0x21, 0x09, 0x0300, 0x000, "\x65\x0C#{[data].pack('C')}\xFF\x00\x00\x00\x00", 0)
  end

  def get_data
    buf = "\0"*8
    buf[0] = 100
    status = handle.usb_control_msg(0xa1, 0x01, 0x0301, 0x000, buf, 0)
    raise "Error reading status" if status != 8
    buf[2]
  end

  def get
    buf = "\0"*8
    buf[0] = 100
    status = handle.usb_control_msg(0xa1, 0x01, 0x0301, 0x000, buf, 0)
    raise "Error reading status" if status != 8
    result = buf[2]
    case result
    when 0xfe then DelcomLight::RGB::GREEN
    when 0xfd then DelcomLight::RGB::RED
    when 0xfb then DelcomLight::RGB::BLUE
    when 0xfc then DelcomLight::RGB::YELLOW
    when 0xfa then DelcomLight::RGB::CYAN
    when 0xf9 then DelcomLight::RGB::PURPLE
    when 0xf8 then DelcomLight::RGB::WHITE
    when 0xfe then DelcomLight::OFF
    else raise 'Unknown result: %02x' % result
    end
  end

  private

  def handle
    return @handle if @handle
    @handle = @device.usb_open
    begin
      # ruby-usb bug: the arity of rusb_detach_kernel_driver_np isn't defined
      # correctly, it should only accept a single argument
      if USB::DevHandle.instance_method(:usb_detach_kernel_driver_np).arity == 2
        @handle.usb_detach_kernel_driver_np(@interface_id, @interface_id)
      else
        @handle.usb_detach_kernel_driver_np(@interface_id)
      end
    rescue Errno::ENODATA => e
      # already detached
    end
    @handle.set_configuration(@device.configurations.first)
    @handle.claim_interface(@interface_id)
    @handle
  end
end
