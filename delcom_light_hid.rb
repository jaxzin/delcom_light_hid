#!/usr/bin/env ruby
#
# AUTHORS
#   Ian Leitch <ian@envato.com>, Copyright 2010 Envato
#     * Original single light RGY version
#   Gregory McIntyre <blue.puyo@gmail.com>
#     * RGY+RGB support
#     * Multiple light support
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

  module RGB
    COLORS = [
      GREEN = 0x01,
      RED = 0x02,
      BLUE = 0x04,
      YELLOW = GREEN | RED,
      CYAN = GREEN | BLUE,
      PURPLE = RED | BLUE,
      WHITE = GREEN | RED | BLUE,
    ]
  end
  module RGY
    COLORS = [
      GREEN = 0x01,
      RED = 0x02,
      YELLOW = 0x04,
      WHITE = GREEN | RED | YELLOW,
    ]
  end
  OFF = 0x00

  # Create a handler and ensure it gets closed after your block exits.
  def self.open(*args_to_new, &block)
    light = new(*args_to_new)
    begin
      block.call(light)
    ensure
      light.close
    end
  end

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

  def set(data)
    handle.usb_control_msg(0x21, 0x09, 0x0635, 0x000, "\x65\x0C#{[data].pack('C')}\xFF\x00\x00\x00\x00", 0)
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
