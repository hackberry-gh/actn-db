require 'oj'

class ::Hash
  def to_json
    Oj.dump(self)
  end
  def as_json
    self
  end
end