import sys
import json

from messagebird.balance import Balance
from messagebird.contact import Contact, ContactList
from messagebird.error import Error
from messagebird.group import Group, GroupList
from messagebird.hlr import HLR
from messagebird.message import Message
from messagebird.voicemessage import VoiceMessage
from messagebird.lookup import Lookup
from messagebird.verify import Verify
from messagebird.http_client import HttpClient
from messagebird.conversation_message import ConversationMessage, ConversationMessageList
from messagebird.conversation import Conversation, ConversationList
from messagebird.conversation_webhook import ConversationWebhook, ConversationWebhookList

ENDPOINT = 'https://rest.messagebird.com'
CLIENT_VERSION = '1.3.1'
PYTHON_VERSION = '%d.%d.%d' % (sys.version_info[0], sys.version_info[1], sys.version_info[2])
USER_AGENT = 'MessageBird/ApiClient/%s Python/%s' % (CLIENT_VERSION, PYTHON_VERSION)
REST_TYPE = 'rest'

CONVERSATION_API_ROOT = 'https://conversations.messagebird.com/v1/'
CONVERSATION_PATH = 'conversations'
CONVERSATION_MESSAGES_PATH = 'messages'
CONVERSATION_WEB_HOOKS_PATH = 'webhooks'
CONVERSATION_TYPE = 'conversation'


class ErrorException(Exception):
    def __init__(self, errors):
        self.errors = errors
        message = ' '.join([str(e) for e in self.errors])
        super(ErrorException, self).__init__(message)


class Client(object):
    def __init__(self, access_key, http_client=None):
        self.access_key = access_key
        self.http_client = http_client

    def _get_http_client(self, type=REST_TYPE):
        if self.http_client:
            return self.http_client

        if type == REST_TYPE:
            return HttpClient(ENDPOINT, self.access_key, USER_AGENT)

        return HttpClient(CONVERSATION_API_ROOT, self.access_key, USER_AGENT)

    def request(self, path, method='GET', params=None, type=REST_TYPE):
        """Builds a request, gets a response and decodes it."""
        response_text = self._get_http_client(type).request(path, method, params)

        if not response_text:
            return response_text

        response_json = json.loads(response_text)

        if 'errors' in response_json:
            raise (ErrorException([Error().load(e) for e in response_json['errors']]))

        return response_json

    def request_plain_text(self, path, method='GET', params=None, type=REST_TYPE):
        """Builds a request, gets a response and returns the body."""
        response_text = self._get_http_client(type).request(path, method, params)

        try:
            # Try to decode the response to JSON to see if the API returned any
            # errors.
            response_json = json.loads(response_text)

            if 'errors' in response_json:
                raise (ErrorException([Error().load(e) for e in response_json['errors']]))
        except ValueError:
            # Do nothing: json.loads throws if the input string is not valid JSON,
            # which is expected. We'll just return the response body below.
            pass

        return response_text

    def balance(self):
        """Retrieve your balance."""
        return Balance().load(self.request('balance'))

    def hlr(self, id):
        """Retrieve the information of a specific HLR lookup."""
        return HLR().load(self.request('hlr/' + str(id)))

    def hlr_create(self, msisdn, reference):
        """Perform a new HLR lookup."""
        return HLR().load(self.request('hlr', 'POST', {'msisdn': msisdn, 'reference': reference}))

    def message(self, id):
        """Retrieve the information of a specific message."""
        return Message().load(self.request('messages/' + str(id)))

    def message_create(self, originator, recipients, body, params=None):
        """Create a new message."""
        if params is None: params = {}
        if type(recipients) == list:
            recipients = ','.join(recipients)

        params.update({'originator': originator, 'body': body, 'recipients': recipients})
        return Message().load(self.request('messages', 'POST', params))

    def message_delete(self, id):
        """Delete a message from the dashboard."""
        self.request_plain_text('messages/' + str(id), 'DELETE')

    def voice_message(self, id):
        "Retrieve the information of a specific voice message."
        return VoiceMessage().load(self.request('voicemessages/' + str(id)))

    def voice_message_create(self, recipients, body, params=None):
        """Create a new voice message."""
        if params is None: params = {}
        if type(recipients) == list:
            recipients = ','.join(recipients)

        params.update({'recipients': recipients, 'body': body})
        return VoiceMessage().load(self.request('voicemessages', 'POST', params))

    def lookup(self, phonenumber, params=None):
        """Do a new lookup."""
        if params is None: params = {}
        return Lookup().load(self.request('lookup/' + str(phonenumber), 'GET', params))

    def lookup_hlr(self, phonenumber, params=None):
        """Retrieve the information of a specific HLR lookup."""
        if params is None: params = {}
        return HLR().load(self.request('lookup/' + str(phonenumber) + '/hlr', 'GET', params))

    def lookup_hlr_create(self, phonenumber, params=None):
        """Perform a new HLR lookup."""
        if params is None: params = {}
        return HLR().load(self.request('lookup/' + str(phonenumber) + '/hlr', 'POST', params))

    def verify(self, id):
        """Retrieve the information of a specific verification."""
        return Verify().load(self.request('verify/' + str(id)))

    def verify_create(self, recipient, params=None):
        """Create a new verification."""
        if params is None: params = {}
        params.update({'recipient': recipient})
        return Verify().load(self.request('verify', 'POST', params))

    def verify_verify(self, id, token):
        """Verify the token of a specific verification."""
        return Verify().load(self.request('verify/' + str(id), params={'token': token}))

    def contact(self, id):
        """Retrieve the information of a specific contact."""
        return Contact().load(self.request('contacts/' + str(id)))

    def contact_create(self, phonenumber, params=None):
        if params is None: params = {}
        params.update({'msisdn': phonenumber})
        return Contact().load(self.request('contacts', 'POST', params))

    def contact_delete(self, id):
        self.request_plain_text('contacts/' + str(id), 'DELETE')

    def contact_update(self, id, params=None):
        self.request_plain_text('contacts/' + str(id), 'PATCH', params)

    def contact_list(self, limit=10, offset=0):
        query = self._format_query(limit, offset)
        return ContactList().load(self.request('contacts?' + query, 'GET', None))

    def group(self, id):
        return Group().load(self.request('groups/' + str(id), 'GET', None))

    def group_create(self, name, params=None):
        if params is None: params = {}
        params.update({'name': name})
        return Group().load(self.request('groups', 'POST', params))

    def group_delete(self, id):
        self.request_plain_text('groups/' + str(id), 'DELETE', None)

    def group_list(self, limit=10, offset=0):
        query = self._format_query(limit, offset)
        return GroupList().load(self.request('groups?' + query, 'GET', None))

    def group_update(self, id, name, params=None):
        if params is None: params = {}
        params.update({'name': name})
        self.request_plain_text('groups/' + str(id), 'PATCH', params)

    def group_add_contacts(self, groupId, contactIds):
        query = self.__group_add_contacts_query(contactIds)
        self.request_plain_text('groups/' + str(groupId) + '?' + query, 'PUT', None)

    def __group_add_contacts_query(self, contactIds):
        # __group_add_contacts_query gets a query string to add contacts to a
        # group. The expected format is ids[]=first-contact&ids[]=second-contact.
        # See: https://developers.messagebird.com/docs/groups#add-contact-to-group.
        return '&'.join('ids[]=' + str(id) for id in contactIds)

    def group_remove_contact(self, groupId, contactId):
        self.request_plain_text('groups/' + str(groupId) + '/contacts/' + str(contactId), 'DELETE', None)

    def conversation_list(self, limit=10, offset=0):
        uri = CONVERSATION_PATH + '?' + self._format_query(limit, offset)
        return ConversationList().load(self.request(uri, 'GET', None, CONVERSATION_TYPE))

    def conversation_start(self, start_request):
        uri = CONVERSATION_PATH + '/start'
        return Conversation().load(self.request(uri, 'POST', start_request, CONVERSATION_TYPE))

    def conversation_update(self, id, update_request):
        uri = CONVERSATION_PATH + '/' + str(id)
        return Conversation().load(self.request(uri, 'PATCH', update_request, CONVERSATION_TYPE))

    def conversation_read(self, id):
        uri = CONVERSATION_PATH + '/' + str(id)
        return Conversation().load(self.request(uri, 'GET', None, CONVERSATION_TYPE))

    def conversation_list_messages(self, conversation_id, limit=10, offset=0):
        uri = CONVERSATION_PATH + '/' + str(conversation_id) + '/' + CONVERSATION_MESSAGES_PATH
        uri += '?' + self._format_query(limit, offset)

        return ConversationMessageList().load(self.request(uri, 'GET', None, CONVERSATION_TYPE))

    def conversation_create_message(self, conversation_id, message_create_request):
        uri = CONVERSATION_PATH + '/' + str(conversation_id) + '/' + CONVERSATION_MESSAGES_PATH
        return ConversationMessage().load(self.request(uri, 'POST', message_create_request, CONVERSATION_TYPE))

    def conversation_read_message(self, message_id):
        uri = CONVERSATION_MESSAGES_PATH + '/' + str(message_id)
        return ConversationMessage().load(self.request(uri, 'GET', None, CONVERSATION_TYPE))

    def conversation_create_webhook(self, webhook_create_request):
        return ConversationWebhook().load(
            self.request(CONVERSATION_WEB_HOOKS_PATH, 'POST', webhook_create_request, CONVERSATION_TYPE))

    def conversation_delete_webhook(self, id):
        uri = CONVERSATION_WEB_HOOKS_PATH + '/' + str(id)
        self.request(uri, 'DELETE', None, CONVERSATION_TYPE)

    def conversation_list_webhooks(self, limit=10, offset=0):
        uri = CONVERSATION_WEB_HOOKS_PATH + '?' + self._format_query(limit, offset)

        return ConversationWebhookList().load(self.request(uri, 'GET', None, CONVERSATION_TYPE))

    def conversation_read_webhook(self, id):
        uri = CONVERSATION_WEB_HOOKS_PATH + '/' + str(id)
        return ConversationWebhook().load(self.request(uri, 'GET', None, CONVERSATION_TYPE))

    def _format_query(self, limit, offset):
        return 'limit=' + str(limit) + '&offset=' + str(offset)
