# Get-DuplicatePhotos

A script to locate duplicate image files between two sets of folders (e.g. Camera Roll folders vs other folders).

It is fairly common, for instance, to copy image files from your Camera Roll, and then leave traces of those edited copies around after modifying them. This script helps to locate those duplicates, assuming that they still have their original the image metadata (i.e. `Date Taken`).

## How it works

- The default duplicate criteria is to match only by `Date Taken` image attribute normalized to UTC (i.e. '2021-01-01 00:11:22').
    - Choose whether the duplicate criteria should also include file size and file hash.
- Searches two groups of folders (i.e. source and other) for image files with 'Date Taken' attribute.
- Compares files of the two groups of folders, identifying duplicates using the criteria you defined
- Finally, exports duplicates into a `duplicates.json` file.

## `duplicates.json`

For DateTaken-only criteria, the key is `DateTaken`, where `DateTaken` is in [`ISO 8601`](https://www.iso.org/iso-8601-date-and-time-format.html) format.

```json
{
    "2021-01-01T00:11:22": [
        "C:\\path\\to\\Camera Roll\\source.jpg", // The first file is the source file.
        "C:\\path\\to\\other folder\\duplicate.jpg", // The rest are duplicates.
        ...
    ],
    ...
}
```

For DateTaken, length, and file hash criteria, the key is `DateTaken-Length-FileHash`, where `DateTaken` is in [`ISO 8601`](https://www.iso.org/iso-8601-date-and-time-format.html) format, `Length` is a integer in bytes, and `FileHash`is an `MD5` hash value.

```json
{
    "2021-01-01T00:11:22-1234567-XXXXXXXXXX": [
        "C:\\path\\to\\Camera Roll\\source.jpg", // The first file is the source file.
        "C:\\path\\to\\other folder\\duplicate.jpg", // The rest are duplicates.
        ...
    ],
    ...
}
```
