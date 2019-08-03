# Give the package a name and run the script:

dataPackageName<-"test"

pkgList <- c("EMLassemblyline")

inst <- pkgList %in% installed.packages()
if (length(pkgList[!inst]) > 0) {
  install.packages(pkgList[!inst], dep = TRUE,
                   repos = "https://cloud.r-project.org")
}

lapply(pkgList, library, character.only = TRUE, quietly = TRUE)


template_directories(
  path = 'dataPackages/',
  dir.name = dataPackageName
)

template_core_metadata(
  path = paste0('dataPackages/', dataPackageName, '/metadata_templates'),
  license = 'CC0'
)


file.copy(from="dataPackages/CoreTemplates/run_EMLassemblyline_Templates.R", to=paste0("dataPackages/", dataPackageName,"/run_EMLassemblyline_for_",dataPackageName,".R"),overwrite = TRUE)