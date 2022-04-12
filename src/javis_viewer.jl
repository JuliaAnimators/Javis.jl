include("structs/Livestream.jl")

"""
    setup_stream(livestreamto=:local; protocol="udp", address="0.0.0.0", port=14015, twitch_key="")

Sets up the livestream configuration.
**NOTE:** Twitch not fully implemented, do not use.
"""
function setup_stream(
    livestreamto::Symbol = :local;
    protocol::String = "udp",
    address::String = "0.0.0.0",
    port::Int = 14015,
    twitch_key::String = "",
)
    StreamConfig(livestreamto, protocol, address, port, twitch_key)
end

"""
    cancel_stream()

Sends a `SIGKILL` signal to the livestreaming process. Though used internally, it can be used stop streaming.
However this method is not guaranted to end the stream on the client side.
"""
function cancel_stream()
    #todo explore better ways of searching and killing processes

    # kill the ffmpeg process
    # ps aux | grep ffmpeg | grep stream_loop | awk '{print $2}' | xargs kill -9
    try
        println("Checking for existing stream....")
        run(
            pipeline(
                `ps aux`,
                pipeline(`grep ffmpeg`, pipeline(`grep stream_loop`, `awk '{print $2}'`)),
            ),
        )
    catch
        return @warn "Not Streaming Anything Currently"
    end

    run(
        pipeline(
            `ps aux`,
            pipeline(
                `grep ffmpeg`,
                pipeline(`grep stream_loop`, pipeline(`awk '{print $2}'`, `xargs kill -9`)),
            ),
        ),
    )
    return "Livestream Cancelled!"
end

"""
    _livestream(streamconfig, framerate, width, height, pathname)

Internal method for livestreaming 
"""
function _livestream(
    streamconfig::StreamConfig,
    framerate::Int,
    width::Int,
    height::Int,
    pathname::String,
)
    cancel_stream()

    livestreamto = streamconfig.livestreamto
    twitch_key = streamconfig.twitch_key

    if livestreamto == :twitch && isempty(twitch_key)
        return error("Please enter your twitch stream key")
    end

    command = [
        "-stream_loop", # loop the stream -1 times i.e. indefinitely
        "-1",
        "-r", # frames per second
        "$framerate",
        "-an",  # Tells FFMPEG not to expect any audio
        "-loglevel", # show only ffmpeg errors
        "error",
        "-re", # read input at native frame rate
        "-i", # input file
        "$pathname",
    ]

    if livestreamto == :twitch
        if isempty(twitch_key)
            error("Please enter your twitch api key")
        end

        # 
        twitch_cmd = [
            "-f",
            "flv", # force the file to flv format
            "rtmp://live.twitch.tv/app/$twitch_key", # stream to the twitch platform using rtmp protocol
        ]
        push!(command, twitch_cmd...)
        @info "Livestreaming to Twitch!"
    elseif livestreamto == :local
        protocol = streamconfig.protocol
        address = streamconfig.address
        port = streamconfig.port
        local_command = ["-f", "mpegts", "$protocol://$address:$port"] # use an mpeg-ts format, and stream to the given address/port using the protocol
        push!(command, local_command...)
        @info "Livestream Started at $protocol://$address:$port"
    end

    # schedule the streaming process and allow it to run asynchronously
    schedule(@task begin
        ffmpeg_exe(`$command`)
    end)
end

_livestream(
    streamconfig::Nothing,
    framerate::Int,
    width::Int,
    height::Int,
    pathname::String,
) = return
