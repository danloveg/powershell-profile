$ISOFileTypeDefinition = @"
using System;

public class ISOFile  
{
    public unsafe static void Create(string Path, object Stream, int BlockSize, int TotalBlocks)
    {
        int bytes = 0;
        byte[] buf = new byte[BlockSize];
        var ptr = (System.IntPtr)(&bytes);
        var output = System.IO.File.OpenWrite(Path);
        var input = Stream as System.Runtime.InteropServices.ComTypes.IStream;

        int percentComplete = 0;
        int lastPercentWritten = -1;
        int blocksWritten = 0;

        if (o != null)
        {
            for (int i = 0; i < TotalBlocks; i++)
            {
                input.Read(buf, BlockSize, ptr);
                output.Write(buf, 0, bytes);

                // Tracks progress
                blocksWritten++;
                percentComplete = (int) Math.Round((double) blocksWritten * 100 / TotalBlocks);
                if (percentComplete != lastPercentWritten)
                {
                    Console.Write(String.Format("{0} %\r", percentComplete).PadLeft(6));
                    lastPercentWritten = percentComplete;
                }
            }
            output.Flush();
            output.Close();
            Console.WriteLine();
        }
    }
}
"@

Function New-ISOFile {  
    <#
    .Synopsis
    Creates a new .iso file

    .Description
    The New-IsoFile cmdlet creates a new .iso file containing content from chosen folders

    .Example
    New-IsoFile "c:\tools","c:Downloads\utils"
    This command creates a .iso file in $env:temp folder (default location) that contains
    c:\tools and c:\downloads\utils folders. The folders themselves are included at the root of
    the .iso image.

    .Example
    New-IsoFile -FromClipboard -Verbose
    Before running this command, select and copy (Ctrl-C) files/folders in Explorer first.

    .Example
    dir c:\WinPE | New-IsoFile -Path c:\temp\WinPE.iso -BootFile "${env:ProgramFiles(x86)}\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\efisys.bin" -Media DVDPLUSR -Title "WinPE"
    This command creates a bootable .iso file containing the content from c:\WinPE folder, but
    the folder itself isn't included. Boot file etfsboot.com can be found in Windows ADK. Refer
    to IMAPI_MEDIA_PHYSICAL_TYPE enumeration for possible media types: 
    http://msdn.microsoft.com/en-us/library/windows/desktop/aa366217(v=vs.85).aspx

    .Notes
    NAME: New-ISOFile
    AUTHOR: Chris Wu, Daniel Lovegrove
    #> 

    [CmdletBinding(DefaultParameterSetName = 'Source')]Param( 
        [Parameter(Position = 1, Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'Source')]$Source,  
        [Parameter(Position = 2)][string]$Path = "$env:temp\$((Get-Date).ToString('yyyyMMdd-HHmmss.ffff')).iso",  
        [ValidateScript( { Test-Path -LiteralPath $_ -PathType Leaf })][string]$BootFile = $null, 
        [ValidateSet('CDR', 'CDRW', 'DVDRAM', 'DVDPLUSR', 'DVDPLUSRW', 'DVDPLUSR_DUALLAYER', 'DVDDASHR', 'DVDDASHRW', 'DVDDASHR_DUALLAYER', 'DISK', 'DVDPLUSRW_DUALLAYER', 'BDR', 'BDRE')][string] $Media = 'DVDPLUSRW_DUALLAYER', 
        [String]$Title = (Get-Date).ToString("yyyyMMdd-HHmmss.ffff"),  
        [Switch]$Force,
        [Parameter(ParameterSetName = 'Clipboard')][switch]$FromClipboard 
    ) 

    Begin {  
        ($cp = new-object System.CodeDom.Compiler.CompilerParameters).CompilerOptions = '/unsafe' 
        If (-Not('ISOFile' -as [Type])) {  
            Add-Type -CompilerParameters $cp -TypeDefinition $ISOFileTypeDefinition
        } 

        if ($BootFile) { 
            if ('BDR', 'BDRE' -contains $Media) {
                Write-Warning "Bootable image doesn't seem to work with media type $Media"
            } 
            ($Stream = New-Object -ComObject ADODB.Stream -Property @{Type = 1 }).Open()  # adFileTypeBinary 
            $Stream.LoadFromFile((Get-Item -LiteralPath $BootFile).Fullname) 
            ($Boot = New-Object -ComObject IMAPI2FS.BootOptions).AssignBootImage($Stream) 
        } 

        $MediaType = @('UNKNOWN', 'CDROM', 'CDR', 'CDRW', 'DVDROM', 'DVDRAM', 'DVDPLUSR', 'DVDPLUSRW', 'DVDPLUSR_DUALLAYER', 'DVDDASHR', 'DVDDASHRW', 'DVDDASHR_DUALLAYER', 'DISK', 'DVDPLUSRW_DUALLAYER', 'HDDVDROM', 'HDDVDR', 'HDDVDRAM', 'BDROM', 'BDR', 'BDRE') 

        Write-Verbose -Message "Selected media type is $Media with value $($MediaType.IndexOf($Media))"
        ($Image = New-Object -com IMAPI2FS.MsftFileSystemImage -Property @{VolumeName = $Title}).ChooseImageDefaultsForMediaType($MediaType.IndexOf($Media)) 

        if (-Not($Target = New-Item -Path $Path -ItemType File -Force:$Force -ErrorAction SilentlyContinue)) {
            Write-Error -Message "Cannot create file $Path. Use -Force parameter to overwrite if the target file already exists."
            break
        }
    }

    Process {
        if ($FromClipboard) {
            if ($PSVersionTable.PSVersion.Major -lt 5) {
                Write-Error -Message 'The -FromClipboard parameter is only supported on PowerShell v5 or higher'
                break
            }
            $Source = Get-Clipboard -Format FileDropList
        }

        foreach ($item in $Source) { 
            if ($item -isnot [System.IO.FileInfo] -and $item -isnot [System.IO.DirectoryInfo]) { 
                $item = Get-Item -LiteralPath $item
            } 

            if ($item) {
                Write-Verbose -Message "Adding item to the target image: $($item.FullName)"
                try {
                    $Image.Root.AddTree($item.FullName, $true)
                }
                catch {
                    Write-Error -Message ($_.Exception.Message.Trim() + ' Try a different media type.')
                }
            }
        }
    }

    End {
        if ($Boot) {
            $Image.BootImageOptions = $Boot
        }
        $Result = $Image.CreateResultImage()
        [ISOFile]::Create($Target.FullName, $Result.ImageStream, $Result.BlockSize, $Result.TotalBlocks) 
        Write-Verbose -Message "Target image ($($Target.FullName)) has been created"
        $Target
    } 
} 

Export-ModuleMember -Function @(
    "New-IsoFile"
)
