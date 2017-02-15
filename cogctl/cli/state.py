import cogctl.api


class State:
    def __init__(self):
        self.configuration = {}
        self.verbosity = 0
        self.profile = None
        self.config_file = None
        self._api = None

    @property
    def api(self):
        if self._api is None:
            self._api = cogctl.api.from_profile(self.profile)

        return self._api
