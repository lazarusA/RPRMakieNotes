## by Lazaro Alonso
using GLMakie, GeometryBasics
using RPRMakie, RadeonProRender
using LinearAlgebra, Colors, FileIO
include("saveRPR.jl")

# background/sky color
#img = [colorant"grey30" for i in 1:1, j in 1:1]
img = load("./lights/envLightImage.exr") 
lights = [EnvironmentLight(1.0, img'[end:-1:1, :]), PointLight(Vec3f(0,0,1.0), RGBf(8.0, 6.0, 5.0))]

fig=Figure(; resolution=(900, 900))
ax=LScene(fig[1, 1]; show_axis=false, scenekw=(;lights=lights))
screen=RPRMakie.RPRScreen(size(ax.scene); plugin=RPR.Northstar, iterations=4500)
matsys=screen.matsys
# box
mesh!(ax,Rect3(Vec3f(-1, -1, -1.1), Vec3f(2, 2, 0.1)); color = :white)
mesh!(ax, Rect3(Vec3f(-1, -1.1, -1.1), Vec3f(2, 0.1, 2.2));
    color=RGB(0.929, 0.773, 0.0))
mesh!(ax, Rect3(Vec3f(-1, 1.0, -1.1), Vec3f(2, 0.1, 2.2));
    color=RGB(0.588, 0.196, 0.722))
mesh!(ax, Rect3(Vec3f(-1, -1, 1.0), Vec3f(2, 2, 0.1));
    color=RGB(0.361, 0.722, 0.361))
mesh!(ax, Rect3(Vec3f(-1, -1, -1.1), Vec3f(0.1, 2, 2.2));
    color =RGB(0.522, 0.522, 0.522))
# sphere
mesh!(ax, SphereTess(; o = Point3f(0.5,0,0), r = 0.5); material=RPR.Glass(matsys))

GLMakie.activate!()
cam = cameracontrols(ax.scene)
cam.eyeposition[] = Vec3f(10.0, 0.0, 0.5)
cam.lookat[] = Vec3f(0.0, 0.0, 0.0)
cam.fov[] = 12
display(fig)
context, task = RPRMakie.replace_scene_rpr!(ax.scene, screen)
nothing # avoid printing stuff into the repl
imageOut = colorbuffer(screen)
save("./imgs/sphere_source_light_clean.png", imageOut) # save just screen scene.
saveRPR("./imgs/sphere_source_light", imageOut,  resolution=(950, 950))