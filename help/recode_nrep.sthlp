{smcl}
{* *! version 1.0.0 11aug2025}
{cmd:help recode_nrep}

{hline}
{title:Title}

    {cmd:recode_nrep} — Automatically recode "Other specify" responses in non-repeat group data

{hline}
{title:Syntax}

    {cmd:recode_nrep} {it:mainvar} {it:splitvar} {it:othvar}

{hline}
{title:Description}

    {cmd:recode_nrep} helps clean and recode open-ended "Other specify" responses
    in non-repeat group survey variables, common in SurveyCTO, ODK, Kobo, etc.

    - {it:mainvar} is the coded response variable (numeric or string).
    - {it:splitvar} is a dummy variable indicating "Other specify" (e.g., code 97 or _97).
    - {it:othvar} contains the open-ended text responses.

    This program:
    
    1. Automatically detects the "other" code from {it:splitvar}'s name.
    2. Finds common text responses (20% or more of cases) in {it:othvar}.
    3. Creates new dummy variables with new numeric codes starting at 1001.
    4. Recodes {it:mainvar} replacing the old "other" code with new codes.
    5. Clears recoded text from {it:othvar} and resets {it:splitvar} where recoded.

    This saves time and improves data cleaning efficiency.

{hline}
{title:Example}

    For variables:
    
    {codeblock 80}
    g208       // main coded variable
    g208_97    // dummy for "Other specify" selected (code 97)
    g208oth    // open-ended "Other specify" text
    {codeblock}

    Run:

    {codeblock 80}
    . recode_nrep g208 g208_97 g208oth
    {codeblock}

{hline}
{title:Author}

    Ashiqur Rahman Rony  
    Data Analyst, Development Research Initiative (dRi)  
    Email: ashiqur.rahman@dri-int.org  
    Alternate: ashiqurrahman.stat@gmail.com

{hline}
{title:Version}

    1.0.0 — 11 August 2025

{hline}
