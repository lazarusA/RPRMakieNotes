# by Lazaro Alonso
# port from the original code used in:
# L Alonso, et. al. https://doi.org/10.1093/comnet/cnx053

using LinearAlgebra, Random, GLMakie
using RPRMakie, RadeonProRender, Colors
include("saveRPR.jl")

function RRGAdjacencyM3D(; radius = 0.17, nodes = 500, rseed = 123)
    Random.seed!(rseed)
    xy = rand(nodes, 3)
    x = xy[:, 1]
    y = xy[:, 2]
    z = xy[:, 3]

    matrixAdjDiag = Diagonal(√2 * randn(nodes))
    matrixAdj = zeros(nodes, nodes)
    for point in 1:nodes-1
        xseps = (x[point+1:end] .- x[point]) .^ 2
        yseps = (y[point+1:end] .- y[point]) .^ 2
        zseps = (z[point+1:end] .- z[point]) .^ 2

        distance = sqrt.(xseps .+ yseps .+ zseps)
        dindx = findall(distance .<= radius) .+ point
        if length(dindx) > 0
            rnd = randn(length(dindx))
            matrixAdj[point, dindx] = rnd
            matrixAdj[dindx, point] = rnd
        end
    end
    return (matrixAdj .+ matrixAdjDiag, x, y, z)
end
adjacencyM3D, x, y, z = RRGAdjacencyM3D()

function getGraphEdges3D(adjMatrix3D, x, y, z)
    xyzos = []
    weights = []
    for i in 1:length(x), j in i+1:length(x)
        if adjMatrix3D[i, j] != 0.0
            push!(xyzos, [x[i], y[i], z[i]])
            push!(xyzos, [x[j], y[j], z[j]])
            push!(weights, adjMatrix3D[i, j])
            push!(weights, adjMatrix3D[i, j])
        end
    end
    return (Point3f.(xyzos), Float32.(weights))
end


cmap = (:Hiroshige, 0.75)
adjmin = minimum(adjacencyM3D)
adjmax = maximum(adjacencyM3D)
diagValues = diag(adjacencyM3D)
segm, weights = getGraphEdges3D(adjacencyM3D, x, y, z)

img = [colorant"grey90" for i in 1:1, j in 1:1]
lights = [EnvironmentLight(1.0, img'), PointLight(Vec3f(2,0,2.0), RGBf(8.0, 6.0, 5.0))]
plane = Rect3f(Vec3f(-5,-2,-1.05), Vec3f(10,4,0.05))

fig = Figure(; resolution=(1000, 1000))
ax = LScene(fig[1, 1]; show_axis=false, scenekw=(lights=lights,))
screen=RPRMakie.RPRScreen(size(ax.scene); plugin=RPR.Northstar, iterations=4500)
matsys=screen.matsys

linesegments!(ax, segm; color = weights, colormap = cmap,
    linewidth = abs.(weights), colorrange = (adjmin, adjmax))
meshscatter!(ax, x, y, z; color = diagValues, markersize = abs.(diagValues) ./ 90,
    colorrange = (adjmin, adjmax), colormap = cmap)
mesh!(ax, plane; color=:gainsboro, material=RPR.DiffuseMaterial(matsys))
fig

GLMakie.activate!()
cam = cameracontrols(ax.scene)
cam.eyeposition[] = Vec3f(1.8,1.8,1.5)
display(fig)
context, task = RPRMakie.replace_scene_rpr!(ax.scene, screen)
nothing # avoid printing stuff into the repl
imageOut = colorbuffer(screen)
save("./imgs/rrg_clean.png", imageOut) # save just screen scene.
saveRPR("./imgs/rrg", imageOut,  resolution=(900, 900))

