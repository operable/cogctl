from collections import OrderedDict
from configparser import ConfigParser


def read_config(file):
    return ini_file_to_map(file)


def add_profile(file, profile_name, profile):
    # Use OrderedDict just to ensure that the individual entries (in
    # an INI file, at any rate) are always written out
    # deterministically. If nothing else, this makes testing a bit
    # easier.
    new_profile = OrderedDict([
        ("host", profile.pop("host")),
        ("port", profile.pop("port")),
        ("secure", profile.pop("secure")),
        ("user", profile.pop("user")),
        ("password", profile.pop("password"))])

    return add_ini_section(file, profile_name, new_profile)

########################################################################


def read_file(ini):
    config = ConfigParser(comment_prefixes=("#"),
                          interpolation=None)
    config.read(ini)
    return config  # TODO: return type here (ini or netrc)


def ini_file_to_map(ini):
    """Convert an INI-formatted file into a plain dict"""

    config = read_file(ini)

    data = {}
    default = None

    for section in config.sections():
        if section == "defaults":
            default = config[section]["profile"]
        else:
            section_data = {"default": False}
            for key in config[section]:
                section_data[key] = config[section][key]

            data[section] = normalize_entry(section_data)

    data[default]["default"] = True
    return data


def normalize_entry(entry):
    """Consolidates url information into a single value.

    Our INI-based configuration sections split up the Cog API root URL
    information across three different options:

    * "secure": a Boolean indicating whether or not to use HTTPS
    * "host"
    * "port"

    Here, we consolidate all these values into a single "url" value,
    place it into the entry, and remove the now-unneeded options that
    comprise it.
    """
    if entry.pop("secure") == "true":
        protocol = "https"
    else:
        protocol = "http"

    host = entry.pop("host")
    port = entry.pop("port")
    entry["url"] = "%s://%s:%s" % (protocol, host, port)
    return entry


def add_ini_section(file, section, options):
    config = read_file(file)

    # TODO: Do this here!

    # add options to the section in a predictable order to aid testing
    # for k in sorted(options.keys()):
    #     config[section][k] = options[k]
    if (not config.has_section('defaults')):
        config['defaults'] = {'profile': section}

    config[section] = options

    # UGH
    #
    # configparser spits out booleans as "True" and "False", which
    # could cause issues with any other software that's reading the
    # config file as well (mainly the Elixir version of cogctl,
    # really).
    #
    # In the absence of any clear way to manage this output, we'll
    # resort to this ugly hack :|
    for section in config.sections():
        if "secure" in config[section]:
            secure = config[section]["secure"]
            config[section]["secure"] = secure.lower()

    with open(file, 'w') as configfile:
        config.write(configfile)
