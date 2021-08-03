"""
    PlutoViewer

Wrapper to assist viewing rendered gifs as cell outputs of Pluto notebooks
when `liveview = false` 
"""
struct PlutoViewer
    filename::String
end
