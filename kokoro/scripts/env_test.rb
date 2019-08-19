#!/usr/bin/env ruby

require 'fileutils'
require 'pathname'
require 'tmpdir'

current_dir = FileUtils.pwd()
puts("--- current_dir: #{current_dir}\n")

realpath = Pathname.new("./").realpath
puts("--- Pathname.new(\"./\").realpath: #{realpath}\n")

temp_dir = Pathname(Dir.mktmpdir(['CocoaPods-Lint-', "-TestTempDir"]))
puts("--- temp_dir: #{temp_dir}\n")

temp_realpath = Pathname.new(temp_dir).realpath
puts("--- Pathname.new(temp_dir).realpath: #{temp_realpath}\n")

puts("--- File.directory?(x): #{File.directory?(temp_realpath)}\n")