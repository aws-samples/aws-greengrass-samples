from messagebird.base import Base

class HLR(Base):
  def __init__(self):
    self.id               = None
    self.href             = None
    self.msisdn           = None
    self.network          = None
    self.reference        = None
    self.status           = None
    self.details          = None
    self._createdDatetime = None
    self._statusDatetime  = None

  @property
  def createdDatetime(self):
    return self._createdDatetime

  @createdDatetime.setter
  def createdDatetime(self, value):
    self._createdDatetime = self.value_to_time(value)

  @property
  def statusDatetime(self):
    return self._statusDatetime

  @statusDatetime.setter
  def statusDatetime(self, value):
    self._statusDatetime = self.value_to_time(value)
