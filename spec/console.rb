#!/usr/bin/env ruby

require 'pry'

lib_dir = File.join File.dirname(__FILE__), '../lib'
lib_dir = File.absolute_path File.expand_path lib_dir
$LOAD_PATH << lib_dir

require 'task'

Task.pry
