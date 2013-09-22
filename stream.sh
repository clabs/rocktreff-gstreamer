#!/bin/bash
FPS="15"
VIDEO_BITRATE="1500"
AUDIO_BITRATE="128"

AIRCAM3="rtsp://172.23.1.248/live/ch00_0"
AIRCAM2="rtsp://172.23.1.246/live/ch00_0"
AIRCAM1="rtsp://172.23.1.247/live/ch00_0"

# Caps
AIRCAM_CAPS="video/x-raw-yuv, width=1280, height=720, framerate=$FPS/1"
AUDIO_CAPS="audio/x-raw-int"

# Sources
		SRC1="rtspsrc location=$AIRCAM1 latency=0 ! decodebin ! ffmpegcolorspace ! $AIRCAM_CAPS"
		#SRC1="videotestsrc pattern=2"

		SRC2="rtspsrc location=$AIRCAM2 latency=0 ! decodebin ! ffmpegcolorspace ! $AIRCAM_CAPS"
		#SRC2="videotestsrc pattern=2"

		SRC3="rtspsrc location=$AIRCAM3 latency=0 ! decodebin ! ffmpegcolorspace ! $AIRCAM_CAPS"
		#oOSRC3="videotestsrc pattern=2"

		SRC4="multifilesrc location=\"layer.png\" caps=\"image/png,framerate=$FPS/1\" ! pngdec ! imagefreeze ! ffmpegcolorspace ! video/x-raw-yuv,format=(fourcc)AYUV,framerate=$FPS/1"
		AUDIO="autoaudiosrc ! audioconvert ! $AUDIO_CAPS"

# Justin Kram
	STREAM_KEY="live_" 
	RTMP_SERVER_URL="rtmp://live.justin.tv/app"
	JUSTIN="\"$RTMP_SERVER_URL/$STREAM_KEY flashver=FME/2.5\20(compatible;\20FMSc\201.0)\""
	
# Steaming Output
	ENCODER="x264enc pass=pass1 threads=0 bitrate=$VIDEO_BITRATE byte-stream=true tune=zerolatency speed-preset=ultrafast"
	RTMPSINK="rtmpsink location=$JUSTIN async=true"
	TCPSINK="tcpserversink host=172.23.1.241 port=1234"
	QUEUE="queue leaky=1"

gst-launch-0.10 \
	videomixer name=mix \
			sink_0::zorder=1 sink_0::xpos=0    sink_0::ypos=0 \
			sink_1::zorder=3 sink_1::xpos=30  sink_1::ypos=226 \
			sink_2::zorder=4 sink_2::xpos=30  sink_2::ypos=444 \
			sink_3::zorder=2 sink_3::xpos=0  sink_3::ypos=0 \
	! ffmpegcolorspace ! videorate ! $ENCODER ! flvmux name=mux streamable=true ! tee name=t \
		t. ! $QUEUE ! $TCPSINK \
		t. ! $QUEUE ! $RTMPSINK \
	$SRC1 ! \
		mix.sink_0 \
	$SRC2 ! \
		videoscale ! video/x-raw-yuv, width=318, height=177, framerate=$FPS/1 ! \
		mix.sink_1 \
	$SRC3 ! \
		videoscale ! video/x-raw-yuv, width=318, height=177, framerate=$FPS/1 ! \
		mix.sink_2 \
	$SRC4 ! \
		mix.sink_3 \
	$AUDIO ! \
		lame bitrate=$AUDIO_BITRATE ! \
		mux.
