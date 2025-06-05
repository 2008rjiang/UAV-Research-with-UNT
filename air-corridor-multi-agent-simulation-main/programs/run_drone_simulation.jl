#!/Users/pmolnar/homebrew/Cellar/julia/1.10.2/bin/julia
####!/usr/bin/env julia
TITLE = raw"
  ____                         ____  _                 _       _   _             
 |  _ \ _ __ ___  _ __   ___  / ___|(_)_ __ ___  _   _| | __ _| |_(_) ___  _ __  
 | | | | '__/ _ \| '_ \ / _ \ \___ \| | '_ ` _ \| | | | |/ _` | __| |/ _ \| '_ \ 
 | |_| | | | (_) | | | |  __/  ___) | | | | | | | |_| | | (_| | |_| | (_) | | | |
 |____/|_|  \___/|_| |_|\___| |____/|_|_| |_| |_|\__,_|_|\__,_|\__|_|\___/|_| |_|
                                                                                 
"
source_dir = expanduser(joinpath(dirname(@__FILE__), "..", "src"))
if !(source_dir in LOAD_PATH)
    push!(LOAD_PATH, source_dir)
end
using Agents
using AirTraffic
using UAVs
using CairoMakie

function main()
    println(TITLE)
    println("Intialize model")
    model = initialize_model()
    println("Start")
    figure, = abmplot(model; agent_marker = drone_marker)
    figure
end

main()