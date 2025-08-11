cap program drop recode
program define recode, rclass
    version 17.0

    // Require exactly 3 variables
    syntax varlist(min=3 max=3)

    local mainvar : word 1 of `varlist'
    local splitvar : word 2 of `varlist'
    local othvar : word 3 of `varlist'

    display as result "Main var: `mainvar'"
    display as result "Split var (others dummy): `splitvar'"
    display as result "Open-ended var: `othvar'"

    // Check variables exist
    foreach v in `mainvar' `splitvar' `othvar' {
        capture confirm variable `v'
        if _rc {
            display as error "Variable `v' not found. Please see help recode."
            exit 198
        }
    }

    // --- DYNAMIC extraction of others_code ---
    local last_us_pos = strpos(reverse("`splitvar'"), "_")
    if `last_us_pos' == 0 {
        display as error "Splitvar name missing underscore (_) for code extraction."
        exit 198
    }
    local last_us_split = length("`splitvar'") - `last_us_pos' + 1
    local others_code_raw = substr("`splitvar'", `last_us_split' + 1, .)
    local others_code = regexr("`others_code_raw'", "^_+", "")
    if "`others_code'" == "" {
        display as error "Could not detect others code from splitvar name."
        exit 198
    }
    display as result "Detected others code: `others_code'"

    // Count non-empty open-ended responses
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
        keep if percent >= 20
        if _N == 0 {
            display as result "No open-ended categories >= 20% frequency. Nothing to recode."
            restore
            exit 0
        }
        list `othvar' count percent, noobs
        quietly levelsof `othvar', local(othlist)
    restore

    // Find existing dummy variables matching mainvar_*
    ds `mainvar'_*
    local varsuffixes "`r(varlist)'"

    // Determine max numeric suffix starting at 1000
    local maxcode = 1000
    foreach v of local varsuffixes {
        if regexm("`v'", "`mainvar'_([0-9]+)$") {
            local num = real(regexs(1))
            if `num' > `maxcode' local maxcode = `num'
        }
    }

    // Create new dummy variables and recode mainvar
    foreach val of local othlist {
        local ++maxcode
        local newvar = "`mainvar'_`maxcode'"

        quietly capture confirm variable `newvar'
        if _rc {
            gen byte `newvar' = 0
        }
        else {
            replace `newvar' = 0
        }

        label var `newvar' "`val'"

        replace `newvar' = 1 if `othvar' == "`val'"
        replace `splitvar' = 0 if `othvar' == "`val'"

        // Replace mainvar values carefully by type
        capture confirm numeric variable `mainvar'
        if !_rc {
            // mainvar is numeric
            local others_code_num = real("`others_code'")
            replace `mainvar' = `maxcode' if `mainvar' == `others_code_num' & `othvar' == "`val'"
        }
        else {
            // mainvar is string
            local maxcode_str = string(`maxcode')
            replace `mainvar' = "`maxcode_str'" if `mainvar' == "`others_code'" & `othvar' == "`val'"
        }

        replace `othvar' = "" if `othvar' == "`val'"

        display as result "Created `newvar' for value: `val' (code `maxcode')"
    }

    display as result "Done. New codes started at 1001 and up (if any were added)."
end
