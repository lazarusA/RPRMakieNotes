## by Lazaro Alonso
using GLMakie, GeometryBasics, Colors
using RPRMakie, RadeonProRender, FileIO
using LinearAlgebra, Downloads
include("saveRPR.jl")

img = [colorant"white" for i in 1:1, j in 1:1] # color as an image, hence also a normal image also works
logoMakie=load("./imgs/makie_logo_transparent.png")
thandle=load("./imgs/lazaro2.png")

lights=[EnvironmentLight(1.0, img), PointLight(Vec3f(0,-2,1.99), RGBf(5.0, 5.0, 5.0))]

function SphereTess(o=Point3f(0), r=1; tess=64)
    return uv_normal_mesh(Tesselation(Sphere(o, r), tess))
end
plane = Rect3f(Vec3f(-3,-9,-1.05), Vec3f(8,17,0.05))
planetop = Rect3f(Vec3f(-3,-9,4.0), Vec3f(8,17,0.05))

jlmkecs = [RGB(0.0, 0.0, 0.0), RGB(0.082, 0.643, 0.918), RGB(0.91, 0.122, 0.361), 
    RGB(0.929, 0.773, 0.0), RGB(0.588, 0.196, 0.722), RGB(0.361, 0.722, 0.361), RGB(0.522, 0.522, 0.522)]

fig = Figure(; resolution=(1600, 900))
ax = LScene(fig[1, 1]; show_axis=false, scenekw=(lights=lights,))
screen = RPRMakie.RPRScreen(size(ax.scene); plugin=RPR.Northstar, iterations=5000)
matsys = screen.matsys
mesh!(ax, SphereTess(Point3f(0.0,-4.5,0), 1.0); color =jlmkecs[2])
mesh!(ax, SphereTess(Point3f(0.0,-2.25,0), 1.0); color =jlmkecs[3])
mesh!(ax, SphereTess(Point3f(0.0,0,0), 1.0); color =jlmkecs[4])
mesh!(ax, SphereTess(Point3f(0.0,2.25,0), 1.0); color =jlmkecs[5])
mesh!(ax, SphereTess(Point3f(0.0,4.5,0), 1.0); color =jlmkecs[6])
# emissive spheres
mesh!(ax, SphereTess(Point3f(0.75, 5.5,-1 + 0.15), 0.15); color=2.5*jlmkecs[6], material=RPR.EmissiveMaterial(matsys))
mesh!(ax, SphereTess(Point3f(0.75, 3.0,-1 + 0.15), 0.15); color=2.5*jlmkecs[5], material=RPR.EmissiveMaterial(matsys))
mesh!(ax, SphereTess(Point3f(0.75, 1.0,-1 + 0.15), 0.15); color=2.5*jlmkecs[4], material=RPR.EmissiveMaterial(matsys))
mesh!(ax, SphereTess(Point3f(0.75, -1.5,-1 + 0.15), 0.15); color=2.5*jlmkecs[3], material=RPR.EmissiveMaterial(matsys))
mesh!(ax, SphereTess(Point3f(0.75, -5.5,-1 + 0.15), 0.15); color=2.5*jlmkecs[2], material=RPR.EmissiveMaterial(matsys))
#walls
mesh!(ax, plane; color = color = :gainsboro, material = RPR.DiffuseMaterial(matsys))
mesh!(ax, planetop; color = color = :gainsboro, material = RPR.DiffuseMaterial(matsys))
mesh!(ax,  Rect3f(Vec3f(-3,-9,-1.05), Vec3f0(0.05,17,5.05)); color = :grey, material=RPR.DiffuseMaterial(matsys))
# at light position 
mesh!(ax, Rect3f(Vec3f(-1,-3, 2.01), Vec3f(2,2.0, 0.05)); color = :white, material=RPR.DiffuseMaterial(matsys))
# emissive material
mesh!(ax, Rect3f(Vec3f(-1,2, 2.0), Vec3f(2,2.5, 0.05)), color = RGBf(3,3,3), 
    material=  RPR.EmissiveMaterial(matsys))

mlogo = mesh!(ax, Rect3f(Vec3f(2,3,-1.0), Vec3f(1.2455,0.5,0.05)), color=logoMakie'[end:-1:1, end:-1:1])
mlazaro = mesh!(ax, Rect3f(Vec3f(-0.5,-0.5,-1.0), Vec3f(0.2, 0.2, 0.05));
    color=thandle'[end:-1:1, :], material=RPR.DiffuseMaterial(matsys))
RPRMakie.rotate!(mlazaro, Vec3f(1, 0, 0), π/2) # Quaternionf(0, 0.0, 0, -1)
translate!(mlazaro, Vec3f(6.025, 4.15, 0))
#mirror
mesh!(ax, Rect3f(Vec3f(-3,-7, -1.05), Vec3f(8,0.05, 5.5)); color = :white, material = RPR.Glass(matsys))

GLMakie.activate!()
cam = cameracontrols(ax.scene)
cam.eyeposition[] =Float32[7.2984867, 9.654725, 0.6902726]
cam.lookat[] = Float32[-0.81408334, 0.84149307, 0.575948]
cam.upvector[] = Float32[0.24841104, 0.26986563, 0.9303031]
cam.zoom_mult[] = 0.62092125f0
zoom!(ax.scene, cameracontrols(ax.scene), 1.1)
display(fig)
context, task = RPRMakie.replace_scene_rpr!(ax.scene, screen)
nothing # avoid printing stuff into the repl
imageOut = colorbuffer(screen)
save("./imgs/materials_julia_room_clean.png", imageOut) # save just screen scene.
saveRPR("./imgs/materials_julia_room", imageOut;  resolution = (1650,950))