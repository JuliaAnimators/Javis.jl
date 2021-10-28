
@testset "delayedposition Trnslation" begin
    testvideo = Video(300, 300)
	Background(1:31, (args...) -> begin; background("white"); sethue("black") end)
	ball1 = Object(1:31, JCircle(O, 10, color="black", action=:fill), Point(-45, 0))
	act!(ball1, Action(1:31, anim_translate(Point(-45, 0), Point(45, 0))))
	act!(ball1, Action(17:31, anim_translate(Javis.delayed_pos(ball1), Point(0, -45))))
	v = render(testvideo, tempdirectory="images", pathname="") 

    for frame in [1, 7, 15, 24, 30]
        png_name = lpad(string(frame), 10, "0")
        @test_reference "refs/delayed_translation_$(frame).png" load("images/$png_name.png",)
    end

    for i in readdir("images", join=true)
        if endswith(i, ".png") 
            rm(i)
        end
    end
end