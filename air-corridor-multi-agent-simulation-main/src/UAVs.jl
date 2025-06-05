module UAVs
export Drone, agent_step!, drone_marker

using Agents, Agents.Pathfinding
using Random, LinearAlgebra
using CairoMakie



@agent struct Drone(ContinuousAgent{2,Float64})
    speed::Float64
    cohere_factor::Float64
    separation::Float64
    separate_factor::Float64
    match_factor::Float64
    visual_distance::Float64
    way_points::Vector{Vector{Float64}}
    way_point_index::Integer
end


function agent_step!(drone, model)
    # Obtain the ids of neighbors within the drone's visual distance
    neighbor_ids = nearby_ids(drone, model, drone.visual_distance)
    N = 0
    match = separate = cohere = (0.0, 0.0)
    # Calculate behaviour properties based on neighbors
    for id in neighbor_ids
        N += 1
        neighbor = model[id].pos
        heading = get_direction(drone.pos, neighbor, model)

        # `cohere` computes the average position of neighboring drones
        cohere = cohere .+ heading
        if euclidean_distance(drone.pos, neighbor, model) < drone.separation
            # `separate` repels the drone away from neighboring drones
            separate = separate .- heading
        end
        # `match` computes the average trajectory of neighboring drones
        match = match .+ model[id].vel
    end
    N = max(N, 1)
    # Normalise results based on model input and neighbor count
    # cohere = cohere ./ N .* drone.cohere_factor
    separate = separate ./ N .* drone.separate_factor
    match = match ./ N .* drone.match_factor
    # Compute velocity based on rules defined above
    drone.vel = (drone.vel .+ cohere .+ separate .+ match) ./ 2
    drone.vel = drone.vel ./ norm(drone.vel)
    # Move drone according to new velocity and speed
    move_agent!(drone, model, drone.speed)
end


const drone_polygon = Makie.Polygon(Point2f[(-1, -1), (2, 0), (-1, 1)])
function drone_marker(b::Drone)
    φ = atan(b.vel[2], b.vel[1]) #+ π/2 + π
    rotate_polygon(drone_polygon, φ)
end


end # module