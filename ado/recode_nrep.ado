*! version 1.1.1
*! recode_nrep.ado
*! Author: Ashiqur Rahman
*! Description: Recode open-ended "other" responses into new or existing codes

cap program drop recode_nrep
program define recode_nrep, rclass
    version 17.0
    syntax varlist(min=3 max=3)

    local mainvar : word 1 of `varlist'
    local splitvar : word 2 of `varlist'
    local othvar : word 3 of `varlist'

    display as result "Main var: `mainvar'"
    display as result "Split var (others dummy): `splitvar'"
    display as result "Open-ended var: `othvar'"

    * --- Check variables exist ---
    foreach v in `mainvar' `splitvar' `othvar' {
        capture confirm variable `v'
        if _rc {
            display as error "Variable `v' not found."
            exit 198
        }
    }

    * --- Detect others code from splitvar name ---
    local last_us_pos = strpos(reverse("`splitvar'"), "_")
    if `last_us_pos' == 0 {
        display as error "Splitvar name missing underscore (_) for code extraction."
        exit 198
    }
    local last_us_split = length("`splitvar'") - `last_us_pos' + 1
    local others_code_raw = substr("`splitvar'", `last_us_split' + 1, .)
    local others_code = regexr("`others_code_raw'", "^_+", "")
    local others_code = trim("`others_code'")
    display as result "Detected others code: `others_code'"

    * --- Collect frequent open-ended responses ---
    preserve
        keep if !missing(`othvar') & trim(`othvar') != ""
        local total = _N
        if `total' == 0 {
            display as error "No non-empty observations in `othvar'. Exiting."
            restore
            exit 198
        }
        contract `othvar', freq(count)
        gen double percent = 100 * count / `total'
        keep if percent >= 10
        if _N == 0 {
            display as result "No open-ended categories >= 10% frequency. Nothing to recode."
            restore
            exit 0
        }
        list `othvar' count percent, noobs
        quietly levelsof `othvar', local(othlist)
    restore

    * --- Find existing dummy variables ---
    ds `mainvar'_*
    local varsuffixes "`r(varlist)'"

    local maxcode = 1000
    foreach v of local varsuffixes {
        if regexm("`v'", "`mainvar'_([0-9]+)$") {
            local num = real(regexs(1))
            if `num' > `maxcode' local maxcode = `num'
        }
    }

    * --- Loop over open-ended responses ---
    foreach val of local othlist {

        * Step A: check if `val` matches any existing dummy label
        local matchcode ""
        local matchvar ""
        foreach v of local varsuffixes {
            local vlab : variable label `v'
            if trim("`vlab'") == trim("`val'") {
                if regexm("`v'", "`mainvar'_([0-9]+)$") {
                    local matchcode = regexs(1)
                    local matchvar = "`v'"
                }
            }
        }

        if "`matchcode'" != "" {
            * --- Case 1: Matched existing split ---
            display as result "Matched `val' to existing code `matchcode'. Re-coding into main variable."

            * Replace in main variable (swap `others_code` with `matchcode`)
            replace `mainvar' = trim( ///
                subinstr(" " + `mainvar' + " ", " `others_code' ", " `matchcode' ", .) ///
            ) if strpos(" " + `mainvar' + " ", " `others_code' ") > 0 & trim(`othvar') == "`val'"

            * Clear the others dummy
            replace `splitvar' = 0 if trim(`othvar') == "`val'"

            * Set the matched dummy to 1
            replace `matchvar' = 1 if trim(`othvar') == "`val'"

            * Zero out any others dummy with same code suffix
            foreach v of local varsuffixes {
                if regexm("`v'", "`mainvar'_`others_code'$") {
                    replace `v' = 0 if trim(`othvar') == "`val'"
                }
            }

            * Blank othvar
            replace `othvar' = "" if trim(`othvar') == "`val'"

        }
        else {
            * --- Case 2: No match → create new code ---
            local ++maxcode
            local newvar = "`mainvar'_`maxcode'"

            quietly capture confirm variable `newvar'
            if _rc {
                gen byte `newvar' = .
            }
            else {
                replace `newvar' = .
            }

            label var `newvar' "`val'"

            replace `newvar' = 1 if trim(`othvar') == "`val'"

            * Force zero if mainvar is non-empty but this newvar is still missing
            replace `newvar' = 0 if trim(`mainvar') != "" & `newvar' == .

            * Place newvar immediately after splitvar
            order `newvar', after(`splitvar')

            replace `splitvar' = 0 if trim(`othvar') == "`val'"

            foreach v of local varsuffixes {
                if regexm("`v'", "`mainvar'_`others_code'$") {
                    replace `v' = 0 if trim(`othvar') == "`val'"
                }
            }

            replace `mainvar' = trim( ///
                subinstr(" " + `mainvar' + " ", " `others_code' ", " `maxcode' ", .) ///
            ) if strpos(" " + `mainvar' + " ", " `others_code' ") > 0 & trim(`othvar') == "`val'"

            replace `othvar' = "" if trim(`othvar') == "`val'"

            display as result "Created `newvar' for value: `val' (code `maxcode')"
        }
    }

    display as result "Done. New codes started at 1001 and up (if any were added)."
end
