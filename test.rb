#!/usr/bin/env ruby
require 'securerandom'
require './player.rb'
require './planet.rb'
require './map.rb'
require 'RMagick'


map = Map.new(
  non_overlapping_planets: true,
  harder_distance_restrictions: true)

puts map.stats

map.draw.write("map.png")
