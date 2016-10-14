#! /usr/bin/ruby
# -*- coding: utf-8 -*-

require 'rubygems'
require 'gruff'

TARGET_DIR = ARGV[0]
FILE_SELECTOR = File.join(TARGET_DIR, '????-??-??-????')

g = Gruff::Line.new
g.font = Magick.fonts.first.name

graph_data = Hash.new{ |h, k| h[k] = {} } # { class => { time => count } }
times = []
klass_appear = Hash.new{ |h, k| h[k] = 0 }

Dir.glob(FILE_SELECTOR) { |file|
  m = %r<(?<version>[^/]+)\-\d+/(?<year>\d{4})-(?<month>\d{2})-(?<day>\d{2})-(?<hour>\d{2})(?<minute>\d{2})\Z>.match(file)
  g.title ||= "mikutter #{m[:version]}"
  time = [m[:day], m[:hour], m[:minute]]
  times << time
  File.open(file){ |io| Marshal.load(io) }.each { |pair|
    klass, count = pair
    #next if klass != :"Gtk::ListStore"
    klass_appear[klass] += count
    graph_data[klass][time] = count } }

times = times.sort.freeze

klass_appear.sort_by{ |k, v| v }.reverse[0..10].each{ |klass, count|
  g.data(klass.to_s, times.map{ |time| graph_data[klass][time] || 0 }) }

# klass = 'Gdk::MiraclePainter'.to_sym
# count = klass_appear[klass]
# g.data(klass.to_s, times.map{ |time| graph_data[klass][time] || 0 })

label_count = 5
while(label_count < 10 and (times.size % label_count) == 0)
  label_count += 1
end

labels = {}
prev = [nil]
label_count.times{ |count|
  pos = times.size / label_count * count
  ftime = times[pos]
  labels[pos.to_i] = ftime.zip(prev).drop_while{ |i| i.first == i.last }.map{ |i| i.first }.join(':')
  prev = ftime
}

pos = times.size - 1
ftime = times[pos]
labels[pos.to_i] = ftime.zip(prev).drop_while{ |i| i.first == i.last }.map{ |i| i.first }.join(':')

p labels
g.labels = labels

g.write('mikutter-memory.png')
