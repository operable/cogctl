import click


def raise_if_not_all_present(targets, items, base_message, key="name"):
    # targets = e.g. a list of names
    #
    # items = a list of API objects retrieved, based on those targets
    #
    # key = the key in the object that should match a target
    #
    # base_message = an exception message, containing a single "{}"
    # formatting marker; the list of targets that are not found in items
    # are added at that point.
    #
    # Use this when you take a list of names and need to ensure that
    # they all identify things that exist.
    #

    targets = set(targets)
    found = {i[key] for i in items}

    if found != targets:
        missing = targets.difference(found)
        message = base_message.format(", ".join(sorted(missing)))
        raise click.BadParameter(message)


def compact_dict(d):
    return {k: v for k, v in d.items() if k and v}
