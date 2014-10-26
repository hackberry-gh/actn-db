require 'oj'
require 'uri'

class ::String
  def to_json
    self
  end
  def as_json
    Oj.load(self)
  end
  def to_domain
    return self unless self.start_with?("http")
    # self.match(/[http|http]:\/\/(\w*:\d*|\w*)\/?/)[1] rescue nil
    URI(self).host
  end
end