# Bangladesh Data Import

To convert the XLSX file provided by the NHF to a formatted CSV of patient data:

1. Name the XLSX file as `bangladesh.xlsx` and place it in the `lib/bangladesh/data/` directory.
1. From the project root, run the `to_csv` script with `ruby lib/bangladesh/to_csv.rb`
1. **Important**: Delete the first two blank rows from the resultant CSV `lib/bangladesh/data/bangladesh.csv` using any
   text editor.
1. From the project root, run the `to_patients` script with `ruby lib/bangladesh/to_patients.rb`

This will parse the CSV file and persist patient records to the database.
