import re
from cogctl.cli.version import version


def test_version(cogctl):
    result = cogctl(version)

    assert result.exit_code == 0
    expr = re.compile('^cogctl ([a-z0-9\-/])+ \(build: (([a-f0-9]){7}|unknown)\)')
    output = result.output.strip()
    assert re.fullmatch(expr, output) is not None
