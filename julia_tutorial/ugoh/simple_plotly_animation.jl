using PlotlyJS

# Agent coordinates (fixed in 3D space)
N = 10
x = rand(N) .* 10
y = rand(N) .* 10
z = rand(N) .* 10

# Format hover text for each agent
hover_labels = ["Agent $i<br>x=$(round(x[i], digits=2))<br>y=$(round(y[i], digits=2))<br>z=$(round(z[i], digits=2))" for i in 1:N]

# Create 3D scatter plot
trace = scatter3d(
    x = x, y = y, z = z,
    mode = "markers",
    text = hover_labels,
    hoverinfo = "text",
    marker = attr(size = 8, color = "blue")
)

layout = Layout(
    title = "Fixed 3D Agent Space with Hover Info",
    scene = attr(
        xaxis = attr(title = "X", range = [0, 10]),
        yaxis = attr(title = "Y", range = [0, 10]),
        zaxis = attr(title = "Z", range = [0, 10]),
        aspectmode = "cube"
    )
)

plot(trace, layout)