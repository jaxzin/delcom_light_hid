require 'delcom_light_hid'
require 'timeout'

light1 = DelcomLight.new(:device_index => 0)
light2 = DelcomLight.new(:device_index => 1)
begin
  begin
    Timeout::timeout(5) do
      loop do
        light1.set DelcomLight::RGB::PURPLE
        light2.set DelcomLight::RGB::YELLOW
        light1, light2 = light2, light1
        sleep 0.5
      end
    end
  rescue Timeout::Error
    light1.set(DelcomLight::OFF)
    light2.set(DelcomLight::OFF)
  end
end
