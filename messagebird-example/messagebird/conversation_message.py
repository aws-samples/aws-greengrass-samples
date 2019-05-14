from messagebird.base import Base

MESSAGE_TYPE_AUDIO = "audio"
MESSAGE_TYPE_FILE = "file"
MESSAGE_TYPE_HSM = "hsm"
MESSAGE_TYPE_IMAGE = "image"
MESSAGE_TYPE_LOCATION = "location"
MESSAGE_TYPE_TEXT = "text"
MESSAGE_TYPE_VIDEO = "video"


class ConversationMessage(Base):

    def __init__(self):
        self.id = None
        self.conversationId = None
        self.channelId = None
        self.direction = None
        self.status = None
        self.type = None
        self.content = None
        self._createdDatetime = None
        self._updatedDatetime = None

    @property
    def createdDatetime(self):
        return self._createdDatetime

    @createdDatetime.setter
    def createdDatetime(self, value):
        if value is not None:
            self._createdDatetime = self.value_to_time(value, '%Y-%m-%dT%H:%M:%SZ')

    @property
    def updatedDatetime(self):
        return self._updatedDatetime

    @updatedDatetime.setter
    def updatedDatetime(self, value):
        if value is not None:
            self._updatedDatetime = self.value_to_time(value, '%Y-%m-%dT%H:%M:%SZ')

    def __str__(self):
        return "\n".join([
            'message id        : %s' % self.id,
            'channel id        : %s' % self.channelId,
            'direction         : %s' % self.direction,
            'status            : %s' % self.status,
            'type              : %s' % self.type,
            'content           : %s' % self.content,
            'created date time : %s' % self._createdDatetime,
            'updated date time : %s' % self._updatedDatetime
        ])


class ConversationMessageReference(Base):
    def __init__(self):
        self.totalCount = None
        self.href = None


class ConversationMessageList(Base):

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
                items.append(ConversationMessage().load(item))

        self._items = items

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
