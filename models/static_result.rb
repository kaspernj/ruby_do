class Ruby_do::Models::Static_result < Knj::Datarow
  has_one [
    {:class => :Plugin, :required => true}
  ]
  
  def data
    return Marshal.load(self[:data])
  end
end