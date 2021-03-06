Function Get-ImageSizes {
    [CmdletBinding()]
	Param (
		[Parameter(Mandatory=$True, ValueFromPipeline=$True)]
		[String[]] $images
	)

    BEGIN {}

    PROCESS{
        ForEach ($image in $images) {
            $data = magick identify -quiet -format '%f|%W|%H' $image

            $dataSplit = ([String] $data).Split('|')

            [PSCustomObject]@{
                Name = [String] $dataSplit[0];
                Width = [Int] $dataSplit[1];
                Height = [Int] $dataSplit[2];
            }
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
    .parameter JpegQuality
    Set the quality value ImageMagick uses to convert images to jpeg. Value can be 0 to 100, 0
    being the lowest quality. Lower quality images use less storage.
    .parameter OutputPath
    The path to the combined output PDF.
    .parameter KeepAll
    By default, the initial images and their JPG intermediates are deleted in the process of
    conversion. If -KeepAll is specified, nothing is deleted.

    .example
    Combine two TIFF images into a PDF called final.pdf with a uniform width of 4000px and a
    quality of 75:

    ConvertAndCombineImagesToPDF -Images @("page1.tif", "page2.tif") -Width 4000 -JpegQuality 75 -OutputPath final.pdf

    .example
    Combine all jpgs in this folder to a pdf called combined.pdf, and keep all of the files:

    Get-ChildItem -Path ./* -Include *.jpg | ConvertAndCombineImagesToPDF -OutputPath combined.pdf -KeepAll
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True, ValueFromPipeline=$True)] [String[]] $Images,
        [Parameter(Mandatory=$False)] [String] $Width,
        [Parameter(Mandatory=$False)] [String] $JpegQuality,
        [Parameter(Mandatory=$True)] [String] $OutputPath,
        [Parameter(Mandatory=$False)] [Switch] $KeepAll
    )

    BEGIN {
        If ($Width -And -Not($Width -Match '^\d+$')) {
            Write-Host "Width `"$($Width)`" is not a positive number." -ForegroundColor Red
            return
        }
        ElseIf ($Width -eq "0") {
            Write-Host "Width cannot be zero." -ForegroundColor Red
            return
        }

        If ($JpegQuality -And -Not($JpegQuality -Match '^\d+$')) {
            Write-Host "JpegQuality `"$($JpegQuality)`" is not a positive number." -ForegroundColor Red
            return
        }
        ElseIf ($JpegQuality) {
            $quality = $JpegQuality -as [Int32]
            If ($quality -lt 0 -Or $quality -gt 100) {
                Write-Host "Quality must be between 0 and 100 (inclusive)" -ForegroundColor Red
                return
            }
        }

        $convertedPDFs = @()
    }

    PROCESS {
        ForEach ($image in $Images) {
            Write-Verbose ("Processing {0}" -f $image)
            $imageExtension = [System.IO.Path]::GetExtension($image)

            If ($imageExtension -eq ".pdf") {
                $convertedPDFs += $image
                Write-Verbose ("File is already in PDF format.`n")
                Continue
            }

            If ($Width) {
                $imageWidth = magick identify -quiet -format "%W" $image
                If ($imageWidth -ne $Width) {
                    Write-Verbose ("Resizing image to width {0}." -f $Width)
                    magick mogrify -quiet -resize "$($Width)x" $image
                }
            }

            $jpg = $NULL
            If ($imageExtension -ne ".jpg") {
                Write-Verbose "Converting image to intermediate JPG."
                $jpg = $image.Replace($imageExtension, '.jpg')
                If ($JpegQuality) {
                    magick convert -quiet $image -quality $JpegQuality $jpg
                }
                Else {
                    magick convert -quiet $image $jpg
                }
            }

            Write-Verbose "Converting to PDF."
            $pdf = $image.Replace($imageExtension, '.pdf')
            If ($NULL -ne $jpg) {
                magick convert -quiet $jpg $pdf
            }
            Else {
                magick convert -quiet $image $pdf
            }
            $convertedPDFs += $pdf

            If (-Not $KeepAll) {
                Write-Verbose "Cleaning up files."
                If ($NULL -ne $jpg) {
                    Remove-Item $jpg
                }
                Remove-Item $image
            }
        }
    }

    END {
        Write-Verbose ("Combining PDFs with qpdf, outputting to {0}." -f $OutputPath)
        qpdf --empty --pages $convertedPDFs -- $OutputPath
        $item = Get-Item $OutputPath
        $item
    }
}


Export-ModuleMember -Function @(
    'Get-ImageSizes',
    'ConvertAndCombineImagesToPDF'
)
