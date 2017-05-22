Set-StrictMode -Version Latest
$RootModuleDir = Split-Path $MyInvocation.MyCommand.Path -Parent
$a = Resolve-Path "$RootModuleDir\.."
$a
$Module = "$a\EventTrace.psd1"
Import-Module $Module -Force -ErrorAction Stop
$ErrorActionPreference = 'Stop'

