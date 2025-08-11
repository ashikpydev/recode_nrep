

# recode_nrep: Automated "Other Specify" Recoding

![Stata 17+](https://img.shields.io/badge/Stata-≥17.0-blue)
[![Apache License](https://img.shields.io/badge/License-Apache%202.0-green)](LICENSE)

Automate recoding of "Other specify" responses in survey data.

## Install
```stata
net install recode_nrep, from("https://raw.githubusercontent.com/ashikpydev/recode_nrep/main/") replace

help recode_nrep
```

## Usage
```stata
recode_nrep mainvar splitvar othvar

    mainvar: Primary variable (g1b4)
    splitvar: "Other" dummy (g1b4_97)
    othvar: Text variable (g1b4oth)
```

## Example

Before:

```
g1b4_97  Other |   21   9.86%
g1b4oth:
   He Plays | 7
   he walks | 14
```

Command:
```stata
recode_nrep g1b4 g1b4_97 g1b4oth
```

After:

```
g1b4_97  Other |    0   0.00%
g1b4_1001       |    7   3.29%  // He Plays
g1b4_1002       |   14   6.57%  // he walks
```

## Features

- Creates new variables for frequent responses
- Starts new codes at 1001
- Blanks processed text responses
- Requires ≥20% response frequency

## License

Apache 2.0 © 2025 Ashiqur Rahman Rony  
Email: ashiqurrahman.stat@gmail.com

# recode_nrep
