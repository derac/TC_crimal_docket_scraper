# This script scrapes the Travis County criminal docket search
# using an attorney's first and last name, supplied in the input_data.csv
# Derek Olson Mar 2023

### SETTING UP THE INITIAL DATA

# Import the csv data, reference it from the root of where the script was
# run from to avoid issues with running the script while the current working
# directory is different.
$attorneys_to_search_list = Import-Csv "$PSScriptRoot\input_data.csv"
$csv_output_file = "$PSScriptRoot\output_data.csv"
$docket_search_url_template = "https://publiccourts.traviscountytx.gov/DSA/api/dockets/settings?criteriaId=attorney&start={0}&end={1}&attorneyLastName={2}&attorneyFirstName={3}"
# we will sleep after every http request to be nice to the host and hopefully not get banned
$sleep_time_ms = 500
# initialize the output as an empty array that we will add to in the loop as we scrape data
$output_csv_data = @()

### SEACHING FOR THE INFORMATION WE NEED AND BUILDING THE OUTPUT
# We will loop over each person in the csv, row by row
foreach ($attorney in $attorneys_to_search_list) {
    # get the start and end dates, try to make them look the same
    # as they do on the website to not attract as much attention

    $start_time = "$(Get-Date -uformat '%Y-%m-%d')T05:00:00.000Z"
    $end_time = "$((Get-Date).AddDays(30) | Get-Date -uformat '%Y-%m-%d')T04:59:59.000Z"

    $docket_search_url = $docket_search_url_template -f $start_time, $end_time, $attorney.last, $attorney.first
    Write-Host "Searching attorney named: $($attorney.first) $($attorney.last)"
    Write-Host "Scraping $docket_search_url"
    $docket_search_response = Invoke-WebRequest -Uri $docket_search_url
    Start-Sleep -Milliseconds $sleep_time_ms
    $docket_search_body = $docket_search_response.Content
    $docket_search_data = ConvertFrom-Json $docket_search_body

    # # loop over the results and include them all, in case more than one match is returned
    # foreach ($result in $docket_search_data) {
    #     $booking_number = $result.bookingNumber
    #     $booking_lookup_url = $booking_lookup_url_template -f $booking_number

    #     # make the call to get the booking
    #     Write-Host "Scraping $booking_lookup_url"
    #     $booking_lookup_response = Invoke-WebRequest -Uri $booking_lookup_url
    #     Start-Sleep -Milliseconds $sleep_time_ms
    #     $booking_lookup_body = $booking_lookup_response.Content
    #     $booking_lookup_data = ConvertFrom-Json $booking_lookup_body
    #     # building the output, the pscustomobject cast is needed
    #     # because it's what export-csv expects
    #     $output_csv_data += [PSCustomObject]@{
    #         name           = $booking_lookup_data.fullName
    #         booking_date   = $booking_lookup_data.bookingDate
    #         booking_number = $booking_lookup_data.bookingNumber
    #         data_url       = $booking_lookup_url
    #     }
    # }
}

$output_csv_data | Export-Csv -Path $csv_output_file -NoTypeInformation -Force