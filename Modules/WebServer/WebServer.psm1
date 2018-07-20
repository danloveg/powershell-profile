# Web server using Node http-server

Set-Alias Serve Start-WebServer

Function Start-WebServer([Int] $Port = 8090, [String] $Directory = ".") {
    Try {
        # No need to check port number, http-server will do that
        If (-Not (Test-Path $Directory)) {
            Write-Error "Cannot serve from $($Directory) since it does not exist"
            return
        }

        If (Get-Command http-server -ErrorAction SilentlyContinue ) {
            http-server -p $Port $Directory
        } Else {
            Write-Warning "http-server is not installed. Attempting to install globally now with npm."

            If (Get-Command npm -ErrorAction SilentlyContinue) {
                npm install -g http-server
                http-server -p $Port $Directory
            } Else {
                Write-Warning "Cannot install http-server without npm (Node Package Manager) installed."
                Write-Host "Install NodeJS to get npm: https://nodejs.org/en/"
            }
        }
    } Catch {
        Write-Error $_.Exception.Message
    }
}

Export-ModuleMember -Function "Start-WebServer"
Export-ModuleMember -Alias "Serve"
