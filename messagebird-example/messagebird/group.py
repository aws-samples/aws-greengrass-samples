from messagebird.base import Base
from messagebird.base_list import BaseList


class ContactReference(Base):

    def __init__(self):
        self.href = None
        self.totalCount = None


class GroupList(BaseList):

    def __init__(self):
        # Signal the BaseList that we're expecting items of type Group...
        super(GroupList, self).__init__(Group)


class Group(Base):

    def __init__(self):
        self.id = None
        self.href = None
        self.name = None
        self._contacts = None
        self.createdDatetime = None
        self.updatedDatetime = None

    @property
    def contacts(self):
        return self._contacts

    @contacts.setter
    def contacts(self, value):
        self._contacts = ContactReference().load(value)

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
