class Map
  attr_accessor :size, :players_count, :players, :planets_count, :planets,
    :zoom, :between_hws, :players_to_size_ratio, :planets_to_players_ratio

  def initialize(args = {})
    @zoom = 4
    @players_to_size_ratio = 10
    @planets_to_players_ratio = 10
    @between_hws = 30
    @planet_radius = 0.001
    @players_count = 30
    @players = []
    @planets = []
    [:players_count, :between_hws, :players_to_size_ratio,
      :planets_to_players_ratio].each do |parameter|
      send("#{parameter}=", args[parameter]) if args[parameter]
    end
    @planets_count = @players_count * @planets_to_players_ratio
    @size = @players_count * @players_to_size_ratio
    generate_map
  end

  def distance_between(x1, y1, x2, y2)
    dx = (x1 - x2).abs
    dx = [dx, @size - dx].min
    dy = (y1 - y2).abs
    dy = [dy, @size - dy].min
    Math.sqrt(dx ** 2 + dy ** 2)
  end

  def draw(zoom = 4)
    @zoom = zoom

    img = Magick::ImageList.new
    img.new_image(zoomed(@size), zoomed(@size))

    hw_area = Magick::Draw.new
    hw_area.fill('#DDEEFF')
    # cir.stroke('black').stroke_width(1)

    planet_brush = Magick::Draw.new
    planet_brush.fill('#003366')

    @planets.each do |planet|
      draw_circle_looped(img, hw_area, planet.x, planet.y, @between_hws / 2) if planet.is_hw?
      draw_circle_looped(img, planet_brush, planet.x, planet.y, planet.size * @planet_radius)
    end

    img
  end

  def zoomed(arg)
    arg * @zoom
  end

  def draw_looped(x, y, &block)
    yield x, y
    yield x + @size, y
    yield x - @size, y
    yield x, y + @size
    yield x, y - @size
  end

  def draw_circle_looped(img, drawing, x, y, radius)
    draw_looped(x, y) do |cur_x, cur_y|
      draw_circle(drawing, cur_x, cur_y, radius)
      drawing.draw(img)
    end
  end

  def draw_circle(drawing, x, y, radius)
     drawing.circle(zoomed(x), zoomed(y), zoomed(x + radius), zoomed(y))
  end

  def generate_map
    puts "Generating map of size #{@size} with #{@planets_count} for #{@players_count} players..."

    create_players

    place_HWs_DWs

    puts "Done."
  end

  def create_players
    1.upto @players_count do |i|
      @players << Player.new
    end
  end

  def place_HWs_DWs
    @players.each do |player|
      placed = false
      x = nil
      y = nil
      100.downto 0  do |try|
        puts "try #{try}"
        x = (SecureRandom.random_number * @size).round 2
        y = (SecureRandom.random_number * @size).round 2
        if hw_can_be_placed_at(x, y)
          placed = true
          break
        end
      end
      if placed
        @planets << Planet.new(x: x, y: y, size: 1000, richness: 10, owner: player, is_hw: true)
        puts "#{player} HW's x, y = #{x}, #{y}"
      else
        raise "Couldn't place HW"
      end
      # Place DWs
      range = 5 + (SecureRandom.random_number * 10)
      angle = SecureRandom.random_number * 360
      dwx = x + (range * Math.cos(angle))
      dwy = y + (range * Math.sin(angle))
      @planets << Planet.new(x: dwx, y: dwy, size: 500, richness: 10, owner: player, is_hw: false)
      range = 5 + (SecureRandom.random_number * 10)
      angle = SecureRandom.random_number * 360
      dwx = x + (range * Math.cos(angle))
      dwy = y + (range * Math.sin(angle))
      @planets << Planet.new(x: dwx, y: dwy, size: 500, richness: 10, owner: player, is_hw: false)
    end
  end

  def hw_can_be_placed_at(x, y)
    @planets.each do |planet|
      puts distance_between(planet.x, planet.y, x, y) if planet.is_hw
      return false if planet.is_hw && distance_between(planet.x, planet.y, x, y) <= @between_hws
    end
    return true
  end

end
