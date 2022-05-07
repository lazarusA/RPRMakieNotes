## by Lazaro Alonso
using GLMakie, GeometryBasics, ColorSchemes
using RPRMakie, RadeonProRender
using LinearAlgebra, Colors, FileIO
using Luxor
using Random
Random.seed!(123)
include("saveRPR.jl")
include("pointsfont.jl")
thandle=load("./imgs/lazaro2.png")
# Letters
letterMesh = []
letters = ["A", "T", "C", "G"]
for l in letters
    mletter = 0.65pointsfont(l)
    top_poly =  [Point3f(2.5 .+ p[1]/30, p[2]/30, 0.15) for p in mletter if isnan(p[1]) == false]
    bottom_poly =  [Point3f(2.5 .+ p[1]/30, p[2]/30, 0.01) for p in mletter if isnan(p[1]) == false]
    push!(letterMesh, getMesh(top_poly, bottom_poly))
end
#helix
npairs, θinit = 40, 10*π/180
z = 1:npairs
θ = z .* θinit
x(θ; r = 5) = r * cos(θ) 
y(θ; r = 5) = r * sin(θ) 
x1, y1 = x.(θ), y.(θ)
x2, y2 = x.(θ .+ π), y.(θ .+ π)
colors1 = rand(1:4, npairs) # 1, 2, 3, 4 =>  'A', 'T', 'C', 'G'
colors2 = [i == 1 ? 2 : i==2 ? 1 : i == 3 ? 4 : 3 for i in colors1]
jlmkecs = [RGB(0.082, 0.643, 0.918), RGB(0.91, 0.122, 0.361), 
    RGB(0.929, 0.773, 0.0), RGB(0.588, 0.196, 0.722)]
lseg, colors = Point3f[], Int64[]
for i in 1:npairs
    push!(lseg, [x1[i], z[i], y1[i]])
    push!(lseg, [x2[i], z[i], y2[i]])
    push!(colors, colors1[i])
    push!(colors, colors2[i])
end

# background/sky color
img = [colorant"grey90" for i in 1:1, j in 1:1]
# color as an array/image, hence a normal image also works

lights = [EnvironmentLight(1, img'), PointLight(Vec3f(0,42,5.0), RGBf(100.0, 100.0, 100.0))]
# custom Tesselation over an Sphere
function SphereTess(; o=Point3f(0), r=1, tess=64)
    return uv_normal_mesh(Tesselation(Sphere(o, r), tess))
end
plane = Rect3f(Vec3f(-20,-10,-5.5), Vec3f(60,55,0.05))
planeL = Rect3f(Vec3f(-10,-2,17.5), Vec3f(20,30,0.05))

# the actual figure
fig=Figure(; resolution=(1600, 800))
ax=LScene(fig[1, 1]; show_axis=false, scenekw=(;lights=lights))
screen=RPRMakie.RPRScreen(size(ax.scene); plugin=RPR.Northstar, iterations=4500)
matsys=screen.matsys

mesh!(ax, plane; color=:gainsboro, material=RPR.DiffuseMaterial(matsys))
mesh!(ax, planeL; color= 2.5colorant"white", material=RPR.EmissiveMaterial(matsys))

[meshscatter!(ax, Point3f(x1[i], z[i], y1[i]);
    color = jlmkecs[colors1[i]], markersize = 0.35,material = RPR.UberMaterial(screen.matsys; diffuse_weight = Vec4f(1, 1, 1, 1),
    reflection_color= Vec4f(0.5,0.5,0.5,1.0),
    reflection_weight = Vec4f(0.9, 0.9, 0.9, 1),
    reflection_roughness = Vec4f(0.1, 0.0, 0.0, 0.0),
    reflection_metalness = Vec4f(0.0, 0.0, 0.0,1.0),
    reflection_mode =  UInt(RPR.RPR_UBER_MATERIAL_IOR_MODE_PBR))) for i in 1:40]
[meshscatter!(ax, Point3f(x2[i], z[i], y2[i]);
    color = jlmkecs[colors2[i]], markersize = 0.35,material = RPR.UberMaterial(screen.matsys; diffuse_weight = Vec4f(1, 1, 1, 1),
    reflection_color= Vec4f(0.5,0.5,0.5,1.0),
    reflection_weight = Vec4f(0.9, 0.9, 0.9, 1),
    reflection_roughness = Vec4f(0.1, 0.0, 0.0, 0.0),
    reflection_metalness = Vec4f(0.0, 0.0, 0.0,1.0),
    reflection_mode =  UInt(RPR.RPR_UBER_MATERIAL_IOR_MODE_PBR))) for i in 1:40]
for i in 1:2:80
    lines!(ax, [lseg[i], (lseg[i] .+ lseg[i+1])/2], linewidth = 20, color = jlmkecs[colors[i]])
    lines!(ax, [(lseg[i] .+ lseg[i+1])/2, lseg[i+1]], linewidth = 20, color = jlmkecs[colors[i+1]])
end
posk = tuple.(-8, 3:10:42,-4.85)
[meshscatter!(ax, [Point3f(posk[i]...)]; color = jlmkecs[i], markersize = 0.5,
    material = RPR.UberMaterial(screen.matsys; diffuse_weight = Vec4f(1, 1, 1, 1),
    reflection_color= Vec4f(0.5,0.5,0.5,1.0),
    reflection_weight = Vec4f(0.9, 0.9, 0.9, 1),
    reflection_roughness = Vec4f(0.1, 0.0, 0.0, 0.0),
    reflection_metalness = Vec4f(0.0, 0.0, 0.0,1.0),
    reflection_mode =  UInt(RPR.RPR_UBER_MATERIAL_IOR_MODE_PBR))) for i in 1:4]
for i in 1:4
    letterx = mesh!(ax, letterMesh[i]; color = jlmkecs[i])
    GLMakie.rotate!(letterx, Vec3f(0, 0, 1), -π/2)
    translate!(letterx, Vec3f(-10, 7 + (i-1)*10, -5.0))
end

mlazaro = mesh!(ax, Rect3f(Vec3f(-0.5,-0.5,-1.0), Vec3f(1.5, 2, 0.25));
    color=thandle', material=RPR.DiffuseMaterial(matsys))
RPRMakie.rotate!(mlazaro, Vec3f(0, 0, 1), -π/2) # Quaternionf(0, 0.0, 0, -1)
translate!(mlazaro, Vec3f(-11, 40.5, -4.5))

GLMakie.activate!()
zoom!(ax.scene, cameracontrols(ax.scene), 0.36)
cam = cameracontrols(ax.scene)
cam.eyeposition[] = Vec3f(-70.38632, 46.678234, 45.849705)
cam.lookat[] = Vec3f(-0.80685806, 20.650236, -1.1407485)
#cam.zoom_mult[] = 0.37565738f0
display(fig)
context, task = RPRMakie.replace_scene_rpr!(ax.scene, screen)
nothing # avoid printing stuff into the repl
imageOut = colorbuffer(screen)
save("./imgs/helix.png", imageOut) # save just screen scene.
#saveRPR("./imgs/helix", imageOut,  resolution=(900, 900))
