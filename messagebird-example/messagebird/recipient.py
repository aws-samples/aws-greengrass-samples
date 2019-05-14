from messagebird.base import Base

class Recipient(Base):
  def __init__(self):
    self.recipient       = None
    self.status          = None
    self._statusDatetime = None

  @property
  def statusDatetime(self):
    return self._statusDatetime

  @statusDatetime.setter
  def statusDatetime(self, value):
    self._statusDatetime = self.value_to_time(value)
