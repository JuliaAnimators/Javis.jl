"""
    Video

Defines the video canvas for an animation.

# Fields
- `width::Int` the width in pixel
- `height::Int` the height in pixel
- `objects::Vector{AbstractObject}` the objects defined in this video
- `background_frames::Vector{Int}` saves for which frames a background is defined
- `defs::Dict{Symbol, Any}` Some definitions which should be accessible throughout the video.
"""
mutable struct Video
    width::Int
    height::Int
    objects::Vector{AbstractObject}
    background_frames::Vector{Int}
    defs::Dict{Symbol,Any}
end

"""
    CURRENT_VIDEO

holds the current video in an array to be declared as a constant
The current video can be accessed using CURRENT_VIDEO[1]
"""
const CURRENT_VIDEO = Array{Video,1}()


"""
    Video(width, height; dev_mode = false)

Create a video with a certain `width` and `height` in pixel. The argument `dev_mode` 
specifies whether to reuse frames during development specified by the `compute_frames` 
paramter in render.

This also sets `CURRENT_VIDEO`.
"""
function Video(width, height; dev_mode = false)
    # some luxor functions need a drawing ;)
    Drawing()
    video = Video(
        width,
        height,
        AbstractObject[],
        Int[],
        Dict{Symbol,Any}(:dev_mode => dev_mode),
    )
    if isempty(CURRENT_VIDEO)
        push!(CURRENT_VIDEO, video)
    else
        CURRENT_VIDEO[1] = video
    end
    empty!(CURRENT_OBJECT)
    return video
end

"""
    update_lastframes(frames)

Updates the list of unchanged frames of the current video if `dev_mode` in [`Video`](@ref) is set.

# Warnings
Shows a warning if argument `frames` cannot be processed to update last frames. Possible 
when frames passed is a [`RFrames`](@ref), which is fine since these will be newly added.
"""
function update_lastframes(frames::Any)
    try
        if typeof(frames) == UnitRange{Int64}
            frames = Vector{Int}(frames)
        end
        if get(CURRENT_VIDEO[1].defs, :dev_mode, false)
            CURRENT_VIDEO[1].defs[:last_frames] =
                setdiff(get(CURRENT_VIDEO[1].defs, :last_frames, Vector{Int}()), frames)
        end
    catch e
        @warn "Argument `frames` with type $(typeof(frames)) passed to `update_lastframes` must have integer vector like type hence ignoring update."
    end
end
