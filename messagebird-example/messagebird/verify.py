from messagebird.base import Base

class Verify(Base):
  def __init__(self):
    self.id                  = None
    self.href                = None
    self.recipient           = None
    self.reference           = None
    self.messages            = None
    self.status              = None
    self._createdDatetime    = None
    self._validUntilDatetime = None


  @property
  def createdDatetime(self):
    return self._createdDatetime

  @createdDatetime.setter
  def createdDatetime(self, value):
    self._createdDatetime = self.value_to_time(value)


  @property
  def validUntilDatetime(self):
    return self._validUntilDatetime

  @validUntilDatetime.setter
  def validUntilDatetime(self, value):
    self._validUntilDatetime = self.value_to_time(value)
