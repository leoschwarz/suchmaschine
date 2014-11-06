#!/usr/bin/env ruby
require 'benchmark'
require 'rubygems'
require 'bundler'
Bundler.require(:default)

LIBRARIES = [:oj, :yajl, :json, :msgpack].freeze
DATA_JSON    = Dir[File.join(File.dirname(__FILE__), "files", "*")].map{|f| File.read(f)}.freeze
DATA_OBJECTS = DATA_JSON.map{|json| Oj.load(json)}.freeze

N = 100_000

def serialize(name, object)
  case name
  when :oj
    Oj.dump(object)
  when :yajl
    Yajl::Encoder.encode(object)
  when :json
    JSON.dump(object)
  when :msgpack
    object.to_msgpack
  end
end

def deserialize(name, string)
  case name
  when :oj
    Oj.load(string)
  when :yajl
    Yajl::Parser.parse(string)
  when :json
    JSON.load(string)
  when :msgpack
    #MessagePack.unpack(string)
  end
end

Benchmark.bmbm do |benchmark|
  LIBRARIES.each do |library|
    benchmark.report("#{library.to_s.ljust(8)} [schreiben]"){ N.times{ serialize(library, DATA_OBJECTS.sample) } }
    benchmark.report("#{library.to_s.ljust(8)} [lesen]    "){ N.times{ deserialize(library, DATA_JSON.sample) } }
  end
end

