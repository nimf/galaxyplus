#! /usr/bin/env ruby
require 'securerandom'
require './player.rb'
require './planet.rb'
require './map.rb'
require 'RMagick'


map = Map.new

map.draw(4).write("map.png")
