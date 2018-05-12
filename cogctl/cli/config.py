import copy
import os
from configobj import ConfigObj
from collections import OrderedDict


class CogctlConfig():

    def __init__(self, filename):
        self.filename = filename
        if os.path.isfile(filename):
            # If the file exists it should be valid, so just try to
            # get the default profile name and the default profile
            self._config = ConfigObj(filename)
            self.default()
        else:
            self._config = ConfigObj()

    def profile(self, profile):
        """
        Raises KeyError if no such profile exists
        """

        # Without copying, we're modifying the in-memory
        # representation of the config file
        p = copy.deepcopy(self._config[profile])
        return CogctlConfig._normalize_entry(p)

    def default_profile_name(self):
        return self._config['defaults']['profile']

    def default(self):
        return self.profile(self.default_profile_name())

    def add(self, profile_name, profile):
        # NOTE: Doesn't do any kind of normalization or converting
        # back to our legacy format... absent any other work, this
        # will result in a mixture of old and new formats for each
        # entry.

        if 'defaults' not in self._config:
            self._config['defaults'] = {'profile': profile_name}

        # Controlling the ordering of keys in the new profile makes
        # for deterministic testing when we write out new entries.
        ordered = OrderedDict()
        for k in sorted(profile.keys()):
            ordered[k] = profile[k]

        self._config[profile_name] = ordered

    def set_default(self, profile_name):
        """ Update the default profile. Raise KeyError if no such profile exists
        """
        if profile_name not in self.profiles():
            raise KeyError("Profile does not exist")

        self._config['defaults']['profile'] = profile_name

    def write(self):
        # We manage the writing ourselves, because the object may have
        # been initialized with a file that does not exist. Using
        # ConfigObj's create_empty=True keyword makes things
        # complicated because it creates the empty file at object
        # creation time, not write time, which means we could be
        # creating empty (and thus invalid) configuration files.
        with open(self.filename, "wb") as f:
            self._config.write(f)

    def profiles(self):
        """ Return a sorted list of profiles present."""
        return sorted([p for p in self._config.keys()
                       if p != "defaults"])

    def update_profile(self, profile_name):
        """Updates an old secure/host/port profile to a modern url-based one.

        """
        p = self.profile(profile_name)

        ordered = OrderedDict()
        for k in sorted(p.keys()):
            ordered[k] = p[k]

        self._config[profile_name] = ordered

    @staticmethod
    def _normalize_entry(entry):
        """Consolidates url information into a single value.

        Our old (Elixir implementation) INI-based configuration
        sections split up the Cog API root URL information across
        three different options:

        * "secure": a Boolean indicating whether or not to use HTTPS
        * "host"
        * "port"

        Here, we consolidate all these values into a single "url" value,
        place it into the entry, and remove the now-unneeded options that
        comprise it.

        """
        if entry.get("url"):
            # Consider it already normalized
            return entry

        if entry.pop("secure") == "true":
            protocol = "https"
        else:
            protocol = "http"

        host = entry.pop("host")
        port = entry.pop("port")
        entry["url"] = "%s://%s:%s" % (protocol, host, port)
        return entry
