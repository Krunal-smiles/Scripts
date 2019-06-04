[CmdletBinding()]
Param([Parameter(Mandatory=$True,Position=1)][string]$axwayxmlfile)

# Read all complete account nodes
$completeApps = Select-xml -Path $axwayxmlfile -XPATH "//completeApplication"

# Read all application custom properties entry to build csv header
$csvheader = "businessUnit,id,name,type,notes,folder,folderShared"
$appkeys = $completeApps.node.application.customAttributes.customProperties.entry.key | Select-Object -Unique
ForEach ($appkey in $appkeys) {
    $csvheader = $csvheader + "," + "app_custom_$($appkey)"
}

# # Read all schedule custom properties entry to build csv header
# $schkeys = $completeApps.node.schedules.entry.key | Select-Object -Unique
# ForEach ($schkey in $schkeys) {
#     $csvheader = $csvheader + "," + "sch_custom_$($schkey)"
# }

$csvheader = $csvheader + ",key,sch_startDate,sch_endDate,sch_exe_hour,sch_exe_min,sch_exe_sec,sch_scheduleType,sch_hourlyType,sch_dailyType,sch_monthlyType,sch_skipHolidays,sch_hourlyStep,sch_sequence,sch_dayOfWeek,sch_dayOfMonth,sch_month"
Set-Content -Path .\apps.csv -Force $csvheader

# Loop through each complete application node
ForEach ($completeApp in $completeApps) {
    # read individual sub node
    $bUnit = $completeApp.node.businessUnit
    $appl = $completeApp.node.application
    $schedules = $completeApp.node.schedules

    # remove newline, formfeed and comma character from notes
    $notes = ""
    if ($($appl.notes)) {
        $notes = $appl.notes.Replace("`n","--").Replace("`r","--").Replace(",","--")
    }

    # build app recor
    $apprec = "$($bUnit),$($appl.id),$($appl.name),$($appl.type),$($notes),$($appl.folder),$($appl.folderShared)"
    $entries = $appl.customAttributes.customProperties.entry

    ForEach ($appkey in $appkeys) {
        $match = ""
        ForEach ($entry in $entries) {
            $match = ""
            if($appkey -eq $entry.key) {
                $match = "1"
                break;
            }
        }
        if ($match -eq 1) {
            $apprec = $apprec + "," +$entry.get_InnerXML()
        } else {
            $apprec = $apprec + ","
        }
    }

    $apprec = $apprec + ",$($schedules.entry.key)"
    # $entries1 = $schedules.entry
    # ForEach ($schkey in $schkeys) {
    #     ForEach ($entry1 in $entries1) {
    #         $match = ""
    #         if($schkey -eq $entry1.key) {
    #             $match = "1"
    #             break;
    #         }
    #     }
    #     if ($match -eq 1) {
    #         $apprec = $apprec + "," +$entry1.get_InnerXML()
    #     } else {
    #         $apprec = $apprec + ","
    #     }
    # }
    $apprec = $apprec + "," + $schedules.entry.schedule.startDate
    $apprec = $apprec + "," + $schedules.entry.schedule.endDate
    $apprec = $apprec + "," + $schedules.entry.schedule.executionTime.hour
    $apprec = $apprec + "," + $schedules.entry.schedule.executionTime.minute
    $apprec = $apprec + "," + $schedules.entry.schedule.executionTime.second
    $apprec = $apprec + "," + $schedules.entry.schedule.scheduleType
    $apprec = $apprec + "," + $schedules.entry.schedule.hourlyType
    $apprec = $apprec + "," + $schedules.entry.schedule.dailyType
    $apprec = $apprec + "," + $schedules.entry.schedule.monthlyType
    $apprec = $apprec + "," + $schedules.entry.schedule.skipHolidays
    $apprec = $apprec + "," + $schedules.entry.schedule.hourlyStep
    $apprec = $apprec + "," + $schedules.entry.schedule.sequence
    $apprec = $apprec + "," + $schedules.entry.schedule.dayOfWeek
    $apprec = $apprec + "," + $schedules.entry.schedule.dayOfMonth
    $apprec = $apprec + "," + $schedules.entry.schedule.month
    
    $apprec | Out-File -FilePath .\apps.csv -Append -Force -Encoding ascii
}



