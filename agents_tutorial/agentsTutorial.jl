using Agents

#space instance
# size = (20, 20)
# space = GridSpaceSingle(size; periodic = false, metric = :chebyshev)

#agent (types) participating in simulation
@agent struct SchellingAgent(GridAgent{2})
    mood::Bool = false
    group::Int
end

#print details
# for (name, type) in zip(fieldnames(SchellingAgent), fieldtypes(SchellingAgent))
#     println(name, "::", type)
# end

# example_agent = SchellingAgent(id = 1, pos = (2, 3), mood = true, group = 1)


#agent stepping function for Schelling model
#called for every schdeuled agent (model_step! only calls once per simulation step)

function schelling_step!(agent, model)
    minhappy = model.min_to_be_happy
    count_neighbors_same_group = 0
    for neighbor in nearby_agents(agent, model)
        if agent.group == neighbor.group
            count_neighbors_same_group +=1
        end
    end

    if count_neighbors_same_group >= minhappy
        agent.mood = true
    else
        agent.mood = false
        move_agent_single!(agent, model) #moves agent to random empty position on grid
    end
    return
end

#define model-level properties
properties = Dict(:min_to_be_happy => 3)

#scheduler, activate agents according to property (group)
# scheduler = Schedulers.ByProperty(:group)

# model = StandardABM(
#     # input arguments
#     SchellingAgent, space;
#     # keyword arguments
#     properties, # in Julia if the input variable and keyword are named the same,
#                 # you don't need to repeat the keyword!
#     agent_step! = schelling_step!,
#     scheduler,
# )

# nagents(schelling) obtains # of agents in model

# using Random: Xoshiro

function initialize(; total_agents = 320, gridsize = (20,20), min_to_be_happy = 3, seed = 125)
    space = GridSpaceSingle(gridsize; periodic = false)
    properties = Dict(:min_to_be_happy => min_to_be_happy)
    rng = Xoshiro(seed)
    model = StandardABM(
        SchellingAgent, space;
        agent_step! = schelling_step!, properties, rng,
        container = Vector, #agents not removed
        scheduler = Schedulers.Randomly() #activated all at once randomly
    )
    #populate model w/ agents
    for n in 1:total_agents
        add_agent_single!(model; mood = false, group = n < total_agents/2 ? 1 : 2)
    end
    return model
end

schelling = initialize();

# step!(schelling) 
#progresses simulation for one step. 
#for # of steps: step!(schelling, #)

#to progress until current model time evaluates to true: ex 90% happy agents
# happy90(model, time) = count(a -> a.mood == true, allagents(model))/nagents(model) ≥ 0.9
# step!(schelling, happy90)

#abmtime(schelling) counts steps taken so far




#### Visualization
using CairoMakie # choosing a plotting backend

groupcolor(a) = a.group == 1 ? :blue : :orange
groupmarker(a) = a.group == 1 ? :circle : :rect

figure, _ = abmplot(schelling; agent_color = groupcolor, agent_marker = groupmarker, agent_size = 10)
figure # returning the figure displays it

abmvideo(
    "schelling.mp4", schelling;
    agent_color = groupcolor, agent_marker = groupmarker, as = 10,
    framerate = 4, frames = 20,
    title = "Schelling's segregation model"
)


#### data collection
# run the model for 5 steps, and collect data.
# The data to collect are given as a vector of tuples: 1st element of tuple is
# what property, or what function of agent -> data, to collect. 2nd element
# is how to aggregate the collected property over all agents in the simulation


using Statistics: mean
xpos(agent) = agent.pos[1]
adata = [(:mood, sum), (xpos, mean)]
adf, mdf = run!(model, 5; adata)
adf # a Julia `DataFrame`