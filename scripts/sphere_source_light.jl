## by Lazaro Alonso
using GLMakie, GeometryBasics
using RPRMakie, RadeonProRender
using LinearAlgebra, Colors, FileIO
include("saveRPR.jl")

# background/sky color
img = [colorant"grey20" for i in 1:1, j in 1:1]
# color as an array/image, hence a normal image also works

lights = [EnvironmentLight(1.0, img'), PointLight(Vec3f(2.25,0,0.5), RGBf(8.0, 6.0, 5.0))]
# custom Tesselation over an Sphere
function SphereTess(; o=Point3f(0), r=1, tess=64)
    return uv_normal_mesh(Tesselation(Sphere(o, r), tess))
end
plane = Rect3f(Vec3f(-5,-2,-1.05), Vec3f(10,4,0.05))

# the actual figure
fig=Figure(; resolution=(900, 900))
ax=LScene(fig[1, 1]; show_axis=false, scenekw=(;lights=lights))
screen=RPRMakie.RPRScreen(size(ax.scene); plugin=RPR.Northstar, iterations=250)
matsys=screen.matsys
mesh!(ax, SphereTess(); color=RGB(0.929, 0.773, 0.0), material=RPR.DiffuseMaterial(matsys))
mesh!(ax, SphereTess(; o = Point3f(0,0,2), r = 0.2); color=65colorant"white",
    material=RPR.EmissiveMaterial(matsys))
mesh!(ax, SphereTess(; o = Point3f(0,2,0.5), r = 0.1); color=65colorant"red",
    material=RPR.EmissiveMaterial(matsys))
mesh!(ax, SphereTess(; o = Point3f(-3,-0.75,-1), r = 0.1); color=65colorant"dodgerblue",
    material=RPR.EmissiveMaterial(matsys))

mesh!(ax, plane; color=:gainsboro, material=RPR.DiffuseMaterial(matsys))
GLMakie.activate!()
zoom!(ax.scene, cameracontrols(ax.scene), 0.22)
display(fig)
context, task = RPRMakie.replace_scene_rpr!(ax.scene, screen)
nothing # avoid printing stuff into the repl
imageOut = colorbuffer(screen)
#save("SpherePlaneSky.png", imageOut) # save just screen scene.
saveRPR("./imgs/sphere_source_light", imageOut,  resolution=(900, 900))