library("Pbase")

fas <- list.files(system.file("extdata", package = "Pbase"),
                  full.names = TRUE,
                  pattern = "fasta$")

#p <- Proteins(fas)[1:10]
(p <- Proteins(fas[2]))
pfeatures(p)
ametadata(p)
pmetadata(p)

#pp <- cleave(p[1:10])
(pp <- cleave(p, missedCleavages = 0))
pfeatures(pp)

## emulate subsetting
p3 <- pp
p3@aa <- p3@aa[1:3]
plot(p3, from = 1, to = 20)
