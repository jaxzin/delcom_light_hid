require 'delcom_light_hid'

lights = (0...2).map{|n| DelcomLight.new(:device_index => n) }
begin
  (0..(DelcomLight::RGB::COLORS.size - lights.size)).each do |i|
    x = i
    lights.each do |l|
      col = DelcomLight::RGB::COLORS[x]
      l.set col
      p [col, l.get]
      x += 1
    end
    sleep 0.5
  end
ensure
  lights.each{|light| light.set DelcomLight::OFF }
end
