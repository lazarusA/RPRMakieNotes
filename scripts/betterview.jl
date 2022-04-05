using GLMakie, MeshIO, GeometryBasics
using Colors
using FileIO, Downloads
#earth_img = load(Downloads.download("https://upload.wikimedia.org/wikipedia/commons/5/56/Blue_Marble_Next_Generation_%2B_topography_%2B_bathymetry.jpg"))

function gridpoints(; nstep=1, lo=-20, hi=20)
    x = y = lo:nstep:hi
    z = x' .* y * 0
    return (x, y, z)
end
x, y, z = gridpoints()
ps = [Point3f(0, 0, 0) for i in 1:6]
directions = [Point3f(1, 0, 0), Point3f(0, 1, 0), Point3f(0, 0, 1),
    Point3f(-1, 0, 0), Point3f(0, -1, 0), Point3f(0, 0, -1)]
colors = [
    RGB(0.082, 0.643, 0.918),
    RGB(0.91, 0.122, 0.361),
    RGB(0.929, 0.773, 0.0),
    RGBAf(0.082, 0.643, 0.918, 0.35),
    RGBAf(0.91, 0.122, 0.361, 0.35),
    RGBAf(0.929, 0.773, 0.0, 0.35)]

camobj = load("./Meshes/camera.obj")
lampobj = load("./Meshes/lamp.obj")
set_theme!()
fig = Figure(resolution=(2200, 1200), backgroundcolor=:grey90)
ax = LScene(fig[1:4, 1:3]; show_axis=false)
axnav = LScene(fig[1, 4]; show_axis=false)
axcam = LScene(fig[2, 4]; show_axis=false)

menu = Menu(fig, options=["A", "B", "C"])
fig[3, 4] = vgrid!(
    Label(fig, "Options", width=nothing),
    menu; tellheight=false, width=200)

# not to render
wireframe!(ax, x, y, z; color=(:black, 0.1),
    transparency=true)
lines!(ax, [Point3f(-20, 0, 0), Point3f(20, 0, 0)],
    color=colors[1], linewidth=2, transparency=true)
lines!(ax, [Point3f(0, -20, 0), Point3f(0, 20, 0)],
    color=colors[2], linewidth=2, transparency=true)
# up to here (leave them out)
msphere = mesh!(ax, Sphere(Point3f(0), 4);
    color=earth_img, transparency=false,
    lightposition=Vec3f(-10, 10, 20))
arrows!(axnav, ps, directions; color=colors, linewidth=0.02,
    arrowsize=Vec3f(0.16, 0.16, 0.2))
mobj = mesh!(axnav, Sphere(Point3f(0), 0.75); color=RGBAf(0.361, 0.722, 0.361, 0.4),
    transparency=true)
text!(axnav, ["X", "Y", "Z"],
    position=[Point3f(1.25, 0, 0), Point3f(0, 1.25, 0), Point3f(0, 0, 1.25)],
    align=(:center, :center), color=colors[1:3], textsize=22)
zoom!(ax.scene, cameracontrols(ax.scene), 0.5)
cam = cameracontrols(ax.scene)

lines!(axcam, [Point3f(cam.eyeposition[]...), Point3f(cam.lookat[]...)],
    transparency=true)

mesh_faces = decompose(TriangleFace{Int}, camobj)
mesh_vertices = decompose(Point{3,Float64}, camobj)
mesh_vadd = [(5 * m .+ cam.eyeposition[]) for m in mesh_vertices]
meshcam = GeometryBasics.Mesh(mesh_vadd, mesh_faces)
#r = [2, 2.0, 2]
objmesh = mesh!(axcam, meshcam; color=colors[5])
#scale!(objmesh, r[1], r[2], r[3])
surface!(axcam, x, y, z; colormap=([:black, colors[1]]),
    transparency=true)
#lamp
lamp_faces = decompose(TriangleFace{Int}, lampobj)
lamp_vertices = decompose(Point{3,Float64}, lampobj)
lamp_vadd = [(4 * m .+ msphere.attributes.lightposition[]) for m in lamp_vertices]
lampcam = GeometryBasics.Mesh(lamp_vadd, lamp_faces)
mesh!(axcam, lampcam, color=:orange, shading=false)
rotate!(axcam.scene, 2.5π)

camcam = cameracontrols(axcam.scene)
camnav = cameracontrols(axnav.scene)

onany(cam.upvector, cam.eyeposition, cam.lookat) do upvec, eye, la
    update_cam!(axcam.scene, camcam, eye, la, upvec)
    update_cam!(axnav.scene, camnav, eye, la, upvec)
end

on(menu.selection) do s
    #create and delte sliders depending on s
    sl_x = Slider(fig[4, 4], range=0:0.01:10, startvalue=3)
end
#save("./imgs/betterview.png", fig)
fig