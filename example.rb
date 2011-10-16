require 'delcom_light_hid'

lights = (0..1).map{|n| DelcomLight.new(:device_index => n) }
begin
  DelcomLight::RGB.keys.each do |col|
    lights.each do |light|
      before = light.get_rgb
      print "Setting #{light.device_index} from #{before} to #{col}..."
      $stdout.flush
      light.set_rgb col
      puts " done (#{light.get_rgb})"
    end
    sleep 0.5
  end
ensure
  lights.each{|light| light.set_rgb 'off' }
end
