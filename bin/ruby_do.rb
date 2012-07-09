#!/usr/bin/env ruby

require "rubygems"
require "knjrbfw"

args = {
  :path => "#{Knj::Os.homedir}/.ruby_do",
  :sock_path => "#{Knj::Os.homedir}/.ruby_do/sock"
}

ARGV.each do |arg|
  if match = arg.match(/^--rdo-(.+?)=(.+)$/)
    args[match[1].to_sym] = match[2]
  end
end

if args[:cmd]
  require "socket"
  UNIXSocket.open(args[:sock_path]) do |sock|
    puts sock.puts(args[:cmd])
  end
  exit
end

def _(str)
  return GetText._(str)
end

require "#{File.realpath(File.dirname(__FILE__))}/../lib/ruby_do.rb"
rdo = Ruby_do.new
rdo.show_win_main
rdo.join