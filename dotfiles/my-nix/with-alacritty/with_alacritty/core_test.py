from unittest import TestCase
from .core import _update_json as update_json
from .core import _DEL_VALUE as DEL_VALUE


class UpdateJsonTest(TestCase):
    def test_creates_keys(self):
        assert update_json({}, "foo.bar", 42) == {"foo": {"bar": 42}}

    def test_clobbers_keys(self):
        assert update_json({"foo": 41}, "foo", 42) == {"foo": 42}

    def test_clobber_entire_thing(self):
        assert update_json({"foo": 41}, ".", 42) == 42

    def test_inconsistent_types(self):
        assert update_json({"font": 41}, "font.size", 42) == {"font": {"size": 42}}

    def test_delete(self):
        assert update_json({"font": {"size": 42}}, "font", DEL_VALUE) == {}
        assert update_json({"font": {"size": 42}}, "font.size", DEL_VALUE) == {
            "font": {}
        }

    def test_delete_entire_thing(self):
        assert update_json({"font": {"size": 42}}, ".", DEL_VALUE) == {}
