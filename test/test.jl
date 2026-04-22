using Revise, GeneratedFiles

GF = GeneratedFile("Cinema.txt")
add_records!(GF,Record("La vita è bella", "film", 1))
add_records!(GF,Record("Il re Leone", Tag("film_d'animazione", 2)),
             Record("The Rocky Horror Picture Show\n", "Musical"),
             Record("Modern Family", "TV_Show", 4))

GF_write(GF)

GF2 = readGF("Cinema.txt")

remove_records!(GF,"TV_Show")
