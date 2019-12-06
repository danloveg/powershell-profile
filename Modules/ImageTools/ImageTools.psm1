Function Get-ImageSizes {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
        [String[]] $images
    )

    BEGIN {}

    PROCESS {
        ForEach ($image in $images) {
            magick identify -quiet -format "%f: %Wx%H`n" $image
        }
    }

    END {}
}

Function ConvertAndCombineImagesToPDF([String[]] $images, [String] $uniformWidth, [String] $outputPath) {
    $convertedPDFs = @()

    ForEach ($image in $images) {
        Write-Host ("Processing {0}" -f $image)
        $imageExtension = [System.IO.Path]::GetExtension($image)

        If ($imageExtension -eq ".pdf") {
            $convertedPDFs += $image
            Write-Host ("File is already in PDF format.`n")
            Continue
        }

        Write-Host ("Resizing image to width {0}." -f $uniformWidth)
        magick mogrify -quiet -resize "$($newWidth)x" $image

        $jpg = $NULL
        If ($imageExtension -ne ".jpg") {
            Write-Host "Converting image to intermediate JPG."
            $jpg = $image.Replace($imageExtension, '.jpg')
            magick convert $image $jpg
        }

        Write-Host "Converting to PDF."
        $pdf = $image.Replace($imageExtension, '.pdf')
        If ($NULL -ne $jpg) {
            magick convert $jpg $pdf
        }
        Else {
            magick convert $image $pdf
        }
        $convertedPDFs += $pdf

        Write-Host "Cleaning up files."
        If ($NULL -ne $jpg) {
            Remove-Item $jpg
        }
        Remove-Item $image

        Write-Host
    }

    Write-Host ("Combining PDFs, outputting to {0}." -f $outputPath)
    pdftk $convertedPDFs cat output $outputPath
    Write-Host ("`nDone.") -ForegroundColor Green
}


Export-ModuleMember -Function @(
    'Get-ImageSizes',
    'ConvertAndCombineImagesToPDF'
)