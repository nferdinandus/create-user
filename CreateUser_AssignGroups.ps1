Install-Module Microsoft.Graph
$Scopes = @("User.ReadWrite.All","group.ReadWrite.All")
Connect-MgGraph -scopes $Scopes -TenantId "2210c954-de6e-4f93-82f9-a5ab5ba1ed18"


# Prompt user to enter information
$givenname = Read-Host -Prompt "Enter First Name"
$surname = Read-Host -Prompt "Enter Surname"
$companyname = Read-Host -Prompt "Enter Company"
$jobtitle = Read-Host -Prompt "Enter Job Title"
$businessPhones = @()
$businessPhones += Read-Host -Prompt "Business Phone"

# Function to capitalize every word in a string
function Capitalize-EveryWord { param ( [string]$inputString )

 
$words = $inputString.Split(" ")
$capitalizedWords = foreach ($word in $words) {
    if ($word -in "van", "der", "de") {
        $word
    } else {
        $firstLetter = $word.Substring(0,1).ToUpper()
        $restOfWord = $word.Substring(1).ToLower()
        $firstLetter + $restOfWord
    }
}

$capitalizedString = $capitalizedWords -join " "

return $capitalizedString
}

# Display options for usage location
Write-Host "Choose usage location:"
Write-Host "1. United Kingdom"
Write-Host "2. Netherlands"
$choice = Read-Host -Prompt "Enter 1 or 2"

# Based on user's choice, set location information
if ($choice -eq "1") {
    $usagelocation = "GB"
    $city = Read-Host -Prompt "Enter City"
    $state = Read-Host -Prompt "Enter State"
    $streetAddress = Read-Host -Prompt "Street Address"
    $country = "United Kingdom"
    $postalCode = Read-Host -Prompt "Postal Code"
    $preferredlanguage = "en-US"
} elseif ($choice -eq "2") {
    $usagelocation = "NL"
    $streetAddress = "Elizabeth Cady Stantonplein 435"
    $city = "Amsterdam"
    $country = "Netherlands"
    $postalCode = "1102BL"
}

# Function to generate a random password
function Generate-RandomPassword {
    $length = 16
    $characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*"
    $randomPassword = ""
    for ($i = 0; $i -lt $length; $i++) {
        $randomPassword += $characters[(Get-Random -Minimum 0 -Maximum $characters.Length)]
    }
    return $randomPassword
}

# Generate random password and domain name
$randomPassword = Generate-RandomPassword

$domainOptions = @("4bf4rx.onmicrosoft.com")
Write-Host "Choose a domain:"
for ($i = 0; $i -lt $domainOptions.Count; $i++) {
    Write-Host "$($i+1). $($domainOptions[$i])"
}
$domainChoice = Read-Host -Prompt "Enter 1" 
$selectedDomain = $domainOptions[$domainChoice - 1]

$domainname = $selectedDomain



# Capitalize names and job title
$givenname = Capitalize-EveryWord -inputString $givenname
$surname = Capitalize-EveryWord -inputString $surname
$companyname = Capitalize-EveryWord -inputString $companyname
$givenname_initial = $givenname[0]
$jobtitle = $jobtitle.ToUpper()

# Create user profile JSON object
$displayname = "$givenname $surname | $companyname"
$mailNickname = "$givenname_initial.$surname" -replace ' ', ''
$userPrincipalName = "$givenname_initial.$surname@$domainname" -replace ' ', ''
$json = @{
    accountEnabled = $true
    displayName = $displayname
    givenName = $givenname
    jobTitle = $jobtitle
    mailNickname = $mailNickname
    passwordProfile = @{
        forceChangePasswordNextSignIn = $true
        password = $randomPassword
    }
    surname = $surname
    userPrincipalName = $userPrincipalName
    usageLocation = $usagelocation
    streetAddress = $streetAddress
    city = $city
    state = $state
    country = $country
    postalCode = $postalCode
    consentProvidedForMinor = "Granted"
    ageGroup = "Adult"
    businessPhones = $businessPhones
    preferredLanguage = $preferredlanguage
} | ConvertTo-Json

# Make API call to create user
$uri = "https://graph.microsoft.com/beta/users"
Write-Host "Creating new user"
$response = Invoke-MgGraphRequest -Method POST -Uri $uri -Body $json -ContentType "application/json"
Write-Host "User created successfully"
Write-Host "Generated password: $randomPassword"

# Get the user ID and add user to groups
$user = Get-MgUser -Filter "userPrincipalName eq '$userPrincipalName'"
if ($user) {
    $userId = $user.Id
    Import-Module Microsoft.Graph.Groups
    $groupIds = @("dc0858d5-d2b7-4570-b52e-52b26ca028bb")
    foreach ($groupId in $groupIds) {
        New-MgGroupMember -GroupId $groupId -DirectoryObjectId $userId
    }

if ($choice -eq "2") {
    New-MgGroupMember -GroupId "70be3aea-cbe8-4e5b-83ef-6237177fdd9c" -DirectoryObjectId $userId
    Write-Host "Added to Group: Sales and Marketing"
} elseif ($choice -eq "1") {
    New-MgGroupMember -GroupId "b1aa6e5a-ff44-4562-9feb-f21e92d40491" -DirectoryObjectId $userId
    Write-Host "Added to Group: Retail"
}

Write-Host "Added to Group: Everyone"
Write-Host "Does the user need a E5 License?"
$license = Read-Host -Prompt "Enter yes or no"
# Based on user's choice, set location information
if ($license -eq "yes") {
    New-MgGroupMember -GroupId "941166ab-d6ba-42fa-ace6-ea53e460430d" -DirectoryObjectId $userId
    Write-Host "Added to Group: License Microsoft 365 E3"
    Write-Host "Please manually assign - Distribution Groups" -ForegroundColor Yellow
} elseif ($choice -eq "no") {
}
}

