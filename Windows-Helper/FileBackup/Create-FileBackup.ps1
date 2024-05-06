#this script copies files (./file.doc) of the currect directory to a Backup folder (./Backup/file_<date>_<time>.doc

$sourcefolder = '.\'
$destinationfolder = '.\Backup'

$files = Get-ChildItem   -Path $sourcefolder -Attributes !Directory

foreach ($file in $files){
$file.FullName
$file.Name
$file.Extension

$backupfile = $file.Name + '_' + ($file.LastWriteTime) -replace '/','_' -replace ' ','_' -replace ':','_'
Write-host Backupfile: $backupfile 
$backupfilefullname = ($destinationfolder + '\' + $backupfile + $file.Extension)
write-host Backufilefullname: $backupfilefullname 

copy-item $file.FullName -Destination $backupfilefullname
}