#!/usr/bin/env python

import configparser
import datetime as dt
import distutils.util
import email
import email.charset
import email.message
import email.utils
import logging
import re
import textwrap
from itertools import islice
from typing import Iterable, Tuple, cast

import imapclient
from tqdm import tqdm

logger = logging.getLogger()


def chunk(arr_range, chunk_size):
    arr_range = iter(arr_range)
    return iter(lambda: tuple(islice(arr_range, chunk_size)), ())


def delete_attachments(msg: email.message.Message, tolerable_part_size_bytes=10 * 1024):
    deleted_attachment_string = textwrap.dedent(
        """
        This message contained an attachment that was deleted at: %(timestamp)s
        The original type was: %(content_type)s
        The filename was: %(filename)s,
        (and it had additional parameters of: %(params)s)
        """
    )

    ct = msg.get_content_type()
    fn = msg.get_filename()

    if msg.is_multipart():
        payload = [
            delete_attachments(x, tolerable_part_size_bytes) for x in msg.get_payload()
        ]
        msg.set_payload(payload)
    elif (
        msg.get_content_disposition() == "attachment"
        or msg.get_content_maintype() == "image"
        or msg.get_content_maintype() == "audio"
        or msg.get_content_maintype() == "video"
        or msg.get_content_maintype() == "music"
        or msg.get_content_maintype() == "x-music"
        or msg.get_content_maintype() == "application"
    ):

        if len(str(msg)) <= tolerable_part_size_bytes:
            logger.debug("Skipping small attachment: " + msg.get_content_type())
        else:
            logger.debug("Deleting attachment: " + msg.get_content_type())

            params = msg.get_params()[1:]
            params = ", ".join(["=".join(p) for p in params])
            replace = deleted_attachment_string % dict(
                content_type=ct,
                filename=fn,
                params=params,
                timestamp=dt.datetime.now().isoformat(),
            )
            msg.set_payload(replace)
            for k, _v in msg.get_params()[1:]:
                msg.del_param(k)
                msg.set_type("text/plain")
                del msg["Content-Transfer-Encoding"]
                del msg["Content-Disposition"]

    return msg


def bulk_fetch(
    client, uids, chunk_size=10
) -> Iterable[Tuple[int, email.message.Message]]:
    for uids in chunk(uids, chunk_size):
        msg_by_id = client.fetch(uids, ["RFC822"])
        for uid, data in msg_by_id.items():
            msg = email.message_from_bytes(data[b"RFC822"])
            yield (uid, msg)


def remove_attachments(
    server_url: str,
    user: str,
    password: str,
    min_size_bytes: int,
    from_folder,
    to_folder,
    max_date: dt.date,
    test_mode: bool = True,
):
    with imapclient.IMAPClient(host=server_url) as client:
        client.login(user, password)
        client.select_folder(from_folder)

        print(
            f"Searching for messages older than {max_date}"
            f" and larger than {min_size_bytes / 1024:.2f} KiB"
            f" in folder {from_folder}...",
            end=" ",
        )
        messages = client.search(
            criteria=[
                "ALL",
                "LARGER",
                min_size_bytes,
                "BEFORE",
                max_date,
            ],  # type: ignore (search() criteria can actually be a deep list, pyright is getting confused by the default str value)
        )
        msg_count = len(messages)
        print(f"found {msg_count} messages!")

        nth_email = 0
        progress = tqdm(
            bulk_fetch(client, messages), total=msg_count, dynamic_ncols=True
        )
        for uid, msg in progress:
            nth_email += 1

            bytes_before = len(msg.as_string().encode("utf8"))
            delete_attachments(msg)
            bytes_after = len(msg.as_string().encode("utf8"))

            date = email.utils.parsedate_to_datetime(msg["date"])
            assert date
            gmail_labels = [
                l for l in client.get_gmail_labels(uid)[uid] if l != from_folder
            ]
            progress.set_description(
                f"UID: {uid}"
                f", Gmail Labels: {gmail_labels}"
                f", Sbj: {msg['subject']}"
                f"; Date: {date}"
                f"; Size: {bytes_before / 1024:.2f} -> {bytes_after / 1024:.2f} KiB"
            )
            if not test_mode:
                _uid_validity, new_uid = parse_append_uid(
                    cast(
                        bytes,
                        client.append(
                            folder=to_folder,
                            msg=msg.as_string().encode("utf8"),
                            msg_time=date,
                            flags=[imapclient.SEEN],
                        ),
                    )
                )
                client.add_gmail_labels([new_uid], gmail_labels)

                # Finally, delete the old message with attachments.
                # From https://developers.google.com/gmail/imap/imap-extensions#special-use_extension_of_the_list_command
                client.move([uid], "[Gmail]/Trash")


def parse_append_uid(append_uid_response: bytes) -> Tuple[int, int]:
    # Note: https://github.com/mjs/imapclient/issues/36 tracks adding support
    # for parsing APPENDUID responses.

    # From https://datatracker.ietf.org/doc/html/rfc2359#section-5
    match = re.match(r"\[APPENDUID (\d+) (\d+)\]", append_uid_response.decode())
    assert match

    uid_validity = int(match.group(1))
    uid = int(match.group(2))
    return (uid_validity, uid)


def main():
    logging.basicConfig(level=logging.INFO)

    config = configparser.ConfigParser()
    config.sections()
    config.read("config.ini")
    config.sections()

    email_age_days = int(config["DEFAULT"]["email_age_days"])
    remove_attachments(
        min_size_bytes=int(int(config["DEFAULT"]["min_size_kib"]) * 1024),
        from_folder=config["DEFAULT"]["from_folder"],
        to_folder=config["DEFAULT"]["to_folder"],
        test_mode=bool(distutils.util.strtobool(config["DEFAULT"]["test_mode"])),
        server_url=config["mailserver"]["server"],
        user=config["mailserver"]["user"],
        password=config["mailserver"]["password"],
        max_date=dt.date.today() - dt.timedelta(days=email_age_days),
    )


if __name__ == "__main__":
    main()
