from messagebird.base import Base
from messagebird.contact import CustomDetails


class ConversationContact(Base):

    def __init__(self):
        self.id = None
        self.href = None
        self.msisdn = None
        self.firstName = None
        self.lastName = None
        self._customDetails = None
        self._createdDatetime = None
        self._updatedDatetime = None

    @property
    def customDetails(self):
        return self._customDetails

    @customDetails.setter
    def customDetails(self, value):
        self._customDetails = CustomDetails().load(value)

    @property
    def createdDatetime(self):
        return self._createdDatetime

    @createdDatetime.setter
    def createdDatetime(self, value):
        self._createdDatetime = self.value_to_time(value, '%Y-%m-%dT%H:%M:%SZ')

    @property
    def updatedDatetime(self):
        return self._updatedDatetime

    @updatedDatetime.setter
    def updatedDatetime(self, value):
        self._updatedDatetime = self.value_to_time(value, '%Y-%m-%dT%H:%M:%SZ')
