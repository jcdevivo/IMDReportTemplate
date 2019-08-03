#' Get DS References for a park-species combination
#'
#' \code{killProject} deletes all project directories and files.
#'
#'
#'
#' @examples
#' killProject()

killProject <-function(x){

  unlink("common",recursive=TRUE)
  unlink("data",recursive=TRUE)
  unlink("dataPackages",recursive=TRUE)
  unlink("figures",recursive=TRUE)
  unlink("metadata",recursive=TRUE)
  unlink("output",recursive=TRUE)

}
