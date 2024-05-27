import errno
import fcntl
import contextlib
from pathlib import Path
from .data import data_dir


class ThereCanBeOnlyOne(Exception):
    def __init__(self, path: Path):
        self.path = path


@contextlib.contextmanager
def enforce():
    """
    Make sure that there is only one copy of this tool running at once. If
    there's already another copy running, raises ThereCanBeOnlyOne.
    """
    lockfile_path = data_dir("autoperipherals.lock")
    with open(lockfile_path, "w") as lockfile:
        try:
            fcntl.lockf(lockfile, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except OSError as e:
            # From https://docs.python.org/3/library/fcntl.html#fcntl.lockf:
            # > If LOCK_NB is used and the lock cannot be acquired, an OSError
            # > will be raised and the exception will have an errno attribute set
            # > to EACCES or EAGAIN (depending on the operating system; for
            # > portability, check for both values).
            if e.errno in (errno.EACCES, errno.EAGAIN):
                raise ThereCanBeOnlyOne(lockfile_path)
            raise e

        try:
            yield
        finally:
            fcntl.lockf(lockfile, fcntl.LOCK_UN)
