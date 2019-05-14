import json
import requests

try:
    from urllib.parse import urljoin
except ImportError:
    from urlparse import urljoin


class HttpClient(object):
    """Used for sending simple HTTP requests."""

    def __init__(self, endpoint, access_key, user_agent):
        self.__supported_status_codes = [200, 201, 204, 401, 404, 405, 422]

        self.endpoint = endpoint
        self.access_key = access_key
        self.user_agent = user_agent

    def request(self, path, method='GET', params=None):
        """Builds a request and gets a response."""
        if params is None: params = {}
        url = urljoin(self.endpoint, path)

        headers = {
            'Accept': 'application/json',
            'Authorization': 'AccessKey ' + self.access_key,
            'User-Agent': self.user_agent,
            'Content-Type': 'application/json'
        }

        if method == 'DELETE':
            response = requests.delete(url, verify=True, headers=headers, data=json.dumps(params))
        elif method == 'GET':
            response = requests.get(url, verify=True, headers=headers, params=params)
        elif method == 'PATCH':
            response = requests.patch(url, verify=True, headers=headers, data=json.dumps(params))
        elif method == 'POST':
            response = requests.post(url, verify=True, headers=headers, data=json.dumps(params))
        elif method == 'PUT':
            response = requests.put(url, verify=True, headers=headers, data=json.dumps(params))
        else:
            raise ValueError(str(method) + ' is not a supported HTTP method')

        if response.status_code in self.__supported_status_codes:
            response_text = response.text
        else:
            response.raise_for_status()

        return response_text
