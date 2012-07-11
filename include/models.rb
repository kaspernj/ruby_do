class Ruby_do::Models
  def self.const_missing(name)
    require "#{File.dirname(__FILE__)}/../models/#{name.to_s.downcase}.rb"
    return const_get(name)
  end
end