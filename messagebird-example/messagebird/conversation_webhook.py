from messagebird.base import Base

CONVERSATION_WEBHOOK_EVENT_CONVERSATION_CREATED = 'conversation.created'
CONVERSATION_WEBHOOK_EVENT_CONVERSATION_UPDATED = 'conversation.updated'
CONVERSATION_WEBHOOK_EVENT_MESSAGE_CREATED = 'message.created'
CONVERSATION_WEBHOOK_EVENT_MESSAGE_UPDATED = 'message.updated'


class ConversationWebhook(Base):

    def __init__(self):
        self.id = None
        self.channelId = None
        self.url = None
        self.events = None
        self._createdDatetime = None
        self._updatedDatetime = None

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

    def __str__(self):
        return "\n".join([
            'id                : %s' % self.id,
            'events            : %s' % self.events,
            'channel id        : %s' % self.channelId,
            'created date time : %s' % self.createdDatetime,
            'updated date time : %s' % self.updatedDatetime
        ])


class ConversationWebhookList(Base):
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
        items = []
        if isinstance(value, list):
            for item in value:
                items.append(ConversationWebhook().load(item))

        self._items = items

    def __str__(self):
        item_ids = []
        for item in self._items:
            item_ids.append(item.id)

        return "\n".join([
            'items IDs  : %s' % item_ids,
            'offset     : %s' % self.offset,
            'limit      : %s' % self.limit,
            'count      : %s' % self.count,
            'totalCount : %s' % self.totalCount,
        ])
