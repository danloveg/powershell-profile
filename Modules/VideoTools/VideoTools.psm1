# Tools to manipulate videos
# Author: Daniel Lovegrove

Function Get-VideoCuts {
    <#
    .synopsis
    Video Slicer using FFmpeg
    - User specifies a path to a video to cut up
    - User specifies an array of one or more timespans to use to make cuts of video
    - A starting ID can be specified
    The script outputs cut video files in the same directory as the input file. The
    videos will be named "<input file name>_part<two digit ID>.<input file extension>"

    .description
    Create a series of slices of a video according to an array of inputted
    timestamps. Uses FFmpeg behind the scenes.

    .parameter video
    The path to the video to cut up
    .parameter timeList
    An array of timestamps. Timestamps must be in the form @("HH:mm:ss", "HH:mm:ss"),
    with the first time being the start time to start cutting and the second time'
    being the end of the cut.
    .parameter firstPart
    The ID to give the first video. This value increments with each outputted
    slice/cut.

    .example
    Get-VideoCuts -video "C:/path/to/video.mp4" -timeList @(@("00:00:00", "00:01:00"), @("00:03:00", "00:04:30"))
    This example creates two cut videos. The first video is a cut from the start of
    the input video to one minute in. The second cut is from 3 minutes to 4 minutes
    30 seconds.
    The path of the first cut video will be "C:/path/to/video_part01.mp4"
    The path of the second cut video will be "C:/path/to/video_part02.mp4"

    .example
    Get-VideoCuts -video "./video.mp4" -timeList @(@("00:10:00", "00:11:00")) -firstPart 77
    This example creates one cut video. The video is a cut from ten minutes to
    eleven minutes. Since the firstPart parameter was supplied, the ID of the cut
    will reflect this parameter.
    The path of the cut video will be "./video_part77.mp4"
    #>

    Param(
        [Parameter(Mandatory=$True)] [String] $video,
        [Parameter(Mandatory=$True)] [Object[]] $timeList,
        [Int] $firstPart=1
    )

    If (-Not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
        Write-Error "ffmpeg is not installed or accessible to PowerShell on the PATH."
        Write-Host "Visit https://ffmpeg.org for ffmpeg installation instructions."
        return
    }

    If (-Not (Test-Path -Path $video -PathType Leaf)) {
        Write-Error ("File {0} does not exist." -f $video)
        return
    }

    $fileExtension = [System.IO.Path]::GetExtension($video)
    If ([String]::IsNullOrEmpty($fileExtension)) {
        Write-Error "Video does not have a valid file extension."
        return
    }

    $currentPart = $firstPart
    $fileName = $video.Replace($fileExtension, ('_part{0:D2}' + $fileExtension))

    ForEach ($time in $timeList) {
        $currentOutputFileName = ($fileName -f $currentPart)

        $timeDiff = New-TimeSpan ([String] $time[0]) ([String] $time[1])
        $numSeconds = $timeDiff.TotalSeconds

        Write-Host ("`nffmpeg -hide_banner -ss {0} -i {1} -t {2} {3}`n" -f $time[0], $video, $numSeconds, $currentOutputFileName) -ForegroundColor Green

        ffmpeg -hide_banner -ss $time[0] -i $video -t $numSeconds $currentOutputFileName

        If ($LASTEXITCODE -ne 0) {
            Write-Host "FFmpeg ran into an error. Stopping."
            return
        }

        $currentPart += 1
    }
}

Export-ModuleMember -Function @(
    "Get-VideoCuts"
)
