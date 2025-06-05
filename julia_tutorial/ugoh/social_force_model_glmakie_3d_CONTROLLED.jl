using GLMakie
using PlotUtils
using Observables
using GeometryBasics: Point3f, Vec3f

# Simulation parameters (initial values and ranges)
initial_N = 50                             # initial number of agents
initial_A = 8.0f0                          # initial repulsion strength
initial_B = 3.0f0                          # initial repulsion range
desired_speed = 2.0f0                      # preferred speed towards goal
relaxation_time = 0.5f0                    # tau: how quickly velocity adjusts to desired
dt = 0.03f0                                # time step for integration (seconds per frame)

# Create figure and 3D axis
fig = Figure(resolution=(1200, 900))
ax = Axis3(fig[1, 1], title="3D Social Force Model", 
           limits = ((-15, 15), (-15, 15), (-15, 15)))  # fixed axis limits for visibility

# Define UI controls
play_pause_state = Observable(false)   # `false` = paused, `true` = running
btn_play = Button(fig[2, 1], label = @lift($play_pause_state ? "Pause" : "Play"))
btn_reset = Button(fig[2, 2], label = "Reset")

# Sliders for N, A, B with labels
slider_N = Slider(fig[3, 1], range = 1:1:100, startvalue = initial_N)
label_N  = Label(fig[3, 2], "Number of Agents")
slider_A = Slider(fig[4, 1], range = 0.0f0:0.5f0:20.0f0, startvalue = initial_A)
label_A  = Label(fig[4, 2], "Repulsion A")
slider_B = Slider(fig[5, 1], range = 0.1f0:0.1f0:10.0f0, startvalue = initial_B)
label_B  = Label(fig[5, 2], "Repulsion B")

# Observable state for agent positions and speeds (for coloring)
positions = Observable(Vector{Point3f}())   # will hold Vector of Point3f (agent positions)
speeds    = Observable(Vector{Float32}())   # will hold Vector of speed magnitudes
# Other state variables (velocities and goals) kept as global variables for update logic
velocities = Vector{Vec3f}(undef, 0)        # will be resized to length N
goals      = Vector{Point3f}(undef, 0)      # goal positions for agents
current_N  = 0                              # current number of agents (updated on reset)

# Function to (re)initialize agents and goals
function reset_simulation!()
    global current_N
    current_N = Int(slider_N.value[])  # get desired N from slider
    # Reinitialize agent positions in a small cluster around origin (e.g., within [-0.5, 0.5]^3)
    local new_positions = [Point3f( (rand() - 0.5) * 1.0,   # 1.0 span (±0.5) in x
                                    (rand() - 0.5) * 1.0,   # y
                                    (rand() - 0.5) * 1.0 )  # z
                            for i in 1:current_N]
    # Initialize velocities to zero
    global velocities = [Vec3f(0, 0, 0) for i in 1:current_N]
    # Assign random goal positions at some distance (e.g., 5 to 10 units away from origin)
    global goals = Point3f[]  # reset goals vector
    for i in 1:current_N
        # pick a random direction (normalize a random vector)
        local vx, vy, vz = randn(), randn(), randn()
        local norm = sqrt(vx^2 + vy^2 + vz^2)
        vx /= norm;  vy /= norm;  vz /= norm
        # pick a random distance in [5, 10]
        local dist = 5 + 5 * rand()
        push!(goals, Point3f(vx * dist, vy * dist, vz * dist))
    end
    # Set initial speeds (all zeros)
    local new_speeds = fill(0.0f0, current_N)
    # Update the observables
    positions[] = new_positions
    speeds[]    = new_speeds
end

# Initialize the simulation with initial parameters
slider_N.value[] = initial_N  # ensure slider reflects initial_N
slider_A.value[] = initial_A
slider_B.value[] = initial_B
reset_simulation!()           # populate initial positions, velocities, goals

# Plot: scatter points for agents, colored by speed (blue=slow, red=fast)
scatter!(ax, positions, color = speeds,
         colormap = PlotUtils.cgrad([:blue, :red]),  # continuous gradient from blue to red
         colorrange = (0, 5),    # map speed 0 -> blue, speed 5 (or above) -> red
         markersize = 8, strokewidth = 0)

# Button interactions
on(btn_play.clicks) do _
    play_pause_state[] = !play_pause_state[]   # toggle running state
end

on(btn_reset.clicks) do _
    play_pause_state[] = false                 # pause the simulation when resetting
    reset_simulation!()                        # reinitialize agents and goals
end

# Main simulation loop (runs asynchronously)
@async begin
    # Error handling wrapper (optional) to catch exceptions in async task
    try
        while true
            if play_pause_state[]
                # Only update positions when running
                # Fetch current parameter values from sliders
                local A_val = Float32(slider_A.value[])
                local B_val = Float32(slider_B.value[])
                # Compute new positions and velocities
                # Copy current state to avoid modifying while computing new state
                local pos = positions[]               # current positions (Vector{Point3f})
                local new_positions = similar(pos)    # array to store updated positions
                local new_speeds = Vector{Float32}(undef, current_N)
                # Loop over each agent for force calculations
                for i in 1:current_N
                    # Driving force toward goal
                    local p_i = pos[i]
                    local v_i = velocities[i]
                    local goal_i = goals[i]
                    # Compute desired velocity towards goal_i
                    local goal_dir = goal_i - p_i                      # vector from agent to goal
                    local dist_to_goal = sqrt(sum(abs2, goal_dir))    # Euclidean distance
                    if dist_to_goal > 0
                        goal_dir /= dist_to_goal                      # normalize direction
                    end
                    # If agent is very close to goal, assign a new random goal (to keep moving)
                    if dist_to_goal < 1.0f0
                        # pick a new random goal (similar method as initialization)
                        local vx, vy, vz = randn(), randn(), randn()
                        local norm = sqrt(vx^2 + vy^2 + vz^2)
                        vx /= norm;  vy /= norm;  vz /= norm
                        local dist = 5 + 5 * rand()
                        goals[i] = Point3f(vx * dist, vy * dist, vz * dist)
                        goal_dir = goals[i] - p_i
                        dist_to_goal = sqrt(sum(abs2, goal_dir))
                        goal_dir /= dist_to_goal
                    end
                    local desired_vel = desired_speed * goal_dir      # desired velocity vector
                    local driving_acc = (desired_vel - v_i) / relaxation_time  # acceleration to v0

                    # Repulsive force from other agents
                    local rep_force = Vec3f(0, 0, 0)
                    for j in 1:current_N
                        if j == i; continue; end
                        local r_ij = p_i - pos[j]
                        local d = sqrt(sum(abs2, r_ij))
                        if d > 1e-6
                            # Compute repulsive force magnitude (A * exp(-d/B))
                            local f_mag = A_val * exp(-d / B_val)
                            # Add to repulsive force (direction from j to i is r_ij normalized)
                            rep_force += (f_mag / d) * r_ij
                        end
                    end

                    # Total acceleration = driving + repulsion (no explicit friction term beyond driving)
                    local total_acc = driving_acc + rep_force
                    # Update velocity and position (Euler integration)
                    v_i += total_acc * dt
                    local new_pos = p_i + v_i * dt
                    # (If desired, could handle boundary conditions or keep within limits here)

                    # Store updates
                    velocities[i] = v_i
                    new_positions[i] = new_pos
                    new_speeds[i] = sqrt(sum(abs2, v_i))   # speed magnitude for color
                end

                # Apply the computed updates to observables
                positions[] = new_positions
                speeds[]    = new_speeds
            end
            sleep(dt)  # wait for next frame (controls simulation frame rate)
        end
    catch e
        @warn "Simulation loop terminated: $e"
    end
end

# Display the figure and start the interactive session
screen = display(fig)
# Block the Julia script from exiting until the GLMakie window is closed
if isinteractive()
    println("Interactive mode: Figure displayed. Adjust parameters and press Play.")
else
    wait(screen)
end