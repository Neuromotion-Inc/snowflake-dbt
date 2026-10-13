DEFINE DATABASE edi_file_ingestion;
DEFINE SCHEMA edi_file_ingestion.app;

-- The regular table in which EDI files will have their raw content loaded to
DEFINE TABLE edi_file_ingestion.app.edi_raw (
  file_path VARCHAR NOT NULL,
  raw_text VARCHAR NOT NULL,
  loaded_at TIMESTAMP_TZ NOT NULL DEFAULT CURRENT_TIMESTAMP()
);

-- snowflake treats staged files like tabular data, so EDI files (which need custom
-- python parsers) are read as a single "cell" in an uncompressed CSV file.
DEFINE FILE FORMAT edi_file_ingestion.app.ff_edi_raw
  TYPE = CSV
  FIELD_DELIMITER = NONE
  RECORD_DELIMITER = NONE
  COMPRESSION = NONE;

-- Records all new files & changes. The stage doesn't have AUTO_REFRESH = TRUE enabled,
-- however it appears as if Fivetran does refresh the directory as part of its sync.
-- The stage itself is owned by Fivetran and is not managed by this project.
DEFINE STREAM edi_file_ingestion.app.edi_file_stream
  ON STAGE FIVETRAN_DATABASE.AVAILITY."ALL";

DEFINE TASK edi_file_ingestion.app.load_edi_raw
  WAREHOUSE = ETL_WH
  WHEN SYSTEM$STREAM_HAS_DATA('edi_file_ingestion.app.edi_file_stream')
  STARTED
AS
  MERGE INTO edi_file_ingestion.app.edi_raw dest
  USING (
    SELECT
      s.RELATIVE_PATH AS file_path,
      f.$1 AS raw_text
    FROM edi_file_ingestion.app.edi_file_stream s
    JOIN @FIVETRAN_DATABASE.AVAILITY."ALL" (FILE_FORMAT => 'edi_file_ingestion.app.ff_edi_raw') f
      ON f.METADATA$FILENAME = s.RELATIVE_PATH
    -- new files and overwrites both appear as INSERT; latest always wins
    WHERE s.METADATA$ACTION = 'INSERT'
  ) src
  ON dest.file_path = src.file_path
  WHEN MATCHED THEN UPDATE SET
    raw_text = src.raw_text,
    loaded_at = CURRENT_TIMESTAMP()
  WHEN NOT MATCHED THEN INSERT (file_path, raw_text, loaded_at)
    VALUES (src.file_path, src.raw_text, CURRENT_TIMESTAMP());
