require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "RubyDo" do
  it "should be able to start the main window" do
    $rdo = Ruby_do.new
    $rdo.show_win_main
  end
end
