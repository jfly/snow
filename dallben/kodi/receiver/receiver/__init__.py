#!/usr/bin/env python

import rxv

def connect():
    return rxv.RXV("http://receiver/YamahaRemoteControl/ctrl")

def set_scene(scene: str):
    rx = connect()
    rx.scene = scene

def off():
    rx = connect()
    rx.on = False
