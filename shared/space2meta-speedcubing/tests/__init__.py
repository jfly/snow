import pytest

# Needed to get pretty assertions in our test helper code.
# See https://docs.pytest.org/en/stable/how-to/writing_plugins.html#assertion-rewriting
pytest.register_assert_rewrite("tests.testing")
