#!/usr/bin/env python

from setuptools import setup, find_packages

setup(
    name='receiver',
    version='1.0',
    packages=find_packages(),
    scripts=[
        "receiver-on.py",
        "tv-on.py",
        "tv-off.py",
    ],
)
