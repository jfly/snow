#!/usr/bin/env nix-shell
#!nix-shell -i python -p audible-cli

import argparse
import urllib.request
import shutil
import glob
import tempfile
import subprocess
import math
import datetime as dt
import asyncio
import audible_cli
import audible_cli.config
import audible_cli.models
from pathlib import Path


async def main():
    parser = argparse.ArgumentParser(description="Download audible podcast")
    parser.add_argument("podcast_asin")
    parser.add_argument("out", type=Path)
    args = parser.parse_args()

    assert args.out.is_dir()
    await download(args.podcast_asin, args.out)


async def get_podcast(client, asin):
    info = await client.get(
        path=f"library/{asin}",
        params={
            "response_groups": (
                "contributors, customer_rights, media, price, product_attrs, "
                "product_desc, product_extended_attrs, product_plan_details, "
                "product_plans, rating, sample, sku, series, reviews, ws4v, "
                "origin, relationships, review_attrs, categories, "
                "badge_types, category_ladders, claim_code_url, in_wishlist, "
                "is_archived, is_downloaded, is_finished, is_playable, "
                "is_removable, is_returnable, is_visible, listening_status, "
                "order_details, origin_asin, pdf_url, percent_complete, "
                "periodicals, provided_review, product_details"
            )
        },
    )
    item = audible_cli.models.LibraryItem(
        data=info,
        api_client=client,
        response_groups=info["response_groups"],
    )
    return item


async def download(podcast_asin: str, out: Path):
    with tempfile.TemporaryDirectory() as tmpdirname:
        temp_dir = Path(tmpdirname)
        raw_download(podcast_asin, temp_dir)
        decrypt(temp_dir)
        await finalize(podcast_asin, temp_dir, out)


async def finalize(podcast_asin: str, temp_dir: Path, out: Path):
    session = audible_cli.config.Session()
    client = session.get_client()

    podcast = await get_podcast(client, podcast_asin)
    children = await podcast.get_child_items()
    assert children is not None

    release_date = dt.date.fromisoformat(podcast._data["release_date"])
    title = f"{podcast.full_title} ({release_date.year})"

    # Figure out how much padding we need to fit all episode indices.
    max_index = len(children)
    padding = math.ceil(math.log10(max_index))

    title_to_final = {}
    for i, child in enumerate(children):
        final_title = f"{title} - E{str(i).zfill(padding)} - {child.title}"
        title_to_final[child.title] = final_title

    # Move all the decrypted files into the final `out` directory.
    final_dir = out / title
    final_dir.mkdir(exist_ok=True)
    for file_str in glob.glob("*.m4a", root_dir=temp_dir):
        file = temp_dir / file_str
        stem = file.stem
        # Hacks for files with bad metadata
        stem = {
            "Episode: Hot White Heist": "Episode 6: Hot White Heist",
            "I Would Never Lie to You": "I Will Never Lie to You",
        }.get(stem, stem)
        new_file = final_dir / file.with_stem(title_to_final[stem]).name
        shutil.move(file, new_file)

    # Download the podcast cover image
    # Note: folder.{jpg,png} has special meaning to AntennaPod:
    # https://github.com/AntennaPod/AntennaPod/blob/bc3b7179112e986958bbb4773419ec94eb3aa67f/core/src/main/java/de/danoeh/antennapod/core/feed/LocalFeedUpdater.java#L52
    url = podcast.get_cover_url()
    urllib.request.urlretrieve(url, final_dir / Path(url).with_stem("folder").name)

    print()
    print(f"Successfully downloaded to {final_dir}")


def raw_download(podcast_asin: str, temp_dir: Path):
    subprocess.run(
        [
            "audible",
            "download",
            "--aaxc",
            "--resolve-podcasts",
            "--asin",
            podcast_asin,
            "--cover",
            "-y",
            "--chapter",
            "-o",
            str(temp_dir),
        ],
        check=True,
    )


def decrypt(temp_dir: Path):
    for file in glob.glob("*/*.aaxc", root_dir=temp_dir):
        subprocess.run(["snowcrypt", file], check=True, cwd=temp_dir)


asyncio.run(main())
