## by Lazaro Alonso
using GLMakie, GeometryBasics
using RPRMakie, RadeonProRender
using LinearAlgebra, Colors, FileIO, Downloads
using CSV, DataFrames
include("saveRPR.jl")

urlimg = "https://upload.wikimedia.org/wikipedia/commons/9/96/NASA_bathymetric_world_map.jpg"
earth_img = load(Downloads.download(urlimg))

## https://earthquake.usgs.gov/earthquakes/map/?extent=-68.39918,-248.90625&extent=72.60712,110.74219
urldata = "https://github.com/lazarusA/BeautifulMakie/raw/main/_assets/data/"
file1 = Downloads.download(urldata * "2021_01_2021_05.csv")
file2 = Downloads.download(urldata * "2021_06_2022_01.csv")
earthquakes1 = DataFrame(CSV.File(file1))
earthquakes2 = DataFrame(CSV.File(file2))
earthquakes = vcat(earthquakes1, earthquakes2)

## depth unit, km
function toCartesian(lon, lat; r = 1.02, cxyz = (0, 0, 0))
    x = cxyz[1] + (r + 1500_000) * cosd(lat) * cosd(lon)
    y = cxyz[2] + (r + 1500_000) * cosd(lat) * sind(lon)
    z = cxyz[3] + (r + 1500_000) * sind(lat)
    return (x, y, z) ./ 1500_000
end

lons, lats = earthquakes.longitude, earthquakes.latitude
depth = earthquakes.depth
mag = earthquakes.mag
toPoints3D = [Point3f([toCartesian(lons[i], lats[i];
    r = -depth[i] * 1000)...]) for i in 1:length(lons)]
ms = (exp.(mag) .- minimum(exp.(mag))) ./ maximum(exp.(mag) .- minimum(exp.(mag)))

# background/sky color
img = [colorant"black" for i in 1:1, j in 1:1]
#img = load("./lights/envLightImage.exr") 
lights = [EnvironmentLight(1.0, img'[end:-1:1, :]), 
    PointLight(Vec3f(1,0.25,0.0), RGBf(65.0, 50.0, 35.0))]
#earth_img = load(Downloads.download("https://www.solarsystemscope.com/textures/download/8k_earth_daymap.jpg"))
function SphereTess(; o=Point3f(0), r=1, tess=64)
    return uv_normal_mesh(Tesselation(Sphere(o, r), tess))
end

fig=Figure(; resolution=(2160, 2160))
ax=LScene(fig[1, 1]; show_axis=false, scenekw=(;lights=lights))
screen=RPRMakie.RPRScreen(size(ax.scene); plugin=RPR.Northstar, iterations=5000)
matsys=screen.matsys
meshscatter!(ax, toPoints3D; markersize = ms / 20 .+ 0.001, color = mag,
    colormap = :nuuk) #Reverse(:linear_bmy_10_95_c78_n256))
#box
mesh!(ax, Rect3f(Vec3f(-1.1,-1.1,-1.25), Vec3f(0.05,2.35,2.35)); material=RPR.Glass(matsys))
mesh!(ax, Rect3f(Vec3f(-1.1,-1.1,-1.25), Vec3f(2.35,0.05,2.35)); material=RPR.Glass(matsys))
mesh!(ax, Rect3f(Vec3f(-1.1,-1.1,-1.25), Vec3f(2.35,2.35,0.05)); material=RPR.Glass(matsys))


GLMakie.activate!()
zoom!(ax.scene, cameracontrols(ax.scene), 0.95)
#cam.lookat[]= Vec3f(0.0, 0.0, 0.0)
#display(fig)
context, task = RPRMakie.replace_scene_rpr!(ax.scene, screen)
nothing # avoid printing stuff into the repl
imageOut = colorbuffer(screen)
save("./imgs/earthquakes_clean2.png", imageOut) # save just screen scene.
saveRPR("./imgs/earthquakes2", imageOut,  resolution=(2160, 2160))