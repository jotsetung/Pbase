#' calculates the monoisotopic mass for peptide sequences
#' @param a character vector
#' @return a named doubled vector
#' @noRd
.calculateMolecularWeight <- function(x) {
    water <- sum(.get.atomic.mass()[c("H", "H", "O")])

    aamass <- setNames(.get.amino.acids()$ResidueMass,
                       .get.amino.acids()$AA)

    ppmass <- unlist(lapply(.singleAA(x), function(p) {
        sum(aamass[p])
    }))
    ppmass <- ppmass + water

    .setNames2(ppmass, x)
}

#' calculates the isoelectric point
#' @param a character vector
#' @return a named doubled vector
#' @references
#' Moore, Dexter S.
#' "Amino acid and peptide net charges: a simple calculational procedure."
#' Biochemical Education 13.1 (1985): 10-11.
#' http://dx.doi.org/10.1016/0307-4412(85)90114-1
#' @noRd
#.calculateIsoelectricPoint <- function(x) {
#}
#

#' test peptides for some properties
#' @param x character, AAString, AAStringSet: sequence
#' @param mass double, length == 2, mass range [Da]
#' @param len double, length == 2, length range
#' @return logical vector, TRUE if the peptides fulfills all criteria otherwise
#' FALSE
#' @noRd
.isValidPeptide <- function(x, mass = NULL, len = NULL
                            ## to be extended (isoelectric point, ...)
                            ) {
    ## initialize with TRUE
    valid <- !logical(length(x))

    if (!is.null(mass)) {
        valid <- valid & .isInRange(.calculateMolecularWeight(x), range = mass)
    }
    if (!is.null(len)) {
        valid <- valid & .isInRange(nchar(x), range = len)
    }

    .setNames2(valid, x)
}

#' calculates IRanges for a peptide "pattern" in a protein "subject"
#' (TODO: this function is too slow!)
#' @param pattern named character, AAString, AAStringSet, AAStringSetList
#' @param subject named character, AAString, AAStringSet
#' @return a named IRangesList
#' @noRd
.peptidePosition <- function(pattern, subject) {
    if (is.null(names(pattern))) {
        stop("No names for ", sQuote("pattern"), " available!")
    }
    if (is.null(names(subject))) {
        stop("No names for ", sQuote("subject"), " available!")
    } else if (anyDuplicated(names(subject))) {
        stop("No duplicated names for ", sQuote("subject"), " allowed!")
    }

    lpat <- split(pattern, names(pattern))
    ## Caution: this will maybe fail for large AA
    lpat <- lapply(lpat, function(x)paste0(unlist(x), collapse="|"))
    lsub <- split(subject, names(subject))

    m <- match(names(lsub), names(lpat))

    r <- mapply(function(p, s, j) {
        if (!is.null(p)) {
            rx <- gregexpr(p, s, fixed = TRUE)[[1L]]
            i <- which(rx > 0L)
            l <- attr(rx, "match.length")[i]
            rx <- rx[i]
            if (length(rx)) {
                return(matrix(c(rx, rx+l-1, rep.int(j, length(rx))), ncol = 3))
            }
        }
    }, p = lpat[m], s = lsub, j = m, SIMPLIFY = FALSE, USE.NAMES = FALSE)

    if (length(r) && any(elementLengths(r) > 0)) {
        r <- do.call(rbind, r)
        ir <- .splitIRanges(IRanges(start = r[, 1L], end = r[, 2L]), f=r[,3L])
        names(ir) <- names(lpat)[unique(r[, 3L])]
    } else {
        ir <- IRanges()
    }
    ir
}
