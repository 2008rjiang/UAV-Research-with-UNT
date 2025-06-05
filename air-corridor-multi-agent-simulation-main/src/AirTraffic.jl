module AirTraffic

using Agents
using UAVs
using Random

export initialize_model


function initialize_model(
    n_drones = 100,
    speed = 1.5,
    cohere_factor = 0.1,
    separation = 2.0,
    separate_factor = 0.25,
    match_factor = 0.04,
    visual_distance = 5.0,
    extent = (100, 100),
    seed = 42
    )

    way_points = [[0,0], [30, 50], [70, 50], [100, 100]]
    way_point_index = 1

    space2d = ContinuousSpace(extent; spacing = visual_distance/1.5)
    rng = Random.MersenneTwister(seed)

    model = StandardABM(Drone, space2d; rng, agent_step!, scheduler = Schedulers.Randomly())
    
    for _ in 1:n_drones
        vel = rand(abmrng(model), SVector{2}) * 2 .- 1
        add_agent!(
            model,
            vel,
            speed,
            cohere_factor,
            separation,
            separate_factor,
            match_factor,
            visual_distance,
            way_points,
            way_point_index
        )
    end
    return model
end


# The function takes a d-dimensional tensor with n elements in each dimensions
# and a d-dimensional convolution filter of size k in each dimension.
# the function applies the convolution to the grid 

function grid_convolution(grid::Array{T,D}, filter::Array{T,D}; padding="VALID") where {T,D}
    # Get dimensions of input grid and filter
    grid_size = size(grid)
    filter_size = size(filter)
    
    # Verify filter dimensions don't exceed grid dimensions
    all(filter_size .<= grid_size) || throw(ArgumentError("Filter size must not exceed grid size"))
    
    if padding == "VALID"
        # Calculate output dimensions for valid padding
        output_size = tuple([grid_size[i] - filter_size[i] + 1 for i in 1:D]...)
        
        # Initialize output array
        output = zeros(T, output_size)
        
        # Generate cartesian indices for sliding window
        ranges = [1:(grid_size[d] - filter_size[d] + 1) for d in 1:D]
        window_positions = CartesianIndices(ranges)
        
        # Perform convolution
        for pos in window_positions
            # Extract window from grid
            window_ranges = [pos[d]:(pos[d] + filter_size[d] - 1) for d in 1:D]
            window = grid[window_ranges...]
            
            # Compute convolution at this position
            output[pos] = sum(window .* filter)
        end
        
    elseif padding == "SAME"
        # Output size same as input
        output_size = grid_size
        output = zeros(T, output_size)
        
        # Calculate padding for each dimension
        pad_sizes = [(filter_size[d] - 1) ÷ 2 for d in 1:D]
        
        # Pad the input grid
        padded_grid = copy(grid)
        for d in 1:D
            pad_dim = zeros(Int, D)
            pad_dim[d] = pad_sizes[d]
            padded_grid = padarray(padded_grid, pad_dim)
        end
        
        # Generate cartesian indices for sliding window
        window_positions = CartesianIndices(output_size)
        
        # Perform convolution
        for pos in window_positions
            # Calculate window position in padded grid
            padded_pos = pos.I .+ pad_sizes
            
            # Extract window from padded grid
            window_ranges = [padded_pos[d]:(padded_pos[d] + filter_size[d] - 1) for d in 1:D]
            window = padded_grid[window_ranges...]
            
            # Compute convolution at this position
            output[pos] = sum(window .* filter)
        end
    else
        throw(ArgumentError("Padding must be either 'VALID' or 'SAME'"))
    end
    
    return output
end

# Helper function to pad arrays
function padarray(arr::Array{T,D}, pad_sizes) where {T,D}
    # Calculate new dimensions
    new_size = size(arr) .+ (2 .* pad_sizes)
    
    # Create padded array
    padded = zeros(T, new_size)
    
    # Calculate ranges for original array placement
    ranges = [pad_sizes[d]+1:pad_sizes[d]+size(arr,d) for d in 1:D]
    
    # Copy original array to padded array
    padded[ranges...] = arr
    
    return padded
end



# # 2D example
# grid2d = rand(5,5)
# filter2d = ones(2,2)
# result = grid_convolution(grid2d, filter2d, padding="VALID")

# # 3D example
# grid3d = rand(4,4,4)
# filter3d = ones(2,2,2)
# result3d = grid_convolution(grid3d, filter3d, padding="SAME")


end