## Overview

This repository provides a PowerShell script that automates the extraction and structuring of telemetry event IDs from the official Microsoft documentation, located in the [`dynamics365smb-devitpro-pb`](https://github.com/MicrosoftDocs/dynamics365smb-devitpro-pb) repository.

## Business Value

The script ensures that telemetry event signals are always in sync with the latest Business Central version.
This eliminates the need for manual maintenance and provides a reliable basis for telemetry analysis.

## Update Cycle

The file [`signals.json`](signals.json) is automatically refreshed every Sunday to reflect the latest changes in the Microsoft documentation.
If changes are identified earlier, the maintainer may trigger an update ahead of schedule.

---

*For more details, see the script itself or contact the repository maintainer.*

## Functionality

The script performs the following steps:

- Downloads the Markdown file containing telemetry event IDs from Microsoft.
- Extracts the columns **Event ID**, **Area**, and **Message** from all relevant tables (including included files).
- Cleans and processes the data (e.g., removes Markdown formatting).
- Exports the final result as a JSON file: [`signals.json`](signals.json).

## Usage

You can directly reference the generated JSON file in your KQL queries from this URL:
[https://raw.githubusercontent.com/frottke/bc-telemetry-event-ids/refs/heads/main/signals.json](https://raw.githubusercontent.com/frottke/bc-telemetry-event-ids/refs/heads/main/signals.json)

## Acknowledgements

A huge thanks goes to [@waldo1001]([https://](https://github.com/waldo1001))
 for his outstanding work on [waldo.BCTelemetry](https://github.com/waldo1001/waldo.BCTelemetry).
The repository provides an excellent Azure Data Explorer dashboard for Business Central telemetry, which perfectly complements the purpose of this project.

## Example

```python
let SignalDefinitions = externaldata(
        eventId:string,
        eventArea:string,
        eventDescription:string
    )
    [h@'https://raw.githubusercontent.com/frottke/bc-telemetry-event-ids/refs/heads/main/signals.json']
    with(format='multijson');
```