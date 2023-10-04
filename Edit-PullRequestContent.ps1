Param(
    [string]$destinationBranch,
    [string[]]$branches,
    [string]$title,
    [string]$description
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = "Pull Request Content"
$form.Size = New-Object System.Drawing.Size(375,350)
$form.StartPosition = 'CenterScreen'

$labelDestinationBranch = New-Object System.Windows.Forms.Label
$labelDestinationBranch.Location = New-Object System.Drawing.Point(10,20)
$labelDestinationBranch.Size = New-Object System.Drawing.Size(280,20)
$labelDestinationBranch.Text = "Target branch:     $destinationBranch"
$form.Controls.Add($labelDestinationBranch)

$labelBranchSelect = New-Object System.Windows.Forms.Label
$labelBranchSelect.Location = New-Object System.Drawing.Point(10,45)
$labelBranchSelect.Size = New-Object System.Drawing.Size(85,20)
$labelBranchSelect.Text = "Source Branch:"
$form.Controls.Add($labelBranchSelect)

$listBranchSelect = New-Object System.Windows.Forms.ComboBox
$listBranchSelect.Location = New-Object System.Drawing.Point(100,45)
$listBranchSelect.Size = New-Object System.Drawing.Size(120,20)
$listBranchSelect.Height = 80
[void] $listBranchSelect.Items.AddRange($branches)
$listBranchSelect.SelectedIndex = 0
$form.Controls.Add($listBranchSelect)

$labelTitle = New-Object System.Windows.Forms.Label
$labelTitle.Location = New-Object System.Drawing.Point(10,70)
$labelTitle.Size = New-Object System.Drawing.Size(40,20)
$labelTitle.Text = "Title:"
$form.Controls.Add($labelTitle)

$textBoxTitle = New-Object System.Windows.Forms.TextBox
$textBoxTitle.Location = New-Object System.Drawing.Point(100,70)
$textBoxTitle.Size = New-Object System.Drawing.Size(250,60)
$textBoxTitle.Multiline = $true
$textBoxTitle.Text = $title
$form.Controls.Add($textBoxTitle)

$labelDescription = New-Object System.Windows.Forms.Label
$labelDescription.Location = New-Object System.Drawing.Point(10,145)
$labelDescription.Size = New-Object System.Drawing.Size(75,30)
$labelDescription.Text = "Description:"
$form.Controls.Add($labelDescription)

$textBoxDescription = New-Object System.Windows.Forms.TextBox
$textBoxDescription.Location = New-Object System.Drawing.Point(100,145)
$textBoxDescription.Size = New-Object System.Drawing.Size(250,110)
$textBoxDescription.Multiline = $true
$textBoxDescription.ScrollBars = 3
$textBoxDescription.AcceptsReturn = $True
$textBoxDescription.AcceptsTab = $True
$textBoxDescription.WordWrap = $True
$textBoxDescription.Text = $description
$form.Controls.Add($textBoxDescription)

$okButton = New-Object System.Windows.Forms.Button
$okButton.Location = New-Object System.Drawing.Point(100,275)
$okButton.Size = New-Object System.Drawing.Size(75,23)
$okButton.Text = 'OK'
$okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $okButton
$form.Controls.Add($okButton)

$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Location = New-Object System.Drawing.Point(173,275)
$cancelButton.Size = New-Object System.Drawing.Size(75,23)
$cancelButton.Text = 'Cancel'
$cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.CancelButton = $cancelButton
$form.Controls.Add($cancelButton)

$form.Topmost = $true

$result = $form.ShowDialog()

if ($result -eq [System.Windows.Forms.DialogResult]::OK)
{
    $pullRequestData = [PSCustomObject]@{
        SourceBranch    = $listBranchSelect.SelectedItem
        Title           = $textBoxTitle.Text
        Description     = $textBoxDescription.Text
    }
    return $pullRequestData
}