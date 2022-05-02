using LinearAlgebra, Random, GLMakie
using RPRMakie, RadeonProRender, Colors
using FileIO

x = y = z = -1:0.01:1
vol1 = [ix * iy * iz for ix in x, iy in y, iz in z]
cmap = :Hiroshige
#img = [colorant"grey30" for i in 1:1, j in 1:1]
img = load("./lights/envLightImage.exr") 
lights = [EnvironmentLight(1.0, img'), PointLight(Vec3f(2,2,2.0), RGBf(10.0, 10.0, 10.0))]
plane = Rect3f(Vec3f(-5,-2,-1.2), Vec3f(10,4,0.05))

fig = Figure(; resolution=(1000, 1000))
ax = LScene(fig[1, 1]; show_axis=false, scenekw=(lights=lights,))
screen=RPRMakie.RPRScreen(size(ax.scene); plugin=RPR.Northstar, iterations=450)
matsys=screen.matsys

volume!(ax, x, y, z, vol1; colormap = cmap, algorithm=:mip, absorption=4f0, 
    material=RPR.VolumeMaterial(matsys))
mesh!(ax, plane; color=:gainsboro, material=RPR.DiffuseMaterial(matsys))

GLMakie.activate!()
cam = cameracontrols(ax.scene)
cam.eyeposition[] = Vec3f(3,3,1.5)
display(fig)
context, task = RPRMakie.replace_scene_rpr!(ax.scene, screen)
nothing # avoid printing stuff into the repl
#imageOut = colorbuffer(screen)
#save("./imgs/volumeM_clean.png", imageOut) # save just screen scene.
#saveRPR("./imgs/volumeM", imageOut,  resolution=(900, 900))
