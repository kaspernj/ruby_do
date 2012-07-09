#This class contains all the GUI-subclasses (windows, tray-icon and such).
class Ruby_do::Gui
  #Autoloader for Gui-subclasses.
  def self.const_missing(name)
    require "#{File.dirname(__FILE__)}/../gui/#{name.to_s.downcase}.rb"
    return self.const_get(name)
  end
end