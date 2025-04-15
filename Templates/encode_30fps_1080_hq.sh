mkdir converted
for i in *.mp4; do ffmpeg -i "$i" -c:v dnxhd -vf "scale=1920:1080,fps=30,format=yuv422p" -profile:v dnxhr_hq -c:a pcm_s16le ./converted/"${i%.*}.mov"; done
