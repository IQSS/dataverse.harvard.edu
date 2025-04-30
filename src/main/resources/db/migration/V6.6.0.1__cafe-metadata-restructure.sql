-- Create compound field 'cafeSourceData' for datasets with data
INSERT INTO datasetfield (datasetversion_id, datasetfieldtype_id)
SELECT DISTINCT df.datasetversion_id,
       dft_comp.id
FROM datasetfield df
JOIN datasetfieldtype dft ON df.datasetfieldtype_id = dft.id
JOIN datasetfieldtype dft_comp ON dft_comp.name = 'cafeSourceData'
WHERE dft.name IN (
    'cafeSourceDataTitle',
    'cafeSourceDataAuthor',
    'cafeSourceDataInstitution',
    'cafeSourceDataVersionNumber',
    'cafeSourceDataDOIOrURL',
    'cafeSourceDataLastModifiedDate',
    'cafeSourceDataDateObtained',
    'cafeSourceDataType',
    'cafeSourceDataTypeOther',
    'cafeSourceDataSpatialResolution',
    'cafeSourceDataSpatialResolutionUnit',
    'cafeSourceDataSpatialResolutionUnitOther',
    'cafeSourceDataTimestep',
    'cafeSourceDataTimestepOther',
    'cafeSourceDataAttribution',
    'cafeSourceDataDisclaimer'
)
  AND NOT EXISTS (
    SELECT 1 FROM datasetfield df2 
    WHERE df2.datasetversion_id = df.datasetversion_id 
      AND df2.datasetfieldtype_id = dft_comp.id
);

-- Create compoundvalue if it doesn't exist
INSERT INTO datasetfieldcompoundvalue (parentdatasetfield_id, displayorder)
SELECT df.id, 0
FROM datasetfield df
JOIN datasetfieldtype dft ON df.datasetfieldtype_id = dft.id
WHERE dft.name = 'cafeSourceData'
  AND NOT EXISTS (
    SELECT 1 FROM datasetfieldcompoundvalue dfcv 
    WHERE dfcv.parentdatasetfield_id = df.id
);

-- cafeSourceDataTitle
INSERT INTO datasetfield (datasetfieldtype_id, parentdatasetfieldcompoundvalue_id)
SELECT dft_new.id, dfcv.id FROM datasetfield df_comp
JOIN datasetfieldtype dft_comp ON df_comp.datasetfieldtype_id = dft_comp.id AND dft_comp.name = 'cafeSourceData'
JOIN datasetfieldcompoundvalue dfcv ON dfcv.parentdatasetfield_id = df_comp.id
JOIN datasetfield df_old ON df_old.datasetversion_id = df_comp.datasetversion_id
JOIN datasetfieldtype dft_old ON df_old.datasetfieldtype_id = dft_old.id AND dft_old.name = 'cafeSourceDataTitle'
JOIN datasetfieldtype dft_new ON dft_new.name = 'cafeSourceDataTitle'
WHERE EXISTS (SELECT 1 FROM datasetfieldvalue dfv WHERE dfv.datasetfield_id = df_old.id)
  AND NOT EXISTS (
    SELECT 1 FROM datasetfield df_new2
    JOIN datasetfieldtype dft_new2 ON df_new2.datasetfieldtype_id = dft_new2.id AND dft_new2.name = 'cafeSourceDataTitle'
    WHERE df_new2.parentdatasetfieldcompoundvalue_id = dfcv.id
  );

INSERT INTO datasetfieldvalue (datasetfield_id, value)
SELECT df_new.id, dfv.value FROM datasetfield df_new
JOIN datasetfieldtype dft_new ON df_new.datasetfieldtype_id = dft_new.id AND dft_new.name = 'cafeSourceDataTitle'
JOIN datasetfieldcompoundvalue dfcv ON df_new.parentdatasetfieldcompoundvalue_id = dfcv.id
JOIN datasetfield df_comp ON dfcv.parentdatasetfield_id = df_comp.id
JOIN datasetfieldtype dft_comp ON df_comp.datasetfieldtype_id = dft_comp.id AND dft_comp.name = 'cafeSourceData'
JOIN datasetfield df_old ON df_old.datasetversion_id = df_comp.datasetversion_id
JOIN datasetfieldtype dft_old ON df_old.datasetfieldtype_id = dft_old.id AND dft_old.name = 'cafeSourceDataTitle'
JOIN datasetfieldvalue dfv ON dfv.datasetfield_id = df_old.id;

DELETE FROM datasetfieldvalue WHERE datasetfield_id IN (
    SELECT df.id FROM datasetfield df JOIN datasetfieldtype dft ON df.datasetfieldtype_id = dft.id
    WHERE dft.name = 'cafeSourceDataTitle' AND df.parentdatasetfieldcompoundvalue_id IS NULL
);

DELETE FROM datasetfield WHERE datasetfieldtype_id = (
    SELECT id FROM datasetfieldtype WHERE name = 'cafeSourceDataTitle'
) AND parentdatasetfieldcompoundvalue_id IS NULL;

-- cafeSourceDataAuthor
-- Create compound field for datasets with author values
INSERT INTO datasetfield (datasetfieldtype_id, parentdatasetfieldcompoundvalue_id)
SELECT dft_new.id, dfcv.id FROM datasetfield df_comp
JOIN datasetfieldtype dft_comp ON df_comp.datasetfieldtype_id = dft_comp.id AND dft_comp.name = 'cafeSourceData'
JOIN datasetfieldcompoundvalue dfcv ON dfcv.parentdatasetfield_id = df_comp.id
JOIN datasetfield df_old ON df_old.datasetversion_id = df_comp.datasetversion_id
JOIN datasetfieldtype dft_old ON df_old.datasetfieldtype_id = dft_old.id AND dft_old.name = 'cafeSourceDataAuthor'
JOIN datasetfieldtype dft_new ON dft_new.name = 'cafeSourceDataAuthor'
WHERE EXISTS (SELECT 1 FROM datasetfieldvalue dfv WHERE dfv.datasetfield_id = df_old.id)
  AND NOT EXISTS (
    SELECT 1 FROM datasetfield df_new2
    JOIN datasetfieldtype dft_new2 ON df_new2.datasetfieldtype_id = dft_new2.id AND dft_new2.name = 'cafeSourceDataAuthor'
    WHERE df_new2.parentdatasetfieldcompoundvalue_id = dfcv.id
  );

-- Insert concatenated author values with semicolon separator
-- For each dataset, create a single value concatenated with all authors
INSERT INTO datasetfieldvalue (datasetfield_id, value)
SELECT 
    df_new.id, 
    (
        SELECT array_to_string(array_agg(dfv2.value ORDER BY dfv2.id), '; ')
        FROM datasetfield df_old2
        JOIN datasetfieldtype dft_old2 ON df_old2.datasetfieldtype_id = dft_old2.id AND dft_old2.name = 'cafeSourceDataAuthor'
        JOIN datasetfieldvalue dfv2 ON dfv2.datasetfield_id = df_old2.id
        WHERE df_old2.datasetversion_id = df_comp.datasetversion_id
    ) AS concatenated_value
FROM datasetfield df_new
JOIN datasetfieldtype dft_new ON df_new.datasetfieldtype_id = dft_new.id AND dft_new.name = 'cafeSourceDataAuthor'
JOIN datasetfieldcompoundvalue dfcv ON df_new.parentdatasetfieldcompoundvalue_id = dfcv.id
JOIN datasetfield df_comp ON dfcv.parentdatasetfield_id = df_comp.id
JOIN datasetfieldtype dft_comp ON df_comp.datasetfieldtype_id = dft_comp.id AND dft_comp.name = 'cafeSourceData';

-- Remove original author values and fields
DELETE FROM datasetfieldvalue WHERE datasetfield_id IN (
    SELECT df.id FROM datasetfield df JOIN datasetfieldtype dft ON df.datasetfieldtype_id = dft.id
    WHERE dft.name = 'cafeSourceDataAuthor' AND df.parentdatasetfieldcompoundvalue_id IS NULL
);

DELETE FROM datasetfield WHERE datasetfieldtype_id = (
    SELECT id FROM datasetfieldtype WHERE name = 'cafeSourceDataAuthor'
) AND parentdatasetfieldcompoundvalue_id IS NULL;


-- cafeSourceDataInstitution
INSERT INTO datasetfield (datasetfieldtype_id, parentdatasetfieldcompoundvalue_id)
SELECT dft_new.id, dfcv.id FROM datasetfield df_comp
JOIN datasetfieldtype dft_comp ON df_comp.datasetfieldtype_id = dft_comp.id AND dft_comp.name = 'cafeSourceData'
JOIN datasetfieldcompoundvalue dfcv ON dfcv.parentdatasetfield_id = df_comp.id
JOIN datasetfield df_old ON df_old.datasetversion_id = df_comp.datasetversion_id
JOIN datasetfieldtype dft_old ON df_old.datasetfieldtype_id = dft_old.id AND dft_old.name = 'cafeSourceDataInstitution'
JOIN datasetfieldtype dft_new ON dft_new.name = 'cafeSourceDataInstitution'
WHERE EXISTS (SELECT 1 FROM datasetfieldvalue dfv WHERE dfv.datasetfield_id = df_old.id);
INSERT INTO datasetfieldvalue (datasetfield_id, value)
SELECT df_new.id, dfv.value FROM datasetfield df_new
JOIN datasetfieldtype dft_new ON df_new.datasetfieldtype_id = dft_new.id AND dft_new.name = 'cafeSourceDataInstitution'
JOIN datasetfieldcompoundvalue dfcv ON df_new.parentdatasetfieldcompoundvalue_id = dfcv.id
JOIN datasetfield df_comp ON dfcv.parentdatasetfield_id = df_comp.id
JOIN datasetfieldtype dft_comp ON df_comp.datasetfieldtype_id = dft_comp.id AND dft_comp.name = 'cafeSourceData'
JOIN datasetfield df_old ON df_old.datasetversion_id = df_comp.datasetversion_id
JOIN datasetfieldtype dft_old ON df_old.datasetfieldtype_id = dft_old.id AND dft_old.name = 'cafeSourceDataInstitution'
JOIN datasetfieldvalue dfv ON dfv.datasetfield_id = df_old.id;
DELETE FROM datasetfieldvalue WHERE datasetfield_id IN (
    SELECT df.id FROM datasetfield df JOIN datasetfieldtype dft ON df.datasetfieldtype_id = dft.id
    WHERE dft.name = 'cafeSourceDataInstitution' AND df.parentdatasetfieldcompoundvalue_id IS NULL
);
DELETE FROM datasetfield WHERE datasetfieldtype_id = (
    SELECT id FROM datasetfieldtype WHERE name = 'cafeSourceDataInstitution'
) AND parentdatasetfieldcompoundvalue_id IS NULL;


-- cafeSourceDataVersionNumber
INSERT INTO datasetfield (datasetfieldtype_id, parentdatasetfieldcompoundvalue_id)
SELECT dft_new.id, dfcv.id FROM datasetfield df_comp
JOIN datasetfieldtype dft_comp ON df_comp.datasetfieldtype_id = dft_comp.id AND dft_comp.name = 'cafeSourceData'
JOIN datasetfieldcompoundvalue dfcv ON dfcv.parentdatasetfield_id = df_comp.id
JOIN datasetfield df_old ON df_old.datasetversion_id = df_comp.datasetversion_id
JOIN datasetfieldtype dft_old ON df_old.datasetfieldtype_id = dft_old.id AND dft_old.name = 'cafeSourceDataVersionNumber'
JOIN datasetfieldtype dft_new ON dft_new.name = 'cafeSourceDataVersionNumber'
WHERE EXISTS (SELECT 1 FROM datasetfieldvalue dfv WHERE dfv.datasetfield_id = df_old.id);
INSERT INTO datasetfieldvalue (datasetfield_id, value)
SELECT df_new.id, dfv.value FROM datasetfield df_new
JOIN datasetfieldtype dft_new ON df_new.datasetfieldtype_id = dft_new.id AND dft_new.name = 'cafeSourceDataVersionNumber'
JOIN datasetfieldcompoundvalue dfcv ON df_new.parentdatasetfieldcompoundvalue_id = dfcv.id
JOIN datasetfield df_comp ON dfcv.parentdatasetfield_id = df_comp.id
JOIN datasetfieldtype dft_comp ON df_comp.datasetfieldtype_id = dft_comp.id AND dft_comp.name = 'cafeSourceData'
JOIN datasetfield df_old ON df_old.datasetversion_id = df_comp.datasetversion_id
JOIN datasetfieldtype dft_old ON df_old.datasetfieldtype_id = dft_old.id AND dft_old.name = 'cafeSourceDataVersionNumber'
JOIN datasetfieldvalue dfv ON dfv.datasetfield_id = df_old.id;
DELETE FROM datasetfieldvalue WHERE datasetfield_id IN (
    SELECT df.id FROM datasetfield df JOIN datasetfieldtype dft ON df.datasetfieldtype_id = dft.id
    WHERE dft.name = 'cafeSourceDataVersionNumber' AND df.parentdatasetfieldcompoundvalue_id IS NULL
);
DELETE FROM datasetfield WHERE datasetfieldtype_id = (
    SELECT id FROM datasetfieldtype WHERE name = 'cafeSourceDataVersionNumber'
) AND parentdatasetfieldcompoundvalue_id IS NULL;


-- cafeSourceDataDOIOrURL
INSERT INTO datasetfield (datasetfieldtype_id, parentdatasetfieldcompoundvalue_id)
SELECT dft_new.id, dfcv.id FROM datasetfield df_comp
JOIN datasetfieldtype dft_comp ON df_comp.datasetfieldtype_id = dft_comp.id AND dft_comp.name = 'cafeSourceData'
JOIN datasetfieldcompoundvalue dfcv ON dfcv.parentdatasetfield_id = df_comp.id
JOIN datasetfield df_old ON df_old.datasetversion_id = df_comp.datasetversion_id
JOIN datasetfieldtype dft_old ON df_old.datasetfieldtype_id = dft_old.id AND dft_old.name = 'cafeSourceDataDOIOrURL'
JOIN datasetfieldtype dft_new ON dft_new.name = 'cafeSourceDataDOIOrURL'
WHERE EXISTS (SELECT 1 FROM datasetfieldvalue dfv WHERE dfv.datasetfield_id = df_old.id);
INSERT INTO datasetfieldvalue (datasetfield_id, value)
SELECT df_new.id, dfv.value FROM datasetfield df_new
JOIN datasetfieldtype dft_new ON df_new.datasetfieldtype_id = dft_new.id AND dft_new.name = 'cafeSourceDataDOIOrURL'
JOIN datasetfieldcompoundvalue dfcv ON df_new.parentdatasetfieldcompoundvalue_id = dfcv.id
JOIN datasetfield df_comp ON dfcv.parentdatasetfield_id = df_comp.id
JOIN datasetfieldtype dft_comp ON df_comp.datasetfieldtype_id = dft_comp.id AND dft_comp.name = 'cafeSourceData'
JOIN datasetfield df_old ON df_old.datasetversion_id = df_comp.datasetversion_id
JOIN datasetfieldtype dft_old ON df_old.datasetfieldtype_id = dft_old.id AND dft_old.name = 'cafeSourceDataDOIOrURL'
JOIN datasetfieldvalue dfv ON dfv.datasetfield_id = df_old.id;
DELETE FROM datasetfieldvalue WHERE datasetfield_id IN (
    SELECT df.id FROM datasetfield df JOIN datasetfieldtype dft ON df.datasetfieldtype_id = dft.id
    WHERE dft.name = 'cafeSourceDataDOIOrURL' AND df.parentdatasetfieldcompoundvalue_id IS NULL
);
DELETE FROM datasetfield WHERE datasetfieldtype_id = (
    SELECT id FROM datasetfieldtype WHERE name = 'cafeSourceDataDOIOrURL'
) AND parentdatasetfieldcompoundvalue_id IS NULL;


-- cafeSourceDataLastModifiedDate
INSERT INTO datasetfield (datasetfieldtype_id, parentdatasetfieldcompoundvalue_id)
SELECT dft_new.id, dfcv.id FROM datasetfield df_comp
JOIN datasetfieldtype dft_comp ON df_comp.datasetfieldtype_id = dft_comp.id AND dft_comp.name = 'cafeSourceData'
JOIN datasetfieldcompoundvalue dfcv ON dfcv.parentdatasetfield_id = df_comp.id
JOIN datasetfield df_old ON df_old.datasetversion_id = df_comp.datasetversion_id
JOIN datasetfieldtype dft_old ON df_old.datasetfieldtype_id = dft_old.id AND dft_old.name = 'cafeSourceDataLastModifiedDate'
JOIN datasetfieldtype dft_new ON dft_new.name = 'cafeSourceDataLastModifiedDate'
WHERE EXISTS (SELECT 1 FROM datasetfieldvalue dfv WHERE dfv.datasetfield_id = df_old.id);
INSERT INTO datasetfieldvalue (datasetfield_id, value)
SELECT df_new.id, dfv.value FROM datasetfield df_new
JOIN datasetfieldtype dft_new ON df_new.datasetfieldtype_id = dft_new.id AND dft_new.name = 'cafeSourceDataLastModifiedDate'
JOIN datasetfieldcompoundvalue dfcv ON df_new.parentdatasetfieldcompoundvalue_id = dfcv.id
JOIN datasetfield df_comp ON dfcv.parentdatasetfield_id = df_comp.id
JOIN datasetfieldtype dft_comp ON df_comp.datasetfieldtype_id = dft_comp.id AND dft_comp.name = 'cafeSourceData'
JOIN datasetfield df_old ON df_old.datasetversion_id = df_comp.datasetversion_id
JOIN datasetfieldtype dft_old ON df_old.datasetfieldtype_id = dft_old.id AND dft_old.name = 'cafeSourceDataLastModifiedDate'
JOIN datasetfieldvalue dfv ON dfv.datasetfield_id = df_old.id;
DELETE FROM datasetfieldvalue WHERE datasetfield_id IN (
    SELECT df.id FROM datasetfield df JOIN datasetfieldtype dft ON df.datasetfieldtype_id = dft.id
    WHERE dft.name = 'cafeSourceDataLastModifiedDate' AND df.parentdatasetfieldcompoundvalue_id IS NULL
);
DELETE FROM datasetfield WHERE datasetfieldtype_id = (
    SELECT id FROM datasetfieldtype WHERE name = 'cafeSourceDataLastModifiedDate'
) AND parentdatasetfieldcompoundvalue_id IS NULL;


-- cafeSourceDataDateObtained
INSERT INTO datasetfield (datasetfieldtype_id, parentdatasetfieldcompoundvalue_id)
SELECT dft_new.id, dfcv.id FROM datasetfield df_comp
JOIN datasetfieldtype dft_comp ON df_comp.datasetfieldtype_id = dft_comp.id AND dft_comp.name = 'cafeSourceData'
JOIN datasetfieldcompoundvalue dfcv ON dfcv.parentdatasetfield_id = df_comp.id
JOIN datasetfield df_old ON df_old.datasetversion_id = df_comp.datasetversion_id
JOIN datasetfieldtype dft_old ON df_old.datasetfieldtype_id = dft_old.id AND dft_old.name = 'cafeSourceDataDateObtained'
JOIN datasetfieldtype dft_new ON dft_new.name = 'cafeSourceDataDateObtained'
WHERE EXISTS (SELECT 1 FROM datasetfieldvalue dfv WHERE dfv.datasetfield_id = df_old.id);
INSERT INTO datasetfieldvalue (datasetfield_id, value)
SELECT df_new.id, dfv.value FROM datasetfield df_new
JOIN datasetfieldtype dft_new ON df_new.datasetfieldtype_id = dft_new.id AND dft_new.name = 'cafeSourceDataDateObtained'
JOIN datasetfieldcompoundvalue dfcv ON df_new.parentdatasetfieldcompoundvalue_id = dfcv.id
JOIN datasetfield df_comp ON dfcv.parentdatasetfield_id = df_comp.id
JOIN datasetfieldtype dft_comp ON df_comp.datasetfieldtype_id = dft_comp.id AND dft_comp.name = 'cafeSourceData'
JOIN datasetfield df_old ON df_old.datasetversion_id = df_comp.datasetversion_id
JOIN datasetfieldtype dft_old ON df_old.datasetfieldtype_id = dft_old.id AND dft_old.name = 'cafeSourceDataDateObtained'
JOIN datasetfieldvalue dfv ON dfv.datasetfield_id = df_old.id;
DELETE FROM datasetfieldvalue WHERE datasetfield_id IN (
    SELECT df.id FROM datasetfield df JOIN datasetfieldtype dft ON df.datasetfieldtype_id = dft.id
    WHERE dft.name = 'cafeSourceDataDateObtained' AND df.parentdatasetfieldcompoundvalue_id IS NULL
);
DELETE FROM datasetfield WHERE datasetfieldtype_id = (
    SELECT id FROM datasetfieldtype WHERE name = 'cafeSourceDataDateObtained'
) AND parentdatasetfieldcompoundvalue_id IS NULL;


-- cafeSourceDataType
-- Create compound fields for datasets with type values
INSERT INTO datasetfield (datasetfieldtype_id, parentdatasetfieldcompoundvalue_id)
SELECT DISTINCT dft_new.id, dfcv.id 
FROM datasetfield df_comp
JOIN datasetfieldtype dft_comp ON df_comp.datasetfieldtype_id = dft_comp.id AND dft_comp.name = 'cafeSourceData'
JOIN datasetfieldcompoundvalue dfcv ON dfcv.parentdatasetfield_id = df_comp.id
JOIN datasetfield df_old ON df_old.datasetversion_id = df_comp.datasetversion_id
JOIN datasetfieldtype dft_old ON df_old.datasetfieldtype_id = dft_old.id AND dft_old.name = 'cafeSourceDataType'
JOIN datasetfieldtype dft_new ON dft_new.name = 'cafeSourceDataType'
WHERE EXISTS (
    SELECT 1 FROM datasetfield_controlledvocabularyvalue dfcv2 
    WHERE dfcv2.datasetfield_id = df_old.id
)
AND NOT EXISTS (
    SELECT 1 FROM datasetfield df_new2
    JOIN datasetfieldtype dft_new2 ON df_new2.datasetfieldtype_id = dft_new2.id AND dft_new2.name = 'cafeSourceDataType'
    WHERE df_new2.parentdatasetfieldcompoundvalue_id = dfcv.id
);

-- Copy controlled vocabulary values
INSERT INTO datasetfield_controlledvocabularyvalue (datasetfield_id, controlledvocabularyvalues_id)
SELECT df_new.id, dfcv2.controlledvocabularyvalues_id
FROM datasetfield df_new
JOIN datasetfieldtype dft_new ON df_new.datasetfieldtype_id = dft_new.id AND dft_new.name = 'cafeSourceDataType'
JOIN datasetfieldcompoundvalue dfcv ON df_new.parentdatasetfieldcompoundvalue_id = dfcv.id
JOIN datasetfield df_comp ON dfcv.parentdatasetfield_id = df_comp.id
JOIN datasetfieldtype dft_comp ON df_comp.datasetfieldtype_id = dft_comp.id AND dft_comp.name = 'cafeSourceData'
JOIN datasetfield df_old ON df_old.datasetversion_id = df_comp.datasetversion_id
JOIN datasetfieldtype dft_old ON df_old.datasetfieldtype_id = dft_old.id AND dft_old.name = 'cafeSourceDataType'
JOIN datasetfield_controlledvocabularyvalue dfcv2 ON dfcv2.datasetfield_id = df_old.id;

-- Remove original references in datasetfield_controlledvocabularyvalue
DELETE FROM datasetfield_controlledvocabularyvalue 
WHERE datasetfield_id IN (
    SELECT df.id FROM datasetfield df 
    JOIN datasetfieldtype dft ON df.datasetfieldtype_id = dft.id
    WHERE dft.name = 'cafeSourceDataType' AND df.parentdatasetfieldcompoundvalue_id IS NULL
);

-- Remove original fields
DELETE FROM datasetfield 
WHERE datasetfieldtype_id = (
    SELECT id FROM datasetfieldtype WHERE name = 'cafeSourceDataType'
) AND parentdatasetfieldcompoundvalue_id IS NULL;


-- cafeSourceDataTypeOther
INSERT INTO datasetfield (datasetfieldtype_id, parentdatasetfieldcompoundvalue_id)
SELECT dft_new.id, dfcv.id FROM datasetfield df_comp
JOIN datasetfieldtype dft_comp ON df_comp.datasetfieldtype_id = dft_comp.id AND dft_comp.name = 'cafeSourceData'
JOIN datasetfieldcompoundvalue dfcv ON dfcv.parentdatasetfield_id = df_comp.id
JOIN datasetfield df_old ON df_old.datasetversion_id = df_comp.datasetversion_id
JOIN datasetfieldtype dft_old ON df_old.datasetfieldtype_id = dft_old.id AND dft_old.name = 'cafeSourceDataTypeOther'
JOIN datasetfieldtype dft_new ON dft_new.name = 'cafeSourceDataTypeOther'
WHERE EXISTS (SELECT 1 FROM datasetfieldvalue dfv WHERE dfv.datasetfield_id = df_old.id);
INSERT INTO datasetfieldvalue (datasetfield_id, value)
SELECT df_new.id, dfv.value FROM datasetfield df_new
JOIN datasetfieldtype dft_new ON df_new.datasetfieldtype_id = dft_new.id AND dft_new.name = 'cafeSourceDataTypeOther'
JOIN datasetfieldcompoundvalue dfcv ON df_new.parentdatasetfieldcompoundvalue_id = dfcv.id
JOIN datasetfield df_comp ON dfcv.parentdatasetfield_id = df_comp.id
JOIN datasetfieldtype dft_comp ON df_comp.datasetfieldtype_id = dft_comp.id AND dft_comp.name = 'cafeSourceData'
JOIN datasetfield df_old ON df_old.datasetversion_id = df_comp.datasetversion_id
JOIN datasetfieldtype dft_old ON df_old.datasetfieldtype_id = dft_old.id AND dft_old.name = 'cafeSourceDataTypeOther'
JOIN datasetfieldvalue dfv ON dfv.datasetfield_id = df_old.id;
DELETE FROM datasetfieldvalue WHERE datasetfield_id IN (
    SELECT df.id FROM datasetfield df JOIN datasetfieldtype dft ON df.datasetfieldtype_id = dft.id
    WHERE dft.name = 'cafeSourceDataTypeOther' AND df.parentdatasetfieldcompoundvalue_id IS NULL
);
DELETE FROM datasetfield WHERE datasetfieldtype_id = (
    SELECT id FROM datasetfieldtype WHERE name = 'cafeSourceDataTypeOther'
) AND parentdatasetfieldcompoundvalue_id IS NULL;


-- cafeSourceDataSpatialResolution
-- Create compound fields for datasets with spatial resolution values
INSERT INTO datasetfield (datasetfieldtype_id, parentdatasetfieldcompoundvalue_id)
SELECT DISTINCT dft_new.id, dfcv.id 
FROM datasetfield df_comp
JOIN datasetfieldtype dft_comp ON df_comp.datasetfieldtype_id = dft_comp.id AND dft_comp.name = 'cafeSourceData'
JOIN datasetfieldcompoundvalue dfcv ON dfcv.parentdatasetfield_id = df_comp.id
JOIN datasetfield df_old ON df_old.datasetversion_id = df_comp.datasetversion_id
JOIN datasetfieldtype dft_old ON df_old.datasetfieldtype_id = dft_old.id AND dft_old.name = 'cafeSourceDataSpatialResolution'
JOIN datasetfieldtype dft_new ON dft_new.name = 'cafeSourceDataSpatialResolution'
WHERE EXISTS (
    SELECT 1 FROM datasetfield df_sub
    JOIN datasetfieldtype dft_sub ON df_sub.datasetfieldtype_id = dft_sub.id
    WHERE dft_sub.name IN ('cafeSourceDataSpatialValue', 'cafeSourceDataSpatialResolutionUnit', 'cafeSourceDataSpatialResolutionUnitOther')
    AND df_sub.parentdatasetfieldcompoundvalue_id IN (
        SELECT dfcv2.id FROM datasetfieldcompoundvalue dfcv2
        JOIN datasetfield df_parent ON dfcv2.parentdatasetfield_id = df_parent.id
        WHERE df_parent.id = df_old.id
    )
)
AND NOT EXISTS (
    SELECT 1 FROM datasetfield df_new2
    JOIN datasetfieldtype dft_new2 ON df_new2.datasetfieldtype_id = dft_new2.id AND dft_new2.name = 'cafeSourceDataSpatialResolution'
    WHERE df_new2.parentdatasetfieldcompoundvalue_id = dfcv.id
);

-- cafeSourceDataSpatialResolutionUnit
-- Create compound fields for datasets with spatial resolution unit values
INSERT INTO datasetfield (datasetfieldtype_id, parentdatasetfieldcompoundvalue_id)
SELECT DISTINCT dft_new.id, dfcv.id 
FROM datasetfield df_comp
JOIN datasetfieldtype dft_comp ON df_comp.datasetfieldtype_id = dft_comp.id AND dft_comp.name = 'cafeSourceData'
JOIN datasetfieldcompoundvalue dfcv ON dfcv.parentdatasetfield_id = df_comp.id
JOIN datasetfield df_old ON df_old.datasetversion_id = df_comp.datasetversion_id
JOIN datasetfieldtype dft_old ON df_old.datasetfieldtype_id = dft_old.id AND dft_old.name = 'cafeSourceDataSpatialResolution'
JOIN datasetfieldtype dft_new ON dft_new.name = 'cafeSourceDataSpatialResolutionUnit'
WHERE EXISTS (
    SELECT 1 FROM datasetfield df_sub
    JOIN datasetfieldtype dft_sub ON df_sub.datasetfieldtype_id = dft_sub.id
    WHERE dft_sub.name = 'cafeSourceDataSpatialResolutionUnit'
    AND df_sub.parentdatasetfieldcompoundvalue_id IN (
        SELECT dfcv2.id FROM datasetfieldcompoundvalue dfcv2
        JOIN datasetfield df_parent ON dfcv2.parentdatasetfield_id = df_parent.id
        WHERE df_parent.id = df_old.id
    )
)
AND NOT EXISTS (
    SELECT 1 FROM datasetfield df_new2
    JOIN datasetfieldtype dft_new2 ON df_new2.datasetfieldtype_id = dft_new2.id AND dft_new2.name = 'cafeSourceDataSpatialResolutionUnit'
    WHERE df_new2.parentdatasetfieldcompoundvalue_id = dfcv.id
);

-- cafeSourceDataSpatialResolutionUnitOther
-- Create compound fields for datasets with spatial resolution unit other values
INSERT INTO datasetfield (datasetfieldtype_id, parentdatasetfieldcompoundvalue_id)
SELECT DISTINCT dft_new.id, dfcv.id 
FROM datasetfield df_comp
JOIN datasetfieldtype dft_comp ON df_comp.datasetfieldtype_id = dft_comp.id AND dft_comp.name = 'cafeSourceData'
JOIN datasetfieldcompoundvalue dfcv ON dfcv.parentdatasetfield_id = df_comp.id
JOIN datasetfield df_old ON df_old.datasetversion_id = df_comp.datasetversion_id
JOIN datasetfieldtype dft_old ON df_old.datasetfieldtype_id = dft_old.id AND dft_old.name = 'cafeSourceDataSpatialResolution'
JOIN datasetfieldtype dft_new ON dft_new.name = 'cafeSourceDataSpatialResolutionUnitOther'
WHERE EXISTS (
    SELECT 1 FROM datasetfield df_sub
    JOIN datasetfieldtype dft_sub ON df_sub.datasetfieldtype_id = dft_sub.id
    WHERE dft_sub.name = 'cafeSourceDataSpatialResolutionUnitOther'
    AND df_sub.parentdatasetfieldcompoundvalue_id IN (
        SELECT dfcv2.id FROM datasetfieldcompoundvalue dfcv2
        JOIN datasetfield df_parent ON dfcv2.parentdatasetfield_id = df_parent.id
        WHERE df_parent.id = df_old.id
    )
)
AND NOT EXISTS (
    SELECT 1 FROM datasetfield df_new2
    JOIN datasetfieldtype dft_new2 ON df_new2.datasetfieldtype_id = dft_new2.id AND dft_new2.name = 'cafeSourceDataSpatialResolutionUnitOther'
    WHERE df_new2.parentdatasetfieldcompoundvalue_id = dfcv.id
);

-- Migrate spatial value values to spatial resolution
INSERT INTO datasetfieldvalue (datasetfield_id, value)
SELECT df_new.id, dfv.value
FROM datasetfield df_new
JOIN datasetfieldtype dft_new ON df_new.datasetfieldtype_id = dft_new.id AND dft_new.name = 'cafeSourceDataSpatialResolution'
JOIN datasetfieldcompoundvalue dfcv ON df_new.parentdatasetfieldcompoundvalue_id = dfcv.id
JOIN datasetfield df_comp ON dfcv.parentdatasetfield_id = df_comp.id
JOIN datasetfieldtype dft_comp ON df_comp.datasetfieldtype_id = dft_comp.id AND dft_comp.name = 'cafeSourceData'
JOIN datasetfield df_old ON df_old.datasetversion_id = df_comp.datasetversion_id
JOIN datasetfieldtype dft_old ON df_old.datasetfieldtype_id = dft_old.id AND dft_old.name = 'cafeSourceDataSpatialResolution'
JOIN datasetfieldcompoundvalue dfcv_parent ON dfcv_parent.parentdatasetfield_id = df_old.id
JOIN datasetfield df_sub ON df_sub.parentdatasetfieldcompoundvalue_id = dfcv_parent.id
JOIN datasetfieldtype dft_sub ON df_sub.datasetfieldtype_id = dft_sub.id AND dft_sub.name = 'cafeSourceDataSpatialValue'
JOIN datasetfieldvalue dfv ON dfv.datasetfield_id = df_sub.id;

-- Migrate spatial resolution unit values to spatial resolution
-- First, copy controlled vocabulary values
INSERT INTO datasetfield_controlledvocabularyvalue (datasetfield_id, controlledvocabularyvalues_id)
SELECT df_new.id, dfcv2.controlledvocabularyvalues_id
FROM datasetfield df_new
JOIN datasetfieldtype dft_new ON df_new.datasetfieldtype_id = dft_new.id AND dft_new.name = 'cafeSourceDataSpatialResolutionUnit'
JOIN datasetfieldcompoundvalue dfcv ON df_new.parentdatasetfieldcompoundvalue_id = dfcv.id
JOIN datasetfield df_comp ON dfcv.parentdatasetfield_id = df_comp.id
JOIN datasetfieldtype dft_comp ON df_comp.datasetfieldtype_id = dft_comp.id AND dft_comp.name = 'cafeSourceData'
JOIN datasetfield df_old ON df_old.datasetversion_id = df_comp.datasetversion_id
JOIN datasetfieldtype dft_old ON df_old.datasetfieldtype_id = dft_old.id AND dft_old.name = 'cafeSourceDataSpatialResolution'
JOIN datasetfieldcompoundvalue dfcv_parent ON dfcv_parent.parentdatasetfield_id = df_old.id
JOIN datasetfield df_sub ON df_sub.parentdatasetfieldcompoundvalue_id = dfcv_parent.id
JOIN datasetfieldtype dft_sub ON df_sub.datasetfieldtype_id = dft_sub.id AND dft_sub.name = 'cafeSourceDataSpatialResolutionUnit'
JOIN datasetfield_controlledvocabularyvalue dfcv2 ON dfcv2.datasetfield_id = df_sub.id;

-- Then, copy normal values
INSERT INTO datasetfieldvalue (datasetfield_id, value)
SELECT df_new.id, dfv.value
FROM datasetfield df_new
JOIN datasetfieldtype dft_new ON df_new.datasetfieldtype_id = dft_new.id AND dft_new.name = 'cafeSourceDataSpatialResolutionUnit'
JOIN datasetfieldcompoundvalue dfcv ON df_new.parentdatasetfieldcompoundvalue_id = dfcv.id
JOIN datasetfield df_comp ON dfcv.parentdatasetfield_id = df_comp.id
JOIN datasetfieldtype dft_comp ON df_comp.datasetfieldtype_id = dft_comp.id AND dft_comp.name = 'cafeSourceData'
JOIN datasetfield df_old ON df_old.datasetversion_id = df_comp.datasetversion_id
JOIN datasetfieldtype dft_old ON df_old.datasetfieldtype_id = dft_old.id AND dft_old.name = 'cafeSourceDataSpatialResolution'
JOIN datasetfieldcompoundvalue dfcv_parent ON dfcv_parent.parentdatasetfield_id = df_old.id
JOIN datasetfield df_sub ON df_sub.parentdatasetfieldcompoundvalue_id = dfcv_parent.id
JOIN datasetfieldtype dft_sub ON df_sub.datasetfieldtype_id = dft_sub.id AND dft_sub.name = 'cafeSourceDataSpatialResolutionUnit'
JOIN datasetfieldvalue dfv ON dfv.datasetfield_id = df_sub.id
WHERE NOT EXISTS (
    SELECT 1 FROM datasetfield_controlledvocabularyvalue dfcv2 
    WHERE dfcv2.datasetfield_id = df_sub.id
);

-- Migrate spatial resolution unit other values to spatial resolution unit other
INSERT INTO datasetfieldvalue (datasetfield_id, value)
SELECT df_new.id, dfv.value
FROM datasetfield df_new
JOIN datasetfieldtype dft_new ON df_new.datasetfieldtype_id = dft_new.id AND dft_new.name = 'cafeSourceDataSpatialResolutionUnitOther'
JOIN datasetfieldcompoundvalue dfcv ON df_new.parentdatasetfieldcompoundvalue_id = dfcv.id
JOIN datasetfield df_comp ON dfcv.parentdatasetfield_id = df_comp.id
JOIN datasetfieldtype dft_comp ON df_comp.datasetfieldtype_id = dft_comp.id AND dft_comp.name = 'cafeSourceData'
JOIN datasetfield df_old ON df_old.datasetversion_id = df_comp.datasetversion_id
JOIN datasetfieldtype dft_old ON df_old.datasetfieldtype_id = dft_old.id AND dft_old.name = 'cafeSourceDataSpatialResolution'
JOIN datasetfieldcompoundvalue dfcv_parent ON dfcv_parent.parentdatasetfield_id = df_old.id
JOIN datasetfield df_sub ON df_sub.parentdatasetfieldcompoundvalue_id = dfcv_parent.id
JOIN datasetfieldtype dft_sub ON df_sub.datasetfieldtype_id = dft_sub.id AND dft_sub.name = 'cafeSourceDataSpatialResolutionUnitOther'
JOIN datasetfieldvalue dfv ON dfv.datasetfield_id = df_sub.id;

-- Remove original references in datasetfield_controlledvocabularyvalue for subfields
DELETE FROM datasetfield_controlledvocabularyvalue 
WHERE datasetfield_id IN (
    SELECT df.id FROM datasetfield df 
    JOIN datasetfieldtype dft ON df.datasetfieldtype_id = dft.id
    WHERE dft.name = 'cafeSourceDataSpatialResolutionUnit' 
    AND df.parentdatasetfieldcompoundvalue_id IN (
        SELECT dfcv.id FROM datasetfieldcompoundvalue dfcv
        JOIN datasetfield df_parent ON dfcv.parentdatasetfield_id = df_parent.id
        JOIN datasetfieldtype dft_parent ON df_parent.datasetfieldtype_id = dft_parent.id
        WHERE dft_parent.name = 'cafeSourceDataSpatialResolution'
    )
);

-- Remove original values in datasetfieldvalue for subfields
DELETE FROM datasetfieldvalue 
WHERE datasetfield_id IN (
    SELECT df.id FROM datasetfield df 
    JOIN datasetfieldtype dft ON df.datasetfieldtype_id = dft.id
    WHERE dft.name IN ('cafeSourceDataSpatialValue', 'cafeSourceDataSpatialResolutionUnit', 'cafeSourceDataSpatialResolutionUnitOther')
    AND df.parentdatasetfieldcompoundvalue_id IN (
        SELECT dfcv.id FROM datasetfieldcompoundvalue dfcv
        JOIN datasetfield df_parent ON dfcv.parentdatasetfield_id = df_parent.id
        JOIN datasetfieldtype dft_parent ON df_parent.datasetfieldtype_id = dft_parent.id
        WHERE dft_parent.name = 'cafeSourceDataSpatialResolution'
    )
);

-- Remove references in datasetfieldcompoundvalue for subfields
DELETE FROM datasetfieldcompoundvalue
WHERE parentdatasetfield_id IN (
    SELECT df.id FROM datasetfield df 
    JOIN datasetfieldtype dft ON df.datasetfieldtype_id = dft.id
    WHERE dft.name IN ('cafeSourceDataSpatialValue', 'cafeSourceDataSpatialResolutionUnit', 'cafeSourceDataSpatialResolutionUnitOther')
    AND df.parentdatasetfieldcompoundvalue_id IN (
        SELECT dfcv.id FROM datasetfieldcompoundvalue dfcv
        JOIN datasetfield df_parent ON dfcv.parentdatasetfield_id = df_parent.id
        JOIN datasetfieldtype dft_parent ON df_parent.datasetfieldtype_id = dft_parent.id
        WHERE dft_parent.name = 'cafeSourceDataSpatialResolution'
    )
);

-- Remove subfields
DELETE FROM datasetfield 
WHERE datasetfieldtype_id IN (
    SELECT id FROM datasetfieldtype 
    WHERE name IN ('cafeSourceDataSpatialValue', 'cafeSourceDataSpatialResolutionUnit', 'cafeSourceDataSpatialResolutionUnitOther')
)
AND parentdatasetfieldcompoundvalue_id IN (
    SELECT dfcv.id FROM datasetfieldcompoundvalue dfcv
    JOIN datasetfield df_parent ON dfcv.parentdatasetfield_id = df_parent.id
    JOIN datasetfieldtype dft_parent ON df_parent.datasetfieldtype_id = dft_parent.id
    WHERE dft_parent.name = 'cafeSourceDataSpatialResolution'
);

-- Remove references in datasetfieldcompoundvalue for parent field
DELETE FROM datasetfieldcompoundvalue
WHERE parentdatasetfield_id IN (
    SELECT df.id FROM datasetfield df 
    JOIN datasetfieldtype dft ON df.datasetfieldtype_id = dft.id
    WHERE dft.name = 'cafeSourceDataSpatialResolution'
    AND df.parentdatasetfieldcompoundvalue_id IS NULL
);

-- Remove parent field
DELETE FROM datasetfield 
WHERE datasetfieldtype_id = (
    SELECT id FROM datasetfieldtype WHERE name = 'cafeSourceDataSpatialResolution'
) AND parentdatasetfieldcompoundvalue_id IS NULL;


-- cafeSourceDataTimestep
-- Create compound fields for datasets with timestep values
INSERT INTO datasetfield (datasetfieldtype_id, parentdatasetfieldcompoundvalue_id)
SELECT DISTINCT dft_new.id, dfcv.id 
FROM datasetfield df_comp
JOIN datasetfieldtype dft_comp ON df_comp.datasetfieldtype_id = dft_comp.id AND dft_comp.name = 'cafeSourceData'
JOIN datasetfieldcompoundvalue dfcv ON dfcv.parentdatasetfield_id = df_comp.id
JOIN datasetfield df_old ON df_old.datasetversion_id = df_comp.datasetversion_id
JOIN datasetfieldtype dft_old ON df_old.datasetfieldtype_id = dft_old.id AND dft_old.name = 'cafeSourceDataTimestep'
JOIN datasetfieldtype dft_new ON dft_new.name = 'cafeSourceDataTimestep'
WHERE EXISTS (
    SELECT 1 FROM datasetfield_controlledvocabularyvalue dfcv2 
    WHERE dfcv2.datasetfield_id = df_old.id
)
AND NOT EXISTS (
    SELECT 1 FROM datasetfield df_new2
    JOIN datasetfieldtype dft_new2 ON df_new2.datasetfieldtype_id = dft_new2.id AND dft_new2.name = 'cafeSourceDataTimestep'
    WHERE df_new2.parentdatasetfieldcompoundvalue_id = dfcv.id
);

-- Copy controlled vocabulary values
INSERT INTO datasetfield_controlledvocabularyvalue (datasetfield_id, controlledvocabularyvalues_id)
SELECT df_new.id, dfcv2.controlledvocabularyvalues_id
FROM datasetfield df_new
JOIN datasetfieldtype dft_new ON df_new.datasetfieldtype_id = dft_new.id AND dft_new.name = 'cafeSourceDataTimestep'
JOIN datasetfieldcompoundvalue dfcv ON df_new.parentdatasetfieldcompoundvalue_id = dfcv.id
JOIN datasetfield df_comp ON dfcv.parentdatasetfield_id = df_comp.id
JOIN datasetfieldtype dft_comp ON df_comp.datasetfieldtype_id = dft_comp.id AND dft_comp.name = 'cafeSourceData'
JOIN datasetfield df_old ON df_old.datasetversion_id = df_comp.datasetversion_id
JOIN datasetfieldtype dft_old ON df_old.datasetfieldtype_id = dft_old.id AND dft_old.name = 'cafeSourceDataTimestep'
JOIN datasetfield_controlledvocabularyvalue dfcv2 ON dfcv2.datasetfield_id = df_old.id;

-- Remove original references in datasetfield_controlledvocabularyvalue
DELETE FROM datasetfield_controlledvocabularyvalue 
WHERE datasetfield_id IN (
    SELECT df.id FROM datasetfield df 
    JOIN datasetfieldtype dft ON df.datasetfieldtype_id = dft.id
    WHERE dft.name = 'cafeSourceDataTimestep' AND df.parentdatasetfieldcompoundvalue_id IS NULL
);

-- Remove original fields
DELETE FROM datasetfield 
WHERE datasetfieldtype_id = (
    SELECT id FROM datasetfieldtype WHERE name = 'cafeSourceDataTimestep'
) AND parentdatasetfieldcompoundvalue_id IS NULL;


-- cafeSourceDataTimestepOther
INSERT INTO datasetfield (datasetfieldtype_id, parentdatasetfieldcompoundvalue_id)
SELECT dft_new.id, dfcv.id FROM datasetfield df_comp
JOIN datasetfieldtype dft_comp ON df_comp.datasetfieldtype_id = dft_comp.id AND dft_comp.name = 'cafeSourceData'
JOIN datasetfieldcompoundvalue dfcv ON dfcv.parentdatasetfield_id = df_comp.id
JOIN datasetfield df_old ON df_old.datasetversion_id = df_comp.datasetversion_id
JOIN datasetfieldtype dft_old ON df_old.datasetfieldtype_id = dft_old.id AND dft_old.name = 'cafeSourceDataTimestepOther'
JOIN datasetfieldtype dft_new ON dft_new.name = 'cafeSourceDataTimestepOther'
WHERE EXISTS (SELECT 1 FROM datasetfieldvalue dfv WHERE dfv.datasetfield_id = df_old.id);
INSERT INTO datasetfieldvalue (datasetfield_id, value)
SELECT df_new.id, dfv.value FROM datasetfield df_new
JOIN datasetfieldtype dft_new ON df_new.datasetfieldtype_id = dft_new.id AND dft_new.name = 'cafeSourceDataTimestepOther'
JOIN datasetfieldcompoundvalue dfcv ON df_new.parentdatasetfieldcompoundvalue_id = dfcv.id
JOIN datasetfield df_comp ON dfcv.parentdatasetfield_id = df_comp.id
JOIN datasetfieldtype dft_comp ON df_comp.datasetfieldtype_id = dft_comp.id AND dft_comp.name = 'cafeSourceData'
JOIN datasetfield df_old ON df_old.datasetversion_id = df_comp.datasetversion_id
JOIN datasetfieldtype dft_old ON df_old.datasetfieldtype_id = dft_old.id AND dft_old.name = 'cafeSourceDataTimestepOther'
JOIN datasetfieldvalue dfv ON dfv.datasetfield_id = df_old.id;
DELETE FROM datasetfieldvalue WHERE datasetfield_id IN (
    SELECT df.id FROM datasetfield df JOIN datasetfieldtype dft ON df.datasetfieldtype_id = dft.id
    WHERE dft.name = 'cafeSourceDataTimestepOther' AND df.parentdatasetfieldcompoundvalue_id IS NULL
);
DELETE FROM datasetfield WHERE datasetfieldtype_id = (
    SELECT id FROM datasetfieldtype WHERE name = 'cafeSourceDataTimestepOther'
) AND parentdatasetfieldcompoundvalue_id IS NULL;


-- cafeSourceDataAttribution
INSERT INTO datasetfield (datasetfieldtype_id, parentdatasetfieldcompoundvalue_id)
SELECT dft_new.id, dfcv.id FROM datasetfield df_comp
JOIN datasetfieldtype dft_comp ON df_comp.datasetfieldtype_id = dft_comp.id AND dft_comp.name = 'cafeSourceData'
JOIN datasetfieldcompoundvalue dfcv ON dfcv.parentdatasetfield_id = df_comp.id
JOIN datasetfield df_old ON df_old.datasetversion_id = df_comp.datasetversion_id
JOIN datasetfieldtype dft_old ON df_old.datasetfieldtype_id = dft_old.id AND dft_old.name = 'cafeSourceDataAttribution'
JOIN datasetfieldtype dft_new ON dft_new.name = 'cafeSourceDataAttribution'
WHERE EXISTS (SELECT 1 FROM datasetfieldvalue dfv WHERE dfv.datasetfield_id = df_old.id);
INSERT INTO datasetfieldvalue (datasetfield_id, value)
SELECT df_new.id, dfv.value FROM datasetfield df_new
JOIN datasetfieldtype dft_new ON df_new.datasetfieldtype_id = dft_new.id AND dft_new.name = 'cafeSourceDataAttribution'
JOIN datasetfieldcompoundvalue dfcv ON df_new.parentdatasetfieldcompoundvalue_id = dfcv.id
JOIN datasetfield df_comp ON dfcv.parentdatasetfield_id = df_comp.id
JOIN datasetfieldtype dft_comp ON df_comp.datasetfieldtype_id = dft_comp.id AND dft_comp.name = 'cafeSourceData'
JOIN datasetfield df_old ON df_old.datasetversion_id = df_comp.datasetversion_id
JOIN datasetfieldtype dft_old ON df_old.datasetfieldtype_id = dft_old.id AND dft_old.name = 'cafeSourceDataAttribution'
JOIN datasetfieldvalue dfv ON dfv.datasetfield_id = df_old.id;
DELETE FROM datasetfieldvalue WHERE datasetfield_id IN (
    SELECT df.id FROM datasetfield df JOIN datasetfieldtype dft ON df.datasetfieldtype_id = dft.id
    WHERE dft.name = 'cafeSourceDataAttribution' AND df.parentdatasetfieldcompoundvalue_id IS NULL
);
DELETE FROM datasetfield WHERE datasetfieldtype_id = (
    SELECT id FROM datasetfieldtype WHERE name = 'cafeSourceDataAttribution'
) AND parentdatasetfieldcompoundvalue_id IS NULL;


-- cafeSourceDataDisclaimer
INSERT INTO datasetfield (datasetfieldtype_id, parentdatasetfieldcompoundvalue_id)
SELECT dft_new.id, dfcv.id FROM datasetfield df_comp
JOIN datasetfieldtype dft_comp ON df_comp.datasetfieldtype_id = dft_comp.id AND dft_comp.name = 'cafeSourceData'
JOIN datasetfieldcompoundvalue dfcv ON dfcv.parentdatasetfield_id = df_comp.id
JOIN datasetfield df_old ON df_old.datasetversion_id = df_comp.datasetversion_id
JOIN datasetfieldtype dft_old ON df_old.datasetfieldtype_id = dft_old.id AND dft_old.name = 'cafeSourceDataDisclaimer'
JOIN datasetfieldtype dft_new ON dft_new.name = 'cafeSourceDataDisclaimer'
WHERE EXISTS (SELECT 1 FROM datasetfieldvalue dfv WHERE dfv.datasetfield_id = df_old.id);
INSERT INTO datasetfieldvalue (datasetfield_id, value)
SELECT df_new.id, dfv.value FROM datasetfield df_new
JOIN datasetfieldtype dft_new ON df_new.datasetfieldtype_id = dft_new.id AND dft_new.name = 'cafeSourceDataDisclaimer'
JOIN datasetfieldcompoundvalue dfcv ON df_new.parentdatasetfieldcompoundvalue_id = dfcv.id
JOIN datasetfield df_comp ON dfcv.parentdatasetfield_id = df_comp.id
JOIN datasetfieldtype dft_comp ON df_comp.datasetfieldtype_id = dft_comp.id AND dft_comp.name = 'cafeSourceData'
JOIN datasetfield df_old ON df_old.datasetversion_id = df_comp.datasetversion_id
JOIN datasetfieldtype dft_old ON df_old.datasetfieldtype_id = dft_old.id AND dft_old.name = 'cafeSourceDataDisclaimer'
JOIN datasetfieldvalue dfv ON dfv.datasetfield_id = df_old.id;
DELETE FROM datasetfieldvalue WHERE datasetfield_id IN (
    SELECT df.id FROM datasetfield df JOIN datasetfieldtype dft ON df.datasetfieldtype_id = dft.id
    WHERE dft.name = 'cafeSourceDataDisclaimer' AND df.parentdatasetfieldcompoundvalue_id IS NULL
);
DELETE FROM datasetfield WHERE datasetfieldtype_id = (
    SELECT id FROM datasetfieldtype WHERE name = 'cafeSourceDataDisclaimer'
) AND parentdatasetfieldcompoundvalue_id IS NULL;
