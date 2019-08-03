# To-do List (delete these as they are completed)
#
# 1. Set DataPackage Parameters
# 2. Update the files to be loaded. these should include the data files, report numbers, and project metadata.
# 3. Update packageDataFrame, packageRefID, and packageURL parameters.
# 4. Run the portion of the script through creation of the table attribute tables
# 5. Update the attribute and factor tables. The factor table will only include factors included in the data set; 
#    ensure factors for data quality flags include all potential options regardless of whether they're present in the data set.
# 6. Update the georgraphic coverage information. Note that this information may need to originate from ancillary data sets.
# 7. Update the temporal coverage information. Note that this information may need to originate from ancillary data sets.
# 8. Update the taxonomic coverage information.
# 9. Update / add additional EML lists to be added
#     a. citation information for the protocol
#     b. sampling design geographic coverage
#     c. sampling design taxonomic coverage
#     d. sampling design temporal coverage
# 10. Run full script until no errors.
# 11. Validate the resultant eml file using https://knb.ecoinformatics.org/emlparser/ 



# General Setup Stuff
pkgList <- c("devtools",
             "dataRetrieval", 
             "waterData", 
             "EflowStats", 
             "EML",
             "EMLassemblyline",
             "lubridate",
             "readtext",
             "zip"
)

inst <- pkgList %in% installed.packages()
if (length(pkgList[!inst]) > 0) {
  install.packages(pkgList[!inst], dep = TRUE,
                   repos = "https://cloud.r-project.org")
}

lapply(pkgList, library, character.only = TRUE, quietly = TRUE)

# Load Data Files.

load(file="data/Output_MeanDailyFlows.RData")
load(file="data/Output_AnalysisPORs.RData")
load(file="data/AllDailyFlowData.RData")
load(file="data/DailyFlowsMetadata.RData")

# Set DataPackage Parameters
datapackageTitle<-"Title."                # official title of the data package
datapackageDescription = "Description."   # short title or description
publicationYear<-2019                     # year of data set publication to Data Store. e.
datapackageDirectoryName="directory"      # subdirectory where the data package processing files are kept (such as "2018_Analysis_PORs")
LastCompleteWaterYear<-"YEAR"             # Year of the last complete water year contained in the data set


ProjectMetadata<-read.csv(file="metadata/ProjectMetadata.csv", stringsAsFactors = FALSE)
ReportNumbers<-read.csv(file="metadata/ReportNumbers.csv", stringsAsFactors = FALSE)
accessdate <- as.Date(DailyFlowsMetadata$DataAcquisitionDateTime,origin="1970-01-01")

# Set Up Directories and File Names
DataPublicationReportRefID<-subset(ReportNumbers$ReferenceID, ReportNumbers$Parameter=="DataPublicationReportRefID")
FlowRefID<-subset(ReportNumbers$ReferenceID, ReportNumbers$Parameter=="FlowRefID")
CleanFlowRefID<-subset(ReportNumbers$ReferenceID, ReportNumbers$Parameter=="CleanFlowRefID")
AnalysisPORsRefID<-subset(ReportNumbers$ReferenceID, ReportNumbers$Parameter=="AnalysisPORsRefID")

DataPublicationReportURL<-paste0("https://irma.nps.gov/DataStore/Reference/Profile/",DataPublicationReportRefID)
FlowURL<-paste0("https://irma.nps.gov/DataStore/Reference/Profile/",FlowRefID)
CleanFlowURL<-paste0("https://irma.nps.gov/DataStore/Reference/Profile/",CleanFlowRefID)
AnalysisPORsURL<-paste0("https://irma.nps.gov/DataStore/Reference/Profile/",AnalysisPORsRefID)

packageDataFrame<-#UPDATETHIS#
packageRefID<-#UPDATETHIS#
packageURL<-#UPDATETHIS#

# Create Product File Names
dataDirectory <- paste0("dataPackages/",datapackageDirectoryName,"/data_objects/")
metadataDirectory<-paste0("dataPackages/",datapackageDirectoryName,"/metadata_templates/")
emlDirectory<-paste0("dataPackages/",datapackageDirectoryName,"/eml/")
fileprefix <- paste0("NPS_IMD_ESProtocol_Hydrology_",datapackageDirectoryName,"_")
datafilename <-paste0(dataDirectory,fileprefix,packageRefID,"-data.csv")
metadatafilename <- paste0(emlDirectory,fileprefix,packageRefID,"-metadata.xml")
manifestfilename <- paste0(dataDirectory,fileprefix,packageRefID,"-manifest.txt")
datapackagefilename <- paste0("output/",fileprefix,packageRefID,"-datapackage.zip")

# Copy Data File to Data Package directory
write.csv(packageDataFrame,datafilename,row.names=FALSE)

stations<-as.data.frame(unique(AllDailyFlowData$site_no))
sites<-whatNWISsites(sites=stations[,1])
sites$site_no_long<-paste("USGS-", sites$site_no, sep="")
sites2<-whatWQPsites(siteid=sites$site_no_long)

write.csv(sites2,paste0(dataDirectory,"siteinfo.csv"))

# Generate Common EML Metadata Elements

## Copy templates from core templates. These should be reviewed and updated before creating EML file

file.copy(from="dataPackages/CoreTemplates/metadata_templates/abstract.txt", to=paste0(metadataDirectory,"abstract.txt"),overwrite=TRUE)
file.copy(from="dataPackages/CoreTemplates/metadata_templates/methods.txt", to=paste0(metadataDirectory,"methods.txt"),overwrite=TRUE)
file.copy(from="dataPackages/CoreTemplates/metadata_templates/keywords.txt", to=paste0(metadataDirectory,"keywords.txt"),overwrite=TRUE)
file.copy(from="dataPackages/CoreTemplates/metadata_templates/personnel.txt", to=paste0(metadataDirectory,"personnel.txt"),overwrite=TRUE)
file.copy(from="dataPackages/CoreTemplates/metadata_templates/intellectual_rights.txt", to=paste0(metadataDirectory,"intellectual_rights.txt"),overwrite=TRUE)
file.copy(from="dataPackages/CoreTemplates/metadata_templates/additional_info.txt", to=paste0(metadataDirectory,"additional_info.txt"),overwrite=TRUE)

intellectual_rights<-readLines(paste0(metadataDirectory,"intellectual_rights.txt"),encoding="UTF-8")
writeLines(intellectual_rights,paste0(metadataDirectory,"intellectual_rights.txt"),useBytes=T)

abstract<-readtext(paste0(metadataDirectory,"abstract.txt"))
abstract<-abstract[1,2]

themekeywords<-read.delim(paste0(metadataDirectory,"keywords.txt"))
themekeywords<-paste(themekeywords$keyword, collapse = ', ')

## Create Metadata Template files. These should be reviewed and updated before creating EML file

# Create Attribute Table

template_table_attributes(
  path = metadataDirectory,
  data.path = dataDirectory,
  data.table = paste0(fileprefix,packageRefID,"-data.csv")
)

# Template categorical variables
template_categorical_variables(
  path = metadataDirectory,
  data.path = dataDirectory
)

# Create Coverage Information

## Template geographic coverage

geographicDescription <- "Gaging stations within areas surrounding or HUC-12 watersheds that intersect boundaries of national parks units in CONUS, AK, HI, and U.S. Territories."

stations<-as.data.frame(unique(AllDailyFlowData$site_no))
sites<-whatNWISsites(sites=stations[,1])
sites$site_no_long<-paste("USGS-", sites$site_no, sep="")
sites2<-whatWQPsites(siteid=sites$site_no_long)


template_geographic_coverage(
  path = metadataDirectory,
  data.path = dataDirectory,
  data.table = 'siteinfo.csv',
  site.col = 'MonitoringLocationIdentifier',
  lat.col = 'LatitudeMeasure',
  lon.col = 'LongitudeMeasure'
)

## Get Temporal Coverage
beginDate <- as.Date(min(AllDailyFlowData$Date))
endDate <- as.Date(max(AllDailyFlowData$Date))

## Create EML
make_eml(
  path = metadataDirectory,
  data.path = dataDirectory,
  eml.path = emlDirectory,
  dataset.title = datapackageTitle, 
  temporal.coverage = c(as.Date(beginDate), as.Date(endDate)),
  maintenance.description = 'completed',
  data.table = paste0(fileprefix,packageRefID,"-data.csv"),
  data.table.description = datapackageDescription,
  data.url = packageURL,
  user.id = 'jcdevivo',
  user.domain = 'NPS-IMD',
  package.id = paste0(fileprefix,packageRefID,"-metadata")
)

# Read EML into R object so we can add additional elements
eml_temp<-read_eml(paste0(emlDirectory,fileprefix,packageRefID,"-metadata.xml"))

#Create Citations

## 

Joe<-list(individualName=list(givenName="J.C.",
                              surName="DeVivo"),
          organizationName="National Park Service"
          )

Lisa<-list(individualName=list(givenName="L.",
                               surName="Nelson"),
           organizationName="National Park Service"
)

Michelle<-list(individualName=list(givenName="M.",
                               surName="Kinseth"),
           organizationName="National Park Service"
)

Tom<-list(individualName=list(givenName="T.",
                               surName="Philippi"),
           organizationName="National Park Service"
)

Bill<-list(individualName=list(givenName="W.B.",
                               surName="Monahan"),
           organizationName="National Park Service"
)

IMD_address <- list(
  deliveryPoint = "1201 Oakridge Avenue, Suite 150",
  city = "Fort Collins",
  administrativeArea = "CO",
  postalCode = "80525",
  country = "USA")


citation <-list(
     shortName = "Environmental Settings Protocol",
     title = 'Protocol for monitoring environmental setting for National Park Service units: Landscape dynamics, climate, and hydrology.',
     creator = list(Joe,Lisa,Michelle,Tom,Bill),
     pubDate = '2019',
     series = "Natural Resource Report",
     reportNumber = 'NPS/IMD/NRR—2018/1844',
     publicationPlace = 'Fort Collins, Colorado',
     publisher = list(
       organizationName = "National Park Service, Inventory and Monitoring Division",
       address = IMD_address),
     distribution = list(
       online = list(url="https://irma.nps.gov/DataStore/Reference/Profile/2244060",
                     onlineDescription = "NPS Data Store"
       )
     )
)

eml_temp2<-eml_temp
eml_temp2$dataset$methods$methodStep$citation<-citation

write_eml(eml_temp2,paste0(emlDirectory,fileprefix,packageRefID,"-metadata.xml"))

# Create Manifest File

cat("This data package was produced by the National Park Service (NPS) Inventory and Monitoring Division and downloaded from the [NPS Data Store](https://irma.nps.gov/DataStore/Reference/Profile/",packageRefID,").",file=manifestfilename,"\n",sep="") 
cat("These data are provided under the Creative Commons CC0 1.0 “No Rights Reserved” (see: https://creativecommons.org/publicdomain/zero/1.0/).",file=manifestfilename,sep="\n",append=TRUE)
cat(" ",file=manifestfilename,sep="\n",append=TRUE)

cat("DATA PRODUCT INFORMATION",file=manifestfilename,sep="\n",append=TRUE)
cat("------------------------",file=manifestfilename,sep="\n",append=TRUE)
cat(" ",file=manifestfilename,sep="\n",append=TRUE)

# ID
cat("ID: ",packageRefID," Data Store Code.",file=manifestfilename,"\n",sep="",append=TRUE) 
cat(" ",file=manifestfilename,sep="\n",append=TRUE)

#Title
cat("Title: ",datapackageTitle,file=manifestfilename,"\n",sep="",append=TRUE) 
cat(" ",file=manifestfilename,sep="\n",append=TRUE)

#Description
cat("Description: ",datapackageDescription,file=manifestfilename,"\n",sep="",append=TRUE) 
cat(" ",file=manifestfilename,sep="\n",append=TRUE)

#Data Theme
cat("Data Theme: Ecological Framework: Water | Hydrology | Surface Water Dynamics",file=manifestfilename,"\n",sep="",append=TRUE) 
cat(" ",file=manifestfilename,sep="\n",append=TRUE)

#Abstract
cat("Abstract: ",abstract,file=manifestfilename,"\n",sep="",append=TRUE) 
cat(" ",file=manifestfilename,sep="\n",append=TRUE)

#Brief Design Description
cat("Brief Design Description: See the NPS Park Environmental Setting Protocol at https://irma.nps.gov/DataStore/Reference/Profile/2258457.",file=manifestfilename,sep="\n",append=TRUE) 
cat(" ",file=manifestfilename,sep="\n",append=TRUE)

#Brief Study Area Description
cat("Brief Study Area Description: ",geographicDescription,file=manifestfilename,"\n",sep="",append=TRUE) 
cat(" ",file=manifestfilename,sep="\n",append=TRUE)

#Keywords
cat("Keywords:",unlist(themekeywords),file=manifestfilename,"\n",sep=" ",append=TRUE) 
cat(" ",file=manifestfilename,sep="\n",append=TRUE)

#Data Quality Standards
cat("Data Quality Standards: See https://irma.nps.gov/DataStore/Reference/Profile/2258459 for a description of data quality standards related to this and associated data products.",file=manifestfilename,"\n",sep=" ",append=TRUE) 
cat(" ",file=manifestfilename,sep="\n",append=TRUE)

cat("EVENT INFORMATION",file=manifestfilename,sep="\n",append=TRUE)
cat("------------------------",file=manifestfilename,sep="\n",append=TRUE)
cat(" ",file=manifestfilename,sep="\n",append=TRUE)


cat("Date for Data Publication: ",as.character(today()),file=manifestfilename,"\n",sep="",append=TRUE) 
cat("Start Date for Mean Flow Data: ",as.character(beginDate),file=manifestfilename,"\n",sep="",append=TRUE)
cat("End Date for Mean Flow Data: ",as.character(endDate),file=manifestfilename,"\n",sep="",append=TRUE)
cat(" ",file=manifestfilename,sep="\n",append=TRUE)
cat("Location: ",geographicDescription,file=manifestfilename,"\n",sep="",append=TRUE)
cat("Geographic coordinates (extent lat/long bounding box and datum):",min(sites$dec_long_va), max(sites$dec_long_va), max(sites$dec_lat_va), min(sites$dec_lat_va), "WGS 84",file=manifestfilename,"\n",sep=" ",append=TRUE)
cat(" ",file=manifestfilename,sep="\n",append=TRUE)
cat("This zip package was generated on: ",as.character(today()),file=manifestfilename,"\n",sep="",append=TRUE) 
cat(" ",file=manifestfilename,sep="\n",append=TRUE)

cat("DATA PACKAGE CONTENTS",file=manifestfilename,sep="\n",append=TRUE)
cat("------------------------",file=manifestfilename,sep="\n",append=TRUE)
cat(" ",file=manifestfilename,sep="\n",append=TRUE)

cat("This zip package contains the following documentation files:",file=manifestfilename,sep="\n",append=TRUE)
cat(" ",file=manifestfilename,sep="\n",append=TRUE)

cat("- This readme file: ", fileprefix, packageRefID, "-manifest.text","\n",file=manifestfilename,sep="",append=TRUE)

cat("- Machine-readable metadata file describing the data set(s): ",fileprefix, packageRefID, "-metadata.xml. This file uses the Ecological Metadata Language (EML) schema. Learn more about this format at https://knb.ecoinformatics.org/external//emlparser/docs/eml-2.1.1/index.html#N1022A.",file=manifestfilename, "\n",sep="",append=TRUE)
cat(" ",file=manifestfilename,sep="\n",append=TRUE)

cat("This zip package contains the following data set(s):",file=manifestfilename,sep="\n",append=TRUE)
cat(" ",file=manifestfilename,sep="\n",append=TRUE)

cat("- ",fileprefix, packageRefID, "-data.csv - ", datapackageDescription,".\n",file=manifestfilename,sep="",append=TRUE)
cat(" ",file=manifestfilename,sep="\n",append=TRUE)

cat("FILE NAMING CONVENTIONS",file=manifestfilename,sep="\n",append=TRUE)
cat("------------------------",file=manifestfilename,sep="\n",append=TRUE)
cat(" ",file=manifestfilename,sep="\n",append=TRUE)

cat("Files are named with a prefix that includes a series of component abbreviations separated by underscores.",file=manifestfilename,sep="\n",append=TRUE)
cat(" ",file=manifestfilename,sep="\n",append=TRUE)

cat("Example data file prefix: NPS_IMD_<Protocol>_<Protocol Topic>_<Data Set Content>_<Water Year>_<RefID>_",file=manifestfilename,sep="\n",append=TRUE)
cat(" ",file=manifestfilename,sep="\n",append=TRUE)

cat("Definitions:",file=manifestfilename,sep="\n",append=TRUE)
cat(" ",file=manifestfilename,sep="\n",append=TRUE)

cat("NPS: National Park Service.",file=manifestfilename,sep="\n",append=TRUE)
cat(" ",file=manifestfilename,sep="\n",append=TRUE)

cat("IMD: Inventory and Monitoring Division.",file=manifestfilename,sep="\n",append=TRUE)
cat(" ",file=manifestfilename,sep="\n",append=TRUE)

cat("<Protocol = ESProtocol>: NPS Environmnetal Settings Protocol.",file=manifestfilename,sep="\n",append=TRUE)
cat(" ",file=manifestfilename,sep="\n",append=TRUE)

cat("<Protocol Topic= Hydrology>: Hydrology.",file=manifestfilename,sep="\n",append=TRUE)
cat(" ",file=manifestfilename,sep="\n",append=TRUE)

cat("<Data Set Content = AllDailiyFlowData>: Unprocessed Mean Daily Flow Data.",file=manifestfilename,sep="\n",append=TRUE)
cat(" ",file=manifestfilename,sep="\n",append=TRUE)

cat("<Water Year>: The last complete water year's worth of data contained in the data set.",file=manifestfilename,sep="\n",append=TRUE)
cat(" ",file=manifestfilename,sep="\n",append=TRUE)

cat("<RefID>: Unique identifyer associated with the Data Store reference code associated with the data package. The Data Store reference code for this product is: ",packageRefID,"\n", file=manifestfilename,sep="",append=TRUE)
cat(" ",file=manifestfilename,sep="\n",append=TRUE)

cat("The data package (and all component files described above) can be downloaded from the NPS Data Store at: https://irma.nps.gov/DataStore/Reference/Profile/",packageRefID,"\n", file=manifestfilename,sep="",append=TRUE)
cat(" ",file=manifestfilename,sep="\n",append=TRUE)


cat("ADDITIONAL INFORMATION",file=manifestfilename,sep="\n",append=TRUE)
cat("------------------------",file=manifestfilename,sep="\n",append=TRUE)
cat(" ",file=manifestfilename,sep="\n",append=TRUE)

cat("External data sources contributing to this product: Hydrologic data available from the USGS Water Quality Portal (http://www.waterqualitydata.us) [accessed ", as.character(accessdate),"].","\n",file=manifestfilename,sep="",append=TRUE)
cat(" ",file=manifestfilename,sep="\n",append=TRUE)

cat("Primary related products: The following four products were created concurrently as a suite for use in calculation of hydrologic metrics as a part of the Park Environmental Settings monitoring protocol:",file=manifestfilename,sep="\n",append=TRUE)
cat(" ",file=manifestfilename,sep="\n",append=TRUE)

cat("1. Data Publication Report. Document describing the methods and the analysis code used to generate data sets in this suite. Available at ", DataPublicationReportURL, ".", "\n",file=manifestfilename,sep="",append=TRUE)
cat(" ",file=manifestfilename,sep="\n",append=TRUE)

cat("2. Mean Daily Flow Data from USGS. This data set contains the raw mean daily flow data and associated data qualification codes for stations of interest. These data are preserved as a record to support reproducible generation of the following data sets and/or if needed to support other uses. Available at ", FlowURL, ".", "\n",file=manifestfilename,sep="",append=TRUE)
cat(" ",file=manifestfilename,sep="\n",append=TRUE)

cat("3. Mean Daily Flow Data For Use in Calculating Hydrologic Metrics. This data set contains mean daily flow data that have been evaluated and processed to ensure suitability for use in calculating hydrologic metrics. This data set includes interpolated values to fill (some) data gaps and some lumping of USGS qualification codes to inform subsequent use in analysis and reporting. Available at ", CleanFlowURL, ".", "\n",file=manifestfilename,sep="",append=TRUE)
cat(" ",file=manifestfilename,sep="\n",append=TRUE)

cat("4. Periods of Record for Analysis.  This data set contains all periods of record to be used when calculating hydrologic metrics at stations of interest.  Periods of record are qualified based on length of data availability and quality of underlying mean daily flow data. Available at ", AnalysisPORsURL, ".", "\n",file=manifestfilename,sep="",append=TRUE)
cat(" ",file=manifestfilename,sep="\n",append=TRUE)

cat("All products related to the Park Environmental Settings monitoring protocol are available at https://irma.nps.gov/DataStore/Reference/Profile/2244060.",file=manifestfilename,sep="\n",append=TRUE)
cat(" ",file=manifestfilename,sep="\n",append=TRUE)

cat("CHANGE LOG",file=manifestfilename,sep="\n",append=TRUE)
cat("------------------------",file=manifestfilename,sep="\n",append=TRUE)
cat(" ",file=manifestfilename,sep="\n",append=TRUE)

cat("N/A",file=manifestfilename,sep="\n",append=TRUE)
cat(" ",file=manifestfilename,sep="\n",append=TRUE)

cat("ADDITIONAL REMARKS",file=manifestfilename,sep="\n",append=TRUE)
cat("------------------------",file=manifestfilename,sep="\n",append=TRUE)
cat(" ",file=manifestfilename,sep="\n",append=TRUE)

cat("N/A",file=manifestfilename,sep="\n",append=TRUE)
cat(" ",file=manifestfilename,sep="\n",append=TRUE)


cat("NPS DATA POLICY AND CITATION GUIDELINES",file=manifestfilename,sep="\n",append=TRUE)
cat("------------------------",file=manifestfilename,sep="\n",append=TRUE)
cat(" ",file=manifestfilename,sep="\n",append=TRUE)

cat("See NPS Inventory and Monitoring Division's data policy and citation guidelines at https://irma.nps.gov/content/portal/about/.",file=manifestfilename,sep="\n",append=TRUE)
cat(" ",file=manifestfilename,sep="\n",append=TRUE)


cat("DATA QUALITY AND VERSIONING",file=manifestfilename,sep="\n",append=TRUE)
cat("------------------------",file=manifestfilename,sep="\n",append=TRUE)
cat(" ",file=manifestfilename,sep="\n",append=TRUE)

cat("The data contained in this file are considered Accepted under the IMD Data Certification Guidance (https://www.google.com/url?q=https://irma.nps.gov/DataStore/Reference/Profile/2227397). Updates to the data, QA/QC and/or processing algorithms over time will occur on an as-needed basis.  Please check back to this site for updates tracked in change logs.",file=manifestfilename,sep="\n",append=TRUE)
cat(" ",file=manifestfilename,sep="\n",append=TRUE)



### Zip up file

zipr(datapackagefilename,c(datafilename,manifestfilename,metadatafilename), recurse=FALSE)