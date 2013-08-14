class Planet
  attr_accessor :x, :y, :kind, :size, :richness, :owner

  def initialize(args)
    [:x, :y, :kind, :size, :richness, :owner].each do |parameter|
      send("#{parameter}=", args[parameter]) if args[parameter]
    end
  end

  def is_hw?
    kind == :hw
  end
end
