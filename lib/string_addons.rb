class String
  def as_utf8
    self.force_encoding('UTF-8')
  end
end
