
function ScriptBlockEval($item) {
  if ($null -ne $item) {
    if ($item -Is [ScriptBlock]) {
      return &$item
    }
    return $item
  }
  return $null
}

function Invoke-TernaryNullCoalescing {
  [Alias("?:")]
  Param()

  begin {
  }
  
  process {
    if ($args) {
      #ternary
      if ($p = [array]::IndexOf($args, '?') + 1) {
        if (ScriptBlockEval($args[0])) {
          return ScriptBlockEval($args[$p])
        }
        return ScriptBlockEval($args[([array]::IndexOf($args, ':', $p)) + 1])
      }

      #null coalescing
      if ($p = ([array]::IndexOf($args, '??', $p) + 1)) {
        if ($result = ScriptBlockEval($args[0])) {
          return $result
        }
        return ScriptBlockEval($args[$p])
      }

      return ScriptBlockEval($args[0])
    }
    return $null
  }
  
  end {
  }
}
