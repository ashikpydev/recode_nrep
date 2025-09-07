*! version 1.3.1
*! recode_nrep.ado
*! Author: Ashiqur Rahman
*! Description: Recode open-ended "other" responses into new or existing codes
*! Notes: First try merging back into existing codes (all responses),
*!        then create new codes only for frequent categories (>=10%).

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

    * --- Collect ALL non-empty open-ended responses ---
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
        quietly levelsof `othvar', local(all_othlist)
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

    * --- STEP A: Try merging ALL responses into existing codes ---
    foreach val of local all_othlist {
        local matchcode ""
        local matchvar ""
        foreach v of local varsuffixes {
            if regexm("`v'", "`mainvar'_([0-9]+)$") {
                local vlab : variable label `v'
                if trim("`vlab'") == trim("`val'") {
                    local matchcode = regexs(1)
                    local matchvar  = "`v'"
                }
            }
        }

        if "`matchcode'" != "" {
            display as result "Matched `val' to existing code `matchcode'. Re-coding into main variable."
            replace `mainvar' = trim( ///
                subinstr(" " + `mainvar' + " ", " `others_code' ", " `matchcode' ", .) ///
            ) if strpos(" " + `mainvar' + " ", " `others_code' ") > 0 ///
                & trim(`othvar') == trim("`val'")
            replace `splitvar' = 0 if trim(`othvar') == trim("`val'")
            replace `matchvar' = 1 if trim(`othvar') == trim("`val'")
            foreach v of local varsuffixes {
                if regexm("`v'", "`mainvar'_`others_code'$") {
                    replace `v' = 0 if trim(`othvar') == trim("`val'")
                }
            }
            replace `othvar' = "" if trim(`othvar') == trim("`val'")

            * --- NEW: Remove duplicate codes after merge ---
            quietly {
                forvalues i = 1/`=_N' {
                    local codes = `mainvar'[`i']
                    local newcodes = ""
                    foreach c of local codes {
                        if strpos(" `newcodes' ", " `c' ") == 0 local newcodes "`newcodes' `c'"
                    }
                    replace `mainvar' = trim("`newcodes'") in `i'
                }
            }
        }
    }

    * --- STEP B: Create new codes only for frequent categories (>=10%) ---
    preserve
        keep if !missing(`othvar') & trim(`othvar') != ""
        local total = _N
        contract `othvar', freq(count)
        gen double percent = 100 * count / `total'
        keep if percent >= 10
        if _N == 0 {
            display as result "No frequent categories (>=10%). No new codes created."
            restore
            exit 0
        }
        list `othvar' count percent, noobs
        quietly levelsof `othvar', local(freq_othlist)
    restore

    foreach val of local freq_othlist {
        local ++maxcode
        local newvar = "`mainvar'_`maxcode'"
        capture confirm variable `newvar'
        if _rc {
            gen byte `newvar' = .
        }
        else {
            replace `newvar' = .
        }
        label var `newvar' "`val'"
        replace `newvar' = 1 if trim(`othvar') == trim("`val'")
        replace `newvar' = 0 if trim(`mainvar') != "" & `newvar' == .
        order `newvar', after(`splitvar')
        replace `splitvar' = 0 if trim(`othvar') == trim("`val'")
        foreach v of local varsuffixes {
            if regexm("`v'", "`mainvar'_`others_code'$") {
                replace `v' = 0 if trim(`othvar') == trim("`val'")
            }
        }
        replace `mainvar' = trim( ///
            subinstr(" " + `mainvar' + " ", " `others_code' ", " `maxcode' ", .) ///
        ) if strpos(" " + `mainvar' + " ", " `others_code' ") > 0 ///
            & trim(`othvar') == trim("`val'")
        replace `othvar' = "" if trim(`othvar') == trim("`val'")
        display as result "Created `newvar' for value: `val' (code `maxcode')"
    }

    display as result "Done. New codes started at 1001 and up (if any were added)."
end
