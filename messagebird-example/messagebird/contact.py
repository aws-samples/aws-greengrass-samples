from messagebird.base import Base
from messagebird.base_list import BaseList


class CustomDetails(Base):

    def __init__(self):
        self.custom1 = None
        self.custom2 = None
        self.custom3 = None
        self.custom4 = None


class GroupReference(Base):

    def __init__(self):
        self.href = None
        self.totalCount = None


class MessageReference(Base):

    def __init__(self):
        self.href = None
        self.totalCount = None


class ContactList(BaseList):

    def __init__(self):
        # Signal the BaseList that we're expecting items of type Contact...
        super(ContactList, self).__init__(Contact)


class Contact(Base):

    def __init__(self):
        self.id = None
        self.href = None
        self.msisdn = None
        self.firstName = None
        self.lastName = None
        self._customDetails = None
        self._groups = None
        self._messages = None
        self._createdDatetime = None
        self._updatedDatetime = None

    @property
    def customDetails(self):
        return self._customDetails

    @customDetails.setter
    def customDetails(self, value):
        self._customDetails = CustomDetails().load(value)

    @property
    def groups(self):
        return self._groups

    @groups.setter
    def groups(self, value):
        self._groups = GroupReference().load(value)

    @property
    def messages(self):
        return self._messages

    @messages.setter
    def messages(self, value):
        self._messages = MessageReference().load(value)

    @property
    def createdDatetime(self):
        return self._createdDatetime

    @createdDatetime.setter
    def createdDatetime(self, value):
        self._createdDatetime = self.value_to_time(value)

    @property
    def updatedDatetime(self):
        return self._updatedDatetime

    @updatedDatetime.setter
    def updatedDatetime(self, value):
        self._updatedDatetime = self.value_to_time(value)
