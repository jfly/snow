#!/usr/bin/env python

import rxv

def set_scene(scene: str):
    rx = rxv.RXV("http://receiver/YamahaRemoteControl/ctrl")
    rx.scene = scene
