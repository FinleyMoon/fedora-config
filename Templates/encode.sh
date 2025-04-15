for i in *.mp4; do ffmpeg -i "$i" -c:v prores_ks -profile:v 3 -c:a pcm_s16le "${i%.*}.mov"; done
