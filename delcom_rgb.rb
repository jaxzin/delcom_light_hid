#!/usr/bin/env ruby
#
# RGY original: Ian Leitch <ian@envato.com>, Copyright 2010 Envato
# RGB version: Gregory McIntyre <blue.puyo@gmail.com>
#
# You'll need to install ruby-usb:
#
#   gem install ruby-usb
#
# Only pass :vendor_id, :product_id or :interface_id to Delcom.open if you need
# to override their defaults.

require 'rubygems' rescue nil
require 'usb'

class Delcom
  DEFAULT_VENDOR_ID = 0x0fc5
  DEFAULT_PRODUCT_ID = 0xb080
  DEFAULT_INTERFACE_ID = 0
  DEFAULT_DEVICE_INDEX = 0

  OFF = 0x00
  COLORS = [
    GREEN = 0x01,
    RED = 0x02,
    BLUE = 0x04, # this is yellow on the RGY model
    YELLOW = GREEN | RED,
    CYAN = GREEN | BLUE,
    PURPLE = RED | BLUE,
    WHITE = GREEN | BLUE | RED,
  ]

  def self.open(*args, &block)
    light = new(*args)
    begin
      block.call(light)
    ensure
      light.close
    end
  end

  def initialize(opts = {})
    @vendor_id = opts[:vendor_id] || DEFAULT_VENDOR_ID
    @product_id = opts[:product_id] || DEFAULT_PRODUCT_ID
    @device_index = opts[:device_index] || DEFAULT_DEVICE_INDEX
    @interface_id = opts[:interface_id] || DEFAULT_INTERFACE_ID
    @device = USB.devices.select {|device| device.idVendor == @vendor_id && device.idProduct == @product_id}[@device_index]
    raise "Unable to find device" unless @device
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
      # ruby-usb bug: the arity of rusb_detach_kernel_driver_np isn't defined correctly, it should only accept a single argument
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

if $0 == __FILE__ # example
  require 'timeout'

  light1 = Delcom.new(:device_index => 0)
  light2 = Delcom.new(:device_index => 1)
  begin
    begin
      Timeout::timeout(5) do
        loop do
          light1.set Delcom::PURPLE
          light2.set Delcom::YELLOW
          light1, light2 = light2, light1
          sleep 0.5
        end
      end
    rescue Timeout::Error
      light1.set(Delcom::OFF)
      light2.set(Delcom::OFF)
    end
  end
end
