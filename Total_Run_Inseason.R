library(dplyr)
library(stringr)
library(fuzzyjoin)
library(ggrepel)
library(openxlsx)
library(tidyr)
library(zoo)
library(scales)
library(flextable)
library(lubridate)

# 1.1

# This script will replace the "Main" tab in the TR20XXworksheet.xlxs file for total run tracking and projections
#Step 1: Udate the date for which you are running this report:

Today<-as.Date("2025-09-16",format("%Y-%m-%d"))
Yesterday<-Today-1
Current.Year<-2025

#Step 2: Download UCI_Harvest from OceanAK and place in the "Harvest" folder
#Step 3: Update Daily Inseason Escapement Data (Fish Creek, Kenai, Kasilof)
#Step 4: Update Age estimates for Escapement and Commercial Catch in the Catch and Escapement Data folder:

#O:\SHAREDAT\Research\UCI Research Core\Projects\Catch and Escapement\2024 Catch & Escapement\Data\TOTAL_RUN_AGE_TRACKING...

#Step 5: Download Statweek 
Stat.Week2025<-read.csv(file("Data/Stat.Week2025.csv"))%>%
  mutate(Stat.Start=as.Date(Stat.Start,format="%m/%d/%Y"),Stat.Stop=as.Date(Stat.Stop,format="%m/%d/%Y"))


#Check to ensure dates have not been changed following BOF cycle:
## Years will need to be updated
KA.GL.Stop<-"2025-06-25" # Kasilof Gillnet-Actual stop date is the 24th
KA.DP.Start<-"2025-06-25" #kasilof Dipnet-Actual start date is the 25th
KA.DP.Stop<-"2025-08-07" #Kasilof Dipnet- Actual stop date is the 7th

KE.DP.Start<-"2025-07-09" #Kenai Dipnet- Actual start date is the 10th
KE.DP.Stop<-"2025-08-01" #kenai Dipnet- Actual stop date is the 31st


################################################################################
# COMMERCIAL HARVEST
#This data is obtained from OceanAK->My folders->Inseason Total Run-> UCI_Harvest. Code below is importing datasets that are saved in the "Harvest" folder.
#However, you should not have to use this code as FDMS output should already have this data

Comm.Harvest<-read.csv(file("Data/Harvest/UCI_Harvest.csv"))


# State Drift (All statistical areas except for Federal EEZ, Kasilof Terminal Harvest Area, and Chinitna Bay)


State.Drift<-Comm.Harvest%>%mutate(Date=as.Date(Catch.Date,format="%Y-%m-%d"))%>%
  filter(Gear.Code==3)%>%filter(!Stat.Area.Name=="24426 - Kasilof Terminal Drift"&!Stat.Area.Name=="24511 - Chinitna Drift"&!Stat.Area.Name=="24464 - UCI EEZ")%>%
  group_by(Date)%>%
  summarize(Fishery.Project="Central District Drift - State Waters", Season.Total=sum(Count))

#Federal EEZ Drift
EEZ.Drift<-Comm.Harvest%>%mutate(Date=as.Date(Catch.Date,format="%Y-%m-%d"))%>%
  filter(Gear.Code==3)%>%filter(Stat.Area.Name=="24464 - UCI EEZ")%>%
  group_by(Date)%>%
  summarize(Fishery.Project="UCI EEZ", Season.Total=sum(Count))

# Kenai Section (24442,24441,24432)
Kenai.Section<-Comm.Harvest%>%mutate(Date=as.Date(Catch.Date,format="%Y-%m-%d"))%>%
  filter(Stat.Area.Name=="24432 - Kalifornsky North"|Stat.Area.Name=="24442 - Salamantof"|Stat.Area.Name=="24441 - Salamantof"|Stat.Area.Name=="24442 - East Forelands")%>%
  group_by(Date)%>%
  summarize(Fishery.Project="Kenai Section Set Net Fishery", Season.Total=sum(Count))

# Kasilof Section (24431,24422,24421)
Kasilof.Section<-Comm.Harvest%>%mutate(Date=as.Date(Catch.Date,format="%Y-%m-%d"))%>%
  filter(Stat.Area.Name=="24421 - Ninilchik"|Stat.Area.Name=="24422 - Coho"|Stat.Area.Name=="24431 - Kalifonsky South")%>%
  group_by(Date)%>%
  summarize(Fishery.Project="Kasilof Section Set Net Fishery", Season.Total=sum(Count))

# Western (24520,24530,24540,24550)
Western<-Comm.Harvest%>%mutate(Date=as.Date(Catch.Date,format="%Y-%m-%d"))%>%
  filter(Stat.Area.Name=="24530 - Tuxedni Bay"|Stat.Area.Name=="24520 - Silver Salmon"|Stat.Area.Name=="24540 - Polly Creek"|Stat.Area.Name=="24550 - Little Jack Slough"|
         Stat.Area.Name=="24610 - Kalgin Island West Side"|Stat.Area.Name=="24620 - Kalgin Island East Side"| #Kalgin Island
         Stat.Area.Name=="24555 - Big River"|Stat.Area.Name=="24560 - West Foreland"| #Kustatan
        Stat.Area.Name=="24510 - Chinitna Set")%>% #Chinitna Set
  group_by(Date)%>%
  summarize(Fishery.Project="Western Subdistrict Set Net Fishery", Season.Total=sum(Count))

# General Knik Arm (24710,24720,24730,24741,24742,24743)
Knik<-Comm.Harvest%>%mutate(Date=as.Date(Catch.Date,format="%Y-%m-%d"))%>%
  filter(Stat.Area.Name=="24710 - Trading Bay"|Stat.Area.Name=="24720 - Tyonek"|Stat.Area.Name=="24730 - Beluga"|Stat.Area.Name=="24741 - Susitna Flats"|Stat.Area.Name=="24742 - Point Mackenzie"|  Stat.Area.Name=="24743 - Fire Island")%>%
  group_by(Date)%>%
  summarize(Fishery.Project="Northern District Set Net Fishery - General Subdistrict", Season.Total=sum(Count))

# Eastern (24770,24780,24790)
Eastern<-Comm.Harvest%>%mutate(Date=as.Date(Catch.Date,format="%Y-%m-%d"))%>%
  filter(Stat.Area.Name=="24770 - Point Possession"|Stat.Area.Name=="24780 - Birch Hill"|Stat.Area.Name=="24790 - #3 Bay")%>%
  group_by(Date)%>%
  summarize(Fishery.Project="Northern District Set Net Fishery - Eastern Subdistrict", Season.Total=sum(Count))

#Kasilof Terminal (Includes drift and gillnet harvests; 24425,24426)
Kasilof.Terminal<-Comm.Harvest%>%mutate(Date=as.Date(Catch.Date,format="%Y-%m-%d"))%>%
  filter(Stat.Area.Name=="24425 - Kasilof Terminal Set"|Stat.Area.Name=="24426 - Kasilof Terminal Drift")%>%
  group_by(Date)%>%
  summarize(Fishery.Project="Kasilof Terminal", Season.Total=sum(Count))


### Combine all
Commercial.Harvest<-rbind(State.Drift, EEZ.Drift, Kenai.Section, Kasilof.Section, Western, Knik, Eastern, Kasilof.Terminal)%>%group_by(Fishery.Project)%>%
  complete(Date = seq.Date(as.Date("2025-06-01",format="%Y-%m-%d"), Today, by="day"))%>%replace(is.na(.),0)
#Generating Cumulative Harvests
Commercial.Harvest.Cumu<-Commercial.Harvest%>%
  group_by(Fishery.Project)%>%mutate(Season.Total=cumsum(Season.Total),Fate="Commercial Harvest")


################################################################################
## Escapement
#Requires daily apportioned sockeye counts. Susitna runs are based on historical run timing and expanded by date of projection. 

#Susitna Projection
Forcast.Total.Run<-404800 #2024 forecast for Susitna stock sockeye
Assumed.Harvest.Rate<-.42 #Mean Harvest rate 2007-2015
Forecast.Escapement<-Forcast.Total.Run-(Forcast.Total.Run*Assumed.Harvest.Rate) #Multiple the harvest rate by projection to get projected escapement

SU.ESC<-read.csv(file("Data/Escapement/Historical/Susitna_Run_Timing.csv"))%>%
  mutate(Date=make_date(year=Current.Year,day=day(as.Date(Date,format = "%d-%b")),month=month(as.Date(Date,format = "%d-%b"))))%>%
  mutate(Daily.Count=Mean.Daily.Prop*Forecast.Escapement,Fishery.Project="Susitna Escapement")%>%select(Date,Daily.Count,Fishery.Project)%>%
  filter(Date<=Yesterday)

#Fish Creek- Obtain from Fish Counts page on ADFG webpage
Fish.Creek<-read.csv(file("Data/Escapement/Fish_Creek.csv"))%>%
  mutate(Date=make_date(year=Current.Year,day=day(as.Date(Date,format = "%d-%b")),month=month(as.Date(Date,format = "%d-%b"))))%>%
  mutate(Fishery.Project="Fish Creek Escapement")%>%filter(Date<=Yesterday)

#Sonar Sites- Obtained from "Escapement" folder
Kasilof.Sonar<-read.csv(file("Data/Escapement/Kasilof_Sonar.csv"))%>%
  mutate(Date=make_date(year=Current.Year,day=day(as.Date(Date,format = "%d-%b")),month=month(as.Date(Date,format = "%d-%b"))))%>%
  mutate(Fishery.Project="Kasilof River Escapement")%>%filter(Date<=Yesterday)

Kenai.Sonar<-read.csv(file("Data/Escapement/Kenai_Sonar.csv"))%>%
  mutate(Date=make_date(year=Current.Year,day=day(as.Date(Date,format = "%d-%b")),month=month(as.Date(Date,format = "%d-%b"))))%>%
  mutate(Fishery.Project="Kenai River Escapement")%>%filter(Date<=Yesterday)

#Crescent- Escapement estimated from harvest of the western district at a harvest rate of 0.463, which is based on GSI of harvest (2005-2021). 
#Please note, this harvest is the historical stat areas of the western reporting group
Crescent<-read.csv(file("Data/Harvest/UCI_Harvest.csv"))%>%mutate(Date=as.Date(Catch.Date,format="%Y-%m-%d"))%>%
  filter(Stat.Area.Name=="24530 - Tuxedni Bay"|Stat.Area.Name=="24520 - Silver Salmon"|Stat.Area.Name=="24540 - Polly Creek"|Stat.Area.Name=="24550 - Little Jack Slough")%>%
  group_by(Date)%>%
  summarize(Season.Total=sum(Count))%>%
  group_by(Date)%>%summarize(Daily.Count=(Season.Total/0.463)-Season.Total)%>%mutate(Fishery.Project="Crescent Escapement")


Escapement<-rbind(SU.ESC,Fish.Creek,Kasilof.Sonar,Kenai.Sonar,Crescent)%>%group_by(Fishery.Project)%>%
  complete(Date = seq.Date(as.Date("2025-06-01",format="%Y-%m-%d"), Today, by="day"))%>%replace(is.na(.),0)

Escapement<-Escapement%>%rbind(Escapement%>%group_by(Date)%>%summarize(Daily.Count=sum(Daily.Count)*.15,Fishery.Project="Other"))# Adding in Unmonitored systems

Escapement.Cumu<-Escapement%>%group_by(Fishery.Project)%>%mutate(Season.Total=cumsum(Daily.Count))%>%
  select(Fishery.Project,Date,Season.Total)%>%
  mutate(Fate="Escapement")


################################################################################
# Sport AND PERSONAL USE PROJECTIONS
# This script is based on the "KENAI- Kasilof PU&SF projection" tab in the TR2023 file.

#First we must estimate harvest rates for each fishery


#Each season, the PU_Sport_HR file will need updated using Comm AMR Appendix A17 and Sport AMR T18 (Columns C and N)
#Note: Kasilof sport harvest is available from the statewide harvest survey webpage
#Also, historical sockeye counts will need updated as well.

#Season Dates
#Kasilof Gillnet-6/15 to 6/24
#Kasilof Dipnet- 6/25 to 8/7
#Kenai Dipnet- 7/10 to 7/31

#Data Wrangling and Reformatting
Hist.KeKa.Sonar<-read.csv(file("Data/Escapement/Historical/KEKA_Hist_Sonar.csv"))%>%
  mutate(Date.Full=make_date(year=Current.Year,day=day(as.Date(Date,format = "%m/%d")),month=month(as.Date(Date,format = "%m/%d"))))#create date that may be sorted chronologically

#This file will require updating each season.
PU_SPORT_HR<-read.csv(file("Data/PU and Sport Harvest/PU_SPORT_HR.csv"))


#Estimate Mean Harvest for PU, Sub and Sport to apply to sonar counts 
#First set season dates and get average passage during those dates
KA.Gillnet<-Hist.KeKa.Sonar%>%filter(River=="Kasilof"&Date.Full>"2025-06-14"&Date.Full<"2025-06-25")%>%group_by(Year)%>%summarize(Kasilof.Sonar.Gillnet=sum(Daily.Count))
KA.Dip<-Hist.KeKa.Sonar%>%filter(River=="Kasilof",Date.Full>"2025-06-25"&Date.Full<"2025-08-07")%>%group_by(Year)%>%summarize(Kasilof.Sonar.Dipnet=sum(Daily.Count))
KA.Sport<-Hist.KeKa.Sonar%>%filter(River=="Kasilof")%>%group_by(Year)%>%summarize(Kasilof.Sonar=sum(Daily.Count))
KE.Dip<-Hist.KeKa.Sonar%>%filter(River=="Kenai",Date.Full>"2025-07-10"&Date.Full<"2025-07-31")%>%group_by(Year)%>%summarize(Kenai.Sonar.Dipnet=sum(Daily.Count))
KE.Sport<-Hist.KeKa.Sonar%>%filter(River=="Kenai")%>%group_by(Year)%>%summarize(Kenai.Sonar=sum(Daily.Count))

#Now estimate harvest rate
Inriver.Harvest<-PU_SPORT_HR%>%mutate(Kasilof.Harvest.Below=Kasilof.Gillnet+Kasilof.Dipnet+Kasilof.Sport.Below.Sonar,
                                                            Kenai.Harvest.Below=Kenai.Dipnet+Kenai.Sport.Below.Sonar)%>%
  left_join(KA.Gillnet)%>%left_join(KA.Dip)%>%left_join(KA.Sport)%>%left_join(KE.Dip)%>%left_join(KE.Sport)%>%
  mutate(Kasilof.Gillnet.Harvestrate=Kasilof.Gillnet/sum(Kasilof.Gillnet,Kasilof.Sonar.Gillnet,na.rm=T),
         Kasilof.Dipnet.Harvestrate=Kasilof.Dipnet/sum(Kasilof.Dipnet,Kasilof.Sonar.Dipnet,na.rm=T),
         Kasilof.Sport.Harvestrate=Kasilof.Sport.Below.Sonar/sum(Kasilof.Sport.Below.Sonar,Kasilof.Sonar, na.rm=T),
         Kenai.Dipnet.Harvestrate=Kenai.Dipnet/sum(Kenai.Dipnet,Kenai.Sonar.Dipnet, na.rm=T),
         Kenai.Sport.Harvestrate=Kenai.Sport.Below.Sonar/sum(Kenai.Sport.Below.Sonar,Kenai.Sonar, na.rm=T))%>%
  select(1,17:21)%>%
  filter(Year<Current.Year&Year>Current.Year-6)%>% #Take 5-year average
  summarize(across(2:6,mean,na.rm=T))


###
# Kasilof 
Kasilof.Gillnet<-read.csv(file("Data/Escapement/Kasilof_Sonar.csv"))%>%
  mutate(Date=make_date(year=Current.Year,day=day(as.Date(Date,format = "%d-%b")),month=month(as.Date(Date,format = "%d-%b"))))%>%
  mutate(Harvest=ifelse(Date<KA.GL.Stop,(Daily.Count*Inriver.Harvest$Kasilof.Gillnet.Harvestrate)/(1-Inriver.Harvest$Kasilof.Gillnet.Harvestrate),0))%>%
  filter(Date<=Yesterday)%>%
  mutate(Fishery.Project="Kasilof Personal Use Gillnet")%>%
  select(Date,Harvest,Fishery.Project)

Kasilof.Dipnet<-read.csv(file("Data/Escapement/Kasilof_Sonar.csv"))%>%
  mutate(Date=make_date(year=Current.Year,day=day(as.Date(Date,format = "%d-%b")),month=month(as.Date(Date,format = "%d-%b"))))%>%
  mutate(Harvest=ifelse(Date>=KA.DP.Start&Date<KA.DP.Stop,(Daily.Count*Inriver.Harvest$Kasilof.Dipnet.Harvestrate)/(1-Inriver.Harvest$Kasilof.Dipnet.Harvestrate),0))%>%
  filter(Date<=Yesterday)%>%
  mutate(Fishery.Project="Kasilof Personal Use Dipnet")%>%
  select(Date,Harvest,Fishery.Project)

Kasilof.Sport<-read.csv(file("Data/Escapement/Kasilof_Sonar.csv"))%>%
  mutate(Date=make_date(year=Current.Year,day=day(as.Date(Date,format = "%d-%b")),month=month(as.Date(Date,format = "%d-%b"))))%>%
  mutate(Harvest=(Daily.Count*Inriver.Harvest$Kasilof.Sport.Harvestrate)/(1-Inriver.Harvest$Kasilof.Sport.Harvestrate))%>%
  filter(Date<=Yesterday)%>%
  mutate(Fishery.Project="Kasilof Sport")%>%
  mutate(Harvest=Harvest*2)%>%#Bag limit was doubled to 6 dureing the 2024 BOF Meeting
  select(Date,Harvest,Fishery.Project)

# Kenai
Kenai.Dipnet<-read.csv(file("Data/Escapement/Kenai_Sonar.csv"))%>%
  mutate(Date=make_date(year=Current.Year,day=day(as.Date(Date,format = "%d-%b")),month=month(as.Date(Date,format = "%d-%b"))))%>%
  mutate(Harvest=ifelse(Date>KE.DP.Start&Date<KE.DP.Stop,(Daily.Count*Inriver.Harvest$Kenai.Dipnet.Harvestrate)/(1-Inriver.Harvest$Kenai.Dipnet.Harvestrate),0))%>%
  filter(Date<=Yesterday)%>%
  mutate(Fishery.Project="Kenai Personal Use Dipnet")%>%
  select(Date,Harvest,Fishery.Project)

Kenai.Sport<-read.csv(file("Data/Escapement/Kenai_Sonar.csv"))%>%
  mutate(Date=make_date(year=Current.Year,day=day(as.Date(Date,format = "%d-%b")),month=month(as.Date(Date,format = "%d-%b"))))%>%
  mutate(Harvest=(Daily.Count*Inriver.Harvest$Kenai.Sport.Harvestrate)/(1-Inriver.Harvest$Kenai.Sport.Harvestrate))%>%
  filter(Date<=Yesterday)%>%
  mutate(Fishery.Project="Kenai Sport")%>%
  select(Date,Harvest,Fishery.Project)%>%
  mutate(Harvest=Harvest*2) #Bag limit was doubled to 6 dureing the 2024 BOF Meeting


#Fish Creek- This is going to cause issues because the run timing is heavily influenced by the weir flooding which yields incomplete counts. 
Fish.PU<-read.csv(file("Data/PU and Sport Harvest/FishHarvestbyDay.csv"))%>%
  mutate(Date=make_date(year=Current.Year,day=day(as.Date(Date,format = "%d-%b")),month=month(as.Date(Date,format = "%d-%b"))))%>%
  group_by(Year)%>%mutate(Timing=cumsum(Harvest)/sum(Harvest))%>%ungroup()%>%
  group_by(Date)%>%
  summarize(Timing=mean(Timing,na.rm=T),Fishery.Project="Fish Creek Personal Use")%>%
  left_join(PU_SPORT_HR%>%select(Year,Fish.Creek.PU)%>%filter(Year>Current.Year-5)%>%summarize(Harvest=mean(Fish.Creek.PU),Fishery.Project="Fish Creek Personal Use"))%>%
  mutate(Harvest=Timing*Harvest)%>%mutate(Harvest=lead(Harvest)-Harvest)%>%
  select(Date,Fishery.Project,Harvest)%>%
  replace(is.na(.), 0)


UCI.PU.SF<-rbind(Kasilof.Gillnet,Kasilof.Dipnet,Kasilof.Sport,Kenai.Dipnet,Kenai.Sport,Fish.PU)%>%
  group_by(Fishery.Project)%>%
  complete(Date = seq.Date(as.Date("2025-06-01",format="%Y-%m-%d"), Today, by="day"))%>%replace(is.na(.),0)

UCI.PU.SF.Cumu<-UCI.PU.SF%>%group_by(Fishery.Project)%>%mutate(Season.Total=cumsum(Harvest))%>%
  select(Fishery.Project,Date,Season.Total)%>%
  mutate(Fate="Personal Use and Sport")


###############################################################################
# OTF
#NOT BEING RUN IN 2024

#OTF<-read.csv(file("O:/DCF/UCI/Research/MNGMT/Ins/24/Harvest/OTF_Harvest.csv"))%>%mutate(Date=as.Date(Date,format="%d-%b"))%>%
#  mutate(Fate="Commercial Harvest", Fishery.Project="OTF", Season.Total=cumsum(Count))%>%select(1,3,4,5)

################################################################################
################################################################################  
# Combine All Fates- Estimates from this will be used in the age allocation model for stock specific return estimates via the Age allocation model in "Age_Composition Script"
Page1<-rbind(Commercial.Harvest.Cumu,Escapement.Cumu,UCI.PU.SF.Cumu)

Page1%>%ggplot()+
  geom_line(aes(Date,Season.Total,color=Fishery.Project),size=1)+
  facet_grid(Fate~.,scales="free")+
  scale_y_continuous(labels = comma)+
  theme_bw()+
  ylab("Cumulative Season Total")+xlab("")

  
Page1%>%filter(Date%in%Yesterday)%>%group_by(Fate)%>%mutate(Total=sum(Season.Total))%>%ungroup()%>%summarize(Grand.Total=sum(Season.Total))


###############################################################################
# Estimating residual fish in districts. This number will be added to the total run estimated by the age comp allocation model
# Methods may be found the OTF OP plan. Exploitation rates are as follows:
# Setnet Fisheries- 70%
# District Wide Drift- 40% 
# Reduced District Drift- 25%

# Residual Fish= (Harvest/Exploitation Rate)-Harvest

# Because residual fish will eventually be counted, we need to subset harvest data for the most recent periods.
# Residual.Fish<-read.csv(file("O:/DCF/UCI/Research/MNGMT/Ins/23/Harvest/UCI_Harvest.csv"))%>% 
#   mutate(Date=as.Date(Catch.Date,format = "%Y-%m-%d"))%>%
#   mutate(Residual.Fish=ifelse(Stat.Area.Name=="24460 - General District Drift",(Count/.4)-Count,
#                               ifelse(Gear.Code==3&!Stat.Area.Name=="24460 - General District Drift",(Count/.25)-Count,(Count/.7)-Count)))%>%
#   group_by(Date)%>%summarize(Total.Return=sum(Residual.Fish),Fate="Residual Fish")%>%
#   complete(Date = seq.Date(min(Date), as.Date("2023-08-31",format("%Y-%m-%d")), by="day"))%>%fill("Fate","Total.Return")
# 

#Add residual fish in district based on most recent harvest and add to page 1 along with escapement from the most recent day 
Inseason.Total.Run<-Page1%>%group_by(Date,Fate)%>%summarize(Total.Return=sum(Season.Total,na.rm = T))
  # rbind(Residual.Fish,rbind(
  #   read.csv(file("O:/DCF/UCI/Research/MNGMT/Ins/23/Inseason Total Run/Data/Susitna_Run_Timing.csv"))%>% # taking the last day passage estimate from all monitored systems and adding to dataframe
  #     mutate(Date=as.Date(Date,format="%d-%b"),Daily.Count=Mean.Daily.Prop*Forecast.Escapement)%>%select(1,4),
  #   
  #   read.csv(file("O:/DCF/UCI/Research/MNGMT/Ins/23/Escapement/Kasilof_Sonar.csv"))%>%mutate(Date=as.Date(Date,format="%d-%b")),
  #   
  #   read.csv(file("O:/DCF/UCI/Research/MNGMT/Ins/23/Escapement/Kenai_Sonar.csv"))%>%mutate(Date=as.Date(Date,format="%d-%b")),
  #   
  #   read.csv(file("O:/DCF/UCI/Research/MNGMT/Ins/23/Escapement/Fish_Creek.csv"))%>%mutate(Date=as.Date(Date,format="%d-%b")))%>%
  #     group_by(Date)%>%
  #     summarize(Total=sum(Daily.Count,na.rm=T))%>%# Totaling all escapements 
  #     mutate(Total.Return=Total+(Total*.15))%>%select(1,3)%>%# Accounting for monitored systems
  #     mutate(Fate="Escapement Prior Day",Date=Date+1))%>%
  # mutate(Total.Return=as.integer(Total.Return))%>%filter(Date<=Yesterday)

#When fishing effort is limited and harvests are low we need to correct the projection using OTF CPUE and Passage Rate for residual fish rather than exploitation rates
Total.Run.By.Date<-Inseason.Total.Run%>%group_by(Date)%>%summarize(Inseason.Total=as.integer(sum(Total.Return)))
  # left_join(read.csv(file("O:/DCF/UCI/Research/MNGMT/Ins/23/OTF/OTF_CPUE.csv"))%>%mutate(Date=as.Date(Date,format="%d-%b")))%>% #grabbing OTF Data
  # left_join(Residual.Fish%>%select(1,2)%>%rename(Residual.Fish=Total.Return))%>% 
  # mutate(Accum1.5=Inseason.Total-Residual.Fish)%>%
  # mutate(CCPUE=cumsum(replace_na(CPUE, 0)),
  #        CPUE.Roll=rollsumr(CPUE,k=3,fill=NA))




### Use this code to alternate between residual estimate calculations prior to August 1
# Correcting.Total.Run <- subset(Total.Run.By.Date,Total.Run.By.Date$Date > as.Date("2023-07-02")) #Subset for dates prior to the three days into the OTF project operations
# 
# for (i in (Correcting.Total.Run$Date)){
#   #i <- as.Date("2023-07-11")
#   df <- subset(Correcting.Total.Run,Correcting.Total.Run$Date %in% c(i,i+1))
#   #df$nick <- df$Inseason.Total
#   
#   if (nrow(df) < 2) {
#     
#   } else {
#     
#     if (df$Inseason.Total[2] < df$Inseason.Total[1]) {
#       
#       Correcting.Total.Run$Inseason.Total[Correcting.Total.Run$Date==i+1] <- (df$Inseason.Total[1] / df$CCPUE[1] ) * df$CPUE.Roll[2] + df$Accum1.5[2]
#     } else {
#       Correcting.Total.Run$Inseason.Total[Correcting.Total.Run$Date==i+1] <- df$Inseason.Total[2]
#     }
#   }
# }
# 
# 

#No data was gathered during the weekend of 22-23
# Total.Run.By.Date<-Correcting.Total.Run%>%mutate(Inseason.Total=ifelse(Date>=as.Date("2023-07-22")&Date<=as.Date("2023-07-23"),NA,Inseason.Total))%>%
  # rbind(Total.Run.By.Date%>%filter(Date<as.Date("2023-07-03")))%>%select(1,2)%>%rename(AccumRun2=Inseason.Total)











