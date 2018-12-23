function main() {

    Import-Module "$PsScriptRoot\..\modules\SortingAlgorithms\SortingAlgorithms"

    $data = 0..255
    <#
    $data = @('209','115','241','77','189','109','97','69','247','212','45','6','39','200','242','211','248','178','134','34','74','11','245','117','123','67','240',
              '174','42','65','22','130','135','225','141','68','232','102','61','172','187','58','226','255','137','96','160','218','238','199','162','63','214','30',
              '127','25','50','161','204','131','149','184','203','51','113','208','57','49','1','158','140','10','133','89','23','176','143','147','3','251','254','171',
              '120','128','233','256','79','198','12','85','154','227','53','2','33','223','5','151','235','99','118','66','116','145','222','201','93','220','52','112',
              '236','114','26','126','183','15','28','82','94','72','29','169','237','215','170','157','107','207','193','100','75','41','166','159','224','56','111','228',
              '182','62','152','21','83','175','196','27','217','202','48','213','206','95','46','124','229','167','9','185','190','250','186','194','164','8','92','80',
              '44','231','81','219','234','188','54','16','70','84','165','181','19','35','73','179','153','18','221','244','216','163','71','239','24','64','7','87','103',
              '230','121','205','252','40','76','59','78','31','101','108','155','17','139','129','47','37','60','55','253','146','132','144','246','98','150','142','91','192',
              '195','4','106','13','38','14','20','36','136','90','105','43','156','104','180','88','138','110','122','191','197','243','86','249','125','173','32','177','168',
              '119','148','210')
    #>
    $hash = Get-PearsonHash "This was a triumph" $data
    $hash
}

<#
.Synopsis
   Short description
.DESCRIPTION
   RFC3074
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Get-PearsonHash
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   Position=0)]
        $Message,

        # Psuedo random shuffled list of range 0..255
        [Parameter(Mandatory=$True,
                   Position=1)]
        $Table,

        [Parameter(Mandatory=$False,
                   Position=2)]
        [int] $Bit_length = 8
    )

    Begin
    {
        $Index = $Message.length % 256
        $Bytes = [System.Text.Encoding]::Unicode.GetBytes($Message)
        $Hash  = ""
        $Collection = @()    # Copy of the input array.
    }
    Process
    {
        # This part generate multiple
        for ($j = 0; $j -lt $Bit_length; ++$j) {

            # This part produces an 8-bit (byte) hash.
            foreach ($Byte in $Bytes) {
                $Index = $Table[($Index + $Byte) % 256]
            }
            $Hash += [Convert]::ToString($Index, 16)
        }
    }
    End
    {   
        # Convert to Hex
        return $Hash
    }
}

main