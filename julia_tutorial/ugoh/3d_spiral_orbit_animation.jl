
using GLMakie
using GeometryBasics: Point3f
using Observables

# Number of particles
N = 10
angles = Observable([2π * i / N for i in 1:N])
radii = [i for i in 1:N]
heights = [i for i in 1:N]
positions = [Observable(Point3f(r * cos(a), h, r * sin(a))) for (r, h, a) in zip(radii, heights, angles[])]

# Scene and axis
fig = Figure(resolution=(1200, 900))
ax = Axis3(fig[1, 1], title = "3D Spiral Orbit", perspectiveness=0.8)
points = [scatter!(ax, [pos[]], markersize=15) for pos in positions]

# Animation
@async begin
    while true
        for i in 1:N
            angles[][i] += 0.02
            r = radii[i]
            h = heights[i]
            new_pos = Point3f(r * cos(angles[][i]), h, r * sin(angles[][i]))
            positions[i][] = new_pos
            points[i][1][] = new_pos
        end
        sleep(0.03)
    end
end

display(fig)
