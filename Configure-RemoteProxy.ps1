function Configure-RemoteProxy {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$proxySettings,
        
        [Parameter(Position = 1)]
        [switch]$RemoveProxy,
        
        [string]$targetComputersFile
    )

    $proxyInfo = $proxySettings -split ":"
    $hostname = $proxyInfo[0]
    $port = $proxyInfo[1]

    $scriptBlock = {
        param ($server, $port)
        
        if ($using:RemoveProxy) {
            Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -Name ProxyServer -Value ""
            Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -Name ProxyEnable -Value 0
            Write-Host "Proxy settings removed on $env:COMPUTERNAME."
        }
        else {
            if ((Test-NetConnection -ComputerName $server -Port $port).TcpTestSucceeded) {
                Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -Name ProxyServer -Value "$($server):$($port)"
                Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -Name ProxyEnable -Value 1
                Write-Host "Proxy settings set for $server:$port on $env:COMPUTERNAME."
            }
            else {
                Write-Host "The proxy address is not valid:  $server:$port on $env:COMPUTERNAME."
            }
        }
    }

    if ($targetComputersFile -ne $null) {
        $targetComputers = Get-Content $targetComputersFile
        foreach ($computer in $targetComputers) {
            Invoke-Command -ComputerName $computer -ScriptBlock $scriptBlock -ArgumentList $hostname, $port
        }
    }
    else {
        Write-Host "Please provide a list of target computers using the -targetComputersFile parameter."
    }
}

# Example usage:
# Configure-RemoteProxy -proxySettings "proxy.server.com:3128" -targetComputersFile "C:\computers.txt"
# Configure-RemoteProxy -proxySettings "proxy.server.com:3128" -RemoveProxy -targetComputersFile "C:\computers.txt"
