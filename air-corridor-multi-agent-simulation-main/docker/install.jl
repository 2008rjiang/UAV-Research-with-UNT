using Pkg

function main()
    pkg_list = ["Agents", "WGLMakie", "CairoMakie", "ImageMagick", "FileIO", "IJulia"]
    println("Install Julia packages:")
    for p in pkg_list
        println(p)
        try
            Pkg.add(p)
        catch
            println("Frailed to install")
        end
    end
    Pkg.precompile()
end

main()


