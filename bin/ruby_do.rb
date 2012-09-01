#!/usr/bin/env ruby

require "rubygems"


#Enable local dev-mode.
gems = ["knjrbfw"]
gems.each do |gem|
  fpath = "#{File.realpath("#{File.dirname(__FILE__)}/../..")}/#{gem}/lib/#{gem}.rb"
  
  if File.exists?(fpath)
    print "Require gem from custom path: '#{fpath}'.\n"
    require fpath
  else
    print "Require gem: '#{gem}'.\n"
    require gem
  end
end


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
rdo.join