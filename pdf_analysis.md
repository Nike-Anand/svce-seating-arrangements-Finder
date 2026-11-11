Based on the debug output you provided, I can see the exact issue with the PDF parsing. Looking at the sample data:

`212720100103910-206MARINE BLOCK SECOND FLOORD2 2`

The format is: **RegisterNumber + HallCode + HallDescription + SeatCode + SerialNumber**

The current regex pattern `^(\d{2,3}-\d{3}|\d{3,4}|MPH - \d{2}).*?([A-Z]\d{1,2})\s+\d+` isn't matching because:

1. The hall code `10-206` comes immediately after the register number with no space
2. The seat code `D2` comes after the hall description with no clear separator

Let me fix this with a more precise pattern:

```dart
// Updated parsing logic for the exact format
final match = RegExp(r'^(\d{2,3}-\d{3}|\d{3,4}|MPH - \d{2})[A-Z\s]*?([A-Z]\d{1,2})\s+\d+\s*$').firstMatch(afterReg);
```

But looking at your data more carefully, I think the issue is simpler. The pattern should be:

```dart
// For: 212720100103910-206MARINE BLOCK SECOND FLOORD2 2
final pattern = RegExp(r'^(\d{2,3}-\d{3}|\d{3,4}).*?([A-Z]\d{1,2})\s+\d+\s*$');
```

This should match:
- `10-206` as hall code
- `D2` as seat code

The issue might be that the regex is too complex. Let me provide a simpler fix.