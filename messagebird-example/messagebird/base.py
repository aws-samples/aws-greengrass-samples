from datetime import datetime

class Base(object):
  def load(self, data):
    for name, value in list(data.items()):
      if hasattr(self, name):
        setattr(self, name, value)

    return self

  def strip_nanoseconds_from_date(self, value):
    if str(value).find(".") != -1:
      return value[:-11] + value[-1:]

    return value

  def value_to_time(self, value, format='%Y-%m-%dT%H:%M:%S+00:00'):
    if value != None:
      value = self.strip_nanoseconds_from_date(value)
      return datetime.strptime(value, format)
