from messagebird.base import Base


class Channel(Base):
    def __init__(self):
        self.id = None
        self.name = None
        self.platformId = None
        self.status = None
        self._createdDateTime = None
        self._updatedDateTime = None

    @property
    def createdDateTime(self):
        return self._createdDateTime

    @createdDateTime.setter
    def createdDateTime(self, value):
        self._createdDateTime = self.value_to_time(value)

    @property
    def updatedDateTime(self):
        return self._updatedDateTime

    @updatedDateTime.setter
    def updatedDateTime(self, value):
        self._updatedDateTime = self.value_to_time(value)
