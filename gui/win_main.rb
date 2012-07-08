class Ruby_do::Gui::Win_main
  def initialize(args)
    @args = args
    
    @gui = Gtk::Builder.new.add("#{File.dirname(__FILE__)}/../glade/win_main.glade")
    Knj::Gtk2.translate(@gui)
  end
  
  def show
    @gui["window"].show_all
    @gui["txtSearch"].grab_focus
  end
end