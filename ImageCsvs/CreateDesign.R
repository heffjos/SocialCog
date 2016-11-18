library(dplyr)

set.seed(1234567890)

# randomize block order for each run - look into counter balancing later
Blocks <- read.csv("Blocks.csv")
Blocks <- select(Blocks, Run, BlockType, NumFear, NumHappy, Context, 
  NumFearFemale, NumHappyFemale, NumFearMale, NumHappyMale)
Order <- c(sample(10), sample(11:20))
Order <- c(sample(10), sample(11:20))
Order <- c(sample(10), sample(11:20))
Order <- c(sample(10), sample(11:20))
Blocks <- Blocks[Order, ]
Blocks <- Blocks %>%
  group_by(Run) %>%
  mutate(BlockNum=1:n())

OrigFaces <- read.csv("Faces.csv") %>%
  filter(!grepl("2[78]M", FileName))
Faces <- OrigFaces
AvailFemale <- (1:nrow(OrigFaces))[Faces$Gender == "Female"]
AvailMale <- (1:nrow(OrigFaces))[Faces$Gender == "Male"]
for (i in 1:nrow(OrigFaces)) {
  if (i %% 2 == 1 && length(AvailFemale > 0)) {
    TmpIdx <- sample.int(length(AvailFemale), 1)
    Faces[i, ] <- OrigFaces[AvailFemale[TmpIdx], ]
    AvailFemale <- AvailFemale[-1*TmpIdx]
  } else {
    TmpIdx <- sample.int(length(AvailMale), 1)
    Faces[i, ] <- OrigFaces[AvailMale[TmpIdx], ]
    AvailMale <- AvailMale[-1*TmpIdx]
  }
}

AvailFemaleFear <- which(Faces$Expression == "NeutFear" & 
  Faces$Gender == "Female")
AvailFemaleHappy <- which(Faces$Expression == "NeutHappy" &
  Faces$Gender == "Female")
AvailMaleFear <- which(Faces$Expression == "NeutFear" &
  Faces$Gender == "Male")
AvailMaleHappy <- which(Faces$Expression == "NeutHappy" &
  Faces$Gender == "Male")

Contextual <- read.csv("Contextual.csv")
AvailNeg <- which(Contextual$Category == "Unpleasant")
AvailPos <- which(Contextual$Category == "Pleasant")

DefaultBlock <- data.frame(
  Run=rep(NA, 4),
  BlockNum=rep(NA, 4),
  TrialNum=rep(NA, 4),
  BlockSplit=rep(NA, 4),# numerically describes facial expression split (1-3)
  Condition=rep(NA, 4), # negative or positive 
  FaceNum=rep(NA, 4),
  FaceGender=rep(NA, 4),
  FaceExpression=rep(NA, 4),
  FaceFileName=rep(NA, 4),
  FaceRace=rep(NA, 4),
  ContextCategory=rep(NA, 4),
  ContextSubCategory=rep(NA, 4),
  ContextFileName=rep(NA, 4)
)

Design <- list(replicate(10, DefaultBlock, simplify=F),
  replicate(10, DefaultBlock, simplify=F)
)

for (iBlock in 1:nrow(Blocks)) {
  TmpBlock <- DefaultBlock

  RunNum <- Blocks$Run[iBlock]
  BlockNum <- Blocks$BlockNum[iBlock]

  FemaleFearIdx = c()
  FemaleHappyIdx = c()
  MaleFearIdx = c()
  MaleHappyIdx = c()
  if (Blocks$NumFearFemale[iBlock] != 0) 
    FemaleFearIdx <- sample.int(length(AvailFemaleFear), 
      Blocks$NumFearFemale[iBlock])
  if (Blocks$NumHappyFemale[iBlock] != 0)
    FemaleHappyIdx <- sample.int(length(AvailFemaleHappy), 
      Blocks$NumHappyFemale[iBlock])
  if (Blocks$NumFearMale[iBlock] != 0)
    MaleFearIdx <- sample.int(length(AvailMaleFear), 
      Blocks$NumFearMale[iBlock])
  if (Blocks$NumHappyMale[iBlock] != 0)
    MaleHappyIdx <- sample.int(length(AvailMaleHappy),
      Blocks$NumHappyMale[iBlock])

  FaceIdx <- c(AvailFemaleFear[FemaleFearIdx],
    AvailFemaleHappy[FemaleHappyIdx],
    AvailMaleFear[MaleFearIdx],
    AvailMaleHappy[MaleHappyIdx]
  )

  if (Blocks$Context[iBlock] == "Negative") {
    TmpIdx <- sample.int(length(AvailNeg), 4)
    ContextIdx <- AvailNeg[TmpIdx]
    AvailNeg <- AvailNeg[-1*TmpIdx]
  } else {
    TmpIdx <- sample.int(length(AvailPos), 4)
    ContextIdx <- AvailPos[TmpIdx]
    AvailPos <- AvailPos[-1*TmpIdx]
  }

  TmpBlock$Run <- RunNum
  TmpBlock$BlockNum <- BlockNum
  # TrialNum later
  TmpBlock$BlockSplit <- Blocks$BlockType[iBlock]
  TmpBlock$Condition <- Blocks$Context[iBlock]
  TmpBlock$FaceNum <- Faces$Number[FaceIdx]
  TmpBlock$FaceGender <- Faces$Gender[FaceIdx]
  TmpBlock$FaceExpression <- Faces$Expression[FaceIdx]
  TmpBlock$FaceFileName <- Faces$FileName[FaceIdx]
  TmpBlock$FaceRace <- Faces$Race[FaceIdx]
  TmpBlock$ContextCategory <- Blocks$Context[iBlock]
  TmpBlock$ContextSubCategory <- Contextual$SubCategory[ContextIdx]
  TmpBlock$ContextFileName <- Contextual$FileName[ContextIdx]

  cat(sprintf("Block: %d\n", iBlock)) 
  if (length(FemaleFearIdx) != 0)
    AvailFemaleFear <- AvailFemaleFear[-1*FemaleFearIdx]
  cat(sprintf("length(AvailFemaleFear): %d length(FemaleFearIdx): %d\n", 
    length(AvailFemaleFear), length(FemaleFearIdx)))
  if (length(FemaleHappyIdx) != 0)
    AvailFemaleHappy <- AvailFemaleHappy[-1*FemaleHappyIdx]
  cat(sprintf("length(AvailFemaleHappy): %d length(FemaleHappyIdx): %d\n", 
    length(AvailFemaleHappy), length(FemaleHappyIdx)))
  if (length(MaleFearIdx) != 0)
    AvailMaleFear <- AvailMaleFear[-1*MaleFearIdx]
  cat(sprintf("length(AvailMaleFear): %d length(MaleFearIdx): %d\n", 
    length(AvailMaleFear), length(MaleFearIdx)))
  if (length(MaleHappyIdx) != 0)
    AvailMaleHappy <- AvailMaleHappy[-1*MaleHappyIdx]
  cat(sprintf("length(AvailMaleHappy): %d length(MaleHappyIdx): %d\n\n", 
    length(AvailMaleHappy), length(MaleHappyIdx)))

  Design[[RunNum]][[BlockNum]] <- TmpBlock[sample.int(nrow(TmpBlock)), ]
} 

Design <- bind_rows(lapply(Design, bind_rows))
Design <- Design %>% 
  group_by(Run) %>%
  mutate(TrialNum=1:n())

GenderSummary <- Design %>%
  group_by(Run, BlockNum) %>%
  summarize(NumFemale=sum(FaceGender=="Female"), NumMale=sum(FaceGender=="Male"))

write.csv(Design, file="./Design.csv", row.names=F, quote=F)
