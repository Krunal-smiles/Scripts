[CmdletBinding()]
Param([Parameter(Mandatory=$True,Position=1)][string]$axwayxmlfile)

# Read all complete account nodes
$completeaccounts = Select-xml -Path $axwayxmlfile -XPATH "//completeAccount"

# Read all application custom properties entry to build csv header
$csvheader = "name,applicationReference,folder,anchor,sub_custom,transferTag,transferDirection,siteReference,dataTfr_type,dataTfr_custom,sch_key,sch_startDate,sch_endDate,sch_exe_hour,sch_exe_min,sch_exe_sec,sch_scheduleType,sch_hourlyType,sch_dailyType,sch_monthlyType,sch_skipHolidays,sch_hourlyStep,sch_sequence,sch_dayOfWeek,sch_dayOfMonth,sch_month"

# pta.on.success.OUT.do.delete
# pta.on.success.IN.do.move
# scheduledFolderMonitor
# pta.on.permfail.IN.do.delete
# pta.on.permfail.OUT.do.delete
# pta.on.success.OUT.do.move
# pta.on.permfail.OUT.do.move
# pta.on.tempfail.IN.do.delete

Set-Content -Path .\subs.csv -Force $csvheader

# Loop through each complete account node
ForEach ($completeaccount in $completeaccounts) {
    # read individual sub node
    $account = $completeaccount.node.account
    
    $subsps = $completeaccount.node.completeSubscription
    ForEach ($subscr in $subsps){
        $csvline = "$($account.name)"
        $csvline = $csvline + "," + $subscr.subscription.applicationReference + "," + $subscr.subscription.folder + "," + $subscr.subscription.anchor + ","

        $entries = $subscr.subscription.customAttributes.customProperties.entry
        ForEach ($entry in $entries) {
            $csvline = "$($csvline) --$($entry.key)=$($entry.get_InnerXML())"
        }

        # get subscriptions
        $apprec = ""
        $schedules = $subscr.schedules
        $apprec = $apprec + ",$($schedules.entry.key)"
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

        # transferConfiguration
        $tfrSubs = $subscr.transferConfiguration
        if ($null -eq $tfrSubs) {
            $csvline = $csvline + ",,,,," + $apprec
            $csvline | Out-File -FilePath .\subs.csv -Append -Force -Encoding ascii
        } else {
            foreach ($tfrSub in $tfrSubs) {
                $tfrline = ""
                $drfline = ""
                $drfcp = ""
                $dataTfrs = $tfrsub.dataTransformation
                ForEach ($dataTfr in $dataTfrs) {
                    $drfline = "$($drfline) -- $($dataTfr.type)"
                    $entries1 = $dataTfr.customAttributes.customProperties.entry
                    ForEach ($entry1 in $entries1) {
                        $drfcp = "$($drfcp) --$($entry1.key)=$($entry1.get_InnerXML())"
                    }
                }
                $tfrline = $drfline + "," + $drfcp
                $fline = $csvline + "," + $tfrSub.transferTag + "," + $tfrSub.transferDirection + "," + $tfrSub.siteReference + "," + $tfrline + $apprec
                $fline | Out-File -FilePath .\subs.csv -Append -Force -Encoding ascii
            }
        }
    }
}