cls

function decrypt($s) { [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($s)) }

$Username = read-host -Prompt 'user'
$Password = read-host -AsSecureString 'password'

$LoginURL = 'https://login.1c.ru/login'
$ContentURL = 'https://releases.1c.ru/total'

$website = wget -Uri $LoginURL -SessionVariable WebSession
$form = $website.forms[0]
$form.Fields.username = $Username
$form.Fields.password = decrypt $Password
wget -Uri $LoginURL -WebSession $WebSession -Body $form.Fields -Method Post | out-null

$data = wget -uri $ContentURL -WebSession $WebSession

function versions($ref) {
    ((wget -uri "https://releases.1c.ru$($ref)" -WebSession $WebSession).Links |
    select innerText, href | ? { $_.href -cmatch '^/version' }).href | % {'https://releases.1c.ru' + $_}
}

$list = @()

$data.Links | ? { $_.href -cmatch '^/project/'} |
select innerText, href | % {
        $obj = @{}
        $obj.id = $_.innerText
        $obj.ref = "https://releases.1c.ru$($_.href)"     
        $obj.ver = versions $_.href
        $list += $obj
    }

$list | ConvertTo-Json -Depth 3 | Out-File releases.json -Encoding 'utf8'
