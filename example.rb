require 'delcom_hid'
require 'timeout'

light1 = Delcom.new(:device_index => 0)
light2 = Delcom.new(:device_index => 1)
begin
  begin
    Timeout::timeout(5) do
      loop do
        light1.set Delcom::RGB::PURPLE
        light2.set Delcom::RGB::YELLOW
        light1, light2 = light2, light1
        sleep 0.5
      end
    end
  rescue Timeout::Error
    light1.set(Delcom::OFF)
    light2.set(Delcom::OFF)
  end
end
