$ErrorActionPreference = 'Stop'

function Join-FieldValues {
    param([object[]]$Values)

    $items = New-Object 'System.Collections.Generic.List[string]'
    foreach ($value in $Values) {
        if ($null -eq $value) { continue }
        if ($value -is [System.Array]) { $parts = $value } else { $parts = @($value) }
        foreach ($part in $parts) {
            if ($null -eq $part) { continue }
            $text = ([string]$part).Trim()
            if (-not [string]::IsNullOrWhiteSpace($text)) { $items.Add($text) }
        }
    }

    $unique = @($items | Select-Object -Unique)
    if ($unique.Count -eq 0) { return 'Non renseigne' }
    return ($unique -join '; ')
}

function Get-CcasField {
    param([Parameter(Mandatory = $true)][string]$Name)

    $view = [Microsoft.Win32.RegistryView]::Default
    if ([Environment]::Is64BitOperatingSystem) {
        $view = [Microsoft.Win32.RegistryView]::Registry64
    }

    $base = $null
    $key = $null
    $parent = $null
    try {
        $base = [Microsoft.Win32.RegistryKey]::OpenBaseKey(
            [Microsoft.Win32.RegistryHive]::LocalMachine, $view)

        # BGInfo custom registry field: HKLM64\SOFTWARE\CCAS\<field>.
        $key = $base.OpenSubKey(('SOFTWARE\CCAS\' + $Name))
        if ($null -ne $key) {
            $value = $key.GetValue('', $null)
            if ($null -ne $value -and -not [string]::IsNullOrWhiteSpace([string]$value)) {
                return ([string]$value).Trim()
            }
            $valueNames = @($key.GetValueNames() | Where-Object { $_ -ne '' })
            if ($valueNames.Count -eq 1) {
                $value = $key.GetValue($valueNames[0], $null)
                if ($null -ne $value) { return ([string]$value).Trim() }
            }
        }

        # Also handle a value named <field> directly under HKLM\SOFTWARE\CCAS.
        $parent = $base.OpenSubKey('SOFTWARE\CCAS')
        if ($null -ne $parent) {
            $value = $parent.GetValue($Name, $null)
            if ($null -ne $value -and -not [string]::IsNullOrWhiteSpace([string]$value)) {
                return ([string]$value).Trim()
            }
        }
    }
    finally {
        if ($null -ne $key) { $key.Dispose() }
        if ($null -ne $parent) { $parent.Dispose() }
        if ($null -ne $base) { $base.Dispose() }
    }

    return 'Non renseigne'
}

function Format-LinkSpeed {
    param([object]$BitsPerSecond)
    if ($null -eq $BitsPerSecond -or [double]$BitsPerSecond -le 0) { return 'Non renseignee' }
    $speed = [double]$BitsPerSecond
    if ($speed -ge 1000000000) { return ('{0:N0} Gbit/s' -f ($speed / 1000000000)) }
    if ($speed -ge 1000000) { return ('{0:N0} Mbit/s' -f ($speed / 1000000)) }
    return ('{0:N0} kbit/s' -f ($speed / 1000))
}

try {
    Add-Type -AssemblyName System.Windows.Forms

    $netConfigs = @()
    try {
        $netConfigs = @(Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration `
            -Filter 'IPEnabled = TRUE' -ErrorAction Stop)
    }
    catch { $netConfigs = @() }

    $ipValues = @(); $macValues = @(); $subnetValues = @()
    $gatewayValues = @(); $dhcpValues = @(); $dnsValues = @()
    foreach ($config in $netConfigs) {
        $ipValues += @($config.IPAddress)
        $macValues += @($config.MACAddress)
        $subnetValues += @($config.IPSubnet)
        $gatewayValues += @($config.DefaultIPGateway)
        $dhcpValues += @($config.DHCPServer)
        $dnsValues += @($config.DNSServerSearchOrder)
    }

    $netAdapters = @()
    foreach ($config in $netConfigs) {
        try {
            $adapter = Get-CimInstance -ClassName Win32_NetworkAdapter `
                -Filter ("Index = {0}" -f [int]$config.Index) -ErrorAction Stop
            if ($null -ne $adapter) { $netAdapters += $adapter }
        }
        catch { }
    }

    $cpuValues = @()
    try { $cpuValues = @(Get-CimInstance -ClassName Win32_Processor | ForEach-Object { $_.Name }) }
    catch { }

    $memoryText = 'Non renseignee'
    try {
        $computer = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop
        if ($computer.TotalPhysicalMemory) {
            $memoryText = ('{0:N1} Go' -f ($computer.TotalPhysicalMemory / 1GB))
        }
    }
    catch { }

    $freeValues = @()
    try {
        foreach ($disk in @(Get-CimInstance -ClassName Win32_LogicalDisk -Filter 'DriveType = 3')) {
            if ($null -ne $disk.FreeSpace) {
                $freeValues += ('{0} {1:N1} Go libres' -f $disk.DeviceID, ($disk.FreeSpace / 1GB))
            }
        }
    }
    catch { }

    $cardValues = @($netAdapters | ForEach-Object { $_.Name })
    $speedValues = @($netAdapters | ForEach-Object { Format-LinkSpeed $_.Speed })

    $logonServer = $env:LOGONSERVER
    if ([string]::IsNullOrWhiteSpace($logonServer)) { $logonServer = 'Non renseigne' }

    $lines = @(
        ('Nom Ordinateur : {0}' -f $env:COMPUTERNAME),
        ('Adresse IP : {0}' -f (Join-FieldValues $ipValues)),
        '',
        ('Compte utilisateur : {0}' -f $env:USERNAME),
        ('Domaine : {0}' -f $env:USERDOMAIN),
        ('Serveur de domaine : {0}' -f $logonServer),
        '',
        ('OS Version : {0}' -f (Get-CcasField 'OS Version')),
        ('Socle Origine : {0}' -f (Get-CcasField 'SocleOrigine')),
        ('Socle Actuel : {0}' -f (Get-CcasField 'SocleActuel')),
        '',
        ('CPU : {0}' -f (Join-FieldValues $cpuValues)),
        ('Memoire physique : {0}' -f $memoryText),
        ('Espace disque restant : {0}' -f (Join-FieldValues $freeValues)),
        ('MAC Adresse : {0}' -f (Join-FieldValues $macValues)),
        '',
        ('Masque sous-reseau : {0}' -f (Join-FieldValues $subnetValues)),
        '',
        ('Passerelle : {0}' -f (Join-FieldValues $gatewayValues)),
        ('Serveur DHCP : {0}' -f (Join-FieldValues $dhcpValues)),
        ('Serveur DNS : {0}' -f (Join-FieldValues $dnsValues)),
        '',
        ('Carte reseau : {0}' -f (Join-FieldValues $cardValues)),
        ('Vitesse reseau : {0}' -f (Join-FieldValues $speedValues))
    )

    $report = $lines -join [Environment]::NewLine
    [System.Windows.Forms.Clipboard]::SetText($report)
    Write-Output 'Rapport copie dans le presse-papiers.'
}
catch {
    Write-Error $_
    exit 1
}
