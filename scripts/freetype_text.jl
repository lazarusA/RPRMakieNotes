using GeometryBasics
using RPRMakie, RadeonProRender
using LinearAlgebra, Colors, FileIO
using DelimitedFiles
using Colors: HSV

function azelrad(azim, elev, radius)
    x = radius * cosd(elev) * cosd(azim)
    y = radius * cosd(elev) * sind(azim)
    z = radius * sind(elev)
    Vec3f(x, y, z)
end

function arealight!(ax, matsys; azim, elev, radius, lookat, size, color)
    rect = Rect2f(-size/2, size)
    color_intensity_adjusted = lift(convert(Observable, color), convert(Observable, size)) do color, size
        Makie.to_color(color) ./ *(size...)
    end
    m = mesh!(ax, rect, material = RPR.EmissiveMaterial(matsys), color = color_intensity_adjusted)

    q = Makie.rotation_between(Vec3f(0, 0, 1), -azelrad(azim, elev, 1))
    Makie.rotate!(m, q)
    Makie.translate!(m, azelrad(azim, elev, radius) + lookat)
    return m
end

function transf!(x, position, scale, azim, elev)
    q = Makie.rotation_between(Vec3f(0, 0, 1), -azelrad(azim, elev, 1))
    Makie.rotate!(x, q)
    Makie.scale!(x, scale)
    Makie.translate!(x, position)
    return
end

using RPRMakie.Makie.FreeTypeAbstraction

# this is on master already in normal conversion form for PointBased
function copied_convert_arguments(b::BezierPath)
    b2 = Makie.replace_nonfreetype_commands(b)
    points = Point2f[]
    last_point = Point2f(NaN)
    last_moveto = false

    function poly3(t, p0, p1, p2, p3)
        Point2f((1-t)^3 .* p0 .+ t*p1*(3*(1-t)^2) + p2*(3*(1-t)*t^2) .+ p3*t^3)
    end

    for command in b2.commands
        if command isa Makie.MoveTo
            last_point = command.p
            last_moveto = true
        elseif command isa Makie.LineTo
            if last_moveto
                isempty(points) || push!(points, Point2f(NaN, NaN))
                push!(points, last_point)
            end
            push!(points, command.p)
            last_point = command.p
            last_moveto = false
        elseif command isa Makie.CurveTo
            if last_moveto
                isempty(points) || push!(points, Point2f(NaN, NaN))
                push!(points, last_point)
            end
            last_moveto = false
            for t in range(0, 1, length = 30)[2:end]
                push!(points, poly3(t, last_point, command.c1, command.c2, command.p))
            end
            last_point = command.p
        end
    end
    return points
end

function make_polypath(points, tags)
    isbitset(x, i) = x & (1 << (i - 1)) != 0
    iscontrolpoint(tag) = !isbitset(tag, 1)
    iscubic(tag) = isbitset(tag, 2)

    points = map(points) do point
        Point(point.x, point.y) ./ 4 # TODO: why is this divisor necessary?
    end

    commands = []

    k = 1
    while k <= length(points)
        if k == 1
            iscontrolpoint(tags[k]) && error("Expected moveto")
            push!(commands, Makie.MoveTo(points[k]))
            k += 1
            continue
        else
            if iscontrolpoint(tags[k]) && iscubic(tags[k])
                c1 = points[k]
                @assert iscontrolpoint(tags[k+1])
                @assert iscubic(tags[k+1])
                c2 = points[k+1]
                if k+2 == length(points)+1
                    p = (commands[1]::Makie.MoveTo).p
                else
                    @assert !iscontrolpoint(tags[k+2])
                    p = points[k+2]
                end
                push!(commands, Makie.CurveTo(c1, c2, p))
                k += 3
                continue
            else
                error("Invalid")
            end
        end
    end
    push!(commands, Makie.ClosePath())

    bp = Makie.BezierPath(commands)
    points = copied_convert_arguments(bp)
    
    return points
end

function RPRMakie.to_rpr_object(context, matsys, scene, plot::Makie.Text{Tuple{Vector{Makie.GlyphCollection}}})
    
    gc = to_value(plot[1])[]

    polygons = GeometryBasics.Polygon[]
    Makie.broadcast_foreach(gc.glyphs, gc.fonts, gc.origins, gc.scales) do gl, fo, ori, scale
        glyph = FreeTypeAbstraction.loadglyph(fo, gl, 64)
        n_points = glyph.outline.n_points
        n_contours = glyph.outline.n_contours
        points = unsafe_wrap(Vector{FT_Vector_}, glyph.outline.points, n_points)
        tags = unsafe_wrap(Vector{Int8}, glyph.outline.tags, n_points)
        contours = unsafe_wrap(Vector{Int16}, glyph.outline.contours, n_contours)
        paths = Vector{Point2f}[]
        for (start, stop) in zip([1; contours[1:end-1] .+ 2], contours .+ 1)
            ppath = make_polypath(points[start:stop], tags[start:stop])
            ppath_transf = map(ppath) do point
                p = point ./ fo.units_per_EM # scale glyph to unit space
                p .* scale + Point2f(ori) # TODO: origin z component needed or not?
            end
            push!(paths, ppath_transf)
        end
        isempty(paths) && return # spaces for example
        # assume for now that the outer outline comes first
        polygon = GeometryBasics.Polygon(paths[1], paths[2:end]) # TODO: this is not quite correct yet, for example an `i` doesn't work because it has two separate contours
        push!(polygons, polygon)
    end


    meshes = map(Makie.triangle_mesh, polygons)
    msh = merge(meshes)
    rpr_mesh = RPR.Shape(context, msh)
    # material = RPRMakie.mesh_material(context, matsys, plot)
    material = RPRMakie.extract_material(matsys, plot)

    color = if gc.colors.sv isa Vector
        u = unique(gc.colors.sv)
        length(u) > 1 && error("Currently only a single color per text works")
        only(u)
    else
        gc.colors.sv
    end

    if !isnothing(color) && hasproperty(material, :color)
        material.color = color
    end
    map(plot.model) do m
        RPR.transform!(rpr_mesh, m)
    end
    set!(rpr_mesh, material)

    return rpr_mesh
end
  

begin
    RPRMakie.activate!(resource=RPR.RPR_CREATION_FLAGS_ENABLE_CPU,
        plugin=RPR.Northstar, iterations=5)
    # background/sky color
    img = [HSV(210,0.5,0.4) for i in 1:1, j in 1:1]
    img = [colorant"gray90" for i in 1:1, j in 1:1]

    # color as an array/image, hence a normal image also works
    lights = [
        EnvironmentLight(1.0, img'),
        # PointLight(azelrad(185, 42, 50), 5000 .* RGBf(HSV(-20,1,1))),
        # PointLight(azelrad(0, 45, 5), 10 .* RGBf(1, 1, 1)),
        # PointLight(azelrad(270, 45, 5), 70 .* RGBf(1, 0.5, 0.5)),
    ]
    
    plane = Rect3f(Vec3f(-0.5, -0.5, -0.0025), Vec3f(1, 1, 0.005))
    
    fig = Figure(; resolution=(900, 900))
    ax = LScene(fig[1, 1]; show_axis=false, scenekw=(; lights=lights))
    screen = RPRMakie.Screen(ax.scene)
    matsys = screen.matsys

    m = mesh!(ax, plane, material = RPR.DiffuseMaterial(matsys), color = :gray30)
    transf!(m, Point3f(0, 0, -0.2), Vec3f(10), 0, 90)

    # m = mesh!(ax, plane, material = RPR.DiffuseMaterial(matsys), color = :gray80)
    # transf!(m, Point3f(0, 0, 2), Vec3f(4), 0, 90)

    # m = mesh!(ax, plane, material = RPR.DiffuseMaterial(matsys), color = :gray80)
    # transf!(m, Point3f(0, -2, 0), Vec3f(4), 90, 0)

    # m = mesh!(ax, plane, material = RPR.DiffuseMaterial(matsys), color = :gray80)
    # transf!(m, Point3f(0, 2, 0), Vec3f(4), 90, 0)

    # m = mesh!(ax, plane, material = RPR.DiffuseMaterial(matsys), color = :gray80)
    # transf!(m, Point3f(-2, 0, 0), Vec3f(4), 180, 0)

    t = text!(ax, 0, 0, text = "Hello you", fontsize = 1, space = :data,
        align = (:center, :center),
        material = RPR.Glass(matsys),
        color = :red,
    )
    transf!(t, Point3f(0), Vec3f(1), 30, -90)

    arealight!(ax, matsys;
        azim = 90,
        elev = 30,
        radius = 2,
        lookat = Vec3f(0, 0, 0),
        size = Vec2f(2, 2),
        color = 10 .* RGBf(1, 1, 1)
    )

    azimuth = -90
    elevation = 70
    nearclip = 0.001
    perspectiveness = 0.3
    zoom = 0.8
    lookat = Vec3f(0.0, 0.0, 0.0)

    ang_max = 90
    ang_min = 0.5

    @assert 0.1 <= perspectiveness <= 1
    angle = ang_min + (ang_max - ang_min) * perspectiveness

    cam_distance = sqrt(3) / sind(angle / 2)
    farclip = 2 * cam_distance
    cam = cameracontrols(ax.scene)
    cam.lookat[] = lookat
    cam.eyeposition[] = lookat + azelrad(azimuth, elevation, cam_distance)
    cam_forward = normalize(lookat - cam.eyeposition[])
    world_up = Vec3f(0, 0, 1)
    cam_right = cross(cam_forward, world_up)
    cam.upvector[] = cross(cam_right, cam_forward)
    cam.fov[] = angle / zoom
    cam.near[] = nearclip
    cam.far[] = farclip
    screen
end
