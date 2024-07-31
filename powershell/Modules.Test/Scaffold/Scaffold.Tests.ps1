BeforeDiscovery {
    Import-Module "$PSScriptRoot/../Assertions.psm1" -DisableNameChecking
    New-Item (Join-Path $PSScriptRoot '..' '.scaffolds') -ItemType Directory -ErrorAction Ignore -Force
}

BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../Modules/Scaffold/Scaffold.psd1')
    $Env:SCAFFOLD_HOME = Join-Path $PSScriptRoot '..' '.scaffolds'
    Copy-Item (Join-Path $PSScriptRoot '../' '../' '../' 'scaffolds' '*.scaffold') -Destination (Join-Path $PSScriptRoot '../' '.scaffolds') -Force
}

Describe 'Get-Scaffolds' {

    It 'Given no values, it lists all scaffolds' {
        Get-Scaffolds | Should -Not -BeNullOrEmpty
    }

    It 'Given value, it returns' {
        $Scaffolds = Get-Scaffolds

        $Scaffolds | Should -HaveCount 1

        $Scaffolds.Scaffold[0] | `
            Should -BeScaffoldItem -PSTypeName 'Scaffold.Container' -Name 'imports' -FullName '.dev', '.fthtml', 'imports'

        $Scaffolds.Scaffold[1] | `
            Should -BeScaffoldItem -PSTypeName 'Scaffold.Container' -Name 'json' -FullName '.dev', '.fthtml', 'json'

        $Scaffolds.Scaffold[2] | `
            Should -BeScaffoldItem -PSTypeName 'Scaffold.Container' -Name 'a' -FullName 'www', 'a'

        $Scaffolds.Scaffold[3] | `
            Should -BeScaffoldItem -PSTypeName 'Scaffold.Container' -Name 'css' -FullName 'www', 'css'

        $Scaffolds.Scaffold[4] | `
            Should -BeScaffoldItem -PSTypeName 'Scaffold.Container' -Name 'js' -FullName 'www', 'js'

        $Scaffolds.Scaffold[5] | `
            Should -BeScaffoldItem -PSTypeName 'Scaffold.Leaf' -Name 'index.fthtml' -FullName '.dev', '.fthtml', 'index.fthtml' `
            -Contents @'
doctype "html"
html (lang=en) {
    head
    {
        meta (charset=utf-8)
        meta (content="IE=edge" http-equiv=X-UA-Compatible)
        meta (content="width=device-width, initial-scale=1" name=viewport)
        title "{{Page Title}}"
    }
    body
}
'@
        $Scaffolds.Scaffold[6] | `
            Should -BeScaffoldItem -PSTypeName 'Scaffold.Leaf' -Name '.gitignore' -FullName '.gitignore' `
            -Contents @'
node_modules/
.fthtml/
dist/
*.vsix
'@

        $Scaffolds.Scaffold[7] | `
            Should -BeScaffoldItem -PSTypeName 'Scaffold.Leaf' -Name 'fthtmlconfig.json' -FullName 'fthtmlconfig.json' `
            -Contents  @'
{
  "rootDir" : ".fthtml",
  "exportDir" :"www",
  "jsonDir" : ".fthtml/json",
  "keepTreeStructure": true
}
'@

    }

}

Describe 'SaveAs-Scaffold' {

    AfterEach {
        Remove-Item $Env:SCAFFOLD_HOME -Recurse -Force -Exclude fthtml-base.scaffold
    }

    It 'Given directory, it should save' {
        SaveAs-Scaffold -Directory (Join-Path $PSScriptRoot './.scaffolds/ts - commonjs') `
            -Name ts:commonjs `
            -About 'TypeScript scaffold for commonjs'

        $Scaffold = Get-Scaffolds | ? { $_.Name -eq 'ts:commonjs' }
        $Scaffold | Should -Not -BeNullOrEmpty

        $Scaffold.Name | Should -BeExactly 'ts:commonjs'
        $Scaffold.About | Should -BeExactly 'TypeScript scaffold for commonjs'
        $Scaffold.Scaffold | Should -Not -BeNullOrEmpty
    }

}

Describe 'Mount-Scaffold' {

    AfterEach {
        Remove-Item $Env:SCAFFOLD_HOME -Recurse -Force -Exclude fthtml-base.scaffold
        Get-ChildItem $PSScriptRoot -Force -Exclude .scaffolds, Scaffold.Tests.ps1 | Remove-Item -Force -Recurse -ErrorAction Ignore
    }

    It 'Given no destination, it should mount to pwd' {
        SaveAs-Scaffold -Directory (Join-Path $PSScriptRoot './.scaffolds/ts - commonjs') `
            -Name ts:commonjs `
            -About 'TypeScript scaffold for commonjs'

        $Location = Get-Location
        Set-Location $PSScriptRoot

        Mount-Scaffold ts:commonjs

        "$PSScriptRoot/lib/index.ts" | Should -Exist
        "$PSScriptRoot/tsconfig.json" | Should -Exist
        "$PSScriptRoot/.gitignore" | Should -Exist

        Set-Location $Location
    }

    It 'Given destination, it should mount to destination' {
        SaveAs-Scaffold -Directory (Join-Path $PSScriptRoot './.scaffolds/ts - commonjs') `
            -Name ts:commonjs `
            -About 'TypeScript scaffold for commonjs'

        Mount-Scaffold ts:commonjs -Destination $PSScriptRoot

        "$PSScriptRoot/lib/index.ts" | Should -Exist
        "$PSScriptRoot/tsconfig.json" | Should -Exist
        "$PSScriptRoot/.gitignore" | Should -Exist
    }

    It 'Given destination with template vars, it should mount interactively' {
        InModuleScope Scaffold {
            Mock Read-Host { 'My First Scaffold Title' }

            Mount-Scaffold fthtml:base -Destination $PSScriptRoot -Interactive

            "$PSScriptRoot/.dev/.fthtml/imports" | Should -Exist
            "$PSScriptRoot/.dev/.fthtml/json" | Should -Exist
            "$PSScriptRoot/.dev/.fthtml/index.fthtml" | Should -Exist
            "$PSScriptRoot/.gitignore" | Should -Exist
            "$PSScriptRoot/fthtmlconfig.json" | Should -Exist

            Get-Content "$PSScriptRoot/.dev/.fthtml/index.fthtml" -Raw | Should -BeExactly @'
doctype "html"
html (lang=en) {
    head
    {
        meta (charset=utf-8)
        meta (content="IE=edge" http-equiv=X-UA-Compatible)
        meta (content="width=device-width, initial-scale=1" name=viewport)
        title "My First Scaffold Title"
    }
    body
}
'@.Trim()
        }
    }
}