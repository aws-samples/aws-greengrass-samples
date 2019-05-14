from messagebird.base    import Base
from messagebird.formats import Formats
from messagebird.hlr     import HLR

class Lookup(Base):
  def __init__(self):
    self.href             = None
    self.countryCode      = None
    self.countryPrefix    = None
    self.phoneNumber      = None
    self.type             = None
    self._formats         = None
    self._hlr             = None

  def __str__(self):
    return str(self.__class__) + ": " + str(self.__dict__)

  @property
  def formats(self):
    return self._formats

  @formats.setter
  def formats(self, value):
    self._formats = Formats().load(value)

  @property
  def hlr(self):
    return self._hlr

  @hlr.setter
  def hlr(self, value):
    self._hlr = HLR().load(value)
