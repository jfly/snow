from setuptools import setup, find_packages

setup(
    name='capslockx',
    version='1.0',
    py_modules=['capslockx'],
    entry_points={
        'console_scripts': [
            'capslockx=capslockx:main',
        ],
    },
)
