from messagebird.base import Base

class Formats(Base):
  def __init__(self):
    self.e164             = None
    self.international    = None
    self.national         = None
    self.rfc3966          = None
