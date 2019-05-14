from messagebird.base import Base


class Links(Base):

    def __init__(self):
        self.first = None
        self.previous = None
        self.next = None
        self.last = None


class BaseList(Base):

    def __init__(self, item_type):
        """When setting items, they are instantiated as objects of type item_type."""
        self.limit = None
        self.offset = None
        self.count = None
        self.totalCount = None
        self._links = None
        self._items = None

        self.itemType = item_type

    @property
    def links(self):
        return self._links

    @links.setter
    def links(self, value):
        self._links = Links().load(value)

    @property
    def items(self):
        return self._items

    @items.setter
    def items(self, value):
        """Create typed objects from the dicts."""
        items = []
        for item in value:
            items.append(self.itemType().load(item))

        self._items = items
