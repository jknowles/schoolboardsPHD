################################################################################
# Read in WERC data and clean it
################################################################################

werc <- read.csv("../Data/WERCdata/WERC Election Data/WERC_Results.csv", 
                stringsAsFactors = FALSE)

table(werc$stafftype)

werc$totvotes <- werc$for. + werc$against
werc$percentfavor <- werc$for. / werc$totvotes
werc$turnout <- werc$totvotes / werc$eligiblevoters

# All WERC union certification elections as of July 2013

################################################################################
# Read in contract extension data
################################################################################

cont <- read.csv("../Data/contractChoices/teachcontract.csv")
table(cont$contract112)
table(cont$contract1213)
table(cont$recert)

################################################################################
# Read in achievement data
################################################################################