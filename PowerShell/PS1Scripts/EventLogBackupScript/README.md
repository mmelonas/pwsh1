# Windows 10 STIG Script Procedures

## Requirements:

In the same directory as the Event Log Backup script, you need to create a "workstations.txt" file. For each line, add the name of the workstations on which you will be running this script remotely.

**Example**:

*workstations.txt*
```
ahcl0uv-admin01
ahcl0uv-admin02
amascuv-10dev01
amascuv-10dev02
```

The script looks for this content and runs each command against the list of computers and then spits out the results.