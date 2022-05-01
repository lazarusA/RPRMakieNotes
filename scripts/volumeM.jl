using LinearAlgebra, Random, GLMakie
using RPRMakie, RadeonProRender, Colors

x = y = z = -1:0.2:1
vol1 = [ix * iy * iz for ix in x, iy in y, iz in z]
cmap = :Hiroshige
img = [colorant"grey90" for i in 1:1, j in 1:1]
lights = [EnvironmentLight(1.0, img'), PointLight(Vec3f(2,0,2.0), RGBf(8.0, 6.0, 5.0))]

fig = Figure(; resolution=(1000, 1000))
ax = LScene(fig[1, 1]; show_axis=false, scenekw=(lights=lights,))
screen=RPRMakie.RPRScreen(size(ax.scene); plugin=RPR.Northstar, iterations=4500)
volume!(ax, x, y, z, vol2; colormap = cmap)

GLMakie.activate!()
display(fig)
context, task = RPRMakie.replace_scene_rpr!(ax.scene, screen)
