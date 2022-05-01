## by Lazaro Alonso
using GLMakie, GeometryBasics
using RPRMakie, RadeonProRender
using LinearAlgebra, Colors, FileIO
using Downloads
include("saveRPR.jl")
# background/sky color
img = [colorant"grey98" for i in 1:1, j in 1:1]
# color as an array/image, hence a normal image also works
lights = [EnvironmentLight(1.0, img'), PointLight(Vec3f(3,3,3.0), RGBf(15, 15, 15))]
# custom Tesselation over an Sphere
function SphereTess(; o=Point3f(0), r=1, tess=64)
    return uv_normal_mesh(Tesselation(Sphere(o, r), tess))
end
plane = Rect3f(Vec3f(-5,-2,-1.05), Vec3f(10,4,0.05))
earth_img = load(Downloads.download("https://www.solarsystemscope.com/textures/download/8k_earth_daymap.jpg"))
# the actual figure
fig=Figure(; resolution=(900, 900))
ax=LScene(fig[1, 1]; show_axis=false, scenekw=(;lights=lights))
screen=RPRMakie.RPRScreen(size(ax.scene); plugin=RPR.Northstar, iterations=4500)
matsys=screen.matsys
material = RPR.UberMaterial(screen.matsys;
    color= Vec4f(0.5,0.25,0.0,1.0),
    diffuse_weight = Vec4f(1, 1, 1, 1),
    reflection_color= Vec4f(0.5,0.5,0.5,1.0),
    reflection_weight = Vec4f(0.9, 0.9, 0.9, 1),
    reflection_roughness = Vec4f(0.1, 0.0, 0.0, 0.0),
    reflection_metalness = Vec4f(0.0, 0.0, 0.0,1.0),
    reflection_mode =  UInt(RPR.RPR_UBER_MATERIAL_IOR_MODE_PBR)# 1,
    )
mesh!(ax, SphereTess(); color= earth_img', #RGB(0.082, 0.643, 0.918),
    material= material)
mesh!(ax, plane; color=:white, material=RPR.DiffuseMaterial(matsys))
GLMakie.activate!()
zoom!(ax.scene, cameracontrols(ax.scene), 0.22)
display(fig)
context, task = RPRMakie.replace_scene_rpr!(ax.scene, screen)
nothing # avoid printing stuff into the repl
imageOut = colorbuffer(screen)
save("./imgs/uberMExample_clean.png", imageOut) # save just screen scene.
saveRPR("./imgs/uberMExample", imageOut,  resolution=(900, 900))