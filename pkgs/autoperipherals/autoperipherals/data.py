import xdg.BaseDirectory
import json
from pydantic import BaseModel
from pathlib import Path
from .xrandr import Rotation


def data_dir(file: str) -> Path:
    data_dir = xdg.BaseDirectory.save_data_path("autoperipherals")
    return Path(data_dir) / file


class State(BaseModel):
    version: str = "1.0"
    rotation_by_edid_hex: dict[str | int, Rotation] = {}

    @staticmethod
    def _statefile() -> Path:
        return data_dir("state.json")

    @classmethod
    def load(cls):
        statefile = cls._statefile()
        if not statefile.exists():
            return cls()
        with statefile.open("r") as f:
            return cls(**json.load(f))

    def save(self):
        self._statefile().write_text(self.model_dump_json())
