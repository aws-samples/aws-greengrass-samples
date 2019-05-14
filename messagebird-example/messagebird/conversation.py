from messagebird.base import Base
from messagebird.conversation_contact import ConversationContact
from messagebird.conversation_channel import Channel
from messagebird.conversation_message import ConversationMessageReference

CONVERSATION_STATUS_ACTIVE = "active"
CONVERSATION_STATUS_ARCHIVED = "archived"


class Conversation(Base):

    def __init__(self):
        self.id = None
        self.contactId = None
        self._contact = None
        self.lastUsedChannelId = None
        self._channels = None
        self._messages = None
        self.status = None
        self._createdDatetime = None
        self._updatedDatetime = None
        self._lastReceivedDatetime = None

    @property
    def contact(self):
        return self._contact

    @contact.setter
    def contact(self, value):
        self._contact = ConversationContact().load(value)

    @property
    def messages(self):
        return self._messages

    @messages.setter
    def messages(self, value):
        self._messages = ConversationMessageReference().load(value)

    @property
    def channels(self):
        return self._channels

    @channels.setter
    def channels(self, value):
        if isinstance(value, list):
            self._channels = []
            for channelData in value:
                self._channels.append(Channel().load(channelData))
        else:
            self._channels = value

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

    @property
    def lastReceivedDatetime(self):
        return self._lastReceivedDatetime

    @lastReceivedDatetime.setter
    def lastReceivedDatetime(self, value):
        self._lastReceivedDatetime = self.value_to_time(value, '%Y-%m-%dT%H:%M:%SZ')

    def __str__(self):
        return "\n".join([
            'id                   : %s' % self.id,
            'contact id           : %s' % self.contactId,
            'last used channel id : %s' % self.lastUsedChannelId,
            'message total count  : %s' % self.messages.totalCount,
            'status               : %s' % self.status,
            'created date time    : %s' % self.createdDatetime,
            'updated date time    : %s' % self.updatedDatetime,
            'last received date   : %s' % self.lastReceivedDatetime,
        ])


class ConversationList(Base):
    def __init__(self):
        self.offset = None
        self.limit = None
        self.count = None
        self.totalCount = None
        self._items = None

    @property
    def items(self):
        return self._items

    @items.setter
    def items(self, value):
        if isinstance(value, list):
            self._items = []
            for item in value:
                self._items.append(Conversation().load(item))

    def __str__(self):
        item_ids = []
        for msg_item in self._items:
            item_ids.append(msg_item.id)

        return "\n".join([
            'items IDs  : %s' % item_ids,
            'offset     : %s' % self.offset,
            'limit      : %s' % self.limit,
            'count      : %s' % self.count,
            'totalCount : %s' % self.totalCount,
        ])
