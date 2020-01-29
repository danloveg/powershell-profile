Function Get-ImageSizes {
    [CmdletBinding()]
	Param (
		[Parameter(Mandatory=$True, ValueFromPipeline=$True)]
		[String[]] $images
	)

    BEGIN {}

    PROCESS{
        ForEach ($image in $images) {
            magick identify -quiet -format "%f: %Wx%H`n" $image
        }
    }

    END {}
}

Function ConvertAndCombineImagesToPDF {
    <#
    .synopsis
    Combines a list of images into a compact PDF. Depends on the user having ImageMagick and qpdf
    installed and in their path.
    - The user specifies a list of images they would like converted and combined to a PDF.
    - A width may be specified so that all images have the same width at the output PDF.
    - The user specifies the path of the output PDF.
    - The user can choose if they want to keep all of the intermediate files.

    .description
    Resizes each image if a width is specified, converts the image to JPG if it's not already a
    JPG, and converts the JPG to PDF.
    Once all images are converted to PDF, they are combined into a single PDF.

    .parameter Images
    An array of image paths.
    .parameter Width
    Determines the width each image will be resized to before converting to PDF. The point of
    specifying a width is to improve the viewing experience of the output PDF in a PDF reader.
    .parameter OutputPath
    The path to the combined output PDF.
    .parameter KeepAll
    By default, the initial images and their JPG intermediates are deleted in the process of
    conversion. If -KeepAll is specified, nothing is deleted.

    .example
    Combine the following tif images into a PDF called final.pdf with a uniform width of 4000px:
    page1.tif (4300x3000)
    page2.tif (4000x3000)

    ConvertAndCombineImagesToPDF -Images @("page1.tif", "page2.tif") -Width 4000 -OutputPath final.pdf

    .example
    Combine all jpgs in this folder to a pdf called combined.pdf, and keep all of the files:

    Get-ChildItem -Path ./* -Include *.jpg | ConvertAndCombineImagesToPDF -OutputPath combined.pdf -KeepAll
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True, ValueFromPipeline=$True)] [String[]] $Images,
        [Parameter(Mandatory=$False)] [String] $Width,
        [Parameter(Mandatory=$True)] [String] $OutputPath,
        [Parameter(Mandatory=$False)] [Switch] $KeepAll
    )

    BEGIN {
        If ($Width -And -Not($Width -Match '\d+')) {
            Write-Host "Width `"$($Width)`" is not a number." -ForegroundColor Red
            return
        }

        $convertedPDFs = @()
    }

    PROCESS {
        ForEach ($image in $Images) {
            Write-Host ("Processing {0}" -f $image)
            $imageExtension = [System.IO.Path]::GetExtension($image)

            If ($imageExtension -eq ".pdf") {
                $convertedPDFs += $image
                Write-Host ("File is already in PDF format.`n")
                Continue
            }

            If ($Width) {
                $imageWidth = magick identify -quiet -format "%W" $image
                If ($imageWidth -ne $Width) {
                    Write-Host ("Resizing image to width {0}." -f $Width)
                    magick mogrify -quiet -resize "$($Width)x" $image
                }
            }

            $jpg = $NULL
            If ($imageExtension -ne ".jpg") {
                Write-Host "Converting image to intermediate JPG."
                $jpg = $image.Replace($imageExtension, '.jpg')
                magick convert -quiet $image $jpg
            }

            Write-Host "Converting to PDF."
            $pdf = $image.Replace($imageExtension, '.pdf')
            If ($NULL -ne $jpg) {
                magick convert -quiet $jpg $pdf
            }
            Else {
                magick convert -quiet $image $pdf
            }
            $convertedPDFs += $pdf

            If (-Not $KeepAll) {
                Write-Host "Cleaning up files."
                If ($NULL -ne $jpg) {
                    Remove-Item $jpg
                }
                Remove-Item $image
            }

            Write-Host
        }
    }

    END {
        Write-Host ("Combining PDFs with qpdf, outputting to {0}." -f $OutputPath)
        qpdf --empty --pages $convertedPDFs -- $OutputPath
        Write-Host ("`nDone.") -ForegroundColor Green
    }
}


Export-ModuleMember -Function @(
    'Get-ImageSizes',
    'ConvertAndCombineImagesToPDF'
)
