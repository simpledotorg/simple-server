SELECT DISTINCT ON (patient_id) id,
                                patient_id,
                                systolic,
                                diastolic,
                                device_created_at
FROM blood_pressures
ORDER BY patient_id, device_created_at DESC;