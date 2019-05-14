from messagebird.base import Base

class Balance(Base):
  def __init__(self):
    self.amount  = None
    self.type    = None
    self.payment = None
