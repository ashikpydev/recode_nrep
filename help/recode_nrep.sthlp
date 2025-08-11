{smcl}
{* *! version 1.0.0 11aug2025}
{cmd:help recode_nrep}

{hline}
{title:Title}

    {cmd:recode_nrep} — Automatically recode_nrep "Other specify" responses in non-repeat group data

{hline}
{title:Syntax}

    {cmd:recode_nrep} {it:mainvar} {it:splitvar} {it:othvar}

{hline}
{title:Description}

    {cmd:recode_nrep} helps clean and recode_nrep open-ended "Other specify" responses 
    in non-repeat group survey variables, common in SurveyCTO, ODK, Kobo, etc.

    - {it:mainvar} is the coded response variable (numeric or string).
    - {it:splitvar} is a dummy variable indicating "Other specify" (e.g., code 97 or _97).
    - {it:othvar} contains the open-ended text responses.

    This program:
    {ul}
    {li} Automatically detects the "other" code from {it:splitvar}'s name.</li>
    {li} Finds common text responses (20% or more of cases) in {it:othvar}.</li>
    {li} Creates new dummy variables with new numeric codes starting at 1001.</li>
    {li} recode_nreps {it:mainvar} replacing the old "other" code with new codes.</li>
    {li} Clears recode_nrepd text from {it:othvar} and resets {it:splitvar} where recode_nrepd.</li>
    {/ul}

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
