
Faces <- read.csv("Faces.csv")
Races <- read.csv("Races.csv")

Faces <- merge(Faces, Races, by="Number")
write.csv(Faces, file="Faces.csv", row.names=F, quote=F)
