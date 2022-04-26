# save output with attributions
noto_sans_bold = assetpath("fonts", "NotoSans-Bold.ttf")
function saveRPR(filename::String, imageOut; resolution = (1200,1200))
    fig = Figure(resolution= resolution)
    ax = Axis(fig[1,1], aspect = DataAspect())
    image!(ax, rotr90(imageOut))
    Label(fig[1,1, Bottom()], "By Lazaro Alonso", textsize = 24)
    Label(fig[1,1, Right()], "Twitter: @LazarusAlon ", textsize = 14, rotation = pi/2)
    Label(fig[1,1, Top()], "using RPRMakie, RadeonProRender, GLMakie ", textsize = 24, font = noto_sans_bold)
    hidedecorations!(ax)
    hidespines!(ax)
    save("$(filename).png", fig)
end
#