## by Lazaro Alonso
using GLMakie, GeometryBasics
using RPRMakie, RadeonProRender
using LinearAlgebra, Colors, FileIO, Downloads
include("saveRPR.jl")

# background/sky color
img = [colorant"grey90" for i in 1:1, j in 1:1]
lights = [EnvironmentLight(1.0, img'[end:-1:1, :]), PointLight(Vec3f(4,0,0.85), RGBf(1.0, 1.0, 1.0))]
earth_img = load(Downloads.download("https://www.solarsystemscope.com/textures/download/8k_earth_daymap.jpg"))
function SphereTess(; o=Point3f(0), r=1, tess=64)
    return uv_normal_mesh(Tesselation(Sphere(o, r), tess))
end

fig=Figure(; resolution=(900, 900))
ax=LScene(fig[1, 1]; show_axis=false, scenekw=(;lights=lights))
screen=RPRMakie.RPRScreen(size(ax.scene); plugin=RPR.Northstar, iterations=5000)
matsys=screen.matsys
# box
mesh!(ax,Rect3(Vec3f(-1, -1, -1.1), Vec3f(2, 2, 0.1)); color = RGB(0.082, 0.643, 0.918))
mesh!(ax, Rect3(Vec3f(-1, -1.1, -1.1), Vec3f(2, 0.1, 2.2));
    color=RGB(0.929, 0.773, 0.0))
mesh!(ax, Rect3(Vec3f(-1, 1.0, -1.1), Vec3f(2, 0.1, 2.2));
    color=RGB(0.588, 0.196, 0.722))
mesh!(ax, Rect3(Vec3f(-1, -1, 1.0), Vec3f(2, 2, 0.1));
    color=RGB(0.361, 0.722, 0.361))
mesh!(ax, Rect3(Vec3f(-1, -1, -1.1), Vec3f(0.1, 2, 2.2));
    color =RGB(0.522, 0.522, 0.522))
# sphere
mesh!(ax, SphereTess(; o=Point3f(0.5,0,0), r = 0.85); color = circshift(earth_img, (0, 3800))')
# extra light
mesh!(ax, SphereTess(; o = Point3f(0.9,-0.95,0.95), r = 0.05); color=65colorant"white",
    material=RPR.EmissiveMaterial(matsys))
mesh!(ax, SphereTess(; o = Point3f(0.9,0.95,0.95), r = 0.05); color=65colorant"white",
    material=RPR.EmissiveMaterial(matsys))
mesh!(ax, SphereTess(; o = Point3f(-0.9,-0.95,-0.95), r = 0.05); color=65colorant"white",
    material=RPR.EmissiveMaterial(matsys))
mesh!(ax, SphereTess(; o = Point3f(-0.9,0.95,-0.95), r = 0.05); color=65colorant"white",
    material=RPR.EmissiveMaterial(matsys))

GLMakie.activate!()
cam = cameracontrols(ax.scene)
cam.eyeposition[] = Vec3f(9.5, 0.0, 0.5)
cam.lookat[] = Vec3f(0.0, 0.0, 0.0)
cam.fov[] = 12
display(fig)
context, task = RPRMakie.replace_scene_rpr!(ax.scene, screen)
nothing # avoid printing stuff into the repl
imageOut = colorbuffer(screen)
save("./imgs/earth_ina_julia_box_clean.png", imageOut) # save just screen scene.
saveRPR("./imgs/earth_ina_julia_box", imageOut,  resolution=(950, 950))

