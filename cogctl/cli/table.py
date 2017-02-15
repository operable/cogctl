from terminaltables import AsciiTable


def render(table_data):
    """
    Render the given data as an ASCII table. Table data
    is provided as a list-of-lists. Column names are provided as a
    list of strings.

    Returns the string.
    """

    table = AsciiTable(table_data)
    table.inner_column_border = False
    table.outer_border = False
    table.inner_heading_row_border = False
    table.padding_left = 0
    table.padding_right = 2
    output = table.table
    return "\n".join([line.strip() for line in output.split("\n")])


def render_dict(d, headers=None):
    """
    Render a single dict as an ASCII table with each dict key
    uppercased and listed one per column.
    """

    if headers is None:
        headers = sorted(list(d.keys()))

    rows = [[titleize(key.replace("_", " ")), d[key]] for key in headers]
    return render(rows)


def render_dicts(dicts, headers=None):
    """
    Render data as an ASCII table with headers automatically
    generated from upcased keys.
    """

    if headers is None:
        headers = sorted(list(dicts[0].keys()))

    rows = [[item[key] for key in headers] for item in dicts]
    headers = [header.upper().replace("_", " ") for header in headers]
    return render([headers] + rows)


def titleize(string):
    return " ".join([capitalize(word) for word in string.split()])


def capitalize(word):
    if word == "id":
        return "ID"
    else:
        return word.capitalize()
