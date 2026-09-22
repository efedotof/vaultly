UPDATE users
SET recovery_public_key = regexp_replace(
        regexp_replace(recovery_public_key, '-----BEGIN [A-Z ]+-----', '', 'g'),
        '-----END [A-Z ]+-----', '', 'g'
    )
WHERE recovery_public_key IS NOT NULL;

UPDATE users
SET recovery_public_key = regexp_replace(recovery_public_key, '\s+', '', 'g')
WHERE recovery_public_key IS NOT NULL;