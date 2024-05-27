import openvpn3
import time
from openvpn3 import Session, StatusMajor, StatusMinor
import dbus
import openvpn3
from dbus.mainloop.glib import DBusGMainLoop
from gi.repository import GLib  # type: ignore # this import does some clever runtime stuff to exist
import datetime as dt
import logging
import dataclasses

logger = logging.getLogger(__name__)


@dataclasses.dataclass
class CachedSessionInfo:
    session: Session

    name: str
    status_major: StatusMajor
    status_minor: StatusMinor


class SessionWatcher:
    def __init__(self, bus: dbus.SystemBus):
        self._session_manager = openvpn3.SessionManager(bus)
        self._session_manager.SessionManagerCallback(self._handle_session_manager)

        # Subscribe to all existing sessions.
        self._info_by_path: dict[str, CachedSessionInfo] = {}
        pre_existing_sessions = self._session_manager.FetchAvailableSessions()
        if len(pre_existing_sessions) == 0:
            self._handle_update()
        else:
            for session in pre_existing_sessions:
                self._add_session(session)

    def _add_session(self, session: Session):
        status = session.GetStatus()
        name = session.GetProperty("session_name")
        info = CachedSessionInfo(
            session=session,
            name=name,
            status_major=openvpn3.StatusMajor(status["major"]),
            status_minor=openvpn3.StatusMinor(status["minor"]),
        )
        self._info_by_path[session.GetPath()] = info
        self._handle_update()

        def handle_session_status_change(major: int, minor: int, _msg: str):
            try:
                info.name = session.GetProperty("session_name")
            except dbus.exceptions.DBusException:
                pass  # Ignore any errors if this property is not accessible.
            status_major = openvpn3.StatusMajor(major)
            status_minor = openvpn3.StatusMinor(minor)
            info.status_major = status_major
            info.status_minor = status_minor
            self._handle_update()

        session.StatusChangeCallback(handle_session_status_change)

    def _remove_session(self, session: Session):
        if session.GetPath() not in self._info_by_path:
            logger.info(
                "Ignoring disappearing session: %s. I've never seen this session before. This seems to happen if I'm starting up just as a session is disappearing",
                session.GetPath(),
            )
            return

        del self._info_by_path[session.GetPath()]
        self._handle_update()

        # Remove the listeners we registered when the session frst appeared.
        session.LogCallback(None)
        session.StatusChangeCallback(None)

    def _wait_for_session_active(self, session: Session):
        """
        Apparently the SESS_CREATED event arrives very early in the
        lifecycle of a vpn session, and all the corresponding dbus objects may
        not be ready to interact with yet. Try a few times to connect before giving up.
        See
        https://github.com/OpenVPN/openvpn3-linux/blob/v20/src/ovpn3cli/commands/log.cpp#L230-L234
        for details.
        """
        session_active_timeout = dt.timedelta(seconds=1)
        start = time.time()

        while True:
            duration = dt.timedelta(seconds=time.time() - start)
            if duration > session_active_timeout:
                logger.warning(
                    "Timed out waiting for session: %s to become active. Maybe it disappeared?",
                    session.GetPath(),
                )
            try:
                session.GetStatus()
            except dbus.exceptions.DBusException as e:
                if e.get_dbus_message() == "Session not active":
                    logger.debug("Couldn't find session %s. Still waiting...")
                    time.sleep(0.01)
                    continue

                raise e
            else:
                # Success! The session is up and ready to use.
                return

    def _handle_session_manager(self, sm_event: openvpn3.SessionManagerEvent):
        if sm_event.GetType() == openvpn3.SessionManagerEventType.SESS_CREATED:
            session = self._session_manager.Retrieve(sm_event.GetPath())
            self._wait_for_session_active(session)
            self._add_session(session)
        elif sm_event.GetType() == openvpn3.SessionManagerEventType.SESS_DESTROYED:
            session = self._session_manager.Retrieve(sm_event.GetPath())
            self._remove_session(session)
        else:
            logger.warning(
                "Unrecognized session manager event type: %s", sm_event.GetType()
            )

    def _handle_update(self):
        self.print_status()

    def print_status(self):
        statuses = [
            " ".join(
                [self._format_status(info.status_major, info.status_minor), info.name]
            )
            for info in self._info_by_path.values()
        ]
        status = ", ".join(statuses) if statuses else "-"

        print(
            status,
            # Needed when running under polybar with its stdout pipe
            flush=True,
        )

    def _format_status(self, _major: StatusMajor, minor: StatusMinor) -> str:
        # Note: we're ignoring the major status here. I think that's ok, the
        # minor status seems to tell us everything we're interested in.
        icon_by_minor = {
            StatusMinor.SESS_AUTH_URL: "🔑",
            StatusMinor.CFG_OK: "⌛",
            StatusMinor.CONN_INIT: "⌛",
            StatusMinor.CONN_CONNECTING: "⌛",
            StatusMinor.CONN_CONNECTED: "🔒",
            StatusMinor.CONN_DISCONNECTING: "⌛",
            StatusMinor.CONN_DISCONNECTED: "✕",
            StatusMinor.CONN_DONE: "✕",
        }
        return icon_by_minor.get(minor, str(minor.name))


def main():
    logging.basicConfig()

    mainloop = GLib.MainLoop()
    dbusloop = DBusGMainLoop(set_as_default=True)
    bus = dbus.SystemBus(mainloop=dbusloop)
    SessionWatcher(bus)

    try:
        mainloop.run()
    except KeyboardInterrupt:
        print("Exiting", flush=True)


if __name__ == "__main__":
    main()
