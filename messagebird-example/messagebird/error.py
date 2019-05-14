from messagebird.base import Base

class Error(Base):
  def __init__(self):
    self.code        = None
    self.description = None
    self.parameter   = None

  def __str__(self):
    return str(dict(code=self.code, description=self.description, parameter=self.parameter))
