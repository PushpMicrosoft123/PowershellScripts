<#
.SYNOPSIS
    Core Script that updates json objects based on user input.
.DESCRIPTION
   Script loads source values to update the target values.

.NOTES
    Version        : 1.0
    File Name      : mapping.psm1
    Author         : Pushpdeep Gupta (pusgup@microsoft.com)
    Creation Date  : March 22, 2021
    Prerequisites  : PowerShell V7.x
    Purpose/Change : Initial script development
#>
function GetorSetPropertyValues {
    param (
        $item,
        $sv,
        $copyValue,
        $property,
        $fr
    ) 
 $sp = $item
 [bool]$isPrevArray = $false
 $count = 0
 $spLst = $property.Split(".")
 #[string]$sv = ""
 foreach($splstitem in $spLst){   
     $prop = $splstitem.Replace("[]","")        
     if(($spLst.Length-1) -eq $count){
             if($copyValue){
                 if($isPrevArray){                    
                     if(($null -ne $sv) -and ($sv.GetType().Name -eq "Object[]")) {
                        $mappingCount = 0
                        foreach ($spItem in $sp) {
                            if($spItem.PSobject.Properties.Name-notcontains $prop){
                                $spItem | Add-Member -MemberType NoteProperty -Name $prop -Value $null
                                #$spItem.$prop = $null
                            }
                            if($fr){
                                $spItem.$prop = $sv[$mappingCount]
                            }
                            else{
                                $spItem.$prop = [string]::IsNullOrEmpty($spItem.$prop) ? $sv[$mappingCount] : $spItem.$prop
                            }
                            $mappingCount++
                        }
                     }
                     else {
                        foreach ($spI in $sp) {
                            if($null -ne $spI){
                                #UpdateValue -f $fr -sourceObject $spI -property $prop -value $sv
                                #$spI.$prop = $sv
                                if($spI.PSobject.Properties.Name -notcontains $prop){
                                    $spI | Add-Member -MemberType NoteProperty -Name $prop -Value $null
                                    #$spI.$prop = $null
                                }

                                if($fr){
                                    $spI.$prop = $sv
                                }
                                else{
                                    $spI.$prop = [string]::IsNullOrEmpty($spI.$prop) ? $sv : $spI.$prop
                                }
                            }                            
                        }
                     }                                             
                 }
                 else{
                     #$sp.$prop = $sv
                     if($sp.PSobject.Properties.Name -notcontains $prop){
                        $sp | Add-Member -MemberType NoteProperty -Name $prop -Value $null
                        #$sp.$prop = $null
                    }
                     if($fr){
                        $sp.$prop = $sv
                    }
                    else{
                        $sp.$prop = [string]::IsNullOrEmpty($sp.$prop) ? $sv : $sp.$prop
                    }
                     #UpdateValue -f $fr -sourceObject $sp -property $prop -value $sv
                 }
             }
             else{
                 $sv = $sp.$prop
             }
         break;
     }

     if(!$isPrevArray){
         $sp = $sp.$prop
         $count++
     }
     else {
         $mapping = 0
         $temp = @()
         
         foreach($spitem in $sp){
             if($mapping -lt $sp.Length){
                if($spitem.$prop){
                    $temp += $spitem.$prop
                }
                # else{
                #    if (!$splstitem.Prop -contains ) {
                #        $spitem | Add-Member -MemberType NoteProperty -Name $prop -Value $null
                #        $temp += $spItem.$prop
                #    }    
                # }
                $mapping++
             }                            
         }
         $sp = $temp
         $isPrevArray = $true
         $count++
     }

     if($splstitem.Contains("[]") -and !$isPrevArray){
         $isPrevArray = $true
     }
 }
   return $sv
}