# Deobfuscated hAUjZrJo.ps1

#
# === Assembly Loading ===
#
Add-Type -AssemblyName System.Security
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

#
# === Payload Selection Logic ===
#

# 1) Always compute this once from obfuscated math/string ops:
$computedKey = 14550  # from Branch 1 evaluation

# Branch 1: when computedKey == 14550
if ($computedKey -eq 14550) {

    # Build payload string in three steps
    $payloadBase      = "v3rKuNIeGCJASR"
    $payloadExtended  = $payloadBase + "rnUJnBKoOwo9xcGOM"
    $payloadFull      = $payloadExtended + "lPsIgdlEPVxLSOzoWWu81htWy1oj"

    # Hand off $payloadFull to the invoker...
}


# Branch 2: next elseif
elseif ($computedKey -eq <BRANCH2_KEY>) {

    # Mode flag
    $flagMode = 5707

    # Sum of constants
    $sumA = 5564
    $sumB = 11131

    # Extracted integer from split:
    $extractedValue = [int](
        "<LONG_LITERAL_STRING_HERE>" -split "BYyaYgFEBHlBPMgXTMeri0kEv"
    )[3]

    # Final numeric parameter
    $finalParam = $sumB + $extractedValue + 2717 + 7959 - 36845

    # These values configure Branch 2 payload...
}


# Branch 3: the next elseif
elseif ($computedKey -eq "<BRANCH3_KEY>") {

    # 1) Pick a character from a template
    $template1    = "<LONG_LITERAL1_HERE>"
    $payloadCharA = $template1[3]

    # 2) Numeric offset
    $offset       = -7965 - 1338 + 3408 + 4806 + 2072 - 8860  # = -7877
    $char2        = "<LONG_LITERAL2_HERE>"[2]
    $payloadNum   = $char2 - $offset

    # 3) String fragment join
    $strFrag     = "7VB57oGPYytUQDtmsqcP"
    $payloadStr  = $payloadNum + $strFrag

    # 4) Append literal
    $payloadFull = $payloadStr + "zuRRPlGl0PP8o7HU"

    # 5) Build action string
    $actionTemplate = "<LONG_LITERAL3_HERE>"
    $payloadAction  = $actionTemplate.
        Remove(17,28).
        Remove(6,21).
        Insert(3,"NgFgpGGIpFU")

    # 6) Final constant
    $finalCode = "MDcj0KSpGDWd26"
}

# ... (remaining branches would follow)