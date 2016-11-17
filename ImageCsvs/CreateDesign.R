library(dplyr)

set.seed(1234567890)

# randomize block order for each run - look into counter balancing later
Blocks <- read.csv("Blocks.csv")
Blocks <- select(Blocks, Run, BlockType, NumFear, NumHappy, Context)
Order <- c(sample(10), sample(11:20))
Blocks <- Blocks[Order, ]
Blocks <- Blocks %>%
  group_by(Run) %>%
  mutate(BlockNum=1:n())

Faces <- read.csv("Faces.csv")
Faces <- Faces %>%
  filter(!grepl("2[78]M", FileName))
Faces <- Faces[sample.int(nrow(Faces)), ]
AvailFear <- (1:nrow(Faces))[Faces$Expression == "NeutFear"]
AvailHappy <- (1:nrow(Faces))[Faces$Expression == "NeutHappy"]
cat(sprintf("length(AvailFear): %d\n", length(AvailFear)))
cat(sprintf("length(AvailHappy): %d\n\n", length(AvailHappy)))

Contextual <- read.csv("Contextual.csv")
AvailNeg <- (1:nrow(Contextual))[Contextual$Category == "Unpleasant"]
AvailPos <- (1:nrow(Contextual))[Contextual$Category == "Pleasant"]

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

  FearIdx <- sample.int(length(AvailFear), Blocks$NumFear[iBlock])
  HappyIdx <- sample.int(length(AvailHappy), Blocks$NumHappy[iBlock])
  FaceIdx <- c(AvailFear[FearIdx], AvailHappy[HappyIdx])

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
  AvailFear <- AvailFear[-1*FearIdx]
  cat(sprintf("length(AvailFear): %d length(FearIdx): %d\n", 
    length(AvailFear), length(FearIdx)))
  AvailHappy <- AvailHappy[-1*HappyIdx]
  cat(sprintf("length(AvailHappy): %d length(HappyIdx): %d\n\n", 
    length(AvailHappy), length(HappyIdx)))

  Design[[RunNum]][[BlockNum]] <- TmpBlock[sample.int(nrow(TmpBlock)), ]
} 

Design <- bind_rows(lapply(Design, bind_rows))

  

  

  
  
  
  
  

# list of runs
#   list of blocks
#   one block = standard data frame
# initialize variables:
#   available negative faces
#   available positive faces
#   available negative context
#   available positive conxtest


# for each run
#   for each block
#     randomly 
