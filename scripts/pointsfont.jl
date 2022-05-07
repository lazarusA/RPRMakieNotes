function pointsfont(letter; fs=60, sx=500, sy=500, shiftx=0, shifty=0)
    Drawing(500, 500)
    newpath()
    fontsize(fs)
    fontface("Mono")
    textpath(letter)
    pathspoints = pathtopoly()
    ymin = []
    xmin = []
    for pnts in pathspoints
        for p in pnts
            push!(ymin, -p[2])
            push!(xmin, p[1])
        end
    end
    ymin = minimum(ymin)
    xmin = minimum(xmin)
    path = Point2f[]
    for pnts in pathspoints
        tmp = [Point2f(p[1] - xmin + shiftx, -p[2] - ymin + shifty) for p in pnts]
        if length(pnts) > 1
            path = vcat(path, tmp)
            path = vcat(path, [tmp[1]])
        end
        path = vcat(path, [Point2f(NaN, NaN)])
    end
    return path
end

function poly_3d(points3d)
    xy = Point2f.(points3d)
    f = faces(GeometryBasics.Polygon(xy))
    return normal_mesh(Point3f.(points3d), f)
end

function getMesh(top_poly, bottom_poly)
    top = poly_3d(top_poly)
    bottom = poly_3d(bottom_poly)
    combined = merge([top, bottom])
    nvertices = length(top.position)
    connection = Makie.band_connect(nvertices)
    meshletter = GeometryBasics.Mesh(GeometryBasics.coordinates(combined), vcat(faces(combined), connection))
    return meshletter
end

function pointsfontLaxtex(letter; fs=60, sx=500, sy=500, shiftx=0, shifty=0)
    Drawing(500, 500)
    newpath()
    fontsize(fs)
    fontface("Mono")
    Luxor.text(letter, Luxor.Point(0,0), paths= true)
    #textpath(letter)
    pathspoints = pathtopoly()
    ymin = []
    xmin = []
    for pnts in pathspoints
        for p in pnts
            push!(ymin, -p[2])
            push!(xmin, p[1])
        end
    end
    ymin = minimum(ymin)
    xmin = minimum(xmin)
    path = Point2f[]
    for pnts in pathspoints
        tmp = [Point2f(p[1] - xmin + shiftx, -p[2] - ymin + shifty) for p in pnts]
        if length(pnts) > 1
            path = vcat(path, tmp)
            path = vcat(path, [tmp[1]])
        end
        path = vcat(path, [Point2f(NaN, NaN)])
    end
    return path
end