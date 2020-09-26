#filename specified or not
$val = $Args[0]
if ( [string]::IsNullOrEmpty( $val ) ) {
    $Args = "in.mp4"
} else {
}

#extract filename
$Args=Split-Path $Args -leaf

#make a directory, move mp4 into it, set directory
New-Item -ItemType directory -Path ./"edit_"$Args
Move-Item -Path ./$Args -Destination ./"edit_"$Args/in.mp4
Set-Location -Path ./"edit_"$Args

#detect silence
ffmpeg -i "in.mp4" -af silencedetect=noise=-50dB:d=0.4 -f null - 2> spec.txt
[regex]::Matches((Get-Content .\spec.txt),"silence_start: ([1-9]\d*|0)(\.\d+)?") | foreach{$_.Value}> start.txt
[regex]::Matches((Get-Content .\spec.txt),"silence_end: ([1-9]\d*|0)(\.\d+)?") | foreach{$_.Value}> end.txt
$start_time = [regex]::Matches((Get-Content .\start.txt),"([1-9]\d*|0)(\.\d+)?") | foreach{$_.Value}
$end_time = [regex]::Matches((Get-Content .\end.txt),"([1-9]\d*|0)(\.\d+)?") | foreach{$_.Value}

#process each $bin_arr_length streams
$arr_length = $start_time.Length -1
$bin_arr_length=100
$trial_all = [Math]::Floor($arr_length/$bin_arr_length);

$index_bin_end =@(0)
if($trial_all -eq 0){
$index_bin_end += $arr_length 
}else{
foreach($i in 1..$trial_all){$index_bin_end += $i*$bin_arr_length}
if($index_bin_end[-1] -eq $arr_length){
}else {
$index_bin_end += $arr_length 
}
}


#generate outn.mp4 files
$num_trial_repeat = $index_bin_end.Length-1
foreach($j in 1..$num_trial_repeat){

$ffmpeg_com = 'ffmpeg -i in.mp4 -filter_complex "'
$index_process = ($index_bin_end[$j-1]+1)..($index_bin_end[$j])

foreach ($i in $index_process){$ffmpeg_com=$ffmpeg_com+"[0:v]trim="+[string]([single]$end_time[$i-1]-0.001)+":"+[string]([single]$start_time[$i]+0.001)+",setpts=PTS-STARTPTS[v"+[string]($i-1)+"]; [0:a]atrim="+[string]([single]$end_time[$i-1]-0.001)+":"+[string]([single]$start_time[$i]+0.001)+",asetpts=PTS-STARTPTS[a"+[string]($i-1)+"]; "}
foreach ($i in $index_process){$ffmpeg_com=$ffmpeg_com+"[v"+[string]($i-1)+"][a"+[string]($i-1)+"]"}
$num_streams = $index_process.Length
$ffmpeg_com = $ffmpeg_com +'concat=n='+[string]($num_streams)+':v=1:a=1[outv][outa]" -map "[outv]" -map "[outa]" out'+[string]$j+'.mp4'

$ffmpeg_com > com_ffmpeg.ps1
.\com_ffmpeg.ps1
}

#generate out.mp4 files
$ffmpeg_com_concat = 'ffmpeg '
foreach($j in 1..$num_trial_repeat){$ffmpeg_com_concat = $ffmpeg_com_concat + "-i out$j.mp4 "}
$ffmpeg_com_concat = $ffmpeg_com_concat + '-filter_complex "'
foreach($j in 1..$num_trial_repeat){$ffmpeg_com_concat = $ffmpeg_com_concat + "["+[string]($j-1)+":v] ["+[string]($j-1)+":a] "}
$ffmpeg_com_concat = $ffmpeg_com_concat + 'concat=n='+[string]($num_trial_repeat)+':v=1:a=1 [v] [a]" -map "[v]" -map "[a]" out.mp4'

$ffmpeg_com_concat > com_ffmpeg_concat.ps1
.\com_ffmpeg_concat.ps1

#normalize audio
ffmpeg -i "out.mp4" -vcodec copy -filter:a dynaudnorm=f=10:g=3 outtemp.mp4
ffmpeg -i "outtemp.mp4" -vcodec copy -filter:a loudnorm outall.mp4

#ffmpeg -i "out.mp4" -vcodec copy -af lowpass=4000,highpass=400 outall.mp4

#$ffmpeg_com_concat = 'ffmpeg -i "concat:out1.mp4'
#foreach($j in 2..$num_trial_repeat){$ffmpeg_com_concat = $ffmpeg_com_concat + "|out$j.mp4"}
#$ffmpeg_com_concat = $ffmpeg_com_concat + '" -vcodec copy -filter:a dynaudnorm=f=10:g=11 out.mp4'

#ffmpeg -f concat -safe 0 -i mylist.txt -c copy out.mp4
#ffmpeg -i out1.mp4 -i out2.mp4 -i out3.mp4 -i out4.mp4 -filter_complex "[0:v] [0:a] [1:v] [1:a] [2:v] [2:a] [3:v] [3:a] concat=n=4:v=1:a=1 [v] [a]" -map "[v]" -map "[a]" out.mp4
#ffmpeg -i "concat:out1.mp4|out2.mp4|out3.mp4|out4.mp4" -vcodec copy -filter:a dynaudnorm out.mp4

# move encoded file to upper directory
Move-Item -Path ./outall.mp4 -Destination ./../"silent_cut_"$Args
Move-item -Path ./in.mp4 -Destination ./$Args
Set-Location -Path ./../

