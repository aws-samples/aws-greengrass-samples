from messagebird.base      import Base
from messagebird.recipient import Recipient

class Message(Base):
  def __init__(self):
    self.id                 = None
    self.href               = None
    self.direction          = None
    self.type               = None
    self.originator         = None
    self.body               = None
    self.reference          = None
    self.validity           = None
    self.gateway            = None
    self.typeDetails        = None
    self.datacoding         = None
    self.mclass             = None
    self._scheduledDatetime = None
    self._createdDatetime   = None
    self._recipients        = None

  @property
  def scheduledDatetime(self):
    return self._scheduledDatetime

  @scheduledDatetime.setter
  def scheduledDatetime(self, value):
    self._scheduledDatetime = self.value_to_time(value)

  @property
  def createdDatetime(self):
    return self._createdDatetime

  @createdDatetime.setter
  def createdDatetime(self, value):
    self._createdDatetime = self.value_to_time(value)

  @property
  def recipients(self):
    return self._recipients

  @recipients.setter
  def recipients(self, value):
    value['items'] = [Recipient().load(r) for r in value['items']]
    self._recipients = value
