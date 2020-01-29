# Powershell Profile
My Windows Powershell profile with tools that I frequently use.

## Notable Cmdlets:

### Get-VideoCuts
Uses ffmpeg to cut a video into multiple arbitrary time slices. Accepts an array of time slices, or a file containing a list of time slices.

### ConvertAndCombineImagesToPDF
Converts images to PDFs, and combines those PDFs into a single PDF. It is possible to specify a width so that all of the images in the output PDF have a uniform width.

### New-ISOFile
A modified version of [this script](https://gallery.technet.microsoft.com/scriptcenter/New-ISOFile-function-a8deeffd) that converts input files to an ISO. I have added a percent progress meter so that you know how far along the conversion is.
