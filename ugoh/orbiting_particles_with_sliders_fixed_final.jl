
using GLMakie
using GeometryBasics: Point3f
using Observables

# Number of particles
N = 100

# Initialize angle and radius sliders
angle_speed = Observable(0.05)
radius_scale = Observable(1.0)

# Create sliders and UI
fig = Figure(resolution = (1200, 900))
ax = Axis3(fig[1, 1], title = "Orbiting Particles with Sliders")
s1 = Slider(fig[2, 1], range = 0:0.01:0.2, startvalue = angle_speed[])
s2 = Slider(fig[3, 1], range = 0.5:0.1:3.0, startvalue = radius_scale[])
label1 = Label(fig[2, 2], "Angle Speed")
label2 = Label(fig[3, 2], "Radius Scale")

# Particle data
angles = [2π * i / N for i in 1:N]
radii = [rand() * 5 for _ in 1:N]
heights = [rand() * 2 for _ in 1:N]
positions = Observable([Point3f(r * cos(a), h, r * sin(a)) for (a, r, h) in zip(angles, radii, heights)])

# Particle color mapping with explicit colorrange
colors = Observable(radii)
scatterplot = scatter!(ax, positions[], color = colors[], markersize = 10, colormap = :viridis, colorrange = (0, 5))

# Animate particles
@async begin
    while true
        for i in 1:N
            angles[i] += angle_speed[]
            r = radii[i] * radius_scale[]
            h = heights[i]
            new_pos = Point3f(r * cos(angles[i]), h, r * sin(angles[i]))
            positions[][i] = new_pos
        end
        scatterplot[1][] = positions[]
        sleep(0.03)
    end
end

display(fig)
