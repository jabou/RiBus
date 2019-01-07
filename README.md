# RiBus

<b>iOS developer:</b> Abou Aldan Jasmin<br>
<b>Android developer:</b> Loncar Mario<br>
<b>Project was developed as part of:</b> Undergraduate final thesis <i>Application development for iOS</i> (Rijeka, 2015) and MIPRO International ICT Convention (Opatija, May 25, 2015, Digital Economy and Government/Local Government/Public Services) with thesis <i>Citybus Mobile Application</i><br><br>
<b>Development of this project was stoped in 2016 so the codebase is not up to date with the latest standards of the iOS development and it is possible that will not run without some major changes.</b><br><br>
<b>Description:</b> RiBus is beautifully designed app that gives you all info about local bus lines in Rijeka.
 
It provides timetable for city bus lines, locations of bus stations and estimated departing time of the next bus for the selected line. It also helps you not to wander looking for bus stop by providing shortest route from your location to certain bus stop.
 
Idea for this app came out of sheer need. Students, tourists and citizens often get confused by bus lines or get tired of running to catch their bus. RiBus is here to make your life easier.

Application uses, for its calculation, official timetables in which a bus should be on station. Currently, it does not show if the bus came earlier on a station or is it late.

##Screenshots
![data](https://cloud.githubusercontent.com/assets/11990539/14766945/5e2b446c-0a1a-11e6-8f34-931af0e93be6.png "First data fetch")
![home](https://cloud.githubusercontent.com/assets/11990539/14766946/5e2d2de0-0a1a-11e6-88d2-93e7fcd62ef5.png "Home screen")
![lines](https://cloud.githubusercontent.com/assets/11990539/14766947/5e311504-0a1a-11e6-96cd-2f6cb3738547.png "List of lines inside timetables")
![timetable](https://cloud.githubusercontent.com/assets/11990539/14766950/5e38d3c0-0a1a-11e6-94e5-010f166295f3.png "Timetable")
![calculation](https://cloud.githubusercontent.com/assets/11990539/14766949/5e35f6b4-0a1a-11e6-9852-b658e70640fc.png "Calculation of bus departures to selected station")
![maps](https://cloud.githubusercontent.com/assets/11990539/14766948/5e34bef2-0a1a-11e6-86ab-253b001512ff.png "All stations")
![zoom](https://cloud.githubusercontent.com/assets/11990539/14766951/5e46ab94-0a1a-11e6-958d-568f56b3987e.png "Zoom on user location and info about selected station")
![nav](https://cloud.githubusercontent.com/assets/11990539/14766952/5e4a6590-0a1a-11e6-838c-2f6b5cc735e1.png "Navigation alert view for selected station")
![filter](https://cloud.githubusercontent.com/assets/11990539/14766953/5e4ccf42-0a1a-11e6-8aac-21898c01041f.png "Filter line")
![direction](https://cloud.githubusercontent.com/assets/11990539/14766954/5e53fe02-0a1a-11e6-94ba-71c468c686de.png "Select direction")
![sel dir](https://cloud.githubusercontent.com/assets/11990539/14766955/5e55f982-0a1a-11e6-9f44-d4561fd1bb21.png "Showing only selected line and direction")

## Version 1.0
- Daily lines (1, 1A, 1B, 2, 2A, 3, 3A, 4, 4A, 5, 5A, 5B, 6, 7, 9)
- Timetables
- Bus Time Arrival Calculation
- Parse online database

## Version 1.0.2
- Minor bug fixes and support for iOS 9

## Version 1.0.3:
- Imported Crashlytics
- Parse Local Datastore
- New lines 13 and KBC

## Version 1.0.4:
- All data transfered on Parse datastore
