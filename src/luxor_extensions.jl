function setline(linewidth)
    action = CURRENT_ACTION[1]
    cs  = action.current_setting
    current_line_width = linewidth * cs.mul_line_width
    Luxor.setline(current_line_width)
end