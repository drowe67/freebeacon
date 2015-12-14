all: freebeacon

freebeacon: freebeacon.c
	gcc -I/usr/local/include/codec2 freebeacon.c -g -o freebeacon -lsamplerate -lportaudio -lsndfile -lcodec2 -Wall
