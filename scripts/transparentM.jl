using LinearAlgebra, Random, GLMakie
using RPRMakie, RadeonProRender, Colors
using Downloads, FileIO, GeometryBasics

function SphereTess(; o=Point3f(0), r=1, tess=64)
    return uv_normal_mesh(Tesselation(Sphere(o, r), tess))
end
n = 1024 ÷ 4 # 2048
θ = LinRange(0, pi, n)
φ = LinRange(-pi, pi, 2 * n)
xe = [cos(φ) * sin(θ) for θ in θ, φ in φ]
ye = [sin(φ) * sin(θ) for θ in θ, φ in φ]
ze = [cos(θ) for θ in θ, φ in φ]

earth_img = load(Downloads.download("https://www.solarsystemscope.com/textures/download/8k_earth_daymap.jpg"))
# the actual plot !
img = [colorant"grey90" for i in 1:1, j in 1:1]
lights = [EnvironmentLight(1.0, img'), PointLight(Vec3f(2,0,2.0), RGBf(8.0, 6.0, 5.0))]
plane = Rect3f(Vec3f(-5,-2,-1.05), Vec3f(10,4,0.05))

fig = Figure(; resolution=(1000, 1000))
ax = LScene(fig[1, 1]; show_axis=false, scenekw=(lights=lights,))
screen=RPRMakie.RPRScreen(size(ax.scene); plugin=RPR.Northstar, iterations=500)
matsys=screen.matsys
mesh!(ax, plane; color=:gainsboro, material=RPR.DiffuseMaterial(matsys))
mesh!(ax, SphereTess(; o=Point3f(0), r=0.5); color = :white, material=RPR.EmissiveMaterial(matsys)) # color= :grey90)
surface!(ax, xe, ye, ze; color=earth_img, material=RPR.TransparentMaterial(matsys))

GLMakie.activate!()
cam = cameracontrols(ax.scene)
cam.eyeposition[] = Vec3f(1.5)
display(fig)
context, task = RPRMakie.replace_scene_rpr!(ax.scene, screen)
#imageOut = colorbuffer(screen)