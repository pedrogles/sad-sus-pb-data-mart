# SAD SUS PB F4-P5 — automated COM UI proof on a TEMP QVW, not a physical KPI approval.
[CmdletBinding()]
param(
 [Parameter(Mandatory=$true)][string]$SourceQvw,
 [Parameter(Mandatory=$true)][string]$F4Dir,
 [string]$Root=(Get-Location).Path
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$prepare=Join-Path ([IO.Path]::GetFullPath($Root)) 'tools\preparar_f4_p5_ui_guardas_qlik.ps1'
if(-not(Test-Path -LiteralPath $prepare -PathType Leaf)){throw 'PREPARE_SCRIPT_MISSING'}
$prep=@(& $prepare -SourceQvw $SourceQvw -F4Dir $F4Dir -Root $Root)
if($prep -notcontains 'FINAL_VERDICT=PREPARED_UI_COPY_NOT_EXECUTED'){throw 'PREPARE_FAILED'}
$match=@($prep|Where-Object{$_ -like 'TRIAL_DIR=*'})
if($match.Count -ne 1){throw 'PREPARE_TRIAL_DIR_NOT_FOUND'}
$trial=$match[0].Substring(10)
$copy=Join-Path $trial 'F4_P5_UI_GUARD_DISPOSABLE.qvw'
$folder=Join-Path $trial 'evidence'
New-Item -ItemType Directory -Path $folder -ErrorAction Stop | Out-Null
$objects=New-Object System.Collections.ArrayList
$cases=New-Object System.Collections.ArrayList
$qv=$null;$doc=$null;$sheet=$null;$failure=$null;$didSave=$false
function Q([string]$expression){return [string]$script:doc.Evaluate($expression)}
function Expect([string]$label,[string]$expression,[string]$value){
 $actual=Q $expression
 if($actual -cne $value){throw ("MISMATCH_"+$label+"_WANT_"+$value+"_GOT_"+$actual)}
 Write-Output ("CHECK "+$label+"="+$actual)
}
function Position($o,[int]$left,[int]$top,[int]$width,[int]$height){
 $f=$o.GetFrameDef()
 $r=$f.Rect
 $r.Left=$left;$r.Top=$top;$r.Width=$width;$r.Height=$height
 [void]$o.SetFrameDef($f)
}
function TextObj([string]$name,[string]$content,[string]$when,[int]$top){
 $o=$script:sheet.CreateTextObject()
 if($null -eq $o){throw "TEXT_CREATE_FAILED=$name"}
 $p=$o.GetProperties()
 $p.Layout.Text.v=$content
 if($when -eq ''){$p.Layout.Frame.Show.Always=$true}
 else{$p.Layout.Frame.Show.Always=$false;$p.Layout.Frame.Show.Expression.v=$when}
 [void]$o.SetProperties($p)
 Position $o 245 $top 875 58
 $back=$o.GetProperties()
 if([string]$back.Layout.Text.v -cne $content -or
    [bool]$back.Layout.Frame.Show.Always -ne ($when -eq '') -or
    ($when -ne '' -and [string]$back.Layout.Frame.Show.Expression.v -cne $when)){
    throw "PROPERTY_READBACK_FAILED=$name"
 }
 [void]$script:objects.Add([pscustomobject]@{name=$name;id=[string]$o.GetObjectID();text=$content;conditional=$when;readback='PASS_COM_ONLY'})
 Write-Output ("OBJECT=$name PROPERTY_READBACK=PASS_COM_ONLY")
}
function ListObj([string]$field,[int]$top){
 $o=$script:sheet.CreateListBox()
 if($null -eq $o){throw "LIST_CREATE_FAILED=$field"}
 $p=$o.GetProperties();$p.Def.Name=$field
 [void]$o.SetProperties($p)
 Position $o 12 $top 215 230
 if([string]$o.GetProperties().Def.Name -cne $field){throw "LIST_READBACK_FAILED=$field"}
 Write-Output ("LISTBOX=$field READBACK=PASS_COM_ONLY")
}
function Sel([string]$field,[string]$value){
 $f=$null
 try{
   $f=$script:doc.GetField($field)
   if($null -eq $f){throw "FIELD_ABSENT=$field"}
   [void]$f.Select($value)
 }finally{
   if($null -ne $f -and [Runtime.InteropServices.Marshal]::IsComObject($f)){
      [void][Runtime.InteropServices.Marshal]::ReleaseComObject($f)
   }
 }
}
function CheckScenario([string]$name,[string]$proc,[string]$serv,[string]$safe,[string]$bp,[string]$bs){
 Expect ($name+'_PROC') 'GetSelectedCount(F4_RD_PROC_REA)' $proc
 Expect ($name+'_SERV') 'GetSelectedCount(P6_SERV_DATASUS_6)' $serv
 Expect ($name+'_SAFE') 'If(GetSelectedCount(F4_RD_PROC_REA)=0,1,0)' $safe
 Expect ($name+'_B_REL') 'If(GetSelectedCount(F4_RD_PROC_REA)>0,1,0)' $bp
 Expect ($name+'_B_RES') 'If(GetSelectedCount(P6_SERV_DATASUS_6)>0,1,0)' $bs
 [void]$script:cases.Add([pscustomobject]@{
   name=$name;proc=$proc;service=$serv;safe=$safe;blockProcedure=$bp;blockService=$bs;
   popLines=(Q 'Count(P6_POP_ROW_DEBUG)');
   popLinesClearProcedure=(Q 'Count({$<F4_RD_PROC_REA=>} P6_POP_ROW_DEBUG)');
   screenshot='NOT_CAPTURED'
 })
 Write-Output ("SCENARIO=$name EXPRESSION_AND_SELECTION_CHECKS=PASS_COM_ONLY")
}
Add-Type -AssemblyName System.Drawing
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class SadQvScreen {
 [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left,Top,Right,Bottom; }
 [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
 [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr handle);
 [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr handle,out RECT value);
 [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr handle,out uint pid);
 [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr handle);
 [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr handle,int cmd);
}
'@
function Screenshot([string]$scenario){
 $matches=@(Get-Process | Where-Object{
     $_.MainWindowHandle -ne [IntPtr]::Zero -and
     $_.ProcessName -match '^(qv|qlikview)$' -and
     $_.MainWindowTitle -like '*F4_P5_UI_GUARD_DISPOSABLE*'
 })
 if($matches.Count -ne 1){throw ("QVW_WINDOW_NOT_UNIQUE="+$matches.Count)}
 $hwnd=$matches[0].MainWindowHandle
 if([SadQvScreen]::IsIconic($hwnd)){[void][SadQvScreen]::ShowWindow($hwnd,9)}
 [void][SadQvScreen]::SetForegroundWindow($hwnd)
 Start-Sleep -Milliseconds 650
 $front=[SadQvScreen]::GetForegroundWindow()
 $windowPid=[uint32]0
 [void][SadQvScreen]::GetWindowThreadProcessId($front,[ref]$windowPid)
 if($front -ne $hwnd -or $windowPid -ne [uint32]$matches[0].Id){
     throw 'FRONT_WINDOW_IS_NOT_TEST_QVW'
 }
 $rect=New-Object SadQvScreen+RECT
 if(-not [SadQvScreen]::GetWindowRect($hwnd,[ref]$rect)){throw 'GET_WINDOW_RECT_FAILED'}
 $w=$rect.Right-$rect.Left;$h=$rect.Bottom-$rect.Top
 if($w -lt 650 -or $h -lt 600 -or $w -gt 5000 -or $h -gt 3500){
    throw ('WINDOW_DIMENSIONS_UNEXPECTED_'+$w+'x'+$h)
 }
 $bmp=[System.Drawing.Bitmap]::new($w,$h)
 try{
   $graphics=[System.Drawing.Graphics]::FromImage($bmp)
   try{$graphics.CopyFromScreen($rect.Left,$rect.Top,0,0,([System.Drawing.Size]::new($w,$h)))}
   finally{$graphics.Dispose()}
   $file=Join-Path $script:folder ($scenario+'.png')
   $bmp.Save($file,[System.Drawing.Imaging.ImageFormat]::Png)
 }finally{$bmp.Dispose()}
 $script:cases[$script:cases.Count-1].screenshot=$file
 Write-Output ("SCREENSHOT=$file CAPTURED_NOT_VISUALLY_AUDITED=True")
}
try{
 foreach($s in $prep){Write-Output $s}
 $qv=New-Object -ComObject 'QlikTech.QlikView'
 $doc=$qv.OpenDoc($copy,'','')
 if($null -eq $doc){throw 'QVW_COM_OPEN_FAILED'}
 $sheet=$doc.ActiveSheet
 if($null -eq $sheet){throw 'ACTIVE_SHEET_ABSENT'}
 [void]$doc.ClearAll()
 Expect 'RD_BASE' 'Count(F4_RD_IDENT)' '566672'
 Expect 'POP_BASE' 'Count(P6_POP_ROW_DEBUG)' '669'
 ListObj 'F4_RD_PROC_REA' 142
 ListObj 'P6_SERV_DATASUS_6' 390
 TextObj 'HEADER' 'PROVA F4-P5 (TECNICA) - NENHUM KPI LIBERADO' '' 3
 TextObj 'SELECTION' '=GetFieldSelections(F4_RD_PROC_REA) & '' | '' & GetFieldSelections(P6_SERV_DATASUS_6)' '' 70
 TextObj 'B_REL_SAFE' 'B/REL: MARCADOR NEUTRO (NAO INDICADOR)' '=If(GetSelectedCount(F4_RD_PROC_REA)=0,1,0)' 140
 TextObj 'B_REL_WARN' 'B/REL: INDISPONIVEL SOB PROCEDIMENTO' '=If(GetSelectedCount(F4_RD_PROC_REA)>0,1,0)' 206
 TextObj 'I_LEI_WARN' 'I/LEI: EXIGE ISOLAMENTO COM AVISO, SEM KPI' '=If(GetSelectedCount(F4_RD_PROC_REA)>0,1,0)' 272
 TextObj 'I_LEI_DEBUG' '=Count(P6_POP_ROW_DEBUG) & '' (linhas) / limpa PROC: '' & Count({$<F4_RD_PROC_REA=>} P6_POP_ROW_DEBUG)' '=If(GetSelectedCount(F4_RD_PROC_REA)>0,1,0)' 338
 TextObj 'R_RES_WARN' 'R/RES: RECORTE SEPARADO NAO APROVADO' '=If(GetSelectedCount(F4_RD_PROC_REA)>0,1,0)' 404
 TextObj 'B_RES_WARN' 'B/RES: INDISPONIVEL SOB SERVICO' '=If(GetSelectedCount(P6_SERV_DATASUS_6)>0,1,0)' 470
 TextObj 'C_PENDING' 'C: TEMPO/TERRITORIO/POP/COBERTURA PENDENTES' '' 536
 [void]$doc.Save();$didSave=$true
 Write-Output 'QVW_SAVED_ONLY_IN_NEW_TEMP_COPY=True'
 CheckScenario 'S0_BASELINE' '0' '0' '1' '0' '0'
 Screenshot 'S0_BASELINE'
 Sel 'F4_RD_PROC_REA' '0201010038'
 CheckScenario 'S1_PROCEDURE' '1' '0' '0' '1' '0'
 Expect 'S1_CLEAR_PROCEDURE_POP_TECH' 'Count({$<F4_RD_PROC_REA=>} P6_POP_ROW_DEBUG)' '669'
 Screenshot 'S1_PROCEDURE'
 [void]$doc.ClearAll()
 CheckScenario 'S2_CLEAR' '0' '0' '1' '0' '0'
 Screenshot 'S2_CLEAR'
 Sel 'P6_SERV_DATASUS_6' '250750'
 CheckScenario 'S3_SERVICE' '0' '1' '1' '0' '1'
 Screenshot 'S3_SERVICE'
 [void]$doc.ClearAll()
 CheckScenario 'S4_RESTORE' '0' '0' '1' '0' '0'
 Screenshot 'S4_RESTORE'
 $h0=(Get-FileHash (Join-Path $folder 'S0_BASELINE.png') -Algorithm SHA256).Hash
 $h1=(Get-FileHash (Join-Path $folder 'S1_PROCEDURE.png') -Algorithm SHA256).Hash
 $h3=(Get-FileHash (Join-Path $folder 'S3_SERVICE.png') -Algorithm SHA256).Hash
 if($h0 -ceq $h1 -or $h0 -ceq $h3){throw 'SCREEN_CAPTURE_NO_PIXEL_TRANSITION'}
 Write-Output 'SCREEN_PIXELS_CHANGED_S0_TO_S1_AND_S3=True_NOT_VISUAL_SEMANTIC_PROOF'
}catch{
 $failure=$_.Exception.Message
 Write-Output ('GATE=FAIL_CLOSED_'+$failure)
}finally{
 if($null -ne $doc){try{[void]$doc.CloseDoc()}catch{Write-Output ('CLOSE_WARNING='+$_.Exception.Message)}}
 if($null -ne $qv -and [Runtime.InteropServices.Marshal]::IsComObject($qv)){
   [void][Runtime.InteropServices.Marshal]::ReleaseComObject($qv)
 }
 $out=[pscustomobject]@{
  trial=$copy;src=$SourceQvw;error=$failure;com_saved=$didSave;
  objects=@($objects.ToArray());scenarios=@($cases.ToArray());
  certification='NOT_UI_VISUAL_AUDIT_NOT_P5_PHYSICAL_APPROVAL'
 }
 $out|ConvertTo-Json -Depth 8|Set-Content -LiteralPath (Join-Path $folder 'audit.json') -Encoding UTF8
 if($didSave){
   try{
     $verified=@(& $prepare -TrialDir $trial)
     foreach($s in $verified){Write-Output $s}
     if($verified -notcontains 'FINAL_VERDICT=PASS_ARTIFACT_INTEGRITY_ONLY_UI_SCREENSHOTS_PENDING'){
       if(-not $failure){$failure='ARTIFACT_SHA256_VERIFICATION_FAILED'}
     }
   }catch{if(-not $failure){$failure='ARTIFACT_VERIFICATION_ERROR_'+$_.Exception.Message}}
 }
 try{
   $zip=Join-Path $trial 'F4_P5_UI_EVIDENCE.zip'
   Compress-Archive -Path (Join-Path $folder '*') -DestinationPath $zip -ErrorAction Stop
   Write-Output ('EVIDENCE_ZIP='+$zip)
   Write-Output ('EVIDENCE_ZIP_SHA256='+(Get-FileHash $zip -Algorithm SHA256).Hash)
 }catch{if(-not $failure){$failure='EVIDENCE_ZIP_ERROR_'+$_.Exception.Message}}
 Write-Output 'RELOAD_EXECUTED=False QVD_WRITES=0'
 Write-Output 'F4_P5_PHYSICAL_FILTERS=NOT_TESTED'
 Write-Output 'UI_SCREENSHOTS=NOT_AUTOMATICALLY_VISUALLY_AUDITED'
}
if($failure){Write-Output ('FINAL_VERDICT=FAIL_CLOSED_'+$failure);exit 1}
Write-Output 'FINAL_VERDICT=PASS_COM_OBJECT_CONFIG_AND_SCREENSHOTS_VISUAL_AUDIT_PENDING'
