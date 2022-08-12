#!/usr/bin/python3

import pa

def main():
    volume = pa.volume()
    muted = pa.is_muted()

    if muted:
        print("Mute")
    else:
        print(str(volume) + "%")

if __name__ == "__main__":
    main()
