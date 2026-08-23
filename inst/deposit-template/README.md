# Source records for *School Boards and the Democratic Promise*

Primary source material for Jared E. Knowles, *School Boards and the Democratic
Promise*, PhD dissertation, University of Wisconsin–Madison, 2015 — a study of
school board elections across Wisconsin from 2002 to 2012.

**3,995 files, 1.6 GB.** This is the evidence layer: the records the dissertation's
datasets were transcribed from. It is deposited so that the analysis remains
auditable after the working copies, the hard drives and the author are gone.

## Why this exists separately from the code

The dissertation's analysis code, the transcribed datasets, and a containerised
build that reproduces the results are in the software repository:

> https://github.com/jknowles/schoolboardsPHD

Everything needed to *reproduce* the dissertation is there — including the 320
transcribed election-result CSVs, which are small. Nothing here is required to
run the analysis.

What is here is the layer underneath: roughly a thousand scanned canvass sheets
and clerk responses, agency records, and the raw statistical files those CSVs
were built from. Their value is not convenience but verification. If someone in
2040 doubts a number, this is what they check it against.

## Provenance

Assembled 2012–2014, principally by public records request:

- **Individual requests to Wisconsin school districts and county clerks**, for
  board election results and statements of the board of canvassers. Each was a
  lawful public-records request, released by the responsible records custodian
  at the district or county. Directory names frequently record the request that
  produced them (`osceolapublicrecordsasrequested`, `schoolboardelectionrequest`,
  `rerecordrequest`).
- **Wisconsin Department of Public Instruction** — district administrator
  directories, enrollment, finance, and student outcome reporting.
- **Wisconsin Employment Relations Commission** — union recertification election
  records following 2011 Act 10.
- **Wisconsin Government Accountability Board** — registered voter and
  participation counts, at municipality, ward and school district level.
- **Wisconsin Department of Administration** — municipal population and
  voting-age population estimates.
- **U.S. Census / NCES** — school district demographics and geography.

All of it is public record. None of it is individual-level voter data: the
Government Accountability Board and Department of Administration files here are
aggregate counts by municipality, ward or district.

## Contents

| Directory | Files | Size | What it is |
|---|---:|---:|---|
| `sbelectionresults/` | 1,564 | 1.1 GB | The core of the collection. One directory per school district (314 of them), holding scanned canvass statements and clerk responses (995 PDFs, 90 DOCs) alongside the 320 transcribed CSVs. |
| `WERCdata/` | 2,045 | 85 MB | Employment Relations Commission union recertification elections, 2002–2013, filed by year and month (1,910 DOCs, 58 PDFs). |
| `Raw Files/` | 199 | 399 MB | Election data, High School Completion files, revenue limits, ward geometry, and the Public DPI union high school shapefile. |
| `2000_Election_DataMM/` | 50 | 17 MB | 2000 Census election and geography crosswalk material, including MCDC `geocorr2k` output and Stata preparation scripts. |
| `TeacherCounts/` | 24 | 16 MB | Staff and teacher counts by district and year. |
| `wasbreport/` | 44 | 12 MB | Wisconsin Association of School Boards report material, plus the district administrator directory. |
| `gab/` | 9 | 6.0 MB | Government Accountability Board voter and candidate counts. |
| `figure/` | 45 | 18 MB | Working figures (PNG/SVG) from exploratory analysis. Output, not source — retained for completeness. |
| `contractChoices/` | 2 | 28 KB | Teacher contract choices following Act 10, including a *Wisconsin State Journal* compilation. |
| `address/` | 3 | 636 KB | A small working set for a district administrator survey mailing. Contains administrator names and work email addresses, the same class of public directory information the Department of Public Instruction publishes. |

## Two things to know before you use this

**The scans have no text layer.** The PDFs are images. They are not searchable
and text cannot be extracted from them without OCR. This is why the dissertation
transcribed them into CSVs by hand rather than parsing them, and it is the
single biggest practical obstacle to reusing this collection.

**Some files are superseded or scrapped.** Directories named `SCRAP`, `SCRAPPED`
and similar hold material the author examined and set aside. They are kept
because the decision to set something aside is itself part of the record. Three
district directories in `sbelectionresults/` (`Dover 1`,
`Goodman-Armstrong Creek`, `Rosendale`) contain no usable CSV for this reason.

## Integrity

`MANIFEST.sha256` lists a SHA-256 for every file. Verify with:

```bash
sha256sum -c MANIFEST.sha256
```

The software repository carries the same checksums for the subset it vendors, so
a file can be matched across both.

## What was removed

157 files of developer detritus — `.Rproj.user/` caches, `.Rhistory`, `.RData`,
and `.Rproj` files. Editor state, not records. Nothing else was withheld,
redacted or altered.

## Citation and licence

The records are public records of the State of Wisconsin and its subdivisions
and carry no copyright. To the extent any compilation right subsists in the way
they were assembled, it is waived under CC0 1.0.

Please cite the dissertation:

> Knowles, Jared E. (2015). *School Boards and the Democratic Promise.*
> PhD dissertation, University of Wisconsin–Madison.

and this deposit by its DOI.
