<#
    .Synopsis
    Check and modify Answer File.
    .DESCRIPTION
    Generates a list of Vuln IDs from CKL and compares them with an Answer File.  The Answer File can then be edited.
    .EXAMPLE
    PS C:\> Manage-AnswerFile.ps1
#>

Function ConvertTo-CSVReport {
  $AnswerFileData = New-Object System.Collections.Generic.List[System.Object]
  $AnswerFileData = Foreach ($Vuln in $AFItems){
    Foreach ($AK in $Vuln.AnswerKeys){
      New-Object psobject -Property ([ordered]@{
        VulnID            = $Vuln.VulnID
        AnswerKey         = $AK.AnswerKey
        ExpectedStatus    = $AK.ExpectedStatus
        ValidationCode    = $AK.ValidationCode
        ValidTrueStatus   = $AK.ValidTrueStatus
        ValidTrueComment  = $AK.ValidTrueComment
        ValidFalseStatus  = $AK.ValidFalseStatus
        ValidFalseComment = $AK.ValidFalseComment
      })
    }
  }
  $AnswerFileData | Export-Csv -Path "$($AFFilePath.replace('.xml','')).csv" -NoTypeInformation
}
Function ConvertTo-HTMLReport {
      [xml]$AFTransform = @'
<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
     <xsl:template match="/STIGComments">
          <html>
               <head>
                    <style type="text/css">
                         .styled-table {
                              border-collapse: collapse;
                              margin: 25px 0;
                              font-size: 0.9em;
                              font-family: sans-serif;
                              min-width: 400px;
                              box-shadow: 0 0 20px rgba(0, 0, 0, 0.15);
                              width: 100%
                         }
                         .styled-table thead tr {
                              background-color: #2E86C1;
                              color: #ffffff;
                              text-align: left;
                         }
                         .styled-table th,
                         .styled-table td {
                              padding: 12px 15px;
                         }
                         .styled-table tbody tr {
                              border-bottom: thin solid #dddddd;
                         }
                         .styled-table tbody tr:last-of-type {
                              border-bottom: 2px solid #3498DB;
                         }
                         .styled-table tbody tr.active-row {
                              font-weight: bold;
                              color: #3498DB;
                         }
                         .hidden {
                              visibility: hidden;
                         }
                         .button {
                              color: #494949 !important;
                              text-align: center;
                              text-transform: uppercase;
                              text-decoration: none;
                              backgrond: #AED6F1;
                              background-color: #AED6F1;
                              padding: 20px;
                              border: 4px solid #494949 !important;
                              display: inline-block;
                              transition: all 0.4s ease 0s;
                              width: 250px;
                              height: 20px;
                              margin: 5px;
                         }
                         .stig_button {
                              color: #494949 !important;
                              text-align: center;
                              text-transform: uppercase;
                              text-decoration: none;
                              backgrond: #ffffff;
                              padding: 20px;
                              border: 4px solid #494949 !important;
                              display: inline-block;
                              transition: all 0.4s ease 0s;
                              width: 450px;
                              height: 10px;
                         }
                         .button:hover{
                              color: #ffffff !important;
                              background: #f6b93b;
                              border-color: #f6b93b !important;
                              transition: all 0.4s ease 0s;
                              cursor: pointer;
                         }
                         .stig_button:hover{
                              color: #ffffff !important;
                              background: #f6b93b;
                              border-color: #f6b93b !important;
                              transition: all 0.4s ease 0s;
                              cursor: pointer;
                         }
                         #topbtn{
                              position: fixed;
                              bottom: 20px;
                              right: 30px;
                              z-index: 99;
                              font-size: 18px;
                              border: none;
                              outline: none;
                              background-color: red;
                              color: white;
                              cursor: pointer;
                              padding: 15px;
                              border-radius: 4px;
                         }
                         #topbtn:hover{
                              background-color: #555;
                         }
                         code {
                             background-color: #eef;
                             display: block;
                         }
                    </style>
                    <script>
                         var topbutton = document.getElementById("topbtn");
                         window.onscroll = function() {scrollFunction()};

                         function scrollFunction() {
                              if (document.body.scrollTop > 20 || document.documentElement.scrollTop > 20) {
                                   topbutton.style.display = "block";
                              } else {
                                   topbutton.style.display = "none";
                              }
                         }
                         function topFunction() {
                              document.body.scrollTop = 0;
                              document.documentElement.scrollTop = 0;
                         }
                         function change(table_value) {
                              var x = document.getElementById(table_value);
                              if (x.style.display === "none") {
                                   x.style.display = "table";
                              } else {
                                   x.style.display = "none";
                              }
                         }
                    </script>
               </head>
               <body>
                    <button onclick="topFunction()" id="topbtn" title="Go to Top">Top</button>
                    <h1 align="center"><xsl:value-of select="@Name" /> STIG Answer File</h1>
                    <p>**************************************************************************************<br />
                        <br />
                        This file contains answers for known opens and findings that cannot be evaluated through technical means.<br />
                        <br />
                        <b>&lt;STIGComments Name&gt;</b> must match the STIG name in STIGList.xml.  When a match is found, this answer file will automatically for the STIG.<br />
                        <b>&lt;Vuln ID&gt;</b> is the STIG VulnID.  Multiple Vuln ID sections may be specified in a single Answer File.<br />
                        <b>&lt;AnswerKey Name&gt;</b> is the name of the key assigned to the answer.  "DEFAULT" can be used to apply the comment to any asset.  Multiple AnswerKey Name sections may be configured within a single Vuln ID section.<br />
                        <b>&lt;ExpectedStatus&gt;</b> is the initial status after the checklist is created.  Valid entries are "Not_Reviewed", "Open", "NotAFinding", and "Not_Applicable".<br />
                        <b>&lt;ValidationCode&gt;</b> must be Powershell code that returns a True/False value.  If blank, "true" is assumed.<br />
                        <b>&lt;ValidTrueStatus&gt;</b> is the status the check should be set to if ValidationCode returns "true".  Valid entries are "Not_Reviewed", "Open", "NotAFinding", and "Not_Applicable".  If blank, <b>&lt;ExpectedStatus&gt;</b> is assumed.<br />
                        <b>&lt;ValidTrueComment&gt;</b> is the verbiage to add to the Comments section if ValidationCode returns "true".<br />
                        <b>&lt;ValidFalseStatus&gt;</b> is the status the check should be set to if ValidationCode DOES NOT return "true".  Valid entries are "Not_Reviewed", "Open", "NotAFinding", and "Not_Applicable".  If blank, <b>&lt;ExpectedStatus&gt;</b> is assumed.<br />
                        <b>&lt;ValidFalseComment&gt;</b> is the verbiage to add to the Comments section if ValidationCode DOES NOT return "true".<br />
                        <br />
                        **************************************************************************************</p>
                </body>
            </html>
        <xsl:for-each select="Vuln">
                <tbody><tr>
                    <td><div class="button_cont"><a class="stig_button" id="button" onclick="change('{@ID}')" title="Show/Hide {@ID}"><xsl:value-of select="@ID" /></a></div></td>
                </tr></tbody>
                    <td><table id="{@ID}" class="styled-table" style="display:none">
                        <thead><tr>
                            <th>Name</th>
                            <th>Expected Status</th>
                            <th>Validation Code</th>
                            <th>Valid True Status</th>
                            <th>Valid True Comment</th>
                            <th>Valid False Status</th>
                            <th>Valid False Comment</th>
                        </tr></thead>
                        <xsl:for-each select="AnswerKey">
                            <tbody><tr>
                                    <td><xsl:value-of select="@Name" /></td>
                                    <td><xsl:value-of select="ExpectedStatus" /></td>
                                    <td><code><xsl:value-of select="ValidationCode" /></code></td>
                                    <td><xsl:value-of select="ValidTrueStatus" /></td>
                                    <td><xsl:value-of select="ValidTrueComment" /></td>
                                    <td><xsl:value-of select="ValidFalseStatus" /></td>
                                    <td><xsl:value-of select="ValidFalseComment" /></td>
                            </tr></tbody>
                        </xsl:for-each>
                    </table></td>
        </xsl:for-each>
     </xsl:template>
</xsl:stylesheet>
'@

    $AFxslt = New-Object System.Xml.Xsl.XslCompiledTransform
    $AFxslt.load($AFTransform)
    $AFxslt.Transform($AFFilePath, "$($AFFilePath.replace('.xml','')).html")
}

Function Close-Form {
  Param (
    [Parameter(Mandatory = $true)]
    [String]$Message
  )

  [System.Windows.MessageBox]::Show($Message, "Maintain Answer File Error", "OK", "Error")
  &$handler_formclose
}

Function Disable-Form {
  $SaveAFKeyLabel.Text = "Save Changes to $($AFKeys.Text)"

  $SaveAFKeyLabel.Visible = $True
  $SaveAFKeyButton.Visible = $True
  $DiscardAFKeyButton.Visible = $True

  $CreateAFKeyButton.Enabled = $False
  $RemoveAFKeyButton.Enabled = $False
  $RenameAFKeyButton.Enabled = $False
  $VulnIDRefreshButton.Enabled = $False
  $AFErrorRefreshButton.Enabled = $False
  $AFErrorRemVulnIDButton.Enabled = $False
  $SaveButton.Enabled = $False
  $AFKeys.Enabled = $False
  $VulnIDBox.Enabled = $False
  $AFErrorBox.Enabled = $False
  $VulnIDStepLabel.Visible = $False
  $OpenAddDelKeyLabel.Visible = $False
}

Function Test-AnswerFile{

  $SupportedVer = [Version]"1.2107.0"
  Get-Content (Join-Path -Path $PsScriptRoot -ChildPath "Evaluate-STIG.ps1") | ForEach-Object {
    If ($_ -like '*$EvaluateStigVersion = *') {
        $Script:Version = [Version]((($_ -split "=")[1]).Trim() -replace '"','')
    }
  }
  If (!($Version -ge $SupportedVer)) {
      Close-Form -Message "Error: Evaluate-STIG $SupportedVer or greater required.  Found $Version.  Please update Evaluate-STIG to a supported version."
  }

  if ((($STIGs | Where-Object { $_.Name -contains $STIG_Name }).Name -eq $AFXML.STIGComments.Name) -or (($STIGs | Where-Object { $_.Name -contains $STIG_Name }).ShortName -eq $AFXML.STIGComments.Name)) {
    Foreach ($AFItem in $AFItems){
      $AFItem.AnswerKeys | Group-Object AnswerKey | ForEach-Object { if ($_.Count -gt 1) { $AFErrorBox.Items.Add($AFItem.VulnID).SubItems.Add("Dupe AnswerKey")}}
      If ($AFItem.VulnID -notin $STIGItems.VulnID){ $AFErrorBox.Items.Add($AFItem.VulnID).SubItems.Add("VulnID not in CKL")}
    }
  }
  else{
    Close-Form -Message "Error: Answer File ($($AFXML.STIGComments.Name)) does not match with Template CKL ($(($STIGs | Where-Object { $_.Name -contains $STIG_Name}).Name))."
  }

}
Function New-AnswerFileItems {

  $STIGLabel.Text = "$STIG_Name AnswerFile"
  $OpenButton.Visible = $False
  $CreateButton.Visible = $False

  $Script:AFItems = New-Object System.Collections.Generic.List[System.Object]
  ForEach ($Object in $AFXML.STIGComments.Vuln) {
    if ($AFItems.VulnID -contains $Object.ID) {
      $AFVulnKeys = ($AFItems | Where-Object {$_.VulnID -contains $Object.ID}).AnswerKeys
      $count = 1
      Foreach ($AFObject in $Object.AnswerKey) {
        $NewObj = [PSCustomObject]@{
          AnswerKey         = $AFObject.Name
          ExpectedStatus    = $AFObject.ExpectedStatus
          ValidationCode    = $AFObject.ValidationCode
          ValidTrueStatus   = $AFObject.ValidTrueStatus
          ValidTrueComment  = $AFObject.ValidTrueComment
          ValidFalseStatus  = $AFObject.ValidFalseStatus
          ValidFalseComment = $AFObject.ValidFalseComment
        }
        if ($AFVulnKeys | Where-Object { $_.AnswerKey -contains $NewObj.AnswerKey }) { $NewObj.AnswerKey = "$($NewObj.AnswerKey)_Copy$count"; $Count++ }
        ($AFItems | Where-Object { $_.VulnID -eq $Object.ID }).AnswerKeys.Add($NewObj)
      }
    }
    else {
      $AFVulnKeys = New-Object System.Collections.Generic.List[System.Object]
      $count = 1
      Foreach ($AFObject in $Object.AnswerKey) {
        $NewObj = [PSCustomObject]@{
          AnswerKey         = $AFObject.Name
          ExpectedStatus    = $AFObject.ExpectedStatus
          ValidationCode    = $AFObject.ValidationCode
          ValidTrueStatus   = $AFObject.ValidTrueStatus
          ValidTrueComment  = $AFObject.ValidTrueComment
          ValidFalseStatus  = $AFObject.ValidFalseStatus
          ValidFalseComment = $AFObject.ValidFalseComment
        }
        if ($AFVulnKeys | Where-Object { $_.AnswerKey -contains $NewObj.AnswerKey }) { $NewObj.AnswerKey = "$($NewObj.AnswerKey)_Copy$count"; $Count++ }
        $AFVulnKeys.Add($NewObj)
      }
      $NewObj = [PSCustomObject]@{
        VulnID     = $object.ID
        AnswerKeys = $AFVulnKeys
      }
      $AFItems.Add($NewObj)
    }
  }

  Test-AnswerFile

  $SaveButton.Visible = $True
  $SaveButton.Enabled = $False
  $AddOutputLabel.Visible = $True
  $CSVCheckBox.Visible = $True
  $HTMLCheckBox.Visible = $True
  $AFPathLabel.Visible = $True
  $AFFileLabel.Visible = $True

  $NextStepLabel.Visible = $False
  $VulnIDStepLabel.Visible = $True

  $AFErrorRefreshButton.Visible = $True
  $AFErrorRemVulnIDButton.Visible = $True

  for ($i = 0; $i -lt $VulnIDBox.Items.Count; $i++) {
    if ($AFItems -match $VulnIDBox.Items[$i].SubItems[0].Text) {
      $VulnIDBox.Items[$i].SubItems[1].Text = "*"
    }
  }
}

Function New-AnswerFile {
  Param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]$NewAFpath,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [String]$STIG_Name
  )

  $EmptyVulns = New-Object System.Collections.Generic.List[System.Object]

  Foreach ($Vuln in $AFItems){
    $EmptyAK = 0
    if ($null -eq $vuln.VulnID){
      $EmptyAK++
    }
    elseif (($vuln.AnswerKeys).count -eq 0) {
      $EmptyAK++
    }
    else{
      Foreach ($AK in $Vuln.AnswerKeys){
        if ($AK.AnswerKey -eq ""){
          $EmptyAK++
        }
      }
    }

    if ($EmptyAK -gt 0) {
      $EmptyVulns.Add($($AFItems | Where-Object { $_.VulnID -eq $Vuln.VulnID }))
    }
  }
  write-host $EmptyVulns
  $EmptyVulns | ForEach-Object {$AFItems.Remove($_)}
  $AFItems = $AFItems | Sort-Object -Property VulnID

  $Encoding = [System.Text.Encoding]::UTF8
  $XmlWriter = New-Object System.Xml.XmlTextWriter($NewAFpath, $Encoding)

  $XmlWriter.Formatting = "Indented"
  $XmlWriter.Indentation = 2

  $XmlWriter.WriteStartDocument()

  $XmlWriter.WriteComment('**************************************************************************************
This file contains answers for known opens and findings that cannot be evaluated through technical means.
<STIGComments Name> must match the STIG ShortName or Name in -ListSupportedProducts.  When a match is found, this answer file will automatically for the STIG.
<Vuln ID> is the STIG VulnID.  Multiple Vuln ID sections may be specified in a single Answer File.
<AnswerKey Name> is the name of the key assigned to the answer.  "DEFAULT" can be used to apply the comment to any asset.  Multiple AnswerKey Name sections may be configured within a single Vuln ID section.
<ExpectedStatus> is the initial status after the checklist is created.  Valid entries are "Not_Reviewed", "Open", "NotAFinding", and "Not_Applicable".
<ValidationCode> must be Powershell code that returns a True/False value.  If blank, "true" is assumed.
<ValidTrueStatus> is the status the check should be set to if ValidationCode returns "true".  Valid entries are "Not_Reviewed", "Open", "NotAFinding", and "Not_Applicable".  If blank, <ExpectedStatus> is assumed.
<ValidTrueComment> is the verbiage to add to the Comments section if ValidationCode returns "true".
<ValidFalseStatus> is the status the check should be set to if ValidationCode DOES NOT return "true".  Valid entries are "Not_Reviewed", "Open", "NotAFinding", and "Not_Applicable".  If blank, <ExpectedStatus> is assumed.
<ValidFalseComment> is the verbiage to add to the Comments section if ValidationCode DOES NOT return "true".
**************************************************************************************')

  $XmlWriter.WriteStartElement("STIGComments")
  $XmlWriter.WriteAttributeString("Name", $STIG_Name)

  Foreach($Item in $AFItems){
    $XmlWriter.WriteStartElement("Vuln")
    $XmlWriter.WriteAttributeString("ID", $Item.VulnID)
    Foreach ($AKItem in $Item.AnswerKeys){
      if ($null -ne $AKItem.AnswerKey){
        $XmlWriter.WriteStartElement("AnswerKey")
        $XmlWriter.WriteAttributeString("Name", $AKItem.AnswerKey)

        $XmlWriter.WriteStartElement("ExpectedStatus")
        If ($AKItem.ExpectedStatus) {
            $XmlWriter.WriteString($AKItem.ExpectedStatus)
        }
        Else {
            $XmlWriter.WriteWhitespace("")
        }
        $XmlWriter.WriteFullEndElement()
        $XmlWriter.WriteStartElement("ValidationCode")
        If ($AKItem.ValidationCode) {
          $XmlWriter.WriteString($AKItem.ValidationCode)
        }
        Else {
          $XmlWriter.WriteWhitespace("")
        }
        $XmlWriter.WriteFullEndElement()
        $XmlWriter.WriteStartElement("ValidTrueStatus")
        If ($AKItem.ValidTrueStatus) {
          $XmlWriter.WriteString($AKItem.ValidTrueStatus)
        }
        Else {
          $XmlWriter.WriteWhitespace("")
        }
        $XmlWriter.WriteFullEndElement()
        $XmlWriter.WriteStartElement("ValidTrueComment")
        If ($AKItem.ValidTrueComment) {
          $XmlWriter.WriteString($AKItem.ValidTrueComment)
        }
        Else {
          $XmlWriter.WriteWhitespace("")
        }
        $XmlWriter.WriteFullEndElement()
        $XmlWriter.WriteStartElement("ValidFalseStatus")
        If ($AKItem.ValidFalseStatus) {
          $XmlWriter.WriteString($AKItem.ValidFalseStatus)
        }
        Else {
          $XmlWriter.WriteWhitespace("")
        }
        $XmlWriter.WriteFullEndElement()
        $XmlWriter.WriteStartElement("ValidFalseComment")
        If ($AKItem.ValidFalseComment) {
          $XmlWriter.WriteString($AKItem.ValidFalseComment)
        }
        Else {
          $XmlWriter.WriteWhitespace("")
        }
        $XmlWriter.WriteFullEndElement()
        $XmlWriter.WriteEndElement()
      }
    }
    $XmlWriter.WriteEndElement()
  }

  $XmlWriter.WriteEndElement()
  $XmlWriter.WriteEnddocument()
  $XmlWriter.Flush()
  $XmlWriter.Close()
}

function Reset-ListViewColumn {
  <#
    .SYNOPSIS
        Sort the ListView's item using the specified column.

    .DESCRIPTION
        Sort the ListView's item using the specified column.
        This function uses Add-Type to define a class that sort the items.
        The ListView's Tag property is used to keep track of the sorting.

    .PARAMETER ListView
        The ListView control to sort.

    .PARAMETER ColumnIndex
        The index of the column to use for sorting.

    .PARAMETER SortOrder
        The direction to sort the items. If not specified or set to None, it will toggle.

    .EXAMPLE
        Set-WFListViewColumn -ListView $listview1 -ColumnIndex 0

    .NOTES
        SAPIEN Technologies, Inc.
        http://www.sapien.com/
#>
  param (
    [ValidateNotNull()]
    [Parameter(Mandatory = $true)]
    [System.Windows.Forms.ListView]$ListView,

    [Parameter(Mandatory = $true)]
    [int]$ColumnIndex,

    [System.Windows.Forms.SortOrder]$SortOrder = 'None')

  if (($ListView.Items.Count -eq 0) -or ($ColumnIndex -lt 0) -or ($ColumnIndex -ge $ListView.Columns.Count)) {
    return;
  }

  #region Define ListViewItemComparer
  try {
    $local:type = [ListViewItemComparer]
  }
  catch {
    Add-Type -ReferencedAssemblies ('System.Windows.Forms') -TypeDefinition  @"
    using System;
    using System.Windows.Forms;
    using System.Collections;
    public class ListViewItemComparer : IComparer
    {
        public int column;
        public SortOrder sortOrder;
        public ListViewItemComparer()
        {
            column = 0;
            sortOrder = SortOrder.Ascending;
        }
        public ListViewItemComparer(int column, SortOrder sort)
        {
            this.column = column;
            sortOrder = sort;
        }
        public int Compare(object x, object y)
        {
            if(column >= ((ListViewItem)x).SubItems.Count)
                return sortOrder == SortOrder.Ascending ? -1 : 1;

            if(column >= ((ListViewItem)y).SubItems.Count)
                return sortOrder == SortOrder.Ascending ? 1 : -1;

            if(sortOrder == SortOrder.Ascending)
                return String.Compare(((ListViewItem)x).SubItems[column].Text, ((ListViewItem)y).SubItems[column].Text);
            else
                return String.Compare(((ListViewItem)y).SubItems[column].Text, ((ListViewItem)x).SubItems[column].Text);
        }
    }
"@ | Out-Null
  }
  #endregion

  if ($ListView.Tag -is [ListViewItemComparer]) {
    #Toggle the Sort Order
    if ($SortOrder -eq [System.Windows.Forms.SortOrder]::None) {
      if ($ListView.Tag.column -eq $ColumnIndex -and $ListView.Tag.sortOrder -eq 'Ascending') {
        $ListView.Tag.sortOrder = 'Descending'
      }
      else {
        $ListView.Tag.sortOrder = 'Ascending'
      }
    }
    else {
      $ListView.Tag.sortOrder = $SortOrder
    }

    $ListView.Tag.column = $ColumnIndex
    $ListView.Sort() #Sort the items
  }
  else {
    if ($SortOrder -eq [System.Windows.Forms.SortOrder]::None) {
      $SortOrder = [System.Windows.Forms.SortOrder]::Ascending
    }

    #Set to Tag because for some reason in PowerShell ListViewItemSorter prop returns null
    $ListView.Tag = New-Object ListViewItemComparer ($ColumnIndex, $SortOrder)
    $ListView.ListViewItemSorter = $ListView.Tag #Automatically sorts
  }
}

add-type -AssemblyName System.Windows.Forms
add-type -AssemblyName System.Drawing
Add-Type -AssemblyName Microsoft.VisualBasic
Add-Type -AssemblyName PresentationFramework
Add-Type -TypeDefinition @'
using System.Runtime.InteropServices;
public class ProcessDPI {
    [DllImport("user32.dll", SetLastError=true)]
    public static extern bool SetProcessDPIAware();
}
'@

$null = [ProcessDPI]::SetProcessDPIAware()

$InitialFormWindowState = New-Object System.Windows.Forms.FormWindowState

$TitleFont = New-Object System.Drawing.Font("Calibri",24,[Drawing.FontStyle]::Bold)
$BodyFont = New-Object System.Drawing.Font("Calibri",18,[Drawing.FontStyle]::Bold)
$BoxFont = New-Object System.Drawing.Font("Calibri", 12, [Drawing.FontStyle]::Regular)
$BoldBoxFont = New-Object System.Drawing.Font("Calibri", 12, [Drawing.FontStyle]::Bold)

$HLine = New-Object System.Windows.Forms.Label
$VLine = New-Object System.Windows.Forms.Label

$STIGLabel = New-Object System.Windows.Forms.Label
$CKLLabel = New-Object System.Windows.Forms.Label
$AFPathLabel = New-Object System.Windows.Forms.Label
$AFFileLabel = New-Object System.Windows.Forms.Label
$AFKeyLabel = New-Object System.Windows.Forms.Label
$AFExpectedLabel = New-Object System.Windows.Forms.Label
$AFValCodeLabel = New-Object System.Windows.Forms.Label
$AFValTSLabel = New-Object System.Windows.Forms.Label
$AFValTCommLabel = New-Object System.Windows.Forms.Label
$AFValFSLabel = New-Object System.Windows.Forms.Label
$AFValFCommLabel = New-Object System.Windows.Forms.Label
$StartHereLabel = New-Object System.Windows.Forms.Label
$NextStepLabel = New-Object System.Windows.Forms.Label
$VulnIDStepLabel = New-Object System.Windows.Forms.Label
$AddOutputLabel = New-Object System.Windows.Forms.Label
$SaveAFKeyLabel = New-Object System.Windows.Forms.Label
$OpenAddDelKeyLabel = New-Object System.Windows.Forms.Label
$AFErrorLabel = New-Object System.Windows.Forms.Label
$AFMarkLabel = New-Object System.Windows.Forms.Label

$AFValCodeBox = New-Object System.Windows.Forms.TextBox
$AFValTCommBox = New-Object System.Windows.Forms.TextBox
$AFValFCommBox = New-Object System.Windows.Forms.TextBox

$CKLInfoBox = New-Object System.Windows.Forms.RichTextBox

$OpenButton = New-Object System.Windows.Forms.Button
$CreateButton = New-Object System.Windows.Forms.Button
$SaveButton = New-Object System.Windows.Forms.Button
$SaveAFKeyButton = New-Object System.Windows.Forms.Button
$DiscardAFKeyButton = New-Object System.Windows.Forms.Button
$CreateAFKeyButton = New-Object System.Windows.Forms.Button
$RemoveAFKeyButton = New-Object System.Windows.Forms.Button
$RenameAFKeyButton = New-Object System.Windows.Forms.Button
$AFErrorRefreshButton = New-Object System.Windows.Forms.Button
$AFErrorRemVulnIDButton = New-Object System.Windows.Forms.Button
$VulnIDRefreshButton = New-Object System.Windows.Forms.Button
$DefaultAFKeyButton = New-Object System.Windows.Forms.Button
$DarkModeButton = New-Object System.Windows.Forms.Button

$VulnIDBox = New-Object System.Windows.Forms.ListView
$AFErrorBox = New-Object System.Windows.Forms.ListView

$SupportedSTIGSBox = New-Object System.Windows.Forms.ListBox

$AFKeys = New-Object System.Windows.Forms.ComboBox
$AFExpectedBox = New-Object System.Windows.Forms.ComboBox
$AFValTSBox = New-Object System.Windows.Forms.ComboBox
$AFValFSBox = New-Object System.Windows.Forms.ComboBox

$HTMLCheckBox = New-Object System.Windows.Forms.CheckBox
$CSVCheckBox = New-Object System.Windows.Forms.CheckBox
$OpenCheckBox = New-Object System.Windows.Forms.CheckBox
$NFCheckBox = New-Object System.Windows.Forms.CheckBox
$NRCheckBox = New-Object System.Windows.Forms.CheckBox
$NACheckBox = New-Object System.Windows.Forms.CheckBox


#----------------------------------------------
#Generated Event Script Blocks
#----------------------------------------------

$OnLoadForm_StateCorrection=
{#Correct the initial state of the form to prevent the .Net maximized form issue
  $form1.WindowState = $InitialFormWindowState

  $PowerShellVersion = $PsVersionTable.PSVersion

  If ($PowerShellVersion -lt [Version]"7.0") {
    Import-Module (Join-Path -Path $PsScriptRoot -ChildPath "Modules" | Join-Path -ChildPath "Master_Functions")
  }
  Else {
    Import-Module (Join-Path -Path $PsScriptRoot -ChildPath "Modules" | Join-Path -ChildPath "Master_Functions") -SkipEditionCheck
  }

  $STIGListXML = Join-Path -Path $PsScriptRoot -ChildPath "xml" | Join-Path -ChildPath "STIGList.xml"
  $Script:STIGs = ([XML](Get-Content $STIGListXML)).List.STIG | Select-Object Name, ShortName, Template -Unique

  ForEach ($STIG in $STIGs) {
    $null = $SupportedSTIGSBox.Items.Add($STIG.Name)
  }

  $CKLLabel.Text = "Supported STIGS"
}

$handler_SupportedSTIGSBox_DoubleClick =
{
  $TemplateCKL = ($STIGs | Where-Object { $_.Name -contains $($SupportedSTIGSBox.SelectedItems) }).Template

  $CKLLabel.Visible = $True

  [xml]$Script:xml = New-Object xml
  $xml.Load($(Join-Path -Path $PsScriptRoot -ChildPath "CKLTemplates" | Join-Path -ChildPath $TemplateCKL))

  $Script:STIG_Name = ($STIGs | Where-Object { $_.Name -contains $($SupportedSTIGSBox.SelectedItems) }).Name

  $STIGLabel.Text = "$STIG_Name (AnswerFile not loaded)"
  $CKLLabel.Text = "$STIG_Name CKL"

  $VulnIDBox.Items.Clear()

  $Script:STIGItems = New-Object System.Collections.Generic.List[System.Object]
  ForEach ($Object in $xml.CHECKLIST.STIGS.iSTIG.VULN) {
    $LegacyIDs = $Object.SelectNodes('./STIG_DATA[VULN_ATTRIBUTE="LEGACY_ID"]/ATTRIBUTE_DATA').InnerText
    Switch (($Object.SelectSingleNode('./STIG_DATA[VULN_ATTRIBUTE="Severity"]/ATTRIBUTE_DATA').InnerText -Replace "\s+", " ").Trim()) {
        "high" {
            $Severity = "I"
        }
        "medium" {
            $Severity = "II"
        }
        "low" {
            $Severity = "III"
        }
    }
    $NewObj = [PSCustomObject]@{
      VulnID            = ($Object.SelectSingleNode('./STIG_DATA[VULN_ATTRIBUTE="Vuln_Num"]/ATTRIBUTE_DATA').InnerText -Replace "\s+", " ").Trim()
      Severity          = $Severity
      LegacyID          = (Select-String -InputObject $LegacyIDS -Pattern "V-\d{4,}" | ForEach-Object {$_.Matches}).Value
      Status            = ($Object.SelectSingleNode('./STATUS').InnerText -Replace "\s+", " ").Trim()
      RuleTitle         = ($Object.SelectSingleNode('./STIG_DATA[VULN_ATTRIBUTE="Rule_Title"]/ATTRIBUTE_DATA').InnerText -Replace "\s+", " ").Trim()
      RuleVuln_Discuss  = ($Object.SelectSingleNode('./STIG_DATA[VULN_ATTRIBUTE="Vuln_Discuss"]/ATTRIBUTE_DATA').InnerText -Replace "\s+", " ").Trim()
      RuleCheck_Content = ($Object.SelectSingleNode('./STIG_DATA[VULN_ATTRIBUTE="Check_Content"]/ATTRIBUTE_DATA').InnerText -Replace "\s+", " ").Trim()
    }
    $STIGItems.Add($NewObj)
  }

  [System.Windows.MessageBox]::Show("Select Evaluate-STIG Result for $($SupportedSTIGSBox.SelectedItems)", "Select Evaluate-STIG Result", "OK", "Exclamation")

  $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{
    InitialDirectory = [Environment]::GetFolderPath('Desktop')
    Filter           = "CKL Files (*.ckl)|*.ckl"
  }

  $Result = $FileBrowser.ShowDialog()

  $Valid = $True
  if ($Result -eq "OK") {
    $CKLFilePath = $FileBrowser.FileName

    [xml]$CKLXML = New-Object xml
    $CKLXML.Load($CKLFilePath)

    if ($xml.CHECKLIST.stigs.iSTIG.STIG_INFO.SelectSingleNode('./SI_DATA[SID_NAME="stigid"]/SID_DATA').InnerText -eq $CKLXML.CHECKLIST.stigs.iSTIG.STIG_INFO.SelectSingleNode('./SI_DATA[SID_NAME="stigid"]/SID_DATA').InnerText){
      if (($xml.CHECKLIST.stigs.iSTIG.STIG_INFO.SelectSingleNode('./SI_DATA[SID_NAME="version"]/SID_DATA').InnerText -eq $CKLXML.CHECKLIST.stigs.iSTIG.STIG_INFO.SelectSingleNode('./SI_DATA[SID_NAME="version"]/SID_DATA').InnerText) -and ($xml.CHECKLIST.stigs.iSTIG.STIG_INFO.SelectSingleNode('./SI_DATA[SID_NAME="releaseinfo"]/SID_DATA').InnerText -eq $CKLXML.CHECKLIST.stigs.iSTIG.STIG_INFO.SelectSingleNode('./SI_DATA[SID_NAME="releaseinfo"]/SID_DATA').InnerText)){

        ForEach ($STIG in $CKLXML.CHECKLIST.STIGS.iSTIG.VULN) {
          ($STIGItems | Where-Object { $_.VulnID -eq $($STIG.SelectSingleNode('./STIG_DATA[VULN_ATTRIBUTE="Vuln_Num"]/ATTRIBUTE_DATA').InnerText) }).Status = $STIG.Status
        }
      }
      else{
        [System.Windows.MessageBox]::Show("$CKLFilePath is an outdated CKL file.  Please run Evaluate-STIG $Version against the host.", "Select Evaluate-STIG Result", "OK", "Error")
        $Valid = $False
      }
    }
    else{
      [System.Windows.MessageBox]::Show("$CKLFilePath does not match selected Supported STIG ($STIG_Name).", "Select Evaluate-STIG Result", "OK", "Error")
      $Valid = $False
    }
  }
  else{
    $Valid = $False
  }

  if ($Valid){
    &$handler_VulnIDRefreshButton_Click

    $AFPathLabel.Text = ""
    $AFFileLabel.Text = ""
    $AFExpectedBox.SelectedIndex = -1
    $AFValTSBox.SelectedIndex = -1
    $AFValFSBox.SelectedIndex = -1
    $form1.Controls | Where-Object { $_ -is [System.Windows.Forms.TextBox] } | ForEach-Object { $_.Clear() }
    $null = $AFFilePath

    $OpenButton.Visible = $True
    $CreateButton.Visible = $True

    $OpenButton.Enabled = $True
    $CreateButton.Enabled = $True

    $StartHereLabel.Visible = $False
    $NextStepLabel.Visible = $True
    $SupportedSTIGSBox.Visible = $False
  }
  else{
    $form1.Controls | Where-Object { $_ -is [System.Windows.Forms.Textbox] } | ForEach-Object { $_.clear() }
    $form1.Controls | Where-Object { $_ -is [System.Windows.Forms.ComboBox] } | ForEach-Object { $_.Items.Clear() }
    $form1.Controls | Where-Object { $_ -is [System.Windows.Forms.ListView] } | ForEach-Object { $_.Items.Clear() }

    $AFExpectedBox.SelectedIndex = -1
    $AFValTSBox.SelectedIndex = -1
    $AFValFSBox.SelectedIndex = -1

    $STIGLabel.Text = "$STIG_Name (AnswerFile not loaded)"
    $CKLLabel.Text = "Supported STIGS"
    $SupportedSTIGSBox.Visible = $True
    $StartHereLabel.Text = "Start by DoubleClicking STIG"
    $StartHereLabel.Visible = $True

    $SaveButton.Visible = $False
    $AFPathLabel.Visible = $False
    $AFFileLabel.Visible = $False
    $SaveAFKeyButton.Visible = $False
    $DiscardAFKeyButton.Visible = $False
    $CKLInfoBox.Visible = $False
    $CreateAFKeyButton.Visible = $False
    $RemoveAFKeyButton.Visible = $False
    $RenameAFKeyButton.Visible = $False
    $NextStepLabel.Visible = $False
    $VulnIDStepLabel.Visible = $False
    $AddOutputLabel.Visible = $False
    $CSVCheckBox.Visible = $False
    $HTMLCheckBox.Visible = $False
    $SaveAFKeyLabel.Visible = $False
    $OpenAddDelKeyLabel.Visible = $False
    $OpenCheckBox.Visible = $False
    $OpenCheckBox.Checked = $True
    $NRCheckBox.Visible = $False
    $NRCheckBox.Checked = $True
    $NFCheckBox.Visible = $False
    $NACheckBox.Visible = $False
    $AFMarkLabel.Visible = $False
    $VulnIDRefreshButton.Visible = $False
    $AFErrorRefreshButton.Visible = $False
    $AFErrorRemVulnIDButton.Visible = $False

    Remove-Variable * -ErrorAction SilentlyContinue
    $STIGItems.Clear()
    $null = $AFFilePath

    $form1.Refresh()
  }
}

$handler_OpenButton_Click=
{
  $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{
    InitialDirectory = [Environment]::GetFolderPath('Desktop')
    Filter           = "XML Files (*.xml)|*.xml|CSV Files (*.csv)|*.csv"
  }

  $Result = $FileBrowser.ShowDialog()

  if ($Result -eq "OK") {
    if ((Get-Item $FileBrowser.FileName).Extension -eq ".xml") {
      $Script:AFFilePath = $FileBrowser.FileName
      Try{
        [xml]$Script:AFXML = New-Object xml
        $AFXML.Load($AFFilePath)
      }
      Catch{
        Close-Form -Message "$AFFilePath `n`n$($_.Exception.Message)"
      }
    }
    else{
      $Filename = $STIG_Name.replace(" ", "_") + "_AnswerFile.xml"

      $Script:AFFilePath = Join-Path -Path $(Split-Path $FileBrowser.FileName) -ChildPath $Filename
      [xml]$AFXML = New-Object xml

      $NewItem = $AFXML.CreateElement("STIGComments")
      $NewItem.SetAttribute( "Name", "$STIG_Name")
      $null = $AFXML.AppendChild($NewItem)

      $AnswerFromCSV = Import-Csv -Path $FileBrowser.FileName
      ForEach ($AnswerVuln in $AnswerFromCSV){
        $Node = $AFXML.STIGComments.SelectSingleNode("./Vuln[@ID='$($AnswerVuln.VulnID)']")

        if (!($Node)){
          $NewVuln = $AFXML.CreateElement("Vuln")
          $NewVuln.SetAttribute( "ID", "$($AnswerVuln.VulnID)")
          $null = $AFXML.STIGComments.AppendChild($NewVuln)

          $Node = $AFXML.STIGComments.SelectSingleNode("./Vuln[@ID='$($AnswerVuln.VulnID)']")
        }

        $NewAK = $AFXML.CreateElement("AnswerKey")
        $NewAK.SetAttribute( "Name", "$($AnswerVuln.AnswerKey)")
        $null = $Node.AppendChild($NewAK)

        $NewItem = $AFXML.CreateElement("ExpectedStatus")
        $NewItem.InnerText = $AnswerVuln.ExpectedStatus
        $null = $NewAK.AppendChild($NewItem)
        $NewItem = $AFXML.CreateElement("ValidationCode")
        $NewItem.InnerText = $AnswerVuln.ValidationCode
        $null = $NewAK.AppendChild($NewItem)
        $NewItem = $AFXML.CreateElement("ValidTrueStatus")
        $NewItem.InnerText = $AnswerVuln.ValidTrueStatus
        $null = $NewAK.AppendChild($NewItem)
        $NewItem = $AFXML.CreateElement("ValidTrueComment")
        $NewItem.InnerText = $AnswerVuln.ValidTrueComment
        $null = $NewAK.AppendChild($NewItem)
        $NewItem = $AFXML.CreateElement("ValidFalseStatus")
        $NewItem.InnerText = $AnswerVuln.ValidFalseStatus
        $null = $NewAK.AppendChild($NewItem)
        $NewItem = $AFXML.CreateElement("ValidFalseComment")
        $NewItem.InnerText = $AnswerVuln.ValidFalseComment
        $null = $NewAK.AppendChild($NewItem)
      }

      $AFXML.Save($AFFilePath)

      Try {
        [xml]$Script:AFXML = New-Object xml
        $AFXML.Load($AFFilePath)
      }
      Catch {
        Close-Form -Message "$AFFilePath `n`n$($_.Exception.Message)"
      }
    }
    $AFPathLabel.Text = "AnswerFile Path: $(Split-Path -Path $FileBrowser.FileName -Parent)"
    $AFFileLabel.Text = "AnswerFile Name: $($FileBrowser.SafeFileName)"

    New-AnswerFileItems
  }
  else{
    $STIGLabel.Text = "$STIG_Name (AnswerFile not loaded)"
  }
}

$handler_CreateButton_Click =
{
  $Filename = $STIG_Name.replace(" ", "_") + "_AnswerFile.xml"

  $STIGLabel.Text = "$STIG_Name AnswerFile"

  $FolderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
  $FolderBrowser.RootFolder = 'MyComputer'

  $Result = $FolderBrowser.ShowDialog()

  if ($Result -eq "OK") {
    $Script:AFFilePath = $(Join-Path $FolderBrowser.SelectedPath -ChildPath $Filename)

    New-AnswerFile $AFFilePath $STIG_Name
    [xml]$Script:AFXML = New-Object xml
    $AFXML.Load($AFFilePath)

    $AFPathLabel.Text = "AnswerFile Path: $($FolderBrowser.SelectedPath)"
    $AFFileLabel.Text = "AnswerFile Name: $FileName"

    New-AnswerFileItems
  }
  else {
    $STIGLabel.Text = "$STIG_Name (AnswerFile not loaded)"
  }
}

$handler_CreateAFKeyButton_Click =
{
  $title = "New Answer File Key"
  $msg = "Enter a new Answer File Key:"

  $NewAFKey = [Microsoft.VisualBasic.Interaction]::InputBox($msg, $title)

  $NewObj = [PSCustomObject]@{
      AnswerKey        = $NewAFKey
      ExpectedStatus     = "Not_Reviewed"
      ValidationCode   = ""
      ValidTrueStatus   = ""
      ValidTrueComment = ""
      ValidFalseStatus  = ""
      ValidFalseComment = ""
    }

  if (($AFItems | Where-Object { $_.VulnID -eq $VulnID }).AnswerKeys -eq $NewObj.AnswerKey) { $NewObj.AnswerKey = "$($NewObj.AnswerKey)_Copy$((($AFItems | Where-Object { $_.VulnID -eq $VulnID }).AnswerKeys -eq $NewObj.AnswerKey).count)" }
  ($AFItems | Where-Object { $_.VulnID -eq $VulnID }).AnswerKeys.Add($NewObj)
  $AFKeys.Items.Add($NewObj.AnswerKey)
  $AFKeys.SelectedItem = $NewObj.AnswerKey
}

$handler_RemoveAFKeyButton_Click =
{
  $confirm = [System.Windows.MessageBox]::Show("Remove $($AFKeys.SelectedItem)?", "Confirmation", "YesNo", "Question")

  if ($confirm -eq "Yes"){
    ($AFItems | Where-Object { $_.VulnID -eq $VulnID }).AnswerKeys.Remove($TempObj)
    $AFKeys.Items.Remove($TempObj.AnswerKey)

    $AFExpectedBox.SelectedIndex = -1
    $AFValTSBox.SelectedIndex = -1
    $AFValFSBox.SelectedIndex = -1
    $form1.Controls | Where-Object { $_ -is [System.Windows.Forms.TextBox] } | ForEach-Object { $_.Clear() }

    ($VulnIDBox.FindItemWithText("$VulnID")).SubItems[1].Text = "-"
  }

  $SaveButton.Enabled = $True
}

$handler_RenameAFKeyButton_Click =
{
  $title = "New Answer File Key Name"
  $msg = "Enter a new Answer File Key Name:"

  $NewAFKey = [Microsoft.VisualBasic.Interaction]::InputBox($msg, $title)

  ($AFItems | Where-Object { $_.VulnID -eq $VulnID }).AnswerKeys.Remove($TempObj)

  $NewObj = [PSCustomObject]@{
    AnswerKey         = $NewAFKey
    ExpectedStatus    = $AFExpectedBox.SelectedItem
    ValidationCode    = $AFValCodeBox.Text
    ValidTrueStatus   = $AFValTSBox.SelectedItem
    ValidTrueComment  = $AFValTCommBox.Text
    ValidFalseStatus  = $AFValFSBox.SelectedItem
    ValidFalseComment = $AFValFCommBox.Text
  }

  if (($AFItems | Where-Object { $_.VulnID -eq $VulnID }).AnswerKeys -eq $NewObj.AnswerKey) { $NewObj.AnswerKey = "$($NewObj.AnswerKey)_Copy$((($AFItems | Where-Object { $_.VulnID -eq $VulnID }).AnswerKeys -eq $NewObj.AnswerKey).count)" }
  ($AFItems | Where-Object { $_.VulnID -eq $VulnID }).AnswerKeys.Add($NewObj)

  $AFKeys.Items.Remove($TempObj.AnswerKey)
  $AFKeys.Items.Add($NewObj.AnswerKey)
  $AFKeys.SelectedItem = $NewObj.AnswerKey

  $SaveButton.Enabled = $True
}

$handler_SaveAFKeyButton_Click =
{
  ($AFItems | Where-Object { $_.VulnID -eq $VulnID }).AnswerKeys.Remove($TempObj)

  $NewObj = [PSCustomObject]@{
    AnswerKey        = $AFKeys.SelectedItem
    ExpectedStatus     = $AFExpectedBox.SelectedItem
    ValidationCode   = $AFValCodeBox.Text
    ValidTrueStatus   = $AFValTSBox.SelectedItem
    ValidTrueComment  = $AFValTCommBox.Text
    ValidFalseStatus  = $AFValFSBox.SelectedItem
    ValidFalseComment = $AFValFCommBox.Text
  }
  ($AFItems | Where-Object { $_.VulnID -eq $VulnID }).AnswerKeys.Add($NewObj)

  ($VulnIDBox.FindItemWithText("$VulnID")).SubItems[1].Text = "+"

  $SaveAFKeyLabel.Visible = $False
  $SaveAFKeyButton.Visible = $False
  $DiscardAFKeyButton.Visible = $False

  $CreateAFKeyButton.Enabled = $True
  $RemoveAFKeyButton.Enabled = $True
  $RenameAFKeyButton.Enabled = $True
  $VulnIDRefreshButton.Enabled = $True
  $AFErrorRefreshButton.Enabled = $True
  $AFErrorRemVulnIDButton.Enabled = $True
  $SaveButton.Enabled = $True
  $AFKeys.Enabled = $True
  $VulnIDBox.Enabled = $True
  $AFErrorBox.Enabled = $True
  $VulnIDStepLabel.Visible = $True
  $OpenAddDelKeyLabel.Visible = $True
}

$handler_DiscardAFKeyButton_Click =
{
  $AFExpectedBox.Text = $TempObj.ExpectedStatus
  $AFValCodeBox.Text = $TempObj.ValidationCode
  $AFValTSBox.Text = $TempObj.ValidTrueStatus
  $AFValTCommBox.Text = $TempObj.ValidTrueComment
  $AFValFSBox.Text = $TempObj.ValidFalseStatus
  $AFValFCommBox.Text = $TempObj.ValidFalseComment

  $null = $TempObj

  $SaveAFKeyLabel.Visible = $False
  $SaveAFKeyButton.Visible = $False
  $DiscardAFKeyButton.Visible = $False

  $CreateAFKeyButton.Enabled = $True
  $RemoveAFKeyButton.Enabled = $True
  $RenameAFKeyButton.Enabled = $True
  $VulnIDRefreshButton.Enabled = $True
  $AFErrorRefreshButton.Enabled = $True
  $AFErrorRemVulnIDButton.Enabled = $True
  $SaveButton.Enabled = $True
  $AFKeys.Enabled = $True
  $VulnIDBox.Enabled = $True
  $AFErrorBox.Enabled = $True
  $VulnIDStepLabel.Visible = $True
  $OpenAddDelKeyLabel.Visible = $True
}

$handler_SaveButton_Click =
{
  New-AnswerFile $AFFilePath $STIG_Name

  $null = Copy-Item $AFFilePath -Destination "$($AFFilePath.replace('.xml','')).bak"

  if ($HTMLCheckBox.Checked -eq $True){
    ConvertTo-HTMLReport
  }

  if ($CSVCheckBox.Checked -eq $True){
    ConvertTo-CSVReport
  }

  $form1.Controls | Where-Object { $_ -is [System.Windows.Forms.Textbox] } | ForEach-Object { $_.clear() }
  $form1.Controls | Where-Object { $_ -is [System.Windows.Forms.ComboBox] } | ForEach-Object { $_.Items.Clear() }
  $form1.Controls | Where-Object { $_ -is [System.Windows.Forms.ListView] } | ForEach-Object { $_.Items.Clear() }

  $AFExpectedBox.SelectedIndex = -1
  $AFValTSBox.SelectedIndex = -1
  $AFValFSBox.SelectedIndex = -1

  $STIGLabel.Text = "$STIG_Name (AnswerFile not loaded)"
  $CKLLabel.Text = "Supported STIGS"
  $SupportedSTIGSBox.Visible = $True
  $SupportedSTIGSBox.ClearSelected()
  $StartHereLabel.Text = "Start by DoubleClicking STIG"
  $StartHereLabel.Visible = $True

  $SaveButton.Visible = $False
  $AFPathLabel.Visible = $False
  $AFFileLabel.Visible = $False
  $SaveAFKeyButton.Visible = $False
  $DiscardAFKeyButton.Visible = $False
  $CKLInfoBox.Visible = $False
  $CreateAFKeyButton.Visible = $False
  $RemoveAFKeyButton.Visible = $False
  $RenameAFKeyButton.Visible = $False
  $NextStepLabel.Visible = $False
  $VulnIDStepLabel.Visible = $False
  $AddOutputLabel.Visible = $False
  $CSVCheckBox.Visible = $False
  $HTMLCheckBox.Visible = $False
  $SaveAFKeyLabel.Visible = $False
  $OpenAddDelKeyLabel.Visible = $False
  $OpenCheckBox.Visible = $False
  $OpenCheckBox.Checked = $True
  $NRCheckBox.Visible = $False
  $NRCheckBox.Checked = $True
  $NFCheckBox.Visible = $False
  $NACheckBox.Visible = $False
  $AFMarkLabel.Visible = $False
  $VulnIDRefreshButton.Visible = $False
  $AFErrorRefreshButton.Visible = $False
  $AFErrorRemVulnIDButton.Visible = $False

  Remove-Variable * -ErrorAction SilentlyContinue
  $AFItems.Clear()
  $STIGItems.Clear()
  $null = $AFFilePath

  $form1.Refresh()
}

$handler_AFErrorRemVulnIDButton_Click = {
  Foreach ($ErrorVulnID in $AFErrorBox.SelectedItems.Text) {
    $OldObj = ($AFItems | Where-Object { $_.VulnID -eq $ErrorVulnID })
    $AFItems.Remove($OldObj)
  }

  &$handler_AFErrorRefreshButton_Click
  $SaveButton.Enabled = $True
}

$handler_AFErrorRefreshButton_Click = {
  $AFErrorBox.Items.Clear()
  Foreach ($AFItem in $AFItems) {
    $AFItem.AnswerKeys | Group-Object AnswerKey | ForEach-Object { if ($_.Count -gt 1) { $AFErrorBox.Items.Add($AFItem.VulnID).SubItems.Add("Dupe AnswerKey") } }
    If ($AFItem.VulnID -notin $STIGItems.VulnID) { $AFErrorBox.Items.Add($AFItem.VulnID).SubItems.Add("VulnID not in CKL") }
  }
}

$handler_VulnIDRefreshButton_Click = {
  $VulnIDBox.Items.Clear()

  If ($OpenCheckBox.Checked -eq $True) { $STIGItems | Where-Object { $_.Status -eq "Open" } | ForEach-Object { $item = New-Object System.Windows.Forms.ListViewItem($_.VulnID); $item.SubItems.Add(""); $item.SubItems.Add($_.Severity); $item.SubItems.Add($_.Status); $VulnIDBox.Items.AddRange($item) } }
  If ($NRCheckBox.Checked -eq $True) { $STIGItems | Where-Object { $_.Status -eq "Not_Reviewed" } | ForEach-Object { $item = New-Object System.Windows.Forms.ListViewItem($_.VulnID); $item.SubItems.Add(""); $item.SubItems.Add($_.Severity); $item.SubItems.Add($_.Status); $VulnIDBox.Items.AddRange($item) } }
  If ($NACheckBox.Checked -eq $True) { $STIGItems | Where-Object { $_.Status -eq "Not_Applicable" } | ForEach-Object { $item = New-Object System.Windows.Forms.ListViewItem($_.VulnID); $item.SubItems.Add(""); $item.SubItems.Add($_.Severity); $item.SubItems.Add($_.Status); $VulnIDBox.Items.AddRange($item) } }
  If ($NFCheckBox.Checked -eq $True) { $STIGItems | Where-Object { $_.Status -eq "NotAFinding" } | ForEach-Object { $item = New-Object System.Windows.Forms.ListViewItem($_.VulnID); $item.SubItems.Add(""); $item.SubItems.Add($_.Severity); $item.SubItems.Add($_.Status); $VulnIDBox.Items.AddRange($item) } }

  for ($i = 0; $i -lt $VulnIDBox.Items.Count; $i++) {
    switch ($VulnIDBox.Items[$i].SubItems[2].Text) {
      "Open" { $VulnIDBox.items[$i].ForeColor = 'Red' }
      "NotAFinding" { $VulnIDBox.items[$i].ForeColor = 'Green' }
      "Not_Reviewed" { $VulnIDBox.items[$i].ForeColor = 'Black' }
      "Not_Applicable" { $VulnIDBox.items[$i].ForeColor = 'Gray' }
    }
    if ($AFItems -match $VulnIDBox.Items[$i].SubItems[0].Text) {
      $VulnIDBox.Items[$i].SubItems[1].Text = "*"
    }
  }

  $OpenCheckBox.Visible = $True
  $NRCheckBox.Visible = $True
  $NFCheckBox.Visible = $True
  $NACheckBox.Visible = $True
  $AFMarkLabel.Visible = $True
  $VulnIDRefreshButton.Visible = $True
}

$handler_VulnIDBox_ColumnClick = {
  #Event Argument: $_ = [System.Windows.Forms.ColumnClickEventArgs]
  Reset-ListViewColumn $this $_.Column
}

$handler_DefaultAFKeyButton_Click = {
  $Script:DefaultAFKey = $AFKeys.SelectedItem
}

$handler_VulnIDBox_MouseDown =
{
  $CKLInfoBox.Clear()
  $form1.Controls | Where-Object { $_ -is [System.Windows.Forms.Textbox] } | ForEach-Object { $_.clear() }
  $form1.Controls | Where-Object { $_ -is [System.Windows.Forms.ComboBox] } | ForEach-Object { $_.Items.Clear() }

  $AFExpectedBox.SelectedIndex = -1
  $AFValTSBox.SelectedIndex = -1
  $AFValFSBox.SelectedIndex = -1

  $CKLInfoBox.Visible = $True

  $handler_AFKeys_SelectedIndexChanged =
  {
    $Script:TempObj = ($AFItems | Where-Object { $_.VulnID -eq $VulnID }).AnswerKeys | Where-Object { $_.AnswerKey -eq $AFKeys.SelectedItem }

    $AFExpectedBox.SelectedIndex = -1
    $AFValTSBox.SelectedIndex = -1
    $AFValFSBox.SelectedIndex = -1

    $SaveAFKeyLabel.Visible = $False
    $SaveAFKeyButton.Visible = $False
    $DiscardAFKeyButton.Visible = $False

    $SelectedAFKey = $AFKeys.Text

    $handler_AFExpectedBox_SelectionChangeCommitted =
    {
      Disable-Form
    }
    $handler_AFValTSBox_SelectionChangeCommitted =
    {
      Disable-Form
    }
    $handler_AFValFSBox_SelectionChangeCommitted =
    {
      Disable-Form
    }
    $handler_AFValCodeBox_KeyDown =
    {
      Disable-Form
    }
    $handler_AFValTCommBox_KeyDown =
    {
      Disable-Form
    }
    $handler_AFValFCommBox_KeyDown =
    {
      Disable-Form
    }

    if (($AFItems -match $VulnID) -or ($AFItems -match ($STIGItems -match $VulnID).LegacyID)) {
      $AFExpectedBox.Text = (($AFItems -match $VulnID).AnswerKeys | Where-Object { $_.AnswerKey -eq $SelectedAFKey}).ExpectedStatus
      $AFValCodeBox.Text = (($AFItems -match $VulnID).AnswerKeys | Where-Object { $_.AnswerKey -eq $SelectedAFKey }).ValidationCode
      $AFValTSBox.Text = (($AFItems -match $VulnID).AnswerKeys | Where-Object { $_.AnswerKey -eq $SelectedAFKey }).ValidTrueStatus
      $AFValTCommBox.Text = (($AFItems -match $VulnID).AnswerKeys | Where-Object { $_.AnswerKey -eq $SelectedAFKey }).ValidTrueComment
      $AFValFSBox.Text = (($AFItems -match $VulnID).AnswerKeys | Where-Object { $_.AnswerKey -eq $SelectedAFKey }).ValidFalseStatus
      $AFValFCommBox.Text = (($AFItems -match $VulnID).AnswerKeys | Where-Object { $_.AnswerKey -eq $SelectedAFKey }).ValidFalseComment
    }

    $AFExpectedBox.add_SelectionChangeCommitted($handler_AFExpectedBox_SelectionChangeCommitted)
    $AFValTSBox.add_SelectionChangeCommitted($handler_AFValTSBox_SelectionChangeCommitted)
    $AFValFSBox.add_SelectionChangeCommitted($handler_AFValFSBox_SelectionChangeCommitted)
    $AFValCodeBox.add_KeyDown($handler_AFValCodeBox_KeyDown)
    $AFValTCommBox.add_KeyDown($handler_AFValTCommBox_KeyDown)
    $AFValFCommBox.add_KeyDown($handler_AFValFCommBox_KeyDown)
  }

  $Script:VulnID = $VulnIDBox.SelectedItems.Text

  if ($OpenButton.Visible -eq $false) {
    if ($null -eq ($AFItems | Where-Object { $_.VulnID -eq $VulnID })) {
      $AFVulnKeys = New-Object System.Collections.Generic.List[System.Object]
      $NewObj = [PSCustomObject]@{
        AnswerKey         = "DEFAULT"
        ExpectedStatus    = "Not_Reviewed"
        ValidationCode    = ""
        ValidTrueStatus   = ""
        ValidTrueComment  = ""
        ValidFalseStatus  = ""
        ValidFalseComment = ""
      }
      $AFVulnKeys.Add($NewObj)

      $NewObj = [PSCustomObject]@{
        VulnID     = $VulnID
        AnswerKeys = $AFVulnKeys
      }
      $AFItems.Add($NewObj)
    }

    $STIGLabel.Text = "$STIG_Name AnswerFile ($VulnID)"
    if ($AFItems -match $VulnID){
      ForEach ($Key in ($AFItems -match $VulnID).AnswerKeys) {
        $null = $AFKeys.Items.Add($Key.AnswerKey)
      }

      ($VulnIDBox.FindItemWithText("$VulnID")).SubItems[1].Text = "+"
    }

    $AFKeys.add_SelectedIndexChanged($handler_AFKeys_SelectedIndexChanged)
    $null = @("Not_Reviewed", "Open", "NotAFinding", "Not_Applicable") | ForEach-Object { $AFExpectedBox.Items.Add($_) }
    $null = @("Not_Reviewed", "Open", "NotAFinding", "Not_Applicable") | ForEach-Object { $AFValTSBox.Items.Add($_) }
    $null = @("Not_Reviewed", "Open", "NotAFinding", "Not_Applicable") | ForEach-Object { $AFValFSBox.Items.Add($_) }

    if ($null -eq $DefaultAFKey){
      $AFKeys.SelectedItem = "DEFAULT"
    }
    else{
      $AFKeys.SelectedItem = $DefaultAFKey
    }
  }
  else{
    $STIGLabel.Text = "$STIG_Name (AnswerFile not loaded)"
  }

  $CKLInfoBox.SelectionFont = $BoldBoxFont
  $CKLInfoBox.AppendText("Rule Title: ")
  $CKLInfoBox.SelectionFont = $BoxFont
  $CKLInfoBox.AppendText("$(($STIGItems -match $VulnID).RuleTitle)`r`n`r`n")
  $CKLInfoBox.SelectionFont = $BoldBoxFont
  $CKLInfoBox.AppendText("Rule Discussion: ")
  $CKLInfoBox.SelectionFont = $BoxFont
  $CKLInfoBox.AppendText("$(($STIGItems -match $VulnID).RuleVuln_Discuss)`r`n`r`n")
  $CKLInfoBox.SelectionFont = $BoldBoxFont
  $CKLInfoBox.AppendText("Rule Check Text: ")
  $CKLInfoBox.SelectionFont = $BoxFont
  $CKLInfoBox.AppendText("$(($STIGItems -match $VulnID).RuleCheck_Content)")

  if ($AFItems){
    $OpenAddDelKeyLabel.Visible = $True
    $CreateAFKeyButton.Visible = $True
    $RemoveAFKeyButton.Visible = $True
    $RenameAFKeyButton.Visible = $True
  }
}

$handler_DarkModeButton_Click = {
  If ($DarkModeButton.Text -eq "Dark Mode Off"){
    $form1.BackColor = "DimGray"
    $form1.Controls | Where-Object { $_ -is [System.Windows.Forms.Textbox] } | ForEach-Object { $_.BackColor = "Gray" }
    $form1.Controls | Where-Object { $_ -is [System.Windows.Forms.ComboBox] } | ForEach-Object { $_.BackColor = "Gray" }
    $form1.Controls | Where-Object { $_ -is [System.Windows.Forms.ListView] } | ForEach-Object { $_.BackColor = "Gray" }
    $form1.Controls | Where-Object { $_ -is [System.Windows.Forms.ListBox] } | ForEach-Object { $_.BackColor = "Gray" }
    $DarkModeButton.Text = "Dark Mode On"
  }
  elseif ($DarkModeButton.Text -eq "Dark Mode On") {
    $form1.BackColor = "Control"
    $form1.Controls | Where-Object { $_ -is [System.Windows.Forms.Textbox] } | ForEach-Object { $_.BackColor = "White" }
    $form1.Controls | Where-Object { $_ -is [System.Windows.Forms.ComboBox] } | ForEach-Object { $_.BackColor = "White" }
    $form1.Controls | Where-Object { $_ -is [System.Windows.Forms.ListView] } | ForEach-Object { $_.BackColor = "White" }
    $form1.Controls | Where-Object { $_ -is [System.Windows.Forms.ListBox] } | ForEach-Object { $_.BackColor = "White" }
    $DarkModeButton.Text = "Dark Mode Off"
  }

  $AFValCodeBox.BackColor = "DarkBlue"
    $AFValCodeBox.ForeColor = "White"
}

$handler_formclose =
{
  if (($SaveButton.Enabled -eq $True) -and ($SaveButton.Visible -eq $True)){
    $confirm = [System.Windows.MessageBox]::Show("$AFFilePath is not saved. Save and Exit?", "Confirmation", "YesNo", "Question")

    if ($confirm -eq "Yes") {
      &$handler_SaveButton_Click
    }
  }

  1..3 | ForEach-Object {[GC]::Collect()}

  $form1.Dispose()
}

$form1 = New-Object System.Windows.Forms.Form
[Windows.Forms.Application]::EnableVisualStyles()

# Verify Evaluate-STIG files integrity
  if (Test-Path (Join-Path -Path $PsScriptRoot -ChildPath "Modules" | Join-Path -ChildPath "Master_Functions")){
      # Import required modules
      $PowerShellVersion = $PsVersionTable.PSVersion

      If ($PowerShellVersion -lt [Version]"7.0") {
          Import-Module (Join-Path -Path $PsScriptRoot -ChildPath "Modules" | Join-Path -ChildPath "Master_Functions")
      }
      Else {
          Import-Module (Join-Path -Path $PsScriptRoot -ChildPath "Modules" | Join-Path -ChildPath "Master_Functions") -SkipEditionCheck
      }
  }
  else{
      Write-Host "ERROR: 'Modules' location detection failed.  Unable to continue." -ForegroundColor Red
      Return
  }

  $Verified = $true
  If (Test-Path (Join-Path -Path $PSScriptRoot -ChildPath "xml" | Join-Path -ChildPath "FileList.xml")) {
    [XML]$FileListXML = Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath "xml" | Join-Path -ChildPath "FileList.xml")
    ForEach ($File in $FileListXML.FileList.File) {
      if ($File.ScanReq -eq "Required"){
        $Path = (Join-Path -Path $PsScriptRoot -ChildPath $File.Path | Join-Path -ChildPath $File.Name)
        If (!(Test-Path $Path)) {
          $Verified = $false
        }
      }
    }
    If ($Verified -eq $False) {
        Write-Host "ERROR: One or more Evaluate-STIG files were not found.  Unable to continue." -ForegroundColor Yellow
        Return
    }
  }
  Else {
      Write-Host "ERROR: 'FileList.xml' not found.  Unable to verify content integrity." -ForegroundColor Red
      Return
  }

#----------------------------------------------
#region Generated Form Code

$form1.Text = "Manage AnswerFiles"
$form1.Name = "form1"
$form1.SuspendLayout()

$form1.AutoScaleDimensions =  New-Object System.Drawing.SizeF(96, 96)
$form1.AutoScaleMode  = [System.Windows.Forms.AutoScaleMode]::Dpi

$form1.FormBorderStyle = "FixedDialog"
$form1.StartPosition = "CenterScreen"
$form1.DataBindings.DefaultDataSourceUpdateMode = 0
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 1920
$System_Drawing_Size.Height = 1000
$form1.ClientSize = $System_Drawing_Size
$form1.StartPosition = "WindowsDefaultLocation"

$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 1150
$System_Drawing_Size.Height = 40
$STIGLabel.Size = $System_Drawing_Size
$STIGLabel.Text = "AnswerFile STIG Name"
$STIGLabel.AutoSize = $False
$STIGLabel.Font = $TitleFont
$STIGLabel.TextAlign = "TopCenter"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 850
$System_Drawing_Point.Y = 5
$STIGLabel.Location = $System_Drawing_Point
$form1.Controls.Add($STIGLabel)

$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 980
$System_Drawing_Size.Height = 40
$AFPathLabel.Size = $System_Drawing_Size
$AFPathLabel.Text = "AnswerFile Path"
$AFPathLabel.AutoSize = $false
$AFPathLabel.Font = $BodyFont
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 800
$System_Drawing_Point.Y = 915
$AFPathLabel.Location = $System_Drawing_Point
$form1.Controls.Add($AFPathLabel)

$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 980
$System_Drawing_Size.Height = 40
$AFFileLabel.Size = $System_Drawing_Size
$AFFileLabel.Text = "AnswerFile FileName"
$AFFileLabel.AutoSize = $false
$AFFileLabel.Font = $BodyFont
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 800
$System_Drawing_Point.Y = 960
$AFFileLabel.Location = $System_Drawing_Point
$form1.Controls.Add($AFFileLabel)

$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 300
$System_Drawing_Size.Height = 480
$VulnIDBox.Size = $System_Drawing_Size
$VulnIDBox.Name = "VulnIDBox"
$VulnIDBox.View = "Details"
$VulnIDBox.MultiSelect = $false
$VulnIDBox.FullRowSelect = $true
$VulnIDBox.Font = $BoxFont
$VulnIDBox.HideSelection = $False
$NameColumn = New-Object System.Windows.Forms.ColumnHeader
$null = $VulnIDBox.Columns.Add($NameColumn)
$NameColumn.text = "Vuln ID"
$NameColumn.width = "125"
$InAFColumn = New-Object System.Windows.Forms.ColumnHeader
$null = $VulnIDBox.Columns.Add($InAFColumn)
$InAFColumn.text = "AF"
$InAFColumn.width = "40"
$CatColumn = New-Object System.Windows.Forms.ColumnHeader
$null = $VulnIDBox.Columns.Add($CatColumn)
$CatColumn.text = "CAT"
$CatColumn.width = "50"
$StatusColumn = New-Object System.Windows.Forms.ColumnHeader
$null = $VulnIDBox.Columns.Add($StatusColumn)
$StatusColumn.text = "CKL Status"
$StatusColumn.width = "245"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 465
$System_Drawing_Point.Y = 70
$VulnIDBox.Location = $System_Drawing_Point
$VulnIDBox.add_ItemSelectionChanged($handler_VulnIDBox_MouseDown)
$VulnIDBox.add_ColumnClick($handler_VulnIDBox_ColumnClick)
$form1.Controls.Add($VulnIDBox)

$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 300
$System_Drawing_Size.Height = 320
$AFErrorBox.Size = $System_Drawing_Size
$AFErrorBox.Name = "AFErrorBox"
$AFErrorBox.View = "Details"
$AFErrorBox.MultiSelect = $True
$AFErrorBox.FullRowSelect = $true
$AFErrorBox.Font = $BoxFont
$NameColumn = New-Object System.Windows.Forms.ColumnHeader
$null = $AFErrorBox.Columns.Add($NameColumn)
$NameColumn.text = "Vuln ID"
$NameColumn.width = "150"
$ErrorColumn = New-Object System.Windows.Forms.ColumnHeader
$null = $AFErrorBox.Columns.Add($ErrorColumn)
$ErrorColumn.text = "Error"
$ErrorColumn.width = "260"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 465
$System_Drawing_Point.Y = 645
$AFErrorBox.Location = $System_Drawing_Point
$form1.Controls.Add($AFErrorBox)

$OpenButton.Name = "OpenButton"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 125
$System_Drawing_Size.Height = 80
$OpenButton.Size = $System_Drawing_Size
$OpenButton.UseVisualStyleBackColor = $True
$OpenButton.Text = "Open AnswerFile (XML/CSV)"
$OpenButton.Font = $BoxFont
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 1660
$System_Drawing_Point.Y = 920
$OpenButton.Location = $System_Drawing_Point
$OpenButton.DataBindings.DefaultDataSourceUpdateMode = 0
$OpenButton.add_Click($handler_OpenButton_Click)
$form1.Controls.Add($OpenButton)
$OpenButton.Enabled = $False

$CreateButton.Name = "CreateButton"
$CreateButton.Size = $System_Drawing_Size
$CreateButton.UseVisualStyleBackColor = $True
$CreateButton.Text = "Create AnswerFile"
$CreateButton.Font = $BoxFont
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 1795
$System_Drawing_Point.Y = 920
$CreateButton.Location = $System_Drawing_Point
$CreateButton.DataBindings.DefaultDataSourceUpdateMode = 0
$CreateButton.add_Click($handler_CreateButton_Click)
$form1.Controls.Add($CreateButton)
$CreateButton.Enabled = $False

$SaveButton.Name = "SaveButton"
$SaveButton.Size = $System_Drawing_Size
$SaveButton.UseVisualStyleBackColor = $True
$SaveButton.Text = "Save AnswerFile (XML)"
$SaveButton.Font = $BoxFont
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 1790
$System_Drawing_Point.Y = 920
$SaveButton.Location = $System_Drawing_Point
$SaveButton.DataBindings.DefaultDataSourceUpdateMode = 0
$SaveButton.add_Click($handler_SaveButton_Click)
$form1.Controls.Add($SaveButton)

$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 400
$System_Drawing_Size.Height = 875
$SupportedSTIGSBox.Size = $System_Drawing_Size
$SupportedSTIGSBox.Name = "SupportedSTIGSBox"
$SupportedSTIGSBox.Font = $BoxFont
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 40
$System_Drawing_Point.Y = 50
$SupportedSTIGSBox.Location = $System_Drawing_Point
$SupportedSTIGSBox.add_DoubleClick($handler_SupportedSTIGSBox_DoubleClick)
$form1.Controls.Add($SupportedSTIGSBox)

$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 435
$System_Drawing_Size.Height = 855
$CKLInfoBox.Size = $System_Drawing_Size
$CKLInfoBox.Name = "CKLInfoBox"
$CKLInfoBox.Multiline = $True
$CKLInfoBox.Scrollbars = "Both"
$CKLInfoBox.Readonly = $True
$CKLInfoBox.Font = $BoxFont
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 10
$System_Drawing_Point.Y = 70
$CKLInfoBox.Location = $System_Drawing_Point
$form1.Controls.Add($CKLInfoBox)

$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 800
$System_Drawing_Size.Height = 40
$CKLLabel.Size = $System_Drawing_Size
$CKLLabel.AutoSize = $False
$CKLLabel.Font = $TitleFont
$CKLLabel.TextAlign = "TopCenter"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 5
$System_Drawing_Point.Y = 5
$CKLLabel.Location = $System_Drawing_Point
$form1.Controls.Add($CKLLabel)

$SaveAFKeyButton.Name = "SaveAFKeyButton"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 125
$System_Drawing_Size.Height = 45
$SaveAFKeyButton.Size = $System_Drawing_Size
$SaveAFKeyButton.UseVisualStyleBackColor = $True
$SaveAFKeyButton.Text = "Save Answer Key Changes"
$SaveAFKeyButton.Font = $BoxFont
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 1775
$System_Drawing_Point.Y = 115
$SaveAFKeyButton.Location = $System_Drawing_Point
$SaveAFKeyButton.DataBindings.DefaultDataSourceUpdateMode = 0
$SaveAFKeyButton.add_Click($handler_SaveAFKeyButton_Click)
$form1.Controls.Add($SaveAFKeyButton)

$DiscardAFKeyButton.Name = "DiscardAFKeyButton"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 125
$System_Drawing_Size.Height = 45
$DiscardAFKeyButton.Size = $System_Drawing_Size
$DiscardAFKeyButton.UseVisualStyleBackColor = $True
$DiscardAFKeyButton.Text = "Discard Answer Key Changes"
$DiscardAFKeyButton.Font = $BoxFont
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 1650
$System_Drawing_Point.Y = 115
$DiscardAFKeyButton.Location = $System_Drawing_Point
$DiscardAFKeyButton.DataBindings.DefaultDataSourceUpdateMode = 0
$DiscardAFKeyButton.add_Click($handler_DiscardAFKeyButton_Click)
$form1.Controls.Add($DiscardAFKeyButton)

$CreateAFKeyButton.Name = "CreateAFKeyButton"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 100
$System_Drawing_Size.Height = 30
$CreateAFKeyButton.Size = $System_Drawing_Size
$CreateAFKeyButton.UseVisualStyleBackColor = $True
$CreateAFKeyButton.Text = "New Key"
$CreateAFKeyButton.Font = $BoxFont
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 1230
$System_Drawing_Point.Y = 55
$CreateAFKeyButton.Location = $System_Drawing_Point
$CreateAFKeyButton.DataBindings.DefaultDataSourceUpdateMode = 0
$CreateAFKeyButton.add_Click($handler_CreateAFKeyButton_Click)
$form1.Controls.Add($CreateAFKeyButton)

$RemoveAFKeyButton.Name = "RemoveAFKeyButton"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 100
$System_Drawing_Size.Height = 30
$RemoveAFKeyButton.Size = $System_Drawing_Size
$RemoveAFKeyButton.UseVisualStyleBackColor = $True
$RemoveAFKeyButton.Text = "Delete Key"
$RemoveAFKeyButton.Font = $BoxFont
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 1330
$System_Drawing_Point.Y = 55
$RemoveAFKeyButton.Location = $System_Drawing_Point
$RemoveAFKeyButton.DataBindings.DefaultDataSourceUpdateMode = 0
$RemoveAFKeyButton.add_Click($handler_RemoveAFKeyButton_Click)
$form1.Controls.Add($RemoveAFKeyButton)

$RenameAFKeyButton.Name = "RenameAFKeyButton"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 100
$System_Drawing_Size.Height = 30
$RenameAFKeyButton.Size = $System_Drawing_Size
$RenameAFKeyButton.UseVisualStyleBackColor = $True
$RenameAFKeyButton.Text = "Rename Key"
$RenameAFKeyButton.Font = $BoxFont
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 1430
$System_Drawing_Point.Y = 55
$RenameAFKeyButton.Location = $System_Drawing_Point
$RenameAFKeyButton.DataBindings.DefaultDataSourceUpdateMode = 0
$RenameAFKeyButton.add_Click($handler_RenameAFKeyButton_Click)
$form1.Controls.Add($RenameAFKeyButton)

$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 250
$System_Drawing_Size.Height = 30
$AFKeyLabel.Size = $System_Drawing_Size
$AFKeyLabel.Text = "AnswerKey:"
$AFKeyLabel.AutoSize = $false
$AFKeyLabel.Font = $BodyFont
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 800
$System_Drawing_Point.Y = 50
$AFKeyLabel.Location = $System_Drawing_Point
$form1.Controls.Add($AFKeyLabel)

$AFExpectedLabel.Size = $System_Drawing_Size
$AFExpectedLabel.Text = "Expected Status:"
$AFExpectedLabel.AutoSize = $false
$AFExpectedLabel.Font = $BodyFont
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 800
$System_Drawing_Point.Y = 120
$AFExpectedLabel.Location = $System_Drawing_Point
$form1.Controls.Add($AFExpectedLabel)

$AFValCodeLabel.Size = $System_Drawing_Size
$AFValCodeLabel.Text = "Validate Code:"
$AFValCodeLabel.AutoSize = $false
$AFValCodeLabel.Font = $BodyFont
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 800
$System_Drawing_Point.Y = 170
$AFValCodeLabel.Location = $System_Drawing_Point
$form1.Controls.Add($AFValCodeLabel)

$AFValTSLabel.Size = $System_Drawing_Size
$AFValTSLabel.Text = "Valid True Status:"
$AFValTSLabel.AutoSize = $false
$AFValTSLabel.Font = $BodyFont
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 800
$System_Drawing_Point.Y = 405
$AFValTSLabel.Location = $System_Drawing_Point
$form1.Controls.Add($AFValTSLabel)

$AFValTCommLabel.Size = $System_Drawing_Size
$AFValTCommLabel.Text = "Valid True Comment:"
$AFValTCommLabel.AutoSize = $false
$AFValTCommLabel.Font = $BodyFont
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 800
$System_Drawing_Point.Y = 455
$AFValTCommLabel.Location = $System_Drawing_Point
$form1.Controls.Add($AFValTCommLabel)

$AFValFSLabel.Size = $System_Drawing_Size
$AFValFSLabel.Text = "Valid False Status:"
$AFValFSLabel.AutoSize = $false
$AFValFSLabel.Font = $BodyFont
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 800
$System_Drawing_Point.Y = 650
$AFValFSLabel.Location = $System_Drawing_Point
$form1.Controls.Add($AFValFSLabel)

$AFValFCommLabel.Size = $System_Drawing_Size
$AFValFCommLabel.Text = "Valid False Comment:"
$AFValFCommLabel.AutoSize = $false
$AFValFCommLabel.Font = $BodyFont
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 800
$System_Drawing_Point.Y = 710
$AFValFCommLabel.Location = $System_Drawing_Point
$form1.Controls.Add($AFValFCommLabel)

$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 300
$System_Drawing_Size.Height = 30
$StartHereLabel.Size = $System_Drawing_Size
$StartHereLabel.Text = "Start by DoubleClicking STIG"
$StartHereLabel.AutoSize = $false
$StartHereLabel.Font = $BodyFont
$StartHereLabel.ForeColor = "Green"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 70
$System_Drawing_Point.Y = 940
$StartHereLabel.Location = $System_Drawing_Point
$form1.Controls.Add($StartHereLabel)

$NextStepLabel.Size = $System_Drawing_Size
$NextStepLabel.Text = "Open/Create Answer File ->"
$NextStepLabel.AutoSize = $false
$NextStepLabel.Font = $BodyFont
$NextStepLabel.ForeColor = "Green"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 1325
$System_Drawing_Point.Y = 940
$NextStepLabel.Location = $System_Drawing_Point
$form1.Controls.Add($NextStepLabel)

$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 350
$System_Drawing_Size.Height = 30
$OpenAddDelKeyLabel.Size = $System_Drawing_Size
$OpenAddDelKeyLabel.Text = "<- Select/Manage AnswerKey"
$OpenAddDelKeyLabel.AutoSize = $false
$OpenAddDelKeyLabel.Font = $BodyFont
$OpenAddDelKeyLabel.ForeColor = "Green"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 1530
$System_Drawing_Point.Y = 50
$OpenAddDelKeyLabel.Location = $System_Drawing_Point
$form1.Controls.Add($OpenAddDelKeyLabel)

$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 500
$System_Drawing_Size.Height = 30
$SaveAFKeyLabel.Size = $System_Drawing_Size
$SaveAFKeyLabel.AutoSize = $false
$SaveAFKeyLabel.Font = $BodyFont
$SaveAFKeyLabel.ForeColor = "Red"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 1200
$System_Drawing_Point.Y = 120
$SaveAFKeyLabel.Location = $System_Drawing_Point
$form1.Controls.Add($SaveAFKeyLabel)

$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 250
$System_Drawing_Size.Height = 30
$VulnIDStepLabel.Size = $System_Drawing_Size
$VulnIDStepLabel.Text = "Select Vuln ID from CKL"
$VulnIDStepLabel.AutoSize = $false
$VulnIDStepLabel.Font = $BodyFont
$VulnIDStepLabel.ForeColor = "Green"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 490
$System_Drawing_Point.Y = 40
$VulnIDStepLabel.Location = $System_Drawing_Point
$form1.Controls.Add($VulnIDStepLabel)

$AFErrorLabel.Size = $System_Drawing_Size
$AFErrorLabel.Text = "AnswerFile Errors"
$AFErrorLabel.AutoSize = $false
$AFErrorLabel.Font = $BodyFont
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 515
$System_Drawing_Point.Y = 605
$AFErrorLabel.Location = $System_Drawing_Point
$form1.Controls.Add($AFErrorLabel)

$AFErrorRemVulnIDButton.Name = "AFErrorRemVulnIDButton"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 170
$System_Drawing_Size.Height = 30
$AFErrorRemVulnIDButton.Size = $System_Drawing_Size
$AFErrorRemVulnIDButton.UseVisualStyleBackColor = $True
$AFErrorRemVulnIDButton.Text = "Delete VulnID"
$AFErrorRemVulnIDButton.Font = $BoxFont
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 465
$System_Drawing_Point.Y = 965
$AFErrorRemVulnIDButton.Location = $System_Drawing_Point
$AFErrorRemVulnIDButton.DataBindings.DefaultDataSourceUpdateMode = 0
$AFErrorRemVulnIDButton.add_Click($handler_AFErrorRemVulnIDButton_Click)
$form1.Controls.Add($AFErrorRemVulnIDButton)

$AFErrorRefreshButton.Name = "AFErrorRefreshButton"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 130
$System_Drawing_Size.Height = 30
$AFErrorRefreshButton.Size = $System_Drawing_Size
$AFErrorRefreshButton.UseVisualStyleBackColor = $True
$AFErrorRefreshButton.Text = "Refresh Error List"
$AFErrorRefreshButton.Font = $BoxFont
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 635
$System_Drawing_Point.Y = 965
$AFErrorRefreshButton.Location = $System_Drawing_Point
$AFErrorRefreshButton.DataBindings.DefaultDataSourceUpdateMode = 0
$AFErrorRefreshButton.add_Click($handler_AFErrorRefreshButton_Click)
$form1.Controls.Add($AFErrorRefreshButton)

$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 180
$System_Drawing_Size.Height = 100
$AddOutputLabel.Size = $System_Drawing_Size
$AddOutputLabel.Text = "Additional Output Types:"
$AddOutputLabel.AutoSize = $false
$AddOutputLabel.Font = $BoxFont
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 1610
$System_Drawing_Point.Y = 895
$AddOutputLabel.Location = $System_Drawing_Point
$form1.Controls.Add($AddOutputLabel)

$AFKeys.Name = "AFKeys"
$AFKeys.Font = $BoxFont
$AFKeys.Width = 150
$AFKeys.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 1050
$System_Drawing_Point.Y = 55
$AFKeys.Location = $System_Drawing_Point
$form1.Controls.Add($AFKeys)

$HLine.Text = ""
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 1070
$System_Drawing_Size.Height = 2
$HLine.Size = $System_Drawing_Size
$HLine.BorderStyle = "Fixed3D"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 780
$System_Drawing_Point.Y = 100
$HLine.Location = $System_Drawing_Point
$form1.Controls.Add($HLine)

$VLine.Text = ""
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 2
$System_Drawing_Size.Height = 1900
$VLine.Size = $System_Drawing_Size
$VLine.BorderStyle = "Fixed3D"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 780
$System_Drawing_Point.Y = 0
$VLine.Location = $System_Drawing_Point
$form1.Controls.Add($VLine)

$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 850
$System_Drawing_Size.Height = 210
$AFValCodeBox.Size = $System_Drawing_Size
$AFValCodeBox.Name = "AFValCodeBox"
$AFValCodeBox.Multiline = $True
$AFValCodeBox.Scrollbars = "Vertical"
$AFValCodeBox.Font = $BoxFont
$AFValCodeBox.BackColor = "DarkBlue"
$AFValCodeBox.ForeColor = "White"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 1050
$System_Drawing_Point.Y = 170
$AFValCodeBox.Location = $System_Drawing_Point
$form1.Controls.Add($AFValCodeBox)

$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 850
$System_Drawing_Size.Height = 180
$AFValTCommBox.Size = $System_Drawing_Size
$AFValTCommBox.Name = "AFValTCommBox"
$AFValTCommBox.Multiline = $True
$AFValTCommBox.Scrollbars = "Vertical"
$AFValTCommBox.Font = $BoxFont
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 1050
$System_Drawing_Point.Y = 455
$AFValTCommBox.Location = $System_Drawing_Point
$form1.Controls.Add($AFValTCommBox)

$AFValFCommBox.Size = $System_Drawing_Size
$AFValFCommBox.Name = "AFValFCommBox"
$AFValFCommBox.Multiline = $True
$AFValFCommBox.Scrollbars = "Vertical"
$AFValFCommBox.Font = $BoxFont
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 1050
$System_Drawing_Point.Y = 710
$AFValFCommBox.Location = $System_Drawing_Point
$form1.Controls.Add($AFValFCommBox)

$AFExpectedBox.Name = "AFExpectedBox"
$AFExpectedBox.Font = $BoxFont
$AFExpectedBox.Width = 125
$AFExpectedBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 1050
$System_Drawing_Point.Y = 125
$AFExpectedBox.Location = $System_Drawing_Point
$form1.Controls.Add($AFExpectedBox)

$AFValTSBox.Name = "AFValTSBox"
$AFValTSBox.Font = $BoxFont
$AFValTSBox.Width = 125
$AFValTSBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 1050
$System_Drawing_Point.Y = 405
$AFValTSBox.Location = $System_Drawing_Point
$form1.Controls.Add($AFValTSBox)

$AFValFSBox.Name = "AFValFSBox"
$AFValFSBox.Font = $BoxFont
$AFValFSBox.Width = 125
$AFValFSBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 1050
$System_Drawing_Point.Y = 655
$AFValFSBox.Location = $System_Drawing_Point
$form1.Controls.Add($AFValFSBox)

$HTMLCheckBox.Name = "HTMLCheckBox"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 75
$System_Drawing_Size.Height = 50
$HTMLCheckBox.Size = $System_Drawing_Size
$HTMLCheckBox.Text = "HTML"
$HTMLCheckBox.Font = $BoxFont
$HTMLCheckBox.Checked = $false
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 1795
$System_Drawing_Point.Y = 885
$HTMLCheckBox.Location = $System_Drawing_Point
$HTMLCheckBox.UseVisualStyleBackColor = $True
$form1.Controls.Add($HTMLCheckBox)

$CSVCheckBox.Name = "CSVCheckBox"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 50
$System_Drawing_Size.Height = 50
$CSVCheckBox.Size = $System_Drawing_Size
$CSVCheckBox.Text = "CSV"
$CSVCheckBox.Font = $BoxFont
$CSVCheckBox.Checked = $false
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 1870
$System_Drawing_Point.Y = 885
$CSVCheckBox.Location = $System_Drawing_Point
$CSVCheckBox.UseVisualStyleBackColor = $True
$form1.Controls.Add($CSVCheckBox)

$OpenCheckBox.Name = "OpenCheckBox"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 35
$System_Drawing_Size.Height = 50
$OpenCheckBox.Size = $System_Drawing_Size
$OpenCheckBox.Text = "O"
$OpenCheckBox.Font = $BoxFont
$OpenCheckBox.Checked = $false
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 465
$System_Drawing_Point.Y = 535
$OpenCheckBox.Location = $System_Drawing_Point
$OpenCheckBox.UseVisualStyleBackColor = $True
$form1.Controls.Add($OpenCheckBox)

$NRCheckBox.Name = "NRCheckBox"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 45
$System_Drawing_Size.Height = 50
$NRCheckBox.Size = $System_Drawing_Size
$NRCheckBox.Text = "NR"
$NRCheckBox.Font = $BoxFont
$NRCheckBox.Checked = $false
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 515
$System_Drawing_Point.Y = 535
$NRCheckBox.Location = $System_Drawing_Point
$NRCheckBox.UseVisualStyleBackColor = $True
$form1.Controls.Add($NRCheckBox)

$NFCheckBox.Name = "NFCheckBox"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 45
$System_Drawing_Size.Height = 50
$NFCheckBox.Size = $System_Drawing_Size
$NFCheckBox.Text = "NF"
$NFCheckBox.Font = $BoxFont
$NFCheckBox.Checked = $false
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 580
$System_Drawing_Point.Y = 535
$NFCheckBox.Location = $System_Drawing_Point
$NFCheckBox.UseVisualStyleBackColor = $True
$form1.Controls.Add($NFCheckBox)

$NACheckBox.Name = "NACheckBox"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 45
$System_Drawing_Size.Height = 50
$NACheckBox.Size = $System_Drawing_Size
$NACheckBox.Text = "NA"
$NACheckBox.Font = $BoxFont
$NACheckBox.Checked = $false
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 645
$System_Drawing_Point.Y = 535
$NACheckBox.Location = $System_Drawing_Point
$NACheckBox.UseVisualStyleBackColor = $True
$form1.Controls.Add($NACheckBox)

$DefaultAFKeyButton.Name = "DefaultAFKeyButton"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 150
$System_Drawing_Size.Height = 20
$DefaultAFKeyButton.Size = $System_Drawing_Size
$DefaultAFKeyButton.UseVisualStyleBackColor = $True
$DefaultAFKeyButton.Text = "Set as Default"
$DefaultAFKeyButton.Font = $BoxFont
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 1050
$System_Drawing_Point.Y = 80
$DefaultAFKeyButton.Location = $System_Drawing_Point
$DefaultAFKeyButton.add_Click($handler_DefaultAFKeyButton_Click)
$form1.Controls.Add($DefaultAFKeyButton)

$VulnIDRefreshButton.Name = "VulnIDRefreshButton"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 65
$System_Drawing_Size.Height = 30
$VulnIDRefreshButton.Size = $System_Drawing_Size
$VulnIDRefreshButton.UseVisualStyleBackColor = $True
$VulnIDRefreshButton.Text = "Refresh"
$VulnIDRefreshButton.Font = $BoxFont
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 700
$System_Drawing_Point.Y = 550
$VulnIDRefreshButton.Location = $System_Drawing_Point
$VulnIDRefreshButton.add_Click($handler_VulnIDRefreshButton_Click)
$form1.Controls.Add($VulnIDRefreshButton)

$DarkModeButton.Name = "DarkModeButton"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 120
$System_Drawing_Size.Height = 20
$DarkModeButton.Size = $System_Drawing_Size
$DarkModeButton.UseVisualStyleBackColor = $True
$DarkModeButton.Text = "Dark Mode Off"
$DarkModeButton.Font = $BoxFont
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 5
$System_Drawing_Point.Y = 975
$DarkModeButton.Location = $System_Drawing_Point
$DarkModeButton.add_Click($handler_DarkModeButton_Click)
$form1.Controls.Add($DarkModeButton)

$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 300
$System_Drawing_Size.Height = 30
$AFMarkLabel.Size = $System_Drawing_Size
$AFMarkLabel.Text = "*Key in AF +Key Added Saved -Key Removed"
$AFMarkLabel.AutoSize = $false
$AFMarkLabel.Font = $BoxFont
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 465
$System_Drawing_Point.Y = 580
$AFMarkLabel.Location = $System_Drawing_Point
$form1.Controls.Add($AFMarkLabel)

$form1.ResumeLayout()

$SaveButton.Visible = $False
$AFPathLabel.Visible = $False
$AFFileLabel.Visible = $False
$SaveAFKeyButton.Visible = $False
$DiscardAFKeyButton.Visible = $False
$CKLInfoBox.Visible = $False
$CreateAFKeyButton.Visible = $False
$RemoveAFKeyButton.Visible = $False
$RenameAFKeyButton.Visible = $False
$NextStepLabel.Visible = $False
$VulnIDStepLabel.Visible = $False
$AddOutputLabel.Visible = $False
$CSVCheckBox.Visible = $False
$HTMLCheckBox.Visible = $False
$SaveAFKeyLabel.Visible = $False
$OpenAddDelKeyLabel.Visible = $False
$OpenCheckBox.Visible = $False
$OpenCheckBox.Checked = $True
$NRCheckBox.Visible = $False
$NRCheckBox.Checked = $True
$NFCheckBox.Visible = $False
$NACheckBox.Visible = $False
$AFMarkLabel.Visible = $False
$VulnIDRefreshButton.Visible = $False
$AFErrorRefreshButton.Visible = $False
$AFErrorRemVulnIDButton.Visible = $False

#Init the OnLoad event to correct the initial state of the form
$InitialFormWindowState = $form1.WindowState

#Save the initial state of the form
$form1.add_Load($OnLoadForm_StateCorrection)

$form1.Add_FormClosed($handler_formclose)
#Show the Form
$null = [Windows.Forms.Application]::Run($form1)

# SIG # Begin signature block
# MIIL+QYJKoZIhvcNAQcCoIIL6jCCC+YCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAz3uA0EG2XzImG
# k2GtZcLRVIaW3eEfwXe2vi/tnDnfBaCCCTswggR6MIIDYqADAgECAgQDAgTXMA0G
# CSqGSIb3DQEBCwUAMFoxCzAJBgNVBAYTAlVTMRgwFgYDVQQKEw9VLlMuIEdvdmVy
# bm1lbnQxDDAKBgNVBAsTA0RvRDEMMAoGA1UECxMDUEtJMRUwEwYDVQQDEwxET0Qg
# SUQgQ0EtNTkwHhcNMjAwNzE1MDAwMDAwWhcNMjUwNDAyMTMzODMyWjBpMQswCQYD
# VQQGEwJVUzEYMBYGA1UEChMPVS5TLiBHb3Zlcm5tZW50MQwwCgYDVQQLEwNEb0Qx
# DDAKBgNVBAsTA1BLSTEMMAoGA1UECxMDVVNOMRYwFAYDVQQDEw1DUy5OU1dDQ0Qu
# MDAxMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA2/Z91ObHZ009DjsX
# ySa9T6DbT+wWgX4NLeTYZwx264hfFgUnIww8C9Mm6ht4mVfo/qyvmMAqFdeyhXiV
# PZuhbDnzdKeXpy5J+oxtWjAgnWwJ983s3RVewtV063W7kYIqzj+Ncfsx4Q4TSgmy
# ASOMTUhlzm0SqP76zU3URRj6N//NzxAcOPLlfzxcFPMpWHC9zNlVtFqGtyZi/STj
# B7ed3BOXmddiLNLCL3oJm6rOsidZstKxEs3I1llWjsnltn7fR2/+Fm+roWrF8B4z
# ekQOu9t8WRZfNohKoXVtVuwyUAJQF/8kVtIa2YyxTUAF9co9qVNZgko/nx0gIdxS
# hxmEvQIDAQABo4IBNzCCATMwHwYDVR0jBBgwFoAUdQmmFROuhzz6c5QA8vD1ebmy
# chQwQQYDVR0fBDowODA2oDSgMoYwaHR0cDovL2NybC5kaXNhLm1pbC9jcmwvRE9E
# SURDQV81OV9OQ09ERVNJR04uY3JsMA4GA1UdDwEB/wQEAwIHgDAWBgNVHSAEDzAN
# MAsGCWCGSAFlAgELKjAdBgNVHQ4EFgQUVusXc6nN92xmQ3XNN+/76hosJFEwZQYI
# KwYBBQUHAQEEWTBXMDMGCCsGAQUFBzAChidodHRwOi8vY3JsLmRpc2EubWlsL3Np
# Z24vRE9ESURDQV81OS5jZXIwIAYIKwYBBQUHMAGGFGh0dHA6Ly9vY3NwLmRpc2Eu
# bWlsMB8GA1UdJQQYMBYGCisGAQQBgjcKAw0GCCsGAQUFBwMDMA0GCSqGSIb3DQEB
# CwUAA4IBAQBCSdogBcOfKqyGbKG45lLicG1LJ2dmt0Hwl7QkKrZNNEDh2Q2+uzB7
# SRmADtSOVjVf/0+1B4jBoyty90WL52rMPVttb8tfm0f/Wgw6niz5WQZ+XjFRTFQa
# M7pBNU54vI3bH4MFBTXUOEoSr0FELFQaByUWfWKrGLnEqYtpDde5FZEYKRv6td6N
# ZH7m5JOiCfEK6gun3luq7ckvx5zIXjr5VKhp+S0Aai3ZR/eqbBZ0wcUF3DOYlqVs
# LiPT0jWompwkfSnxa3fjNHD+FKvd/7EMQM/wY0vZyIObto3QYrLru6COAyY9cC/s
# Dj+R4K4392w1LWdo3KrNzkCFMAX6j/bWMIIEuTCCA6GgAwIBAgICAwUwDQYJKoZI
# hvcNAQELBQAwWzELMAkGA1UEBhMCVVMxGDAWBgNVBAoTD1UuUy4gR292ZXJubWVu
# dDEMMAoGA1UECxMDRG9EMQwwCgYDVQQLEwNQS0kxFjAUBgNVBAMTDURvRCBSb290
# IENBIDMwHhcNMTkwNDAyMTMzODMyWhcNMjUwNDAyMTMzODMyWjBaMQswCQYDVQQG
# EwJVUzEYMBYGA1UEChMPVS5TLiBHb3Zlcm5tZW50MQwwCgYDVQQLEwNEb0QxDDAK
# BgNVBAsTA1BLSTEVMBMGA1UEAxMMRE9EIElEIENBLTU5MIIBIjANBgkqhkiG9w0B
# AQEFAAOCAQ8AMIIBCgKCAQEAzBeEny3BCletEU01Vz8kRy8cD2OWvbtwMTyunFaS
# hu+kIk6g5VRsnvbhK3Ho61MBmlGJc1pLSONGBhpbpyr2l2eONAzmi8c8917V7Bpn
# JZvYj66qGRmY4FXX6UZQ6GdALKKedJKrMQfU8LmcBJ/LGcJ0F4635QocGs9UoFS5
# hLgVyflDTC/6x8EPbi/JXk6N6iod5JIAxNp6qW/5ZBvhiuMo19oYX5LuUy9B6W7c
# A0cRygvYcwKKYK+cIdBoxAj34yw2HJI8RQt490QPGClZhz0WYFuNSnUJgTHsdh2V
# NEn2AEe2zYhPFNlCu3gSmOSp5vxpZWbMIQ8cTv4pRWG47wIDAQABo4IBhjCCAYIw
# HwYDVR0jBBgwFoAUbIqUonexgHIdgXoWqvLczmbuRcAwHQYDVR0OBBYEFHUJphUT
# roc8+nOUAPLw9Xm5snIUMA4GA1UdDwEB/wQEAwIBhjBnBgNVHSAEYDBeMAsGCWCG
# SAFlAgELJDALBglghkgBZQIBCycwCwYJYIZIAWUCAQsqMAsGCWCGSAFlAgELOzAM
# BgpghkgBZQMCAQMNMAwGCmCGSAFlAwIBAxEwDAYKYIZIAWUDAgEDJzASBgNVHRMB
# Af8ECDAGAQH/AgEAMAwGA1UdJAQFMAOAAQAwNwYDVR0fBDAwLjAsoCqgKIYmaHR0
# cDovL2NybC5kaXNhLm1pbC9jcmwvRE9EUk9PVENBMy5jcmwwbAYIKwYBBQUHAQEE
# YDBeMDoGCCsGAQUFBzAChi5odHRwOi8vY3JsLmRpc2EubWlsL2lzc3VlZHRvL0RP
# RFJPT1RDQTNfSVQucDdjMCAGCCsGAQUFBzABhhRodHRwOi8vb2NzcC5kaXNhLm1p
# bDANBgkqhkiG9w0BAQsFAAOCAQEAOQUb0g6nPvWoc1cJ5gkhxSyGA3bQKu8HnKbg
# +vvMpMFEwo2p30RdYHGvA/3GGtrlhxBqAcOqeYF5TcXZ4+Fa9CbKE/AgloCuTjEY
# t2/0iaSvdw7y9Vqk7jyT9H1lFIAQHHN3TEwN1nr7HEWVkkg41GXFxU01UHfR7vgq
# TTz+3zZL2iCqADVDspna0W5pF6yMla6gn4u0TmWu2SeqBpctvdcfSFXkzQBZGT1a
# D/W2Fv00KwoQgB2l2eiVk56mEjN/MeI5Kp4n57mpREsHutP4XnLQ01ZN2qgn+844
# JRrzPQ0pazPYiSl4PeI2FUItErA6Ob/DPF0ba2y3k4dFkUTApzGCAhQwggIQAgEB
# MGIwWjELMAkGA1UEBhMCVVMxGDAWBgNVBAoTD1UuUy4gR292ZXJubWVudDEMMAoG
# A1UECxMDRG9EMQwwCgYDVQQLEwNQS0kxFTATBgNVBAMTDERPRCBJRCBDQS01OQIE
# AwIE1zANBglghkgBZQMEAgEFAKCBhDAYBgorBgEEAYI3AgEMMQowCKACgAChAoAA
# MBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQBgjcCAQsxDjAMBgor
# BgEEAYI3AgEVMC8GCSqGSIb3DQEJBDEiBCDMnj8WjIAAZ5PdB7FWEiPC6r4tyRf0
# PncW4HpEY020uDANBgkqhkiG9w0BAQEFAASCAQC9f4u+LNFvqLRuw6rEqhnaU3lp
# b0Rjk3p/pgZYX8KNAF4yutsQd6RsrEqZl0gVSbqZ5GQPKCvIJQdPJB2Lr+cXwpy6
# 9lfFfYfmRMOPRvrmnZC+nviU5xlItinspI5eF6pbep3KB8yctejLm1uFsd4OKCeX
# iGIHJsyoTHdAsC1lDD9FRdz1LvvG2IFnPRk5fiOjQDUVGou7Bd83wxIY/IUwpJms
# jpm+ozkwWTmG0m0oPokOrIX6769MNdtGUOGn6qVDPOkXwpOhT5nW1KL3wvoT+dUu
# TSEN2gPJ8t+CaCNFupy4/sT4Nj+VJaFNbJSsWxccP8NnSvXP5dAwJH5GX4Ed
# SIG # End signature block
