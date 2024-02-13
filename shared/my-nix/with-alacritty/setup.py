#!/usr/bin/env python

from setuptools import setup, find_packages

setup(
    name="with-alacritty",
    version="1.0",
    packages=find_packages(),
    install_requires=[
        "mergedeep",
        "psutil",
        "pyxdg",
        "tomli-w",
    ],
    entry_points={
        "console_scripts": ["with-alacritty=with_alacritty.cli:main"],
    },
)
