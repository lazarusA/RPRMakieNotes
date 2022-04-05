using GLMakie
using FileIO, Downloads
link = "https://upload.wikimedia.org/wikipedia/commons/c/c3/Solarsystemscope_texture_2k_earth_daymap.jpg"
earth_img = load(Downloads.download(link))
fig = Figure(resolution=(1600, 1200))
ax1 = LScene(fig[1, 1]; show_axis = false)
ax2 = LScene(fig[1, 2]; show_axis = false)
s1 = mesh!(ax1, Sphere(Point3f(0), 1), color=earth_img)
s2 = mesh!(ax2, Sphere(Point3f(0, 2.1, 0), 1), color=earth_img)
#rotate!(ax1.scene, 3.5π)
#rotate!(ax2.scene, 3.5π)
fig