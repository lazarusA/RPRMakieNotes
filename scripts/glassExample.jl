## by Lazaro Alonso
using GLMakie, GeometryBasics
using RPRMakie, RadeonProRender
using LinearAlgebra, Colors, FileIO
using Downloads
include("saveRPR.jl")

function SurfaceGlassX(matsys, path::String)
    return RPR.Matx(matsys, path)
end

function glass_material()
    return (
        reflection_weight = 1,
        reflection_color = RGBf(1.0, 1.0, 1.0),
        reflection_metalness = 0,
        reflection_ior = 1.4,
        diffuse_weight = 1,
        transparency = 0.45, # 1 is fully transparent
        emission_color = RGBf(1, 1, 1.0),
    )
end

# background/sky color
img = [colorant"grey90" for i in 1:1, j in 1:1]
# color as an array/image, hence a normal image also works

lights = [EnvironmentLight(1.0, img'), PointLight(Vec3f(2,2,2.0), RGBf(20.0, 20.0, 20.0))]
# custom Tesselation over an Sphere
function SphereTess(; o=Point3f(0), r=1, tess=64)
    return uv_normal_mesh(Tesselation(Sphere(o, r), tess))
end
plane = Rect3f(Vec3f(-5,-2,-1.05), Vec3f(10,4,0.05))

earth_img = load(Downloads.download("https://www.solarsystemscope.com/textures/download/8k_earth_daymap.jpg"))

# the actual figure
fig=Figure(; resolution=(900, 900))
ax=LScene(fig[1, 1]; show_axis=false, scenekw=(;lights=lights))
screen=RPRMakie.RPRScreen(size(ax.scene); plugin=RPR.Northstar, iterations=250)
matsys=screen.matsys
#sglass = SurfaceGlassX(matsys, "./matxs/standard_surface_glass.mtlx")
#gold = RPR.SurfaceGoldX(matsys)
mesh!(ax, SphereTess(; o=Point3f(0), r=0.5); color = :grey90, material = RPR.EmissiveMaterial(matsys)) # color= :grey90)
mesh!(ax, SphereTess(); color= earth_img', #RGB(0.082, 0.643, 0.918),
    material=glass_material())
mesh!(ax, plane; color=:gainsboro, material=RPR.DiffuseMaterial(matsys))
GLMakie.activate!()
zoom!(ax.scene, cameracontrols(ax.scene), 0.22)
display(fig)
context, task = RPRMakie.replace_scene_rpr!(ax.scene, screen)
nothing # avoid printing stuff into the repl
#imageOut = colorbuffer(screen)
#save("SpherePlaneSky.png", imageOut) # save just screen scene.
#saveRPR("./imgs/sphere_plane_greysky", imageOut,  resolution=(900, 900))