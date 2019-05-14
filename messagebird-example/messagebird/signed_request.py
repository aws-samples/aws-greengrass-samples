import hashlib
import hmac
import base64
import time
from collections import OrderedDict

try:
    from urllib.parse import urlencode
except ImportError:
    from urllib import urlencode


class SignedRequest:

    def __init__(self, requestSignature, requestTimestamp, requestBody, requestParameters):
        self._requestSignature = requestSignature
        self._requestTimestamp = str(requestTimestamp)
        self._requestBody = requestBody
        self._requestParameters = requestParameters

    def verify(self, signing_key):
        payload = self._build_payload()
        expected_signature = base64.b64decode(self._requestSignature)
        calculated_signature = hmac.new(signing_key.encode('latin-1'), payload.encode('latin-1'),
                                        hashlib.sha256).digest()
        return expected_signature == calculated_signature

    def is_recent(self, offset=10):
        return int(time.time()) - int(self._requestTimestamp) < offset

    def _build_payload(self):
        checksum_body = hashlib.sha256(self._requestBody.encode('latin-1')).digest()
        str_checksum_body = checksum_body.decode('latin-1')
        parts = [self._requestTimestamp, urlencode(self._sort_dict(self._requestParameters), True), str_checksum_body]
        return "\n".join(parts)

    def _sort_dict(self, dict):
        sorted_dict = OrderedDict()

        for key in sorted(dict):
            sorted_dict[key] = dict[key]

        return sorted_dict
