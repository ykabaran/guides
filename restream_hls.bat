@echo off
@title Restream SkyDog
:loop

ffmpeg -i https://betamg-i.akamaihd.net/hls/live/252820/skybet/0_2q2jxm2n_3/chunklist.m3u8 -c:v copy -c:a copy -f flv rtmp://192.168.1.173:5130/live/skydog/livestream

goto loop
