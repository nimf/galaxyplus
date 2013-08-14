class Map
  attr_accessor :size, :players_count, :players, :planets_count, :planets,
    :zoom, :restrictions, :players_to_size_ratio, :planets_to_players_ratio

  def initialize(args = {})
    @planets_probability = {
      0  ... 8   => {size: 0..0,       richness: 0..0,  kind: :asteroid}, # 8%
      8  ... 26  => {size: 0..500,     richness: 5..25, kind: :small},    # 18%
      26 ... 76  => {size: 0..1000,    richness: 0..10, kind: :regular},  # 50%
      76 ... 94  => {size: 1000..2000, richness: 1..10, kind: :big},      # 18%
      94 ... 100 => {size: 1500..2500, richness: 0..3,  kind: :superbig}  # 6%
    }
    @zoom = 4
    @players_to_size_ratio = 10
    @planets_to_players_ratio = 10
    @restrictions = {}
    @restrictions[:distance] = {
      :hw => 30,
      :big => 10,
      :superbig => 20
    }
    @dw_to_hw_min = 5
    @dw_to_hw_max = 15
    @planet_radius = 0.001
    @players_count = 30
    @players = []
    @planets = []
    [:players_count, :restrictions, :players_to_size_ratio,
      :planets_to_players_ratio].each do |parameter|
      send("#{parameter}=", args[parameter]) if args[parameter]
    end
    @planets_count = @players_count * @planets_to_players_ratio
    @planets_to_place = @planets_count
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

    brush = {
      hw: Magick::Draw.new,
      dw: Magick::Draw.new,
      asteroid: Magick::Draw.new,
      small: Magick::Draw.new,
      regular: Magick::Draw.new,
      big: Magick::Draw.new,
      superbig: Magick::Draw.new
    }

    brush[:hw].fill('#003366')
    brush[:dw].fill('#003366')
    brush[:asteroid].fill('#000000')
    brush[:small].fill('#FF3300')
    brush[:regular].fill('#FF9900')
    brush[:big].fill('#009933')
    brush[:superbig].fill('#00CC99')

    hw_area = Magick::Draw.new
    hw_area.fill('#DDEEFF')
    # cir.stroke('black').stroke_width(1)

    @planets.each do |planet|
      draw_circle_looped(img, hw_area, planet.x, planet.y, @restrictions[:distance][:hw] / 2) if planet.is_hw?
      draw_circle_looped(img, brush[planet.kind], planet.x, planet.y, get_planet_radius(planet.size))
    end

    img
  end

  def zoomed(arg)
    arg * @zoom
  end

  def get_planet_radius(size)
    radius = size * @planet_radius
    return 0.5 if radius < 0.5
    radius
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
    # puts "x=#{x} y=#{y} r=#{radius}"
    drawing.circle(zoomed(x), zoomed(y), zoomed(x + radius), zoomed(y))
  end

  def generate_map
    puts "Generating map of size #{@size} with #{@planets_count} for #{@players_count} players..."

    create_players

    place_HWs_DWs

    puts "Planets left to place: #{@planets_to_place} out of #{@planets_count}"

    @planets_to_place.times { add_random_planet }

    puts "Done."
  end

  def create_players
    1.upto @players_count do |i|
      @players << Player.new
    end
  end

  def place_HWs_DWs
    @players.each do |player|
      x, y = get_coords_for_new :hw
      add_planet(x: x, y: y, kind: :hw, size: 1000, richness: 10, owner: player)
      puts "#{player} HW's x, y = #{x}, #{y}"
      2.times { place_DW(player, x, y) }
    end
  end

  def place_DW(player, x, y)
    range = @dw_to_hw_min + (SecureRandom.random_number * (@dw_to_hw_max - @dw_to_hw_min))
    angle = SecureRandom.random_number * 360
    dwx = (x + (range * Math.cos(angle))).round 2
    dwy = (y + (range * Math.sin(angle))).round 2
    add_planet(x: dwx, y: dwy, kind: :dw, size: 500, richness: 10, owner: player)
  end

  def add_planet(args)
    @planets << Planet.new(args)
    puts "New planet: #{args[:kind]} [#{args[:x]}, #{args[:y]}] #{args[:size]}"
    @planets_to_place -= 1
  end

  def add_random_planet
    dice = SecureRandom.random_number * 100
    chosen = @planets_probability.find { |r| r[0].cover? dice }[1]
    delta_size = chosen[:size].end - chosen[:size].begin
    size = (chosen[:size].begin + SecureRandom.random_number * delta_size).round 2
    delta_rich = chosen[:richness].end - chosen[:richness].begin
    richness = (chosen[:richness].begin + SecureRandom.random_number * delta_rich).round 2
    x, y = get_coords_for_new chosen[:kind]
    add_planet(x: x, y: y, kind: chosen[:kind], size: size, richness: richness)
  end

  def get_coords_for_new(kind)
    100.downto 0  do |try|
      x = (SecureRandom.random_number * @size).round 2
      y = (SecureRandom.random_number * @size).round 2
      return [x, y] if can_place_planet_at?(x, y, kind)
    end
    raise "Could not place planet"
  end

  def can_place_planet_at?(x, y, kind)
    return true unless [:hw, :big, :superbig].include? kind
    @planets.each do |planet|
      if planet.kind == :hw || planet.kind == kind
        return false if distance_between(planet.x, planet.y, x, y) <= @restrictions[:distance][kind]
      end
    end
    return true
  end

  def stats
    resp = "Players: #{@players.size}\n"
    planets_count = 0
    stat = {}
    @planets.each do |planet|
      next if planet.kind == :hw || planet.kind == :dw
      stat[planet.kind] = stat[planet.kind] ? stat[planet.kind] + 1 : 1
      planets_count +=1
    end
    resp << "Free planets total: #{planets_count}\n"
    resp << "Kind\t\tCount\tPercentage\n"
    stat.each do |kind, count|
      resp << "#{kind}\t\t#{count}\t#{(100 * count / planets_count).round(2)}\n"
    end
    resp
  end

end
