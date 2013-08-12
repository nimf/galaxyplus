class Planet
  attr_accessor :x, :y, :size, :richness, :owner, :is_hw

  def initialize(args)
    [:x, :y, :size, :richness, :owner, :is_hw].each do |parameter|
      send("#{parameter}=", args[parameter]) if args[parameter]
    end
  end

  def is_hw?
    is_hw
  end
end
