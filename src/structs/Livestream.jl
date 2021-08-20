"""
    StreamConfig

Holds the conguration for livestream, defaults to `nothing`

#Fields
- `livestreamto::Symbol` Livestream platform `:local` or `:twitch`  
- `protocol::String` The streaming protocol to be used. Defaults to UDP
- `address::String` The IP address for the `:local` stream(ignored in case of `:twitch`)
- `port::Int` The port for the `:local` stream(ignored in case of `:twitch`)
- `twitch_key::String` Twitch stream key for your account
- `frames::Union{UnitRange{Int}, Symbol}` The specific frames to be livestreamed. Defaults to `:all` 
"""
struct StreamConfig
    livestreamto::Symbol
    protocol::String
    address::String
    port::Int
    twitch_key::String
    frames::Union{UnitRange{Int},Symbol}
end
